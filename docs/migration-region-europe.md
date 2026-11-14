# Migration vers une région européenne — plan et état

*Décision du propriétaire (14/11/2026) : « la région, c'est l'Europe, Bruxelles ou ailleurs ». Ce document traduit cette décision en actions. **Projet créé le 14/11/2026 après confirmation du propriétaire** (identifiant et facturation de la section 1) : voir l'état en section 4. La région d'une base Firestore et d'un bucket ne se change plus.*

## Pourquoi

Le projet actuel `djama-1c7f8` stocke Firestore en **`nam5` (États-Unis)** et Storage en **`US-WEST1` (États-Unis)** ; seules les fonctions sont en Belgique (`europe-west1`). MERUT traite des données sensibles (orientation déduite, photos) de membres européens : les garder en Europe est la position la plus protectrice (`docs/rgpd-registre-des-traitements.md` §4, priorité P0 avant l'ouverture). **Pourquoi un nouveau projet plutôt que de modifier `djama-1c7f8`** : la région d'une base Firestore et d'un bucket Storage est fixée à leur création et ne peut jamais être changée ; la seule façon d'avoir les données en Europe est de créer un nouveau projet. *Correction du 14/11/2026* : ce document affirmait que `djama-1c7f8` servait aussi à une autre application de l'éditeur ; **vérification faite ce jour, rien ne le confirme** (seule l'application « kamalove » = ancien nom de MERUT y est enregistrée, Android et iOS ; toutes les collections et les 13 comptes sont ceux de MERUT : 11 comptes de test et 2 comptes réels). Une application qui s'y connecterait sans y être enregistrée resterait invisible : à confirmer par le propriétaire avant de supprimer quoi que ce soit (étape 11). Le projet `mansa-prod` appartient à NEEGUI et n'est jamais touché.

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

- [x] §1 confirmé par le propriétaire le 14/11/2026 : identifiant `merut-prod`, nom « MERUT », compte de facturation `billingAccounts/01C917-088172-B4386F`.
- [x] **Étapes 1 et 2** : projet `merut-prod` créé (Firebase ajouté, facturation active, API activées) ; **Firestore `(default)` en `europe-west1`** et **bucket `merut-prod.firebasestorage.app` en `EUROPE-WEST1`**, vérifiés.
- [~] **Étape 3** : Authentication initialisée, **e-mail/mot de passe activé**, protection d'énumération des e-mails activée (comme l'ancien projet). **Reste (propriétaire)** : connexion Google (console Firebase → Authentication → Sign-in method → Google, écran de consentement OAuth) et modèles d'e-mails en français.
- [~] **Étape 4** : application Android `com.kamalove.kamalove` enregistrée (`1:729051681548:android:7f04ab42b0801c5d856f29`), les deux empreintes SHA-1 de l'ancien projet ajoutées. **Reste** : basculer `lib/firebase_options.dart` et `android/app/google-services.json` sur `merut-prod` (fichier de configuration déjà téléchargé hors dépôt) — à faire en même temps que la reconstruction de l'APK, pour que le dépôt ne pointe jamais sur un projet sans administrateur ni banques de questions. Les empreintes SHA-256 et la clé de publication (Play Console) restent à ajouter.
- [x] **Étape 5 faite (« déploie » sur `merut-prod`, 14/11/2026)** : règles Firestore et Storage, index, **74 fonctions** (3 lots), politique de nettoyage des images de fonctions (7 jours). `scripts/verify_deployed.py merut-prod` : « 74 fonctions et les 2 jeux de règles identiques au dépôt ». Première tentative : une fonction à déclencheur Firestore (`onMessageCreated`) a échoué (« Permission denied while using the Eventarc Service Agent », délai de propagation d'un projet neuf) ; réussie au second passage.
- [ ] **Étape 6** : banques de questions (`adminSeedQuestionBanks`), premier administrateur (`bootstrapFirstAdmin`) et comptes de test — il faut d'abord un compte administrateur sur le nouveau projet (le compte du propriétaire n'existe pas encore sur `merut-prod`). Il n'existe pas de script de création des 10 comptes de test (ils ont été créés à la main à l'époque) : à écrire.
- [~] **Étape 7 — à décider par le propriétaire** : SafeSearch passe maintenant par le point d'accès européen de Vision (`eu-vision.googleapis.com`, `functions/src/shared/photoModeration.ts`, essai réel sur le bucket européen). **Mais la détection de visage n'existe pas sur les points d'accès régionaux** (« Feature FACE_DETECTION not supported in regional endpoints »). Elle reste donc sur le point d'accès mondial : l'image envoyée pour détecter un visage peut être traitée hors UE. Essayé : détection par étiquettes sur le point d'accès européen, inutilisable seule (elle ne voit pas le visage d'une photo de plein pied : 1 faux négatif sur 4 portraits testés). Options : (a) garder ainsi pour l'instant, (b) détecter les visages dans nos propres fonctions en Belgique (modèle léger embarqué, un peu de développement, aucun transfert) — recommandé avant l'ouverture, (c) ne plus exiger de visage.
- [ ] Étape 8 : App Check (Play Integrity) — console, avec le propriétaire.
- [~] **Étape 9** : les scripts visent le projet donné par `MERUT_PROJECT` (défaut `djama-1c7f8`, voir `scripts/target.py`, qui refuse de mélanger la clé d'un projet avec un autre). Sur `merut-prod` : `test_consent_enforced.py` **48/48**, `test_events_flow.py` **48/48**, dépôt de fichiers (photo, affiche, pièce d'identité) accepté pour un membre consentant. Les autres scripts attendent les comptes de test de l'étape 6.
- [ ] Étape 10 : APK reconstruit sur la nouvelle configuration, installation et vérification sur téléphone.
- [ ] Étape 11 : ancien projet nettoyé (après accord explicite et relevé de ce qui sera supprimé).
- [ ] Étape 12 : registre RGPD §4 et politique de confidentialité (localisation réelle), à la bascule.
- **Tant que l'étape 4 n'est pas terminée, l'application, l'APK de test et la production d'usage restent sur `djama-1c7f8`.**
