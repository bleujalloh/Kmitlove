"""Test réel (production, compte de test Awa) des corrections de l'audit du
13/11/2026 : genre et date de naissance verrouillés (saveProfil), pays des
événements validé (createCommunityPost), suppression de la position
(updateMyLocation, `clear: true`). Awa retrouve son état d'origine.

Usage : SEED_PASSWORD=... python scripts/test_audit_fixes.py   (gcloud connecté)"""
import json, os, re, subprocess, sys, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AWA = "qbK7VyDO5OMrNe49Um8cU72bxTq2"
API_KEY = re.search(r"apiKey: '([^']+)'", open(os.path.join(ROOT, "lib", "firebase_options.dart"), encoding="utf-8").read()).group(1)
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"

results = []
def check(name, ok, detail=""):
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else f" -- {detail}"))

def http(method, url, body=None, headers=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, method=method, headers=headers or {})
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try: return e.code, json.loads(raw)
        except Exception: return e.code, {"raw": raw[:200]}

s, r = http("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
            {"email": "awa.test5@example.com", "password": os.environ["SEED_PASSWORD"], "returnSecureToken": True})
TOKEN = r["idToken"]
def call(fn, data):
    return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, {"Authorization": f"Bearer {TOKEN}"})
def admin(method, path, body=None):
    return http(method, f"{FS}/{path}", body, {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT})
def status_of(r): return r.get("error", {}).get("status")
def msg_of(r): return r.get("error", {}).get("message", "")

def plain(v):
    k, val = next(iter(v.items()))
    if k == "arrayValue": return [plain(x) for x in val.get("values", [])]
    if k == "integerValue": return int(val)
    if k == "nullValue": return None
    if k == "mapValue": return {kk: plain(vv) for kk, vv in val.get("fields", {}).items()}
    return val

# saveProfil exige désormais le consentement RGPD art. 9 (14/11/2026) :
# Awa le donne avant les tests (compte de test, aucun effet sur un vrai membre).
call("recordSensitiveConsent", {"granted": True, "version": 1})

# --- profil d'Awa tel qu'il est en base (pour rejouer un enregistrement identique)
s, doc = admin("GET", f"users/{AWA}")
profile = {k: plain(v) for k, v in doc["fields"].items()}
s, st = admin("GET", f"user_status/{AWA}")
birth = plain(st["fields"]["birthDate"])
payload = {k: v for k, v in profile.items() if k not in ("age", "showReadReceipts", "compatAnswersVisible", "updatedAt")}
payload["birthDate"] = birth

# 1. mêmes valeurs : accepté
s, r = call("saveProfil", payload)
check("enregistrement identique accepté", s == 200, (s, r))
# 2. genre modifié : refusé
other = "Homme" if profile["gender"] == "Femme" else "Femme"
s, r = call("saveProfil", {**payload, "gender": other})
check("changement de genre refusé", status_of(r) == "FAILED_PRECONDITION" and "gender-locked" in msg_of(r), (s, r))
# 3. date de naissance modifiée : refusée
s, r = call("saveProfil", {**payload, "birthDate": "1990-05-05T00:00:00.000"})
check("changement de date de naissance refusé", status_of(r) == "FAILED_PRECONDITION" and "birthdate-locked" in msg_of(r), (s, r))
s, st2 = admin("GET", f"user_status/{AWA}")
check("la date de naissance en base est inchangée", plain(st2["fields"]["birthDate"]) == birth)
s, doc2 = admin("GET", f"users/{AWA}")
check("le genre en base est inchangé", plain(doc2["fields"]["gender"]) == profile["gender"])

# 4. pays d'un événement : liste fermée (la vérification précède celle du statut d'organisateur)
base = {"type": "evenement_public", "text": "[TEST] x", "title": "t", "capacity": 10, "category": "soiree", "format": "presentiel",
        "city": "Paris", "timezone": "Europe/Paris", "eventDate": "2030-01-01T18:00:00.000", "preciseLocation": "x"}
s, r = call("createCommunityPost", {**base, "country": "Narnia"})
check("événement : pays inventé refusé", status_of(r) == "INVALID_ARGUMENT" and "Pays" in msg_of(r), (s, r))
s, r = call("createCommunityPost", {**base, "country": "france"})
check("événement : « france » accepté comme pays (refus suivant = organisateur non validé, pas le pays)",
      "Pays" not in msg_of(r), (s, r))

# 5. position : enregistrement puis suppression
a = admin("PATCH", f"user_status/{AWA}?updateMask.fieldPaths=locationLat&updateMask.fieldPaths=locationLng",
          {"fields": {"locationLat": {"doubleValue": 48.8}, "locationLng": {"doubleValue": 2.3}}})
s, r = call("updateMyLocation", {"clear": True})
check("suppression de la position acceptée", s == 200 and r.get("result", {}).get("cleared") is True, (s, r))
s, st3 = admin("GET", f"user_status/{AWA}")
check("latitude, longitude et date supprimées", not any(k in st3["fields"] for k in ("locationLat", "locationLng", "locationUpdatedAt")), list(st3["fields"].keys()))
s, r = call("updateMyLocation", {"lat": 999, "lng": 2})
check("coordonnées invalides toujours refusées", status_of(r) == "INVALID_ARGUMENT", (s, r))

bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
