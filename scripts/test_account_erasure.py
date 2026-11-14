"""Test réel (production) du droit à l'effacement : crée un compte JETABLE,
lui fait laisser des données partout (j'aime et réponses sur la publication
d'un compte de test, signal d'appareil partagé, match + message, photo de
conversation, affiche, photo de profil), appelle deleteAccount, puis vérifie
que plus rien ne subsiste. Le compte d'Amara (test) n'est jamais supprimé.

Usage : SEED_PASSWORD=... python scripts/test_account_erasure.py
(gcloud connecté ; compte de test Amara)."""
import json, os, re, subprocess, sys, time, urllib.request, urllib.error, urllib.parse

from target import PROJECT, BUCKET, API_KEY  # projet visé : voir scripts/target.py
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
EMAIL = f"erasure.test.{int(time.time())}@example.com"
PASSWORD = os.environ["SEED_PASSWORD"]
AMARA_EMAIL = "amara.test1@example.com"
AMARA = "q7mb6hpDHSfZd9jHeRnGvbY1L5p1"
DEVICE = f"erasure-test-device-{int(time.time())}"

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
    return http(method, f"{FS}/{path}", body, {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT})
def sign(path, payload):
    return http("POST", f"https://identitytoolkit.googleapis.com/v1/{path}?key={API_KEY}", payload)
def call(fn, data, token):
    h = {"Authorization": f"Bearer {token}"}
    return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, h)
def upload(name):
    return http("POST", f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=media&name={urllib.parse.quote(name, safe='')}",
                headers={"Authorization": f"Bearer {ADMIN}", "Content-Type": "image/jpeg", "x-goog-user-project": PROJECT}, raw=b"\xff\xd8\xff test")
def objects(prefix):
    s, r = http("GET", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o?prefix={urllib.parse.quote(prefix, safe='')}",
                headers={"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT})
    return [o["name"] for o in r.get("items", [])]
def fv(v): return {"stringValue": v}

# --- compte jetable
s, r = sign("accounts:signUp", {"email": EMAIL, "password": PASSWORD, "returnSecureToken": True})
assert s == 200, (s, r)
UID, TOKEN = r["localId"], r["idToken"]
s, r = sign("accounts:signInWithPassword", {"email": AMARA_EMAIL, "password": PASSWORD, "returnSecureToken": True})
AMARA_TOKEN = r["idToken"]
admin("PATCH", f"users/{UID}", {"fields": {"displayName": fv("Test Effacement"), "age": {"integerValue": "30"}}})
admin("PATCH", f"user_status/{UID}", {"fields": {"filtrageStatus": fv("active"), "sensitiveConsent": {"mapValue": {"fields": {"granted": {"booleanValue": True}, "version": {"integerValue": "1"}}}}}})

post_id = None
match_id = "_".join(sorted([UID, AMARA]))
try:
    s, r = call("createCommunityPost", {"type": "publication", "text": "[TEST AUTOMATIQUE] publication pour le test d'effacement"}, AMARA_TOKEN)
    post_id = r["result"]["postId"]
    s, r = call("togglePostLike", {"postId": post_id}, TOKEN)
    check("(préparation) j'aime posé par le compte jetable", s == 200 and r["result"]["liked"] is True, (s, r))
    s, r = call("replyToPost", {"postId": post_id, "text": "réponse à effacer"}, TOKEN)
    check("(préparation) réponse laissée par le compte jetable", s == 200, (s, r))
    call("togglePostLike", {"postId": post_id}, AMARA_TOKEN)
    call("replyToPost", {"postId": post_id, "text": "réponse d'Amara, à conserver"}, AMARA_TOKEN)

    s, r = call("registerDeviceSignal", {"deviceId": DEVICE}, AMARA_TOKEN)
    s, r = call("registerDeviceSignal", {"deviceId": DEVICE}, TOKEN)
    check("(préparation) signal d'appareil partagé avec Amara", s == 200, (s, r))
    s, dev = admin("GET", f"device_signals/{DEVICE}")
    uids_before = [v["stringValue"] for v in dev["fields"]["uids"]["arrayValue"]["values"]]
    check("(préparation) l'appareil référence les deux comptes", set(uids_before) == {UID, AMARA}, uids_before)

    admin("PATCH", f"matches/{match_id}", {"fields": {"members": {"arrayValue": {"values": [fv(UID), fv(AMARA)]}}, "uid1": fv(min(UID, AMARA)), "uid2": fv(max(UID, AMARA))}})
    admin("POST", f"matches/{match_id}/messages", {"fields": {"fromUid": fv(UID), "text": fv("message à effacer")}})
    upload(f"chat_photos/{match_id}/test.jpg")
    upload(f"event_posters/{UID}/test.jpg")
    upload(f"profile_photos/{UID}/test.jpg")
    check("(préparation) fichiers Storage en place",
          len(objects(f"chat_photos/{match_id}/")) == 1 and len(objects(f"event_posters/{UID}/")) == 1 and len(objects(f"profile_photos/{UID}/")) == 1)

    # --- l'effacement
    s, r = call("deleteAccount", {}, TOKEN)
    check("deleteAccount accepté", s == 200 and r.get("result", {}).get("ok") is True, (s, r))

    # --- vérifications
    s, replies = admin("GET", f"community_posts/{post_id}/replies")
    authors = [d["fields"]["authorUid"]["stringValue"] for d in replies.get("documents", [])]
    check("réponse du compte supprimé effacée", UID not in authors, authors)
    check("réponse d'Amara conservée", AMARA in authors, authors)
    s, likes = admin("GET", f"community_posts/{post_id}/likes")
    liker_ids = [d["name"].split("/")[-1] for d in likes.get("documents", [])]
    check("j'aime du compte supprimé effacé", UID not in liker_ids, liker_ids)
    check("j'aime d'Amara conservé", AMARA in liker_ids, liker_ids)
    s, dev = admin("GET", f"device_signals/{DEVICE}")
    uids_after = [v["stringValue"] for v in dev.get("fields", {}).get("uids", {}).get("arrayValue", {}).get("values", [])]
    check("signal d'appareil : le compte supprimé en est retiré, Amara y reste", uids_after == [AMARA], uids_after)
    check("match supprimé", admin("GET", f"matches/{match_id}")[0] == 404)
    check("photo de conversation supprimée de Storage", objects(f"chat_photos/{match_id}/") == [])
    check("affiche supprimée de Storage", objects(f"event_posters/{UID}/") == [])
    check("photo de profil supprimée de Storage", objects(f"profile_photos/{UID}/") == [])
    check("profil supprimé", admin("GET", f"users/{UID}")[0] == 404)
    check("statut supprimé", admin("GET", f"user_status/{UID}")[0] == 404)
    s, r = sign("accounts:signInWithPassword", {"email": EMAIL, "password": PASSWORD, "returnSecureToken": True})
    check("compte d'authentification supprimé", s == 400, (s, r))
finally:
    # nettoyage des données de test d'Amara
    if post_id:
        for coll in ("replies", "likes"):
            s, docs = admin("GET", f"community_posts/{post_id}/{coll}?pageSize=100")
            for d in docs.get("documents", []):
                admin("DELETE", f"community_posts/{post_id}/{coll}/" + d["name"].split("/")[-1])
        admin("DELETE", f"community_posts/{post_id}")
    admin("DELETE", f"device_signals/{DEVICE}")
    admin("DELETE", f"rate_limits/{AMARA}_reply_hour")
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
