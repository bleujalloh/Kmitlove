"""Test de robustesse (production, comptes JETABLES) : appelle CHAQUE fonction
appelable avec des entrées absentes ou malformées (aucune donnée, objet vide,
champs de mauvais type, texte, liste) et signale toute réponse « INTERNAL »
(erreur 500 non maîtrisée). Une fonction bien écrite répond « paramètres
invalides » ou « refusé », jamais par un plantage : un plantage cache un
défaut (entrée non vérifiée, lecture de champ absent...) que personne n'a
encore rencontré.

Exclues par prudence (elles agiraient pour de vrai) : deleteAccount,
bootstrapFirstAdmin, triggerEmergencyAlert, adminSeedQuestionBanks.
Les comptes jetables (un membre, un administrateur) sont supprimés à la fin.

Usage : SEED_PASSWORD=... PYTHONIOENCODING=utf-8 python scripts/smoke_all_callables.py"""
import json, os, re, subprocess, sys, time, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = re.search(r"apiKey: '([^']+)'", open(os.path.join(ROOT, "lib", "firebase_options.dart"), encoding="utf-8").read()).group(1)
ADMIN_TOKEN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
AH = {"Authorization": f"Bearer {ADMIN_TOKEN}", "x-goog-user-project": PROJECT}
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
PASSWORD = os.environ["SEED_PASSWORD"]
STAMP = int(time.time())

MEMBER_FUNCTIONS = """activateBoost cancelParticipation checkInParticipant computeCompatibility createCommunityPost exportMyData
getCompatQuestions getDiscoverCandidates getEventLocation getEventShareCode getLikes getProfileCompletion inviteToEvent
listMyReports recordActivity recordSensitiveConsent recordSwipe redeemEventInviteCode registerDeviceSignal registerFcmToken
replyToPost reportCommunityPost reportUser requestFiltrageReview requestOrganizerStatus requestParticipation
requestSanctionAppeal respondToParticipation retractLike saveProfil sendMessage setNotificationPreferences
setProfileVisibility startFiltrageAttempt submitEventReview submitFiltrageAttempt submitIdentityVerification togglePostLike
undoLastSwipe unregisterFcmToken updateEventState updateMyLocation useJetonToResurface""".split()
ADMIN_FUNCTIONS = """adminCreateTip adminDeleteTip adminListActionLogs adminListIdentityVerifications adminListModerationRequests
adminListOrganizerRequests adminListPendingCommunityPosts adminListPendingPhotos adminListUsers adminResolveModerationRequest
adminReviewCommunityPost adminReviewIdentityVerification adminReviewOrganizerRequest adminReviewPhoto adminSetSuspension
adminSuspendOrganizer resolveFiltrageReview resolveSanctionAppeal""".split()

PAYLOADS = {
    "aucune donnée": None,
    "objet vide": {},
    "champs de mauvais type": {"postId": 5, "uid": 5, "targetUid": 5, "matchId": 5, "text": 5, "reason": 5, "code": 5,
                               "storagePath": 5, "action": 5, "approve": "oui", "granted": "oui", "answers": "x",
                               "requestId": 5, "tipId": 5, "photoId": 5, "attemptId": 5, "lat": "x", "lng": "x"},
    "texte": "abc",
    "liste": [],
}


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
    except Exception as e:  # délai dépassé, réseau
        return 0, {"raw": str(e)[:200]}


def sign(path, payload):
    return http("POST", f"https://identitytoolkit.googleapis.com/v1/{path}?key={API_KEY}", payload)


def new_account(label):
    s, r = sign("accounts:signUp", {"email": f"{label}.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
    assert s == 200, (label, s, r)
    uid = r["localId"]
    consent = {"mapValue": {"fields": {"granted": {"booleanValue": True}, "version": {"integerValue": "1"}}}}
    http("PATCH", f"{FS}/user_status/{uid}", {"fields": {"filtrageStatus": {"stringValue": "active"}, "sensitiveConsent": consent}}, AH)
    http("PATCH", f"{FS}/users/{uid}", {"fields": {"displayName": {"stringValue": f"Test {label}"}, "age": {"integerValue": "30"}}}, AH)
    return uid, r["idToken"]


U, U_TOKEN = new_account("smoke-u")
K, _ = new_account("smoke-k")
http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:update", {"localId": K, "customAttributes": json.dumps({"admin": True})}, AH)
s, r = sign("accounts:signInWithPassword", {"email": f"smoke-k.{STAMP}@example.com", "password": PASSWORD, "returnSecureToken": True})
K_TOKEN = r["idToken"]

problems, total = [], 0
try:
    for names, token, who in ((MEMBER_FUNCTIONS, U_TOKEN, "membre"), (ADMIN_FUNCTIONS, K_TOKEN, "admin")):
        for fn in names:
            for label, payload in PAYLOADS.items():
                total += 1
                s, r = http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": payload}, {"Authorization": f"Bearer {token}"})
                status = r.get("error", {}).get("status")
                if status == "INTERNAL" or s >= 500 or s == 0:
                    problems.append((fn, who, label, s, status, r.get("error", {}).get("message") or r.get("raw")))
                    print(f"PLANTAGE {fn} ({who}, {label}) -> {s} {status}")
finally:
    # le membre est supprimé par la vraie fonction (c'est aussi un test de plus) ; l'administrateur par l'API
    http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/deleteAccount", {"data": {}}, {"Authorization": f"Bearer {U_TOKEN}"})
    http("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:delete", {"localId": K}, AH)
    for uid in (U, K):
        for path in (f"users/{uid}", f"user_status/{uid}"):
            http("DELETE", f"{FS}/{path}", None, AH)
print(f"\n{total} appels, {len(problems)} plantage(s)")
by_fn = {}
for fn, who, label, s, status, msg in problems:
    by_fn.setdefault(fn, []).append((label, msg))
for fn, items in by_fn.items():
    print(f"- {fn}: {len(items)} entrée(s) qui plantent ({', '.join(sorted({l for l, _ in items}))})")
sys.exit(1 if problems else 0)
