# Migration vers une région européenne — plan et état

*Décision du propriétaire (14/11/2026) : « la région, c'est l'Europe, Bruxelles ou ailleurs ». Ce document traduit cette décision en actions. **Rien n'a été créé** à ce jour : la création d'un projet est une dépense et un acte définitif (la région d'une base Firestore et d'un bucket ne se change plus), elle attend la confirmation des deux points de la section 1.*

## Pourquoi

Le projet actuel `djama-1c7f8` stocke Firestore en **`nam5` (États-Unis)** et Storage en **`US-WEST1` (États-Unis)** ; seules les fonctions sont en Belgique (`europe-west1`). MERUT traite des données sensibles (orientation déduite, photos) de membres européens : les garder en Europe est la position la plus protectrice (`docs/rgpd-registre-des-traitements.md` §4, priorité P0 avant l'ouverture). Ce projet sert aussi de bac à sable à une autre application de l'éditeur : un projet MERUT dédié règle aussi ce mélange.

## 1. Ce qu'il faut que le propriétaire confirme avant que je crée quoi que ce soit

1. **Identifiant et nom du nouveau projet** — proposition : `merut-prod` (« MERUT »), à confirmer ou changer (l'identifiant est définitif).
2. **Compte de facturation** à rattacher — le projet actuel utilise `billingAccounts/01C917-088172-B4386F` ; confirmer que le nouveau projet doit utiliser le même (forfait Blaze, paiement à l'usage : aucun coût tant qu'il n'y a pas d'usage réel notable).

Région retenue, sauf avis contraire : **Belgique (`europe-west1`)** pour Firestore **et** Storage, comme les fonctions — c'est « Bruxelles » au sens Google, et cela évite toute latence ou facturation de trafic entre régions. Alternative : multi-région `eur3` (Belgique + Pays-Bas) pour Firestore, un peu plus disponible mais un peu plus cher ; à ne choisir que sur demande.

## 2. Pourquoi la migration est simple aujourd'hui

L'ouverture publique n'a **pas eu lieu** : la base ne contient que des **comptes de test** (Awa, Amara… et leurs données). Il n'y a donc **aucune donnée de membre réel à déplacer** : on recrée le projet vide en Europe, on y déploie le dépôt, on recrée les comptes de test, et on abandonne les données de test de l'ancien projet. Plus on attend l'ouverture, plus ce serait compliqué (export/import de comptes et de fichiers) : c'est le bon moment.

## 3. Étapes (dans l'ordre)

| # | Action | Qui |
|---|---|---|
| 1 | Créer le projet, rattacher la facturation, activer les API (Firestore, Storage, Cloud Functions, Cloud Scheduler, Cloud Vision, Cloud Messaging, Identity Toolkit) | moi, après confirmation §1 |
| 2 | Créer la base Firestore **en `europe-west1`** et le bucket Storage **en `europe-west1`** (définitif) | moi |
| 3 | Activer Authentication : e-mail/mot de passe et Google ; modèles d'e-mails (vérification, réinitialisation) en français | moi + propriétaire (écran de consentement OAuth Google, domaine d'envoi) |
| 4 | Enregistrer l'application Android `com.kamalove.kamalove`, ajouter les empreintes SHA-1 et SHA-256 (débogage et **clé de publication**) ; régénérer `firebase_options.dart` et `google-services.json` | moi ; la clé de publication vient du propriétaire (Play Console) |
| 5 | Déployer `firestore.rules`, `storage.rules`, `firestore.indexes.json` (index de groupe de collections inclus : `participations.uid`, `replies.authorUid`, `likes.likerUid`, `reviews.uid`) puis les fonctions | moi, sur « déploie » |
| 6 | Semer les banques de questions (`adminSeedQuestionBanks`), créer le premier administrateur (`bootstrapFirstAdmin`), recréer les comptes de test | moi |
| 7 | Cloud Vision : utiliser le point d'accès européen `eu-vision.googleapis.com` pour que les images ne quittent pas l'UE (`functions/src/shared/photoModeration.ts`) | moi |
| 8 | App Check : enregistrer l'app (Play Integrity), vérifier en mode surveillance, puis `ENFORCE_APP_CHECK = true` (`functions/src/shared/appCheck.ts`) | moi + propriétaire (console) |
| 9 | Paramétrer les scripts de test sur le nouveau projet (constante `PROJECT`) et rejouer toute la série ; `scripts/verify_deployed.py` doit répondre « identique » | moi |
| 10 | Reconstruire l'APK avec la nouvelle configuration, l'installer, vérifier sur téléphone | moi |
| 11 | Nettoyer l'ancien projet : supprimer **uniquement** les collections et fichiers de MERUT (jamais ceux de l'autre application) | moi, après accord explicite et relevé de ce qui sera supprimé |
| 12 | Mettre à jour `docs/rgpd-registre-des-traitements.md` §4 (localisation réelle) et la politique de confidentialité | moi |

## 4. État

- [ ] §1 confirmé par le propriétaire
- [ ] Projet européen créé
- [ ] Déploiement et tests sur le nouveau projet
- [ ] Ancien projet nettoyé
