"""Vérifie que le consentement RGPD art. 9 est VRAIMENT imposé côté serveur,
pas seulement par l'écran de l'appli (un client modifié contourne un écran).

Un membre jetable SANS consentement tente chaque fonction de membre et un dépôt
de photo (Firestore) ; un second membre jetable, avec consentement, sert de
cible. Résultat attendu : tout est refusé « consent-required », sauf une courte
liste de fonctions volontairement ouvertes (supprimer son compte, exporter ses
données, donner ou retirer son consentement, signaler, alerte d'urgence, recours,
réglages de notification, jeton de notification, activité).

Tout est supprimé à la fin.

Usage : SEED_PASSWORD=... PYTHONIOENCODING=utf-8 python scripts/test_consent_enforced.py"""
import json, os, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

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

def http(method, url, body=None, headers=None, raw=None):
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    if raw is None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw_e = e.read().decode()
        try: return e.code, json.loads(raw_e)
        except Exception: return e.code, {"raw": raw_e[:200]}

def fv(v): return {"stringValue": v}
def admin(method, path, body=None): return http(method, f"{FS}/{path}", body, AH)
def sign(path, payload): return http("POST", f"https://identitytoolkit.googleapis.com/v1/{path}?key={API_KEY}", payload)
def call(fn, data, token): return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, {"Authorization": f"Bearer {token}"})
def msg(r): return r.get("error", {}).get("message", "")
def is_consent_refusal(r): return "consent-required" in msg(r)

CONSENT = {"mapValue": {"fields": {"granted": {"booleanValue": True}, "version": {"integerValue": "1"}}}}
created = []
def new_account(label, consent):
    s, r = sign("accounts:signUp", {"email": f"{label}.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    assert s == 200, (label, s, r)
    uid = r["localId"]
    fields = {"filtrageStatus": fv("active")}
    if consent:
        fields["sensitiveConsent"] = CONSENT
    admin("PATCH", f"user_status/{uid}", {"fields": fields})
    admin("PATCH", f"users/{uid}", {"fields": {"displayName": fv(f"Test {label}"), "age": {"integerValue": "30"}}})
    created.append(uid)
    return uid, r["idToken"]

N, N_T = new_account("cons-n", consent=False)   # sans consentement
M, M_T = new_account("cons-m", consent=True)    # avec consentement (cible)

# Fonctions de membre qui DOIVENT exiger le consentement, avec des arguments plausibles.
GATED = {
    "activateBoost": {}, "cancelParticipation": {"postId": "x"}, "checkInParticipant": {"postId": "x", "targetUid": M, "code": "A"},
    "computeCompatibility": {"targetUid": M}, "createCommunityPost": {"type": "publication", "text": "test"},
    "getCompatQuestions": {}, "getDiscoverCandidates": {}, "getEventLocation": {"postId": "x"}, "getEventShareCode": {"postId": "x"},
    "getLikes": {}, "inviteToEvent": {"postId": "x", "targetUid": M}, "recordSwipe": {"targetUid": M, "action": "pass"},
    "redeemEventInviteCode": {"code": "ABCDEF"}, "replyToPost": {"postId": "x", "text": "t"},
    "requestFiltrageReview": {}, "requestOrganizerStatus": {}, "requestParticipation": {"postId": "x"},
    "respondToParticipation": {"postId": "x", "targetUid": M, "accept": True}, "retractLike": {"targetUid": M},
    "saveProfil": {}, "sendMessage": {"matchId": "x_y", "text": "t"}, "startFiltrageAttempt": {},
    "submitEventReview": {"postId": "x", "rating": 5}, "submitFiltrageAttempt": {}, "submitIdentityVerification": {"storagePath": "x"},
    "togglePostLike": {"postId": "x"}, "undoLastSwipe": {}, "updateEventState": {"postId": "x", "eventState": "termine"},
    "updateMyLocation": {}, "useJetonToResurface": {},
}
# Fonctions volontairement ouvertes sans consentement (gestion du compte, sécurité).
OPEN = {
    "recordSensitiveConsent": {"granted": "x", "version": 1}, "exportMyData": None, "getProfileCompletion": {}, "listMyReports": {},
    "setNotificationPreferences": {}, "setProfileVisibility": {"hidden": True}, "registerFcmToken": {}, "unregisterFcmToken": {},
    "recordActivity": {}, "registerDeviceSignal": {}, "requestSanctionAppeal": {}, "reportUser": {"targetUid": M, "reason": "x"},
    "reportCommunityPost": {"postId": "x", "reason": "x"},
}

try:
    for fn, args in GATED.items():
        s, r = call(fn, args, N_T)
        check(f"sans consentement : {fn} refusée (consent-required)", is_consent_refusal(r), (s, msg(r)[:120]))
    for fn, args in OPEN.items():
        if args is None:
            continue
        s, r = call(fn, args, N_T)
        check(f"sans consentement : {fn} reste ouverte (compte, sécurité)", not is_consent_refusal(r), (s, msg(r)[:120]))

    # Photo de profil : l'analyse Cloud Vision est déclenchée par la création du
    # DOCUMENT de la photo (firestore.rules), pas par le dépôt du fichier. Storage
    # ne contrôle pas le consentement (essayé le 14/11/2026 : refusé à tous en
    # production, retiré) ; le fichier seul reste inerte. On vérifie donc ici le
    # document de la photo, qui est le vrai verrou.
    def create_photo_doc(uid, token, photo_id):
        name = f"projects/{PROJECT}/databases/(default)/documents/users/{uid}/photos/{photo_id}"
        body = {"writes": [{"update": {"name": name, "fields": {"status": fv("pending"), "storagePath": fv(f"profile_photos/{uid}/{photo_id}.jpg")}},
                            "updateTransforms": [{"fieldPath": "uploadedAt", "setToServerValue": "REQUEST_TIME"}],
                            "currentDocument": {"exists": False}}]}
        return http("POST", f"{FS}:commit", body, {"Authorization": f"Bearer {token}"})
    s, r = create_photo_doc(N, N_T, "avant")
    check("sans consentement : création du document d'une photo refusée par Firestore", s in (401, 403), (s, str(r)[:120]))
    s, r = create_photo_doc(M, M_T, "avec")
    check("avec consentement : création du document d'une photo acceptée (contrôle positif)", s == 200, (s, str(r)[:120]))
    for u, pid in ((N, "avant"), (M, "avec")):
        admin("DELETE", f"users/{u}/photos/{pid}")

    # Version périmée du consentement : refus aussi
    admin("PATCH", f"user_status/{M}?updateMask.fieldPaths=sensitiveConsent",
          {"fields": {"sensitiveConsent": {"mapValue": {"fields": {"granted": {"booleanValue": True}, "version": {"integerValue": "0"}}}}}})
    s, r = call("getLikes", {}, M_T)
    check("consentement donné pour une ANCIENNE version du texte : refusé", is_consent_refusal(r), (s, msg(r)[:120]))
    admin("PATCH", f"user_status/{M}?updateMask.fieldPaths=sensitiveConsent", {"fields": {"sensitiveConsent": CONSENT}})
    s, r = call("getLikes", {}, M_T)
    check("consentement valide : getLikes passe (contrôle positif)", s == 200, (s, msg(r)[:120]))

    # Compte NEUF (aucun document de statut, le consentement est demandé avant le questionnaire)
    s, r = sign("accounts:signUp", {"email": f"cons-new.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    NEW, NEW_T = r["localId"], r["idToken"]
    created.append(NEW)
    s, r = call("recordSensitiveConsent", {"granted": True, "version": 1}, NEW_T)
    s2, st = admin("GET", f"user_status/{NEW}")
    check("compte neuf : donner son consentement crée le statut (consentement avant le questionnaire)",
          s == 200 and s2 == 200 and "sensitiveConsent" in st.get("fields", {}), (s, s2))

    # Un compte supprimé dont le jeton serait encore valide ne peut pas se recréer en donnant son consentement
    http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:delete", {"localId": N}, AH)
    admin("DELETE", f"user_status/{N}")
    s, r = call("recordSensitiveConsent", {"granted": True, "version": 1}, N_T)
    s2, st = admin("GET", f"user_status/{N}")
    check("compte supprimé : le consentement ne recrée pas de statut fantôme", s2 == 404, (s, s2))
finally:
    for uid in created:
        http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:delete", {"localId": uid}, AH)
        for path in (f"users/{uid}", f"user_status/{uid}"):
            admin("DELETE", path)
        body = {"structuredQuery": {"from": [{"collectionId": "rate_limits"}],
                "where": {"fieldFilter": {"field": {"fieldPath": "uid"}, "op": "EQUAL", "value": {"stringValue": uid}}}}}
        s, rows = http("POST", f"{FS}:runQuery", body, AH)
        for row in rows if isinstance(rows, list) else []:
            if "document" in row:
                http("DELETE", f"https://firestore.googleapis.com/v1/{row['document']['name']}", None, AH)
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
