"""Test réel (production, comptes JETABLES + Amara) du lot du 14/11/2026 :
envoi de messages par le serveur (sendMessage) et limites de fréquence,
limite des signalements, consentement RGPD art. 9, export complet des
données, suppression du selfie après décision, purge des comptes inactifs,
suppression des avis et des compteurs à la suppression du compte.

Crée ses comptes de test (aucun compte réel touché), nettoie tout à la fin.

Usage : SEED_PASSWORD=... PYTHONIOENCODING=utf-8 python scripts/test_messaging_rgpd.py
(gcloud connecté ; compte de test Amara)."""
import datetime, json, os, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
REGION = "europe-west1"
BUCKET = "djama-1c7f8.firebasestorage.app"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = re.search(r"apiKey: '([^']+)'", open(os.path.join(ROOT, "lib", "firebase_options.dart"), encoding="utf-8").read()).group(1)
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
FS_ROOT = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
PASSWORD = os.environ["SEED_PASSWORD"]
STAMP = int(time.time())
AMARA_EMAIL = "amara.test1@example.com"
AMARA = "q7mb6hpDHSfZd9jHeRnGvbY1L5p1"
AH = {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT}
now = datetime.datetime.now(datetime.timezone.utc)

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
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw_e = e.read().decode()
        try: return e.code, json.loads(raw_e)
        except Exception: return e.code, {"raw": raw_e[:200]}

def admin(method, path, body=None):
    return http(method, f"{FS_ROOT}/{path}", body, AH)
def sign(path, payload):
    return http("POST", f"https://identitytoolkit.googleapis.com/v1/{path}?key={API_KEY}", payload)
def call(fn, data, token):
    return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, {"Authorization": f"Bearer {token}"})
def code(r): return r.get("error", {}).get("status")
def message(r): return r.get("error", {}).get("message", "")
def fv(v): return {"stringValue": v}
def tsv(days): return {"timestampValue": (now - datetime.timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S.000Z")}
def upload(name):
    return http("POST", f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=media&name={urllib.parse.quote(name, safe='')}",
                headers={**AH, "Content-Type": "image/jpeg"}, raw=b"\xff\xd8\xff test")
def file_exists(name):
    return http("GET", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(name, safe='')}", headers=AH)[0] == 200
def delete_file(name):
    http("DELETE", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(name, safe='')}", headers=AH)
def set_uploader(name, uid):
    return http("PATCH", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(name, safe='')}",
                {"metadata": {"uploaderUid": uid}}, AH)
def auth_user_exists(uid):
    s, r = http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:lookup", {"localId": [uid]}, AH)
    return bool(r.get("users"))
def query_docs(collection, field, value):
    body = {"structuredQuery": {"from": [{"collectionId": collection}],
            "where": {"fieldFilter": {"field": {"fieldPath": field}, "op": "EQUAL", "value": {"stringValue": value}}}}}
    s, r = http("POST", f"{FS_ROOT}:runQuery", body, AH)
    return [x["document"]["name"] for x in r if isinstance(x, dict) and "document" in x] if isinstance(r, list) else []
def delete_by_name(name):
    http("DELETE", f"https://firestore.googleapis.com/v1/{name}", headers=AH)
def plain(v):
    k, val = next(iter(v.items()))
    if k == "mapValue": return {kk: plain(vv) for kk, vv in val.get("fields", {}).items()}
    if k == "arrayValue": return [plain(x) for x in val.get("values", [])]
    if k == "integerValue": return int(val)
    if k == "nullValue": return None
    return val

def new_account(label):
    s, r = sign("accounts:signUp", {"email": f"{label}.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    assert s == 200, (label, s, r)
    uid = r["localId"]
    admin("PATCH", f"users/{uid}", {"fields": {"displayName": fv(f"Test {label}"), "age": {"integerValue": "30"}}})
    admin("PATCH", f"user_status/{uid}", {"fields": {"filtrageStatus": fv("active")}})
    return uid, r["idToken"]

created = []
def cleanup_account(uid):
    for name in query_docs("moderation_requests", "reporterUid", uid):
        delete_by_name(name)
    for name in query_docs("admin_action_logs", "adminUid", uid):
        delete_by_name(name)
    http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:delete", {"localId": uid}, AH)
    for path in (f"users/{uid}", f"user_status/{uid}"):
        admin("DELETE", path)

s, r = sign("accounts:signInWithPassword", {"email": AMARA_EMAIL, "password": PASSWORD, "returnSecureToken": True})
A_TOKEN = r["idToken"]

J, J_TOKEN = new_account("rgpd-j")
K, K_TOKEN = new_account("rgpd-k")      # administrateur jetable
P, _ = new_account("rgpd-p")            # compte inactif jetable
created += [J, K, P]
MATCH = "_".join(sorted([J, AMARA]))
post_id = None
try:
    payload = {"displayName": "Test RGPD", "birthDate": "1995-01-01T00:00:00.000", "gender": "Femme", "seekingGenders": ["Homme"],
               "country": "France", "city": "Paris", "bio": "profil de test", "relationshipIntent": "relation_serieuse"}
    admin("PATCH", f"matches/{MATCH}", {"fields": {"members": {"arrayValue": {"values": [fv(J), fv(AMARA)]}}}})

    # ---------- consentement art. 9 : sans lui, rien ne passe
    s, r = call("saveProfil", payload, J_TOKEN)
    check("sans consentement : profil refusé (consent-required)", code(r) == "FAILED_PRECONDITION" and "consent-required" in message(r), (s, r))
    s, r = call("sendMessage", {"matchId": MATCH, "text": "sans consentement"}, J_TOKEN)
    check("sans consentement : envoi de message refusé", code(r) == "FAILED_PRECONDITION" and "consent-required" in message(r), (s, r))
    s, r = call("getLikes", {}, J_TOKEN)
    check("sans consentement : likes refusés", code(r) == "FAILED_PRECONDITION" and "consent-required" in message(r), (s, r))
    s, r = call("recordSensitiveConsent", {"granted": "oui", "version": 1}, J_TOKEN)
    check("consentement : valeur non booléenne refusée", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("recordSensitiveConsent", {"granted": True, "version": 99}, J_TOKEN)
    check("consentement donné sur une autre version du texte : refusé", code(r) == "FAILED_PRECONDITION" and "outdated" in message(r), (s, r))
    s, r = call("recordSensitiveConsent", {"granted": True}, J_TOKEN)
    check("consentement sans version : refusé", code(r) == "FAILED_PRECONDITION", (s, r))
    s, r = call("recordSensitiveConsent", {"granted": True, "version": 1}, J_TOKEN)
    check("consentement donné", s == 200, (s, r))
    s, st = admin("GET", f"user_status/{J}")
    consent = plain(st["fields"]["sensitiveConsent"])
    check("consentement enregistré (accord, version, date)", consent.get("granted") is True and consent.get("version") == 1 and "at" in consent, consent)
    s, r = call("saveProfil", payload, J_TOKEN)
    check("avec consentement : profil enregistré", s == 200, (s, r))

    # ---------- messagerie : envoi serveur

    s, r = call("sendMessage", {"matchId": MATCH, "text": "  bonjour  "}, J_TOKEN)
    check("sendMessage : message texte accepté", s == 200 and r["result"]["ok"] is True, (s, r))
    s, doc = admin("GET", f"matches/{MATCH}/messages/{r['result']['id']}") if s == 200 else (0, {})
    f = doc.get("fields", {})
    check("le message est enregistré par le serveur (expéditeur, texte nettoyé, lu par l'expéditeur)",
          f.get("fromUid", {}).get("stringValue") == J and f.get("text", {}).get("stringValue") == "bonjour"
          and [x["stringValue"] for x in f.get("readBy", {}).get("arrayValue", {}).get("values", [])] == [J], doc)

    s, r = http("POST", f"{FS_ROOT}/matches/{MATCH}/messages", {"fields": {"fromUid": fv(J), "text": fv("contournement")}},
                {"Authorization": f"Bearer {J_TOKEN}"})
    check("écriture directe d'un message refusée par les règles", s == 403, (s, r))

    s, r = call("sendMessage", {"matchId": MATCH, "text": "   "}, J_TOKEN)
    check("message vide refusé", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("sendMessage", {"matchId": MATCH, "text": "x" * 2001}, J_TOKEN)
    check("message de plus de 2000 caractères refusé", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("sendMessage", {"matchId": MATCH, "imageStoragePath": f"chat_photos/{J}_autre/x.jpg"}, J_TOKEN)
    check("photo hors du dossier de la conversation refusée", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("sendMessage", {"matchId": MATCH, "imageStoragePath": f"chat_photos/{MATCH}/absente.jpg"}, J_TOKEN)
    check("photo jamais envoyée dans Storage refusée", code(r) == "FAILED_PRECONDITION", (s, r))
    upload(f"chat_photos/{MATCH}/ok.jpg")
    s, r = call("sendMessage", {"matchId": MATCH, "imageStoragePath": f"chat_photos/{MATCH}/ok.jpg"}, J_TOKEN)
    check("photo sans auteur de dépôt inscrit : refusée", code(r) == "PERMISSION_DENIED", (s, r))
    set_uploader(f"chat_photos/{MATCH}/ok.jpg", AMARA)
    s, r = call("sendMessage", {"matchId": MATCH, "imageStoragePath": f"chat_photos/{MATCH}/ok.jpg"}, J_TOKEN)
    check("photo déposée par l'autre membre : refusée", code(r) == "PERMISSION_DENIED", (s, r))
    set_uploader(f"chat_photos/{MATCH}/ok.jpg", J)
    s, r = call("sendMessage", {"matchId": MATCH, "imageStoragePath": f"chat_photos/{MATCH}/ok.jpg"}, J_TOKEN)
    check("photo de conversation acceptée (auteur du dépôt = expéditeur)", s == 200, (s, r))

    s, r = call("sendMessage", {"matchId": MATCH, "text": "intrus"}, K_TOKEN)
    check("un non-membre de la conversation est refusé", code(r) == "PERMISSION_DENIED", (s, r))

    admin("PATCH", f"blocks/{MATCH}", {"fields": {"blockerUid": fv(AMARA), "blockedUid": fv(J)}})
    s, r = call("sendMessage", {"matchId": MATCH, "text": "malgré le blocage"}, J_TOKEN)
    check("conversation bloquée : envoi refusé", code(r) == "PERMISSION_DENIED", (s, r))
    admin("DELETE", f"blocks/{MATCH}")

    admin("PATCH", f"user_status/{J}?updateMask.fieldPaths=filtrageStatus", {"fields": {"filtrageStatus": fv("suspended")}})
    s, r = call("sendMessage", {"matchId": MATCH, "text": "suspendu"}, J_TOKEN)
    check("compte suspendu : envoi refusé", code(r) == "PERMISSION_DENIED", (s, r))
    admin("PATCH", f"user_status/{J}?updateMask.fieldPaths=filtrageStatus", {"fields": {"filtrageStatus": fv("active")}})

    # ---------- limite de fréquence : 20 messages par minute (2 déjà envoyés ci-dessus)
    ok_count, first_fail = 0, None
    for i in range(30):
        s, r = call("sendMessage", {"matchId": MATCH, "text": f"rafale {i}"}, J_TOKEN)
        if s == 200: ok_count += 1
        else:
            first_fail = r
            break
    check("limite de fréquence : exactement 20 messages par minute acceptés (2 + 18)", ok_count == 18, ok_count)
    check("au-delà : refus « trop de demandes »", first_fail is not None and code(first_fail) == "RESOURCE_EXHAUSTED", first_fail)
    s, r = call("sendMessage", {"matchId": MATCH, "text": "autre membre"}, A_TOKEN)
    check("la limite est par membre (Amara n'est pas bloquée)", s == 200, (s, r))
    s, rl = admin("GET", f"rate_limits/{J}_msg_min")
    check("compteur de fréquence enregistré côté serveur", s == 200 and plain(rl["fields"]["count"]) == 20, rl)

    # ---------- limite des signalements : 10 par heure
    s, r = call("reportUser", {"targetUid": AMARA, "reason": "autre", "details": 5}, J_TOKEN)
    check("signalement : détails non textuels refusés (avant tout quota)", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("reportUser", {"targetUid": AMARA, "reason": "autre", "details": "x" * 1001}, J_TOKEN)
    check("signalement : détails de plus de 1000 caractères refusés", code(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("reportUser", {"targetUid": AMARA, "reason": "autre", "matchId": MATCH, "messageId": "inexistant"}, J_TOKEN)
    check("signalement : message qui ne correspond pas refusé (sans consommer de quota)", code(r) == "INVALID_ARGUMENT", (s, r))
    ok_reports, fail = 0, None
    for i in range(14):
        s, r = call("reportUser", {"targetUid": AMARA, "reason": "autre", "details": f"[TEST AUTOMATIQUE] {i}"}, J_TOKEN)
        if s == 200: ok_reports += 1
        else:
            fail = r
            break
    check("signalements : 10 par heure acceptés", ok_reports == 10, ok_reports)
    check("signalements : le onzième est refusé (trop de demandes)", fail is not None and code(fail) == "RESOURCE_EXHAUSTED", fail)

    # ---------- consentement retiré : tout est de nouveau refusé
    call("recordSensitiveConsent", {"granted": False, "version": 1}, J_TOKEN)
    s_, r_ = call("saveProfil", payload, J_TOKEN)
    check("consentement retiré : profil de nouveau refusé", code(r_) == "FAILED_PRECONDITION" and "consent-required" in message(r_), (s_, r_))
    s_, r_ = call("sendMessage", {"matchId": MATCH, "text": "après retrait"}, J_TOKEN)
    check("consentement retiré : envoi de message refusé", code(r_) == "FAILED_PRECONDITION" and "consent-required" in message(r_), (s_, r_))
    call("recordSensitiveConsent", {"granted": True, "version": 1}, J_TOKEN)

    # ---------- données pour l'export, puis export complet
    s, r = call("createCommunityPost", {"type": "publication", "text": "[TEST AUTOMATIQUE] publication pour l'export"}, A_TOKEN)
    post_id = r["result"]["postId"]
    call("togglePostLike", {"postId": post_id}, J_TOKEN)
    call("replyToPost", {"postId": post_id, "text": "réponse pour l'export"}, J_TOKEN)
    admin("PATCH", f"community_posts/{post_id}/reviews/{J}", {"fields": {"uid": fv(J), "rating": {"integerValue": "4"}, "comment": fv("avis de test")}})
    admin("PATCH", f"users/{J}/photos/p1", {"fields": {"storagePath": fv(f"profile_photos/{J}/p1.jpg"), "status": fv("rejected"),
                                                      "rejectedBy": fv("auto_moderation"), "uploadedAt": tsv(1)}})
    upload(f"profile_photos/{J}/p1.jpg")
    # photo « piégée » : chemin du selfie d'un AUTRE membre (les règles l'interdisent
    # à la création ; on la pose par l'administration pour vérifier le garde-fou serveur)
    admin("PATCH", f"users/{J}/photos/evil", {"fields": {"storagePath": fv(f"identity_verifications/{K}/selfie.jpg"), "status": fv("pending"),
                                                        "uploadedAt": tsv(1)}})
    admin("PATCH", f"users/{J}/favorites/zz1", {"fields": {"createdAt": tsv(1)}})
    admin("PATCH", f"user_status/{J}?updateMask.fieldPaths=fcmTokens", {"fields": {"fcmTokens": {"arrayValue": {"values": [fv("jeton-secret-1")]}}}})

    s, r = call("exportMyData", {}, J_TOKEN)
    ex = r.get("result", {})
    check("export : appel accepté", s == 200, (s, r))
    check("export : messages envoyés (texte et photo)", any(m["text"] == "bonjour" for m in ex.get("messagesSent", [])) and any(m["sentPhoto"] for m in ex.get("messagesSent", [])), ex.get("messagesSent"))
    check("export : photo en fichier (lien de téléchargement) avec raison de refus",
          any(str(p_.get("downloadUrl") or "").startswith("https://") and p_.get("rejectedBy") == "auto_moderation" for p_ in ex.get("photos", [])), ex.get("photos"))
    evil = next((p_ for p_ in ex.get("photos", []) if p_["id"] == "evil"), None)
    check("export : un chemin Storage piégé (selfie d'un autre membre) n'est JAMAIS signé", evil is not None and evil.get("downloadUrl") is None, evil)
    check("export : événements en favori", len(ex.get("favoriteEvents", [])) == 1, ex.get("favoriteEvents"))
    check("export : pas d'identifiant interne d'un administrateur ni d'un autre membre dans le statut",
          not any(k.endswith("By") or k == "lastPassTargetUid" for k in (ex.get("status") or {})), list((ex.get("status") or {}).keys()))
    check("export : j'aime et réponses de la Communauté", len(ex.get("communityLikes", [])) == 1 and len(ex.get("communityReplies", [])) == 1, (ex.get("communityLikes"), ex.get("communityReplies")))
    check("export : avis sur un événement", len(ex.get("eventReviews", [])) == 1 and ex["eventReviews"][0]["rating"] == 4, ex.get("eventReviews"))
    check("export : signalements faits, sans désigner la personne visée",
          len(ex.get("reportsMade", [])) == 10 and all("targetUid" not in x for x in ex["reportsMade"]), ex.get("reportsMade"))
    check("export : jetons de notification remplacés par un simple nombre",
          ex.get("notificationDevices") == 1 and "fcmTokens" not in (ex.get("status") or {}) and "jeton-secret-1" not in json.dumps(ex), ex.get("notificationDevices"))
    check("export : consentement inclus, dates en texte lisible",
          (ex.get("status") or {}).get("sensitiveConsent", {}).get("granted") is True and isinstance(ex["status"]["sensitiveConsent"].get("at"), str), (ex.get("status") or {}).get("sensitiveConsent"))

    # ---------- selfie supprimé après la décision du modérateur
    admin_claims = http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:update",
                        {"localId": K, "customAttributes": json.dumps({"admin": True})}, AH)
    s, r = sign("accounts:signInWithPassword", {"email": f"rgpd-k.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    K_ADMIN_TOKEN = r["idToken"]
    selfie = f"identity_verifications/{J}/selfie.jpg"
    upload(selfie)
    s, r = call("submitIdentityVerification", {"storagePath": selfie}, J_TOKEN)
    check("(préparation) vérification d'identité déposée", s == 200 and file_exists(selfie), (s, r))
    s, r = call("adminReviewIdentityVerification", {"uid": J, "approve": True}, K_ADMIN_TOKEN)
    check("décision du modérateur acceptée", s == 200, (s, r))
    s2, r2 = call("adminReviewIdentityVerification", {"uid": J, "approve": True}, K_ADMIN_TOKEN)
    check("seconde décision sans demande en attente : refusée", code(r2) == "FAILED_PRECONDITION", (s2, r2))
    s2, r2 = call("adminReviewIdentityVerification", {"uid": J, "approve": "false"}, K_ADMIN_TOKEN)
    check("décision : booléen strict (« false » en texte refusé)", code(r2) == "INVALID_ARGUMENT", (s2, r2))
    s, st = admin("GET", f"user_status/{J}")
    f = st["fields"]
    check("selfie supprimé de Storage après la décision", not file_exists(selfie))
    check("la décision est conservée sans le chemin du selfie",
          "identityVerificationStoragePath" not in f and f["isVerified"]["booleanValue"] is True and f["identityVerificationStatus"]["stringValue"] == "verified", f)

    # ---------- purge des comptes inactifs (compte jetable P, 24 mois sans activité)
    admin("PATCH", f"user_status/{P}?updateMask.fieldPaths=lastActiveAt", {"fields": {"lastActiveAt": tsv(24 * 30.44)}})
    jobs = subprocess.run(f'gcloud scheduler jobs list --location={REGION} --project={PROJECT} --format="value(name)"',
                          shell=True, capture_output=True, text=True).stdout.split()
    job = next((j.split("/")[-1] for j in jobs if "purgeInactiveAccounts" in j), None)
    check("tâche planifiée purgeInactiveAccounts trouvée", job is not None, jobs)
    def run_job():
        return subprocess.run(f"gcloud scheduler jobs run {job} --location={REGION} --project={PROJECT}", shell=True, capture_output=True, text=True)
    if job:
        run_job()
        for _ in range(30):
            time.sleep(3)
            s, st = admin("GET", f"user_status/{P}")
            if "inactivityWarnUndeliveredAt" in st.get("fields", {}): break
        check("1re exécution, aucun appareil joignable : avertissement non remis, PAS de compte à rebours, compte conservé",
              "inactivityWarnUndeliveredAt" in st.get("fields", {}) and "inactivityWarnedAt" not in st.get("fields", {}) and auth_user_exists(P), st)
        admin("PATCH", f"user_status/{P}?updateMask.fieldPaths=inactivityWarnedAt", {"fields": {"inactivityWarnedAt": tsv(31)}})
        run_job()
        for _ in range(30):
            time.sleep(3)
            if admin("GET", f"user_status/{P}")[0] == 404: break
        check("2e exécution (30 jours après l'avertissement) : compte supprimé (données et compte d'authentification)",
              admin("GET", f"user_status/{P}")[0] == 404 and admin("GET", f"users/{P}")[0] == 404 and not auth_user_exists(P),
              (admin("GET", f"user_status/{P}")[0], auth_user_exists(P)))

    # ---------- suppression du compte : avis, compteurs, fichiers, places, invitations, blocages, favoris
    admin("PATCH", f"community_posts/{post_id}?updateMask.fieldPaths=participantsCount", {"fields": {"participantsCount": {"integerValue": "1"}}})
    admin("PATCH", f"community_posts/{post_id}/participations/{J}", {"fields": {"uid": fv(J), "status": fv("accepted"), "requestedAt": tsv(2)}})
    admin("PATCH", f"community_posts/{post_id}/participations/{K}", {"fields": {"uid": fv(K), "status": fv("waitlisted"), "requestedAt": tsv(1)}})
    admin("PATCH", f"community_posts/{post_id}/private/invitations",
          {"fields": {"invitedUids": {"arrayValue": {"values": [fv(J), fv(K)]}}}})
    admin("PATCH", f"blocks/{MATCH}", {"fields": {"blockerUid": fv(AMARA), "blockedUid": fv(J)}})
    s, r = call("deleteAccount", {}, J_TOKEN)
    check("deleteAccount accepté", s == 200, (s, r))
    check("avis de l'événement supprimé avec le compte", admin("GET", f"community_posts/{post_id}/reviews/{J}")[0] == 404)
    s, kp = admin("GET", f"community_posts/{post_id}/participations/{K}")
    check("place libérée : la liste d'attente est promue", plain(kp["fields"]["status"]) == "accepted", kp)
    s, pd = admin("GET", f"community_posts/{post_id}")
    check("place libérée : le compteur de participants reste juste (1 sortie, 1 entrée)", plain(pd["fields"]["participantsCount"]) == 1, pd.get("fields", {}).get("participantsCount"))
    check("participation du compte supprimé effacée", admin("GET", f"community_posts/{post_id}/participations/{J}")[0] == 404)
    s, inv = admin("GET", f"community_posts/{post_id}/private/invitations")
    check("liste d'invités : le compte supprimé en est retiré, l'autre reste", plain(inv["fields"]["invitedUids"]) == [K], inv)
    check("blocage dont le compte était la cible supprimé", admin("GET", f"blocks/{MATCH}")[0] == 404)
    check("événement en favori supprimé", admin("GET", f"users/{J}/favorites/zz1")[0] == 404)
    check("compteurs de fréquence supprimés avec le compte", admin("GET", f"rate_limits/{J}_msg_min")[0] == 404 and admin("GET", f"rate_limits/{J}_report_hour")[0] == 404)
    check("photo de profil supprimée de Storage", not file_exists(f"profile_photos/{J}/p1.jpg"))
finally:
    for name in query_docs("rate_limits", "uid", AMARA):
        delete_by_name(name)
    admin("DELETE", f"matches/{MATCH}")
    for pth in (f"chat_photos/{MATCH}/ok.jpg", f"identity_verifications/{J}/selfie.jpg", f"profile_photos/{J}/p1.jpg"):
        delete_file(pth)
    if post_id:
        for sub in ("replies", "likes", "reviews", "participations", "private"):
            s_, listing = admin("GET", f"community_posts/{post_id}/{sub}")
            for d in listing.get("documents", []):
                delete_by_name(d["name"])
        admin("DELETE", f"community_posts/{post_id}")
    if J:
        s_, listing = admin("GET", f"matches/{MATCH}/messages")
        for d in listing.get("documents", []):
            delete_by_name(d["name"])
    for uid in created:
        cleanup_account(uid)
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
