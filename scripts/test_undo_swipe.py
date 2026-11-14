"""Test réel (production, comptes de test uniquement) du bouton « retour » de
Découvrir (undoLastSwipe) : Premium requis, passage uniquement, dernier swipe
uniquement, usurpation impossible. Remet les comptes de test dans leur état.

Usage : SEED_PASSWORD=... python scripts/test_undo_swipe.py
(gcloud connecté ; compte de test Awa, cibles Kofi et Idriss)."""
import json, os, re, subprocess, sys, urllib.request, urllib.error

from target import PROJECT, BUCKET, API_KEY  # projet visé : voir scripts/target.py
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AWA = "qbK7VyDO5OMrNe49Um8cU72bxTq2"
KOFI = "0C644laYtXewUKunJW4P77Kqjh63"
IDRISS = "JyYrfK9bI1XStqoFnwLktEGkZ5m2"
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
def swipe_exists(target): return admin("GET", f"swipes/{AWA}_{target}")[0] == 200
def set_status(fields, mask):
    admin("PATCH", f"user_status/{AWA}?" + "&".join(f"updateMask.fieldPaths={m}" for m in mask), {"fields": fields})

s, cur = admin("GET", f"user_status/{AWA}")
orig_premium = cur.get("fields", {}).get("isPremium")
def cleanup():
    for t in (KOFI, IDRISS):
        admin("DELETE", f"swipes/{AWA}_{t}")
    set_status({"isPremium": orig_premium or {"booleanValue": False}, "lastPassTargetUid": {"nullValue": None}}, ["isPremium", "lastPassTargetUid"])

cleanup()
try:
    # 1. passage puis retour refusé : pas Premium
    s, r = call("recordSwipe", {"targetUid": KOFI, "action": "pass"})
    check("passage enregistré", s == 200, (s, r))
    s, r = call("undoLastSwipe", {"targetUid": KOFI})
    check("retour refusé sans Premium", status_of(r) == "PERMISSION_DENIED", (s, r))
    check("le passage est toujours là après le refus", swipe_exists(KOFI))
    # 2. Premium : retour accepté
    set_status({"isPremium": {"booleanValue": True}}, ["isPremium"])
    s, r = call("undoLastSwipe", {"targetUid": KOFI})
    check("retour accepté en Premium", s == 200, (s, r))
    check("le passage a bien été supprimé", not swipe_exists(KOFI))
    s, r = call("undoLastSwipe", {"targetUid": KOFI})
    check("second retour sur le même profil refusé", status_of(r) == "FAILED_PRECONDITION", (s, r))
    # 3. seul le dernier swipe
    call("recordSwipe", {"targetUid": KOFI, "action": "pass"})
    call("recordSwipe", {"targetUid": IDRISS, "action": "pass"})
    s, r = call("undoLastSwipe", {"targetUid": KOFI})
    check("retour refusé sur un avant-dernier passage", status_of(r) == "FAILED_PRECONDITION", (s, r))
    check("l'avant-dernier passage est intact", swipe_exists(KOFI))
    s, r = call("undoLastSwipe", {"targetUid": IDRISS})
    check("retour accepté sur le dernier passage", s == 200, (s, r))
    # 4. jamais un like
    s, r = call("recordSwipe", {"targetUid": IDRISS, "action": "like"})
    check("like enregistré", s == 200, (s, r))
    s, r = call("undoLastSwipe", {"targetUid": IDRISS})
    check("retour d'un like refusé", status_of(r) == "FAILED_PRECONDITION", (s, r))
    check("le like est intact", swipe_exists(IDRISS))
    # 5. paramètres invalides / sans connexion
    s, r = call("undoLastSwipe", {})
    check("cible manquante refusée", status_of(r) == "INVALID_ARGUMENT", (s, r))
    s, r = http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/undoLastSwipe", {"data": {"targetUid": KOFI}})
    check("sans connexion refusé", status_of(r) == "UNAUTHENTICATED", (s, r))
finally:
    cleanup()
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
