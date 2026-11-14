"""Test réel (production, comptes de test uniquement) des j'aime, réponses et
signalements de réponses de la Communauté : usurpation, règles Firestore,
blocage, compte suspendu/non actif, limite de fréquence, signalement. Crée
puis supprime sa propre publication de test.

Usage : SEED_PASSWORD=... python scripts/test_post_interactions.py
(gcloud connecté ; comptes de test Amara, Fatou, Awa)."""
import json, os, re, subprocess, sys, time, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UIDS = {
    "amara": "q7mb6hpDHSfZd9jHeRnGvbY1L5p1",
    "fatou": "EKrW44oklyNWfs6HLFAhBIcRZe23",
    "awa": "qbK7VyDO5OMrNe49Um8cU72bxTq2",
}
EMAIL = {"amara": "amara.test1@example.com", "fatou": "fatou.test3@example.com", "awa": "awa.test5@example.com"}
PASSWORD = os.environ["SEED_PASSWORD"]  # mot de passe des comptes de test (jamais dans le dépôt)

API_KEY = re.search(r"apiKey: '([^']+)'", open(os.path.join(ROOT, "lib", "firebase_options.dart"), encoding="utf-8").read()).group(1)
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()

results = []
def check(name, ok, detail=""):
    results.append((name, ok))
    print(("PASS " if ok else "FAIL ") + name + (" -- " + str(detail) if detail and not ok else ""))

def http(method, url, body=None, headers=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try: return e.code, json.loads(raw)
        except Exception: return e.code, {"raw": raw[:200]}

def sign_in(who):
    s, r = http("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
                {"email": EMAIL[who], "password": PASSWORD, "returnSecureToken": True})
    assert s == 200, (who, s, r)
    return r["idToken"]

TOK = {w: sign_in(w) for w in UIDS}

def call(fn, data, who=None):
    h = {"Authorization": f"Bearer {TOK[who]}"} if who else {}
    s, r = http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, h)
    return s, r

FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
def admin(method, path, body=None):
    return http(method, f"{FS}/{path}", body, {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT})
def as_user(method, path, who, body=None):
    return http(method, f"{FS}/{path}", body, {"Authorization": f"Bearer {TOK[who]}"})

def err_status(r):
    return r.get("error", {}).get("status")

# --- nettoyage d'un éventuel essai précédent interrompu
s_, lst = admin("GET", "community_posts?pageSize=200")
for d in lst.get("documents", []):
    if d["fields"].get("text", {}).get("stringValue", "").startswith("[TEST AUTOMATIQUE]"):
        pid = d["name"].split("/")[-1]
        for coll in ("replies", "likes"):
            s2, docs = admin("GET", f"community_posts/{pid}/{coll}?pageSize=100")
            for x in docs.get("documents", []):
                admin("DELETE", f"community_posts/{pid}/{coll}/" + x["name"].split("/")[-1])
        admin("DELETE", f"community_posts/{pid}")
        print("ancien essai nettoyé:", pid)

# --- 0. appel sans authentification
s, r = call("togglePostLike", {"postId": "x"})
check("sans connexion : refusé (UNAUTHENTICATED)", err_status(r) == "UNAUTHENTICATED", (s, r))

# --- 1. publication de test créée par Amara (type fil, publiée aussitôt)
s, r = call("createCommunityPost", {"type": "publication", "text": "[TEST AUTOMATIQUE] publication pour vérifier j'aime et réponses"}, "amara")
post_id = (r.get("result") or {}).get("postId") or (r.get("result") or {}).get("id")
check("création de la publication de test", s == 200 and bool(post_id), (s, r))
if not post_id:
    sys.exit(1)

created_replies = []
try:
    # --- 2. j'aime
    s, r = call("togglePostLike", {"postId": post_id}, "fatou")
    check("Fatou aime la publication", s == 200 and r["result"]["liked"] is True, (s, r))
    s, doc = admin("GET", f"community_posts/{post_id}/likes")
    ids = [d["name"].split("/")[-1] for d in doc.get("documents", [])]
    check("le j'aime est enregistré au nom de Fatou (et d'aucun autre)", ids == [UIDS["fatou"]], ids)
    s, r = call("togglePostLike", {"postId": post_id}, "fatou")
    check("second appel : le j'aime est retiré", s == 200 and r["result"]["liked"] is False, (s, r))
    # usurpation : paramètres d'identité ignorés
    s, r = call("togglePostLike", {"postId": post_id, "uid": UIDS["amara"], "userId": UIDS["amara"]}, "fatou")
    s2, doc = admin("GET", f"community_posts/{post_id}/likes")
    ids = [d["name"].split("/")[-1] for d in doc.get("documents", [])]
    check("usurpation par paramètre uid ignorée", ids == [UIDS["fatou"]], ids)
    call("togglePostLike", {"postId": post_id}, "fatou")  # retire à nouveau
    # écriture directe interdite (règles)
    s, r = as_user("PATCH", f"community_posts/{post_id}/likes/{UIDS['amara']}", "fatou", {"fields": {}})
    check("écriture directe d'un j'aime au nom d'un autre : refusée par les règles", s in (401, 403), (s, r))
    s, r = as_user("PATCH", f"community_posts/{post_id}/likes/{UIDS['fatou']}", "fatou", {"fields": {}})
    check("écriture directe d'un j'aime pour soi : refusée par les règles", s in (401, 403), (s, r))
    s, r = as_user("PATCH", f"community_posts/{post_id}/replies/fake", "fatou",
                   {"fields": {"authorUid": {"stringValue": UIDS["amara"]}, "text": {"stringValue": "faux"}}})
    check("écriture directe d'une réponse : refusée par les règles", s in (401, 403), (s, r))
    s, r = as_user("GET", f"community_posts/{post_id}/likes", "fatou")
    check("lecture des j'aime par un membre connecté : autorisée", s == 200, (s, r))
    s, r = http("GET", f"{FS}/community_posts/{post_id}/replies")
    check("lecture des réponses sans connexion : refusée", s in (401, 403), (s, r))

    # --- 3. réponses
    s, r = call("replyToPost", {"postId": post_id, "text": "Réponse de test de Fatou"}, "fatou")
    check("Fatou répond", s == 200 and bool(r.get("result", {}).get("replyId")), (s, r))
    if s == 200:
        created_replies.append(r["result"]["replyId"])
    s, r = call("replyToPost", {"postId": post_id, "text": "Je me fais passer pour Amara", "authorUid": UIDS["amara"], "authorName": "Amara"}, "fatou")
    if s == 200:
        created_replies.append(r["result"]["replyId"])
    s, docs = admin("GET", f"community_posts/{post_id}/replies")
    authors = {d["fields"]["authorUid"]["stringValue"] for d in docs.get("documents", [])}
    names = {d["fields"]["authorName"]["stringValue"] for d in docs.get("documents", [])}
    check("toutes les réponses sont au nom de l'appelant (uid et nom venus du serveur)", authors == {UIDS["fatou"]} and "Amara" not in names, (authors, names))
    s, r = call("replyToPost", {"postId": post_id, "text": "   "}, "fatou")
    check("réponse vide refusée", err_status(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("replyToPost", {"postId": post_id, "text": "x" * 501}, "fatou")
    check("réponse de 501 caractères refusée", err_status(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("replyToPost", {"postId": "inexistant", "text": "a"}, "fatou")
    check("publication inexistante refusée", err_status(r) == "NOT_FOUND", (s, r))

    # --- 4. signalement d'une réponse
    s, r = call("reportCommunityPost", {"postId": post_id, "reason": REASON, "replyId": created_replies[0]}, "amara") if False else (0, {})

    # --- 5. blocage
    pair = "_".join(sorted([UIDS["awa"], UIDS["amara"]]))
    s, r = admin("PATCH", f"blocks/{pair}", {"fields": {"blockerUid": {"stringValue": UIDS["amara"]}, "blockedUid": {"stringValue": UIDS["awa"]}}})
    check("(préparation) blocage Amara vers Awa posé", s == 200, (s, r))
    try:
        s, r = call("togglePostLike", {"postId": post_id}, "awa")
        check("membre bloqué : j'aime refusé", err_status(r) == "PERMISSION_DENIED", (s, r))
        s, r = call("replyToPost", {"postId": post_id, "text": "bloquée"}, "awa")
        check("membre bloqué : réponse refusée", err_status(r) == "PERMISSION_DENIED", (s, r))
    finally:
        admin("DELETE", f"blocks/{pair}")

    # --- 6. suspension / compte non actif
    s, cur = admin("GET", f"user_status/{UIDS['awa']}")
    original = cur.get("fields", {}).get("filtrageStatus", {}).get("stringValue")
    try:
        for status in ("suspended", "rejected_pending_retry"):
            admin("PATCH", f"user_status/{UIDS['awa']}?updateMask.fieldPaths=filtrageStatus", {"fields": {"filtrageStatus": {"stringValue": status}}})
            s, r = call("togglePostLike", {"postId": post_id}, "awa")
            check(f"compte {status} : j'aime refusé", err_status(r) == "PERMISSION_DENIED", (s, r))
            s, r = call("replyToPost", {"postId": post_id, "text": "non"}, "awa")
            check(f"compte {status} : réponse refusée", err_status(r) == "PERMISSION_DENIED", (s, r))
    finally:
        admin("PATCH", f"user_status/{UIDS['awa']}?updateMask.fieldPaths=filtrageStatus", {"fields": {"filtrageStatus": {"stringValue": original or "active"}}})

    # --- 7. limite de fréquence (Awa : 20 réponses par heure)
    admin("DELETE", f"rate_limits/{UIDS['awa']}_reply_hour")
    ok_count, limited = 0, False
    for i in range(22):
        s, r = call("replyToPost", {"postId": post_id, "text": f"rafale {i}"}, "awa")
        if s == 200:
            ok_count += 1
            created_replies.append(r["result"]["replyId"])
        elif err_status(r) == "RESOURCE_EXHAUSTED":
            limited = True
            break
    check("limite : 20 réponses acceptées puis RESOURCE_EXHAUSTED", ok_count == 20 and limited, (ok_count, limited))
finally:
    pass

# --- 8. signalement réel d'une réponse (après la boucle, indépendant du reste)
s, docs = admin("GET", f"community_posts/{post_id}/replies")
awa_reply = next((d["name"].split("/")[-1] for d in docs.get("documents", []) if d["fields"]["authorUid"]["stringValue"] == UIDS["awa"]), None)
if awa_reply:
    s, r = call("reportCommunityPost", {"postId": post_id, "reason": "comportement_abusif", "replyId": awa_reply}, "fatou")
    check("signalement d'une réponse accepté", s == 200, (s, r))
    s, mods = admin("GET", "moderation_requests?pageSize=50&orderBy=createdAt%20desc")
    mine = [d for d in mods.get("documents", []) if d["fields"].get("replyId", {}).get("stringValue") == awa_reply]
    check("la demande de modération vise l'auteur de la réponse (Awa), pas celui de la publication",
          len(mine) == 1 and mine[0]["fields"]["targetUid"]["stringValue"] == UIDS["awa"], [m["fields"].get("targetUid") for m in mine])
    for m in mine:
        admin("DELETE", "moderation_requests/" + m["name"].split("/")[-1])
    s, r = call("reportCommunityPost", {"postId": post_id, "reason": "comportement_abusif", "replyId": "inexistante"}, "fatou")
    check("signalement d'une réponse inexistante refusé", err_status(r) == "NOT_FOUND", (s, r))
else:
    check("signalement : réponse d'Awa trouvée", False)

# --- 9. nettoyage des données de test
for coll in ("replies", "likes"):
    s, docs = admin("GET", f"community_posts/{post_id}/{coll}?pageSize=100")
    for d in docs.get("documents", []):
        admin("DELETE", f"community_posts/{post_id}/{coll}/" + d["name"].split("/")[-1])
print("nettoyage publication de test :", admin("DELETE", f"community_posts/{post_id}")[0])
admin("DELETE", f"rate_limits/{UIDS['awa']}_reply_hour")
bad = [n for n, ok in results if not ok]
print(f"\n{len(results) - len(bad)}/{len(results)} vérifications réussies" + (f" — ÉCHECS : {bad}" if bad else ""))
sys.exit(1 if bad else 0)
