"""Projet Firebase visé par les scripts de test et d'exploitation.

Par défaut : le projet actuel (`djama-1c7f8`). Pour viser le projet européen :
    MERUT_PROJECT=merut-prod MERUT_API_KEY=<clé web de l'application> python scripts/...
La clé d'API se lit dans `lib/firebase_options.dart` SEULEMENT si ce fichier
pointe sur le même projet ; sinon le script s'arrête (jamais de clé d'un projet
utilisée contre un autre, ni de test lancé sur le mauvais projet par erreur).
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.environ.get("MERUT_PROJECT", "djama-1c7f8")
BUCKET = f"{PROJECT}.firebasestorage.app"
REGION = "europe-west1"


def _api_key():
    given = os.environ.get("MERUT_API_KEY")
    if given:
        return given
    text = open(os.path.join(ROOT, "lib", "firebase_options.dart"), encoding="utf-8").read()
    project_in_file = re.search(r"projectId: '([^']+)'", text).group(1)
    if project_in_file != PROJECT:
        raise SystemExit(
            f"lib/firebase_options.dart pointe sur « {project_in_file} » et le script vise « {PROJECT} » : "
            "fournir MERUT_API_KEY (clé web du projet visé)."
        )
    return re.search(r"apiKey: '([^']+)'", text).group(1)


def __getattr__(name):  # clé lue seulement si un script la demande (API_KEY)
    if name == "API_KEY":
        return _api_key()
    raise AttributeError(name)
