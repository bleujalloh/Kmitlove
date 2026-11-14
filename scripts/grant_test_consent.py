"""Donne le consentement RGPD art. 9 (version 1) aux COMPTES DE TEST seulement
(adresses en @example.com). Nécessaire après le déploiement du lot du
14/11/2026 : le serveur refuse désormais découverte, likes, swipes, messages
et enregistrement du profil à tout membre sans consentement valide — les
comptes de test d'Awa, Amara, etc. n'en ont pas, ce qui ferait échouer les
scripts de test. Aucun compte réel n'est touché.

Usage : python scripts/grant_test_consent.py   (gcloud connecté)"""
import json, subprocess, sys, urllib.request, urllib.error

from target import PROJECT, BUCKET, API_KEY  # projet visé : voir scripts/target.py
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
H = {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT, "Content-Type": "application/json"}
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"


def http(method, url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, method=method, headers=H)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, {"raw": e.read().decode()[:200]}


status, data = http("GET", f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts:batchGet?maxResults=1000")
if status != 200:
    sys.exit(f"liste des comptes impossible : {status} {data}")
tests = [u for u in data.get("users", []) if u.get("email", "").lower().endswith("@example.com")]
print(f"{len(tests)} compte(s) de test (@example.com) sur {len(data.get('users', []))}")
now = __import__("datetime").datetime.now(__import__("datetime").timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
for u in tests:
    uid = u["localId"]
    body = {"fields": {"sensitiveConsent": {"mapValue": {"fields": {
        "granted": {"booleanValue": True}, "version": {"integerValue": "1"}, "at": {"timestampValue": now}}}}}}
    s, r = http("PATCH", f"{FS}/user_status/{uid}?updateMask.fieldPaths=sensitiveConsent&currentDocument.exists=true", body)
    print(("ok   " if s == 200 else f"saut ({s}) "), u.get("email"))
