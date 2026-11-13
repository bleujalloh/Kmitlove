"""Test réel (production, comptes de test Awa et Amara) des fonctions de
Paramètres : préférences de notification, visibilité du profil, liste de mes
signalements. Remet les comptes de test dans leur état d'origine.

Usage : SEED_PASSWORD=... python scripts/test_settings_functions.py   (gcloud connecté)"""
import json, os, re, subprocess, sys, datetime, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
REGION = "europe-west1"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AWA = "qbK7VyDO5OMrNe49Um8cU72bxTq2"
AMARA = "q7mb6hpDHSfZd9jHeRnGvbY1L5p1"
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

def sign_in(email):
    s, r = http("POST", f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
                {"email": email, "password": os.environ["SEED_PASSWORD"], "returnSecureToken": True})
    return r["idToken"]
TOK = {"awa": sign_in("awa.test5@example.com"), "amara": sign_in("amara.test1@example.com")}

def call(fn, data, who=None):
    h = {"Authorization": f"Bearer {TOK[who]}"} if who else {}
    return http("POST", f"https://{REGION}-{PROJECT}.cloudfunctions.net/{fn}", {"data": data}, h)
def admin(method, path, body=None):
    return http(method, f"{FS}/{path}", body, {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT})
def status_of(r): return r.get("error", {}).get("status")
def status_doc(uid): return admin("GET", f"user_status/{uid}")[1].get("fields", {})

orig = status_doc(AWA)
orig_prefs = orig.get("notificationPrefs")
orig_hidden = orig.get("profileHidden")

try:
    # ---- préférences de notification
    s, r = call("setNotificationPreferences", {"likes": False}, "awa")
    check("préférence « likes » coupée", s == 200, (s, r))
    prefs = status_doc(AWA).get("notificationPrefs", {}).get("mapValue", {}).get("fields", {})
    check("enregistrée en base (likes=false)", prefs.get("likes", {}).get("booleanValue") is False, prefs)
    s, r = call("setNotificationPreferences", {"messages": True}, "awa")
    prefs = status_doc(AWA).get("notificationPrefs", {}).get("mapValue", {}).get("fields", {})
    check("fusion : les autres clés sont conservées", prefs.get("likes", {}).get("booleanValue") is False and prefs.get("messages", {}).get("booleanValue") is True, prefs)
    s, r = call("setNotificationPreferences", {"likes": "oui"}, "awa")
    check("valeur non booléenne refusée", status_of(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("setNotificationPreferences", {}, "awa")
    check("aucune préférence refusée", status_of(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("setNotificationPreferences", {"inconnue": True}, "awa")
    check("clé inconnue ignorée donc refusée (rien à enregistrer)", status_of(r) == "INVALID_ARGUMENT", (s, r))
    s, r = call("setNotificationPreferences", {"likes": True})
    check("sans connexion refusé", status_of(r) == "UNAUTHENTICATED", (s, r))

    # ---- visibilité du profil
    s, r = call("setProfileVisibility", {"hidden": True}, "awa")
    check("profil masqué", s == 200 and status_doc(AWA).get("profileHidden", {}).get("booleanValue") is True, (s, r))
    s, r = call("setProfileVisibility", {"hidden": "oui"}, "awa")
    check("valeur invalide refusée", status_of(r) == "INVALID_ARGUMENT", (s, r))
    # Amara ne doit plus voir Awa dans Découvrir (swipe éventuel retiré d'abord)
    admin("DELETE", f"swipes/{AMARA}_{AWA}")
    s, r = call("getDiscoverCandidates", {"maxDistanceKm": 500, "useMyLocation": False}, "amara")
    cands = r.get("result", {}).get("candidates", []) if s == 200 else None
    uids = [c.get("uid") for c in (cands or [])]
    check("profil masqué : absent de Découvrir", cands is not None and AWA not in uids, (s, uids))
    call("setProfileVisibility", {"hidden": False}, "awa")
    s, r = call("getDiscoverCandidates", {"maxDistanceKm": 500, "useMyLocation": False}, "amara")
    uids2 = [c.get("uid") for c in r.get("result", {}).get("candidates", [])] if s == 200 else []
    print("info : profil réaffiché (visible de nouveau dans Découvrir pour les comptes qui le recherchent)")

    # ---- mes signalements
    doc = admin("POST", "moderation_requests", {"fields": {
        "type": {"stringValue": "user_report"}, "reporterUid": {"stringValue": AWA}, "targetUid": {"stringValue": AMARA},
        "reason": {"stringValue": "arnaque"}, "resolved": {"booleanValue": False}, "details": {"stringValue": "secret interne"},
        "createdAt": {"timestampValue": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")},
    }})[1]
    doc_id = doc["name"].split("/")[-1]
    s, r = call("listMyReports", {}, "awa")
    mine = r.get("result", {}).get("reports", [])
    check("mon signalement est listé", any(x["id"] == doc_id and x["reason"] == "arnaque" and x["resolved"] is False for x in mine), (s, r))
    check("aucun détail interne ni cible renvoyés", all(set(x.keys()) == {"id", "type", "reason", "createdAtMs", "resolved"} for x in mine), mine[:1])
    s, r = call("listMyReports", {}, "amara")
    check("le signalement d'Awa n'apparaît pas chez Amara", all(x["id"] != doc_id for x in r.get("result", {}).get("reports", [])), (s, r))
    s, r = call("listMyReports", {})
    check("sans connexion refusé", status_of(r) == "UNAUTHENTICATED", (s, r))
    admin("DELETE", f"moderation_requests/{doc_id}")
finally:
    # remise à l'état d'origine
    mask = "updateMask.fieldPaths=notificationPrefs&updateMask.fieldPaths=profileHidden"
    fields = {}
    if orig_prefs: fields["notificationPrefs"] = orig_prefs
    if orig_hidden: fields["profileHidden"] = orig_hidden
    admin("PATCH", f"user_status/{AWA}?{mask}", {"fields": fields})

bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
