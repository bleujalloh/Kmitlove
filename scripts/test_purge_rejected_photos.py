"""Test réel (production, compte de test Awa) de la purge automatique des
photos refusées (purgeRejectedPhotos). Crée 4 photos factices puis lance la
fonction planifiée via Cloud Scheduler :
  - refusée il y a 40 jours (automatique)         -> doit disparaître (doc + fichier)
  - refusée il y a 5 jours, envoyée il y a 41 j    -> doit rester (la date du refus compte, pas celle de l'envoi)
  - refusée par un modérateur il y a 3 jours       -> doit rester
  - approuvée, envoyée il y a 41 jours             -> doit rester (seul « refusée » est purgé)
Nettoie ensuite ses propres données.

Usage : python scripts/test_purge_rejected_photos.py   (gcloud connecté)"""
import datetime, json, os, subprocess, sys, time, urllib.parse, urllib.request, urllib.error

PROJECT = "djama-1c7f8"
BUCKET = "djama-1c7f8.firebasestorage.app"
AWA = "qbK7VyDO5OMrNe49Um8cU72bxTq2"
ADMIN = subprocess.run("gcloud auth print-access-token", shell=True, capture_output=True, text=True).stdout.strip()
FS = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
now = datetime.datetime.now(datetime.timezone.utc)

results = []
def check(name, ok, detail=""):
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else f" -- {detail}"))

def http(method, url, body=None, headers=None, raw=None):
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    if raw is None: req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, {"raw": e.read().decode()[:200]}

H = {"Authorization": f"Bearer {ADMIN}", "x-goog-user-project": PROJECT}
def admin(method, path, body=None): return http(method, f"{FS}/{path}", body, H)
def ts(days): return {"timestampValue": (now - datetime.timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S.000Z")}
def sv(v): return {"stringValue": v}
def upload(name):
    return http("POST", f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=media&name={urllib.parse.quote(name, safe='')}",
                headers={**H, "Content-Type": "image/jpeg"}, raw=b"\xff\xd8\xff test")
def file_exists(name):
    return http("GET", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(name, safe='')}", headers=H)[0] == 200

PHOTOS = {
    "zz_test_old_auto":   {"status": "rejected", "uploadedAt": 41, "moderatedAt": 40, "rejectedBy": sv("auto_moderation"), "purged": True},
    "zz_test_recent_rej": {"status": "rejected", "uploadedAt": 41, "moderatedAt": 5,  "rejectedBy": sv("auto_moderation"), "purged": False},
    "zz_test_admin_rej":  {"status": "rejected", "uploadedAt": 50, "reviewedAt": 3,   "purged": False},
    "zz_test_approved":   {"status": "approved", "uploadedAt": 41, "moderatedAt": 40, "purged": False},
}
def path_of(pid): return f"profile_photos/{AWA}/{pid}.jpg"

def cleanup():
    for pid in PHOTOS:
        admin("DELETE", f"users/{AWA}/photos/{pid}")
        http("DELETE", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(path_of(pid), safe='')}", headers=H)

cleanup()
try:
    for pid, spec in PHOTOS.items():
        fields = {"storagePath": sv(path_of(pid)), "status": sv(spec["status"]), "uploadedAt": ts(spec["uploadedAt"])}
        if "moderatedAt" in spec: fields["moderatedAt"] = ts(spec["moderatedAt"])
        if "reviewedAt" in spec: fields["reviewedAt"] = ts(spec["reviewedAt"])
        if "rejectedBy" in spec: fields["rejectedBy"] = spec["rejectedBy"]
        s, r = admin("PATCH", f"users/{AWA}/photos/{pid}", {"fields": fields})
        upload(path_of(pid))
        check(f"(préparation) {pid}", s == 200 and file_exists(path_of(pid)), (s, r))

    # lancement de la fonction planifiée
    job = subprocess.run(
        f'gcloud scheduler jobs list --location=europe-west1 --project={PROJECT} --format="value(name)"',
        shell=True, capture_output=True, text=True).stdout.split()
    name = next((j.split("/")[-1] for j in job if "purgeRejectedPhotos" in j), None)
    check("tâche planifiée purgeRejectedPhotos trouvée", name is not None, job)
    if name:
        r = subprocess.run(f"gcloud scheduler jobs run {name} --location=europe-west1 --project={PROJECT}", shell=True, capture_output=True, text=True)
        check("tâche lancée", r.returncode == 0, r.stderr[:200])
        for _ in range(30):                         # attendre l'exécution (jusqu'à ~90 s)
            time.sleep(3)
            if admin("GET", f"users/{AWA}/photos/zz_test_old_auto")[0] == 404:
                break
        for pid, spec in PHOTOS.items():
            doc_gone = admin("GET", f"users/{AWA}/photos/{pid}")[0] == 404
            file_gone = not file_exists(path_of(pid))
            if spec["purged"]:
                check(f"{pid} : document et fichier supprimés", doc_gone and file_gone, (doc_gone, file_gone))
            else:
                check(f"{pid} : conservée", (not doc_gone) and (not file_gone), (doc_gone, file_gone))
finally:
    cleanup()
bad = results.count(False)
print(f"\n{len(results) - bad}/{len(results)} vérifications réussies")
sys.exit(1 if bad else 0)
