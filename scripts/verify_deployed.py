#!/usr/bin/env python3
"""Compare ce qui est EN LIGNE (Cloud Functions + règles Firestore/Storage)
avec le dépôt. Cause racine de l'audit du 13/11/2026 : 8 fonctions en
ligne différaient du code commité sans que rien ne le signale.

Usage (depuis la racine du dépôt, gcloud connecté) :
    python scripts/verify_deployed.py [project_id]
Code de sortie 0 = identique, 1 = écart (liste affichée).
"""
import difflib, json, os, re, subprocess, sys, tempfile, urllib.request, zipfile

PROJECT = sys.argv[1] if len(sys.argv) > 1 else "djama-1c7f8"
# Déployées mais volontairement désactivées dans index.ts (paiements en
# pause, décision du propriétaire) : signalées, pas bloquantes.
KNOWN_ORPHANS = {"verifyPurchase"}
SHELL = os.name == "nt"


def run(cmd):
    return subprocess.run(cmd, check=True, capture_output=True, shell=SHELL, text=True).stdout


def norm(b):
    return "\n".join(
        l for l in b.replace(b"\r\n", b"\n").decode("utf-8", "replace").splitlines()
        if not l.startswith("//#")
    )


def main():
    problems = []
    tmp = tempfile.mkdtemp(prefix="verify_deployed_")
    out = os.path.join(tmp, "head")
    subprocess.run(
        ["node", "node_modules/typescript/bin/tsc", "--outDir", out],
        cwd="functions", check=True,
    )

    # --- Fonctions : fichier de la fonction + tout ce qu'il charge
    fns = json.loads(run(f"gcloud functions list --v2 --project={PROJECT} --format=json"))
    index = open("functions/src/index.ts", encoding="utf-8").read()
    live = "\n".join(l for l in index.splitlines() if not l.strip().startswith("//"))
    exported = {}
    for m in re.finditer(r'export\s*\{([^}]+)\}\s*from\s*"([^"]+)"', live):
        for n in (x.strip() for x in m.group(1).split(",") if x.strip()):
            exported[n] = m.group(2).lstrip("./")
    zips = {}
    for f in fns:
        name = f["name"].split("/")[-1]
        if name not in exported:
            if name in KNOWN_ORPHANS:
                print(f"note : {name} est en ligne mais désactivée dans le code (paiements en pause)")
                continue
            problems.append(f"fonction en ligne absente du code : {name}")
            continue
        ss = f["buildConfig"]["source"]["storageSource"]
        key = (ss["bucket"], ss["object"])
        if key not in zips:
            dst = os.path.join(tmp, f"{len(zips)}.zip")
            run(f"gcloud storage cp gs://{key[0]}/{key[1]} {dst} --project={PROJECT}")
            zips[key] = zipfile.ZipFile(dst)
        rel = f"lib/{exported[name]}.js"
        deployed = norm(zips[key].read(rel))
        head = norm(open(os.path.join(out, exported[name] + ".js"), "rb").read())
        if deployed != head:
            problems.append(f"fonction {name} : le code en ligne diffère du dépôt ({rel})")
    for n in exported:
        if not any(f["name"].endswith("/" + n) for f in fns):
            problems.append(f"fonction du code non déployée : {n}")

    # --- Règles
    token = run("gcloud auth print-access-token").strip()
    def api(path):
        req = urllib.request.Request(
            "https://firebaserules.googleapis.com/v1/" + path,
            headers={"Authorization": f"Bearer {token}", "x-goog-user-project": PROJECT},
        )
        return json.load(urllib.request.urlopen(req))
    for release, repo in ((f"projects/{PROJECT}/releases/cloud.firestore", "firestore.rules"),
                          (f"projects/{PROJECT}/releases/firebase.storage/{PROJECT}.firebasestorage.app", "storage.rules")):
        rs = api(api(release)["rulesetName"].split("v1/")[-1])
        dep = rs["source"]["files"][0]["content"].replace("\r\n", "\n").strip()
        here = open(repo, encoding="utf-8").read().replace("\r\n", "\n").strip()
        if dep != here:
            d = [l for l in difflib.unified_diff(dep.splitlines(), here.splitlines(), lineterm="", n=0)][:6]
            problems.append(f"règles {repo} différentes : {d}")

    if problems:
        print("ÉCART entre la production et le dépôt :")
        for p in problems:
            print(" -", p)
        sys.exit(1)
    print(f"OK : {len(fns)} fonctions et les 2 jeux de règles sont identiques au dépôt.")


main()
