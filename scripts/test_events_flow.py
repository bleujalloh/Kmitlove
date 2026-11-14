"""Test réel (production, comptes JETABLES) du parcours complet d'un événement :
création, demandes (acceptation automatique, liste d'attente, sur demande, sur
invitation), lieu précis, validation à l'entrée, annulation avec promotion de
la liste d'attente, avis, fin d'événement, invitations et code de partage.

Ce parcours n'avait jamais été joué de bout en bout : c'est là qu'a été trouvé,
le 14/11/2026, le défaut d'annulation d'une place confirmée. Tout est supprimé à
la fin (événements de test et comptes jetables).

Usage : SEED_PASSWORD=... PYTHONIOENCODING=utf-8 python scripts/test_events_flow.py"""
import json, os, re, subprocess, sys, time, urllib.request, urllib.error

from target import PROJECT, BUCKET, API_KEY  # projet visé : voir scripts/target.py
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADMIN_TOKEN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
AH = {"Authorization": f"Bearer {ADMIN_TOKEN}", "x-goog-user-project": PROJECT}
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
PASSWORD = os.environ["SEED_PASSWORD"]
STAMP = int(time.time())

results = []
def check(name, ok, detail=""):
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else f" -- {detail}"))

def http(method, url, body=None, headers=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, method=method, headers=headers or {})
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try: return e.code, json.loads(raw)
        except Exception: return e.code, {"raw": raw[:200]}

def admin(method, path, body=None): return http(method, f"{FS}/{path}", body, AH)
def sign(path, payload): return http("POST", f"https://identitytoolkit.googleapis.com/v1/{path}?key={API_KEY}", payload)
def call(fn, data, token): return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, {"Authorization": f"Bearer {token}"})
def code(r): return r.get("error", {}).get("status")
def fv(v): return {"stringValue": v}
def plain(v):
    k, val = next(iter(v.items()))
    if k == "mapValue": return {kk: plain(vv) for kk, vv in val.get("fields", {}).items()}
    if k == "arrayValue": return [plain(x) for x in val.get("values", [])]
    if k == "integerValue": return int(val)
    if k == "nullValue": return None
    return val
def doc_fields(path):
    s, r = admin("GET", path)
    return {k: plain(v) for k, v in r.get("fields", {}).items()} if s == 200 else None

CONSENT = {"mapValue": {"fields": {"granted": {"booleanValue": True}, "version": {"integerValue": "1"}}}}
created = []
def new_account(label, organizer=False):
    s, r = sign("accounts:signUp", {"email": f"{label}.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    assert s == 200, (label, s, r)
    uid = r["localId"]
    fields = {"filtrageStatus": fv("active"), "sensitiveConsent": CONSENT}
    if organizer:
        fields.update({"organizerStatus": fv("approved"), "isVerified": {"booleanValue": True}})
    admin("PATCH", f"user_status/{uid}", {"fields": fields})
    admin("PATCH", f"users/{uid}", {"fields": {"displayName": fv(f"Test {label}"), "age": {"integerValue": "30"}}})
    created.append(uid)
    return uid, r["idToken"]

O, O_T = new_account("ev-org", organizer=True)
P1, P1_T = new_account("ev-p1")
P2, P2_T = new_account("ev-p2")
P3, P3_T = new_account("ev-p3")
posts = []

def create_event(token, **extra):
    base = {"type": "evenement_public", "title": "[TEST AUTOMATIQUE] Soirée", "text": "événement de test",
            "eventDate": "2027-03-20T19:00:00", "capacity": 1, "preciseLocation": "12 rue des Tests",
            "category": "soiree", "format": "presentiel", "city": "Paris", "country": "France", "timezone": "Europe/Paris"}
    base.update(extra)
    s, r = call("createCommunityPost", base, token)
    if s != 200:
        return None, (s, r)
    pid = r["result"]["postId"]
    posts.append(pid)
    f = doc_fields(f"community_posts/{pid}")
    if f and f.get("status") != "published":
        admin("PATCH", f"community_posts/{pid}?updateMask.fieldPaths=status", {"fields": {"status": fv("published")}})
    return pid, None

try:
    # ---------- événement public, capacité 1
    E1, err = create_event(O_T)
    check("création d'un événement public", E1 is not None, err)
    if E1:
        s, r = call("requestParticipation", {"postId": E1}, P1_T)
        check("1re demande : acceptée automatiquement", s == 200 and r["result"]["status"] == "accepted", (s, r))
        s, r = call("requestParticipation", {"postId": E1}, P2_T)
        check("2e demande (événement complet) : liste d'attente", s == 200 and r["result"]["status"] == "waitlisted", (s, r))
        s, r = call("requestParticipation", {"postId": E1}, P1_T)
        check("demande en double refusée", code(r) == "ALREADY_EXISTS", (s, r))
        check("le compteur de participants vaut 1", doc_fields(f"community_posts/{E1}")["participantsCount"] == 1)

        s, r = call("getEventLocation", {"postId": E1}, P1_T)
        check("lieu précis : visible pour le participant accepté", s == 200 and "12 rue des Tests" in json.dumps(r), (s, r))
        s, r = call("getEventLocation", {"postId": E1}, P3_T)
        check("lieu précis : refusé à un membre sans demande", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("getEventLocation", {"postId": E1}, O_T)
        check("lieu précis : visible pour l'organisateur", s == 200, (s, r))

        code1 = doc_fields(f"community_posts/{E1}/participations/{P1}")["checkinCode"]
        s, r = call("checkInParticipant", {"postId": E1, "targetUid": P1, "code": "FAUX0000"}, O_T)
        check("entrée : mauvais code refusé", code(r) == "INVALID_ARGUMENT", (s, r))
        s, r = call("checkInParticipant", {"postId": E1, "targetUid": P1, "code": code1}, P3_T)
        check("entrée : un autre membre ne peut pas valider", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("checkInParticipant", {"postId": E1}, O_T)
        check("entrée : paramètres manquants -> réponse maîtrisée (pas de plantage)", code(r) == "INVALID_ARGUMENT", (s, r))
        s, r = call("checkInParticipant", {"postId": E1, "targetUid": P1, "code": code1}, O_T)
        check("entrée : bon code accepté par l'organisateur", s == 200, (s, r))
        check("la présence est enregistrée", doc_fields(f"community_posts/{E1}/participations/{P1}")["checkedIn"] is True)

        # annulation d'une place confirmée : la liste d'attente est promue (défaut corrigé le 14/11/2026)
        s, r = call("cancelParticipation", {"postId": E1}, P1_T)
        check("annulation d'une place confirmée : acceptée, la liste d'attente est promue",
              s == 200 and r["result"].get("promotedUid") == P2, (s, r))
        check("après promotion, le compteur reste à 1", doc_fields(f"community_posts/{E1}")["participantsCount"] == 1)
        check("la personne promue est acceptée, avec un code d'entrée",
              doc_fields(f"community_posts/{E1}/participations/{P2}").get("status") == "accepted"
              and doc_fields(f"community_posts/{E1}/participations/{P2}").get("checkinCode"))
        s, r = call("cancelParticipation", {"postId": E1}, P1_T)
        check("annuler deux fois : refusé", code(r) == "FAILED_PRECONDITION", (s, r))

        # avis
        s, r = call("submitEventReview", {"postId": E1, "rating": 5}, P2_T)
        check("avis AVANT la fin de l'événement : refusé (défaut corrigé le 14/11/2026)", code(r) == "FAILED_PRECONDITION", (s, r))
        s, r = call("updateEventState", {"postId": E1, "eventState": "termine"}, P2_T)
        check("fin d'événement : refusée à un participant", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("updateEventState", {"postId": E1, "eventState": "termine"}, O_T)
        check("fin d'événement déclarée par l'organisateur", s == 200, (s, r))
        s, r = call("updateEventState", {"postId": E1, "eventState": "annule"}, O_T)
        check("statut définitif : plus de changement", code(r) == "FAILED_PRECONDITION", (s, r))
        s, r = call("submitEventReview", {"postId": E1, "rating": 6}, P2_T)
        check("avis : note hors 1-5 refusée", code(r) == "INVALID_ARGUMENT", (s, r))
        s, r = call("submitEventReview", {"postId": E1, "rating": 5}, P3_T)
        check("avis : refusé à qui n'a pas participé", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("submitEventReview", {"postId": E1, "rating": 5, "comment": "super"}, P2_T)
        check("avis d'un participant accepté après l'événement", s == 200, (s, r))
        s, r = call("requestParticipation", {"postId": E1}, P3_T)
        check("demande sur un événement terminé : refusée", code(r) == "FAILED_PRECONDITION", (s, r))

    # ---------- événement « sur demande » : acceptation manuelle
    E2, err = create_event(O_T, type="evenement_prive", accessMode="sur_demande", capacity=5)
    check("création d'un événement sur demande", E2 is not None, err)
    if E2:
        s, r = call("requestParticipation", {"postId": E2}, P1_T)
        check("sur demande : la demande attend la réponse de l'organisateur", s == 200 and r["result"]["status"] == "pending", (s, r))
        s, r = call("respondToParticipation", {"postId": E2, "targetUid": P1, "accept": "false"}, O_T)
        check("réponse : « false » en texte refusé (il valait « oui » avant le 14/11/2026)", code(r) == "INVALID_ARGUMENT", (s, r))
        s, r = call("respondToParticipation", {"postId": E2, "targetUid": P1, "accept": True}, P3_T)
        check("réponse : refusée à un membre qui n'est pas l'organisateur", code(r) in ("PERMISSION_DENIED",), (s, r))
        s, r = call("respondToParticipation", {"postId": E2, "targetUid": P1, "accept": True}, O_T)
        check("réponse : acceptation par l'organisateur", s == 200, (s, r))
        check("acceptation : compteur à 1 et participation acceptée",
              doc_fields(f"community_posts/{E2}")["participantsCount"] == 1
              and doc_fields(f"community_posts/{E2}/participations/{P1}")["status"] == "accepted")
        s, r = call("respondToParticipation", {"postId": E2, "targetUid": P1, "accept": True}, O_T)
        check("réponse deux fois : refusée", code(r) == "FAILED_PRECONDITION", (s, r))

    # ---------- événement « sur invitation » : invitations et code de partage
    E3, err = create_event(O_T, type="evenement_prive", accessMode="sur_invitation", capacity=5, invitedUids=[P1])
    check("création d'un événement sur invitation", E3 is not None, err)
    if E3:
        # recherche d'un membre par prénom pour l'inviter
        s, r = call("searchMembersToInvite", {"query": "Test ev-p"}, O_T)
        found = {m["uid"] for m in r.get("result", {}).get("members", [])}
        check("recherche par prénom : l'organisateur trouve les membres (sans lui-même)", s == 200 and {P1, P2, P3} <= found and O not in found, (s, found))
        s, r = call("searchMembersToInvite", {"query": "tes"}, O_T)
        check("recherche : la casse de la saisie n'empêche pas de trouver", s == 200 and len(r["result"]["members"]) >= 3, (s, r))
        s, r = call("searchMembersToInvite", {"query": "ab"}, O_T)
        check("recherche : moins de 3 lettres refusé", code(r) == "INVALID_ARGUMENT", (s, r))
        s, r = call("searchMembersToInvite", {"query": "Test ev-p"}, P1_T)
        check("recherche : réservée aux organisateurs approuvés", code(r) == "PERMISSION_DENIED", (s, r))
        admin("PATCH", f"blocks/{'_'.join(sorted([O, P2]))}", {"fields": {"blockerUid": fv(O), "blockedUid": fv(P2)}})
        admin("PATCH", f"user_status/{P3}?updateMask.fieldPaths=profileHidden", {"fields": {"profileHidden": {"booleanValue": True}}})
        s, r = call("searchMembersToInvite", {"query": "Test ev-p"}, O_T)
        found = {m["uid"] for m in r.get("result", {}).get("members", [])}
        check("recherche : un membre bloqué ou au profil masqué n'apparaît pas", found == {P1}, found)
        admin("DELETE", f"blocks/{'_'.join(sorted([O, P2]))}")
        admin("PATCH", f"user_status/{P3}?updateMask.fieldPaths=profileHidden", {"fields": {"profileHidden": {"booleanValue": False}}})
        s, r = call("requestParticipation", {"postId": E3}, P2_T)
        check("sur invitation : un membre non invité est refusé", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("requestParticipation", {"postId": E3}, P1_T)
        check("sur invitation : le membre invité est accepté", s == 200 and r["result"]["status"] == "accepted", (s, r))
        s, r = call("inviteToEvent", {"postId": E3, "targetUid": P2}, P3_T)
        check("inviter : refusé à un membre qui n'est pas l'organisateur", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("inviteToEvent", {"postId": E3, "targetUid": P2}, O_T)
        check("inviter : accepté pour l'organisateur", s == 200, (s, r))
        s, r = call("requestParticipation", {"postId": E3}, P2_T)
        check("sur invitation : le membre invité ensuite est accepté", s == 200 and r["result"]["status"] == "accepted", (s, r))
        s, r = call("getEventShareCode", {"postId": E3}, P3_T)
        check("code de partage : refusé à un autre membre", code(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("getEventShareCode", {"postId": E3}, O_T)
        share = r.get("result", {}).get("code") or r.get("result", {}).get("shareCode")
        check("code de partage : donné à l'organisateur", s == 200 and bool(share), (s, r))
        if share:
            s, r = call("redeemEventInviteCode", {"code": "ZZZZZZ"}, P3_T)
            check("code de partage inconnu : refusé proprement", code(r) in ("NOT_FOUND", "INVALID_ARGUMENT"), (s, r))
            s, r = call("redeemEventInviteCode", {"code": share}, P3_T)
            check("code de partage : le membre est invité", s == 200, (s, r))
            s, r = call("requestParticipation", {"postId": E3}, P3_T)
            check("après le code : la demande est acceptée", s == 200 and r["result"]["status"] == "accepted", (s, r))
finally:
    for pid in posts:
        for sub in ("participations", "private", "reviews", "replies", "likes"):
            s, listing = admin("GET", f"community_posts/{pid}/{sub}")
            for d in listing.get("documents", []):
                http("DELETE", f"https://firestore.googleapis.com/v1/{d['name']}", None, AH)
        s, f = admin("GET", f"community_posts/{pid}")
        share_code = None
        admin("DELETE", f"community_posts/{pid}")
    # codes d'invitation créés par les événements de test
    for pid in posts:
        body = {"structuredQuery": {"from": [{"collectionId": "event_invite_codes"}],
                "where": {"fieldFilter": {"field": {"fieldPath": "postId"}, "op": "EQUAL", "value": {"stringValue": pid}}}}}
        s, rows = http("POST", f"{FS}:runQuery", body, AH)
        for row in rows if isinstance(rows, list) else []:
            if "document" in row:
                http("DELETE", f"https://firestore.googleapis.com/v1/{row['document']['name']}", None, AH)
    for uid in created:
        for coll in ("rate_limits",):
            body = {"structuredQuery": {"from": [{"collectionId": coll}],
                    "where": {"fieldFilter": {"field": {"fieldPath": "uid"}, "op": "EQUAL", "value": {"stringValue": uid}}}}}
            s, rows = http("POST", f"{FS}:runQuery", body, AH)
            for row in rows if isinstance(rows, list) else []:
                if "document" in row:
                    http("DELETE", f"https://firestore.googleapis.com/v1/{row['document']['name']}", None, AH)
        http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:delete", {"localId": uid}, AH)
        for path in (f"users/{uid}", f"user_status/{uid}"):
            admin("DELETE", path)
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
