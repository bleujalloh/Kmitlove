# MERUT — Documentation RGPD : registre des traitements et état de conformité

*Établi le 2026-11-13 à partir du code réel du dépôt et de la configuration réellement déployée (projet Firebase `djama-1c7f8`). Ce document ne remplace pas un avis juridique : il décrit fidèlement ce que l'application fait des données, ce qui est déjà conforme, et ce qui reste à faire. Chaque écart est marqué **[ÉCART]**, chaque point à décider par le propriétaire **[DÉCISION]**.*

Public concerné : MERUT est une application de rencontres réservée aux personnes majeures, avec des membres en France et en Europe. Le RGPD (règlement UE 2016/679) s'applique, ainsi que, pour la France, la loi Informatique et Libertés et les recommandations de la CNIL.

---

## 1. Responsable de traitement et contacts

- **Responsable de traitement** : l'éditeur de MERUT. **[À COMPLÉTER]** raison sociale, adresse, numéro d'immatriculation (immatriculation en cours à la date de ce document).
- **Délégué à la protection des données (DPO)** : **[DÉCISION]** non désigné. Une application de rencontres traitant à grande échelle des données révélant l'orientation sexuelle est susceptible de rendre la désignation obligatoire (art. 37). À trancher avec un conseil juridique.
- **Point de contact des membres** : **[À COMPLÉTER]** adresse e-mail dédiée aux demandes de droits.

## 2. Registre des traitements (art. 30)

| # | Traitement | Finalité | Données | Base légale (proposée) | Conservation **actuelle** | Où |
|---|---|---|---|---|---|---|
| T1 | Compte et connexion | Créer et sécuriser le compte | Identifiant Firebase Auth, e-mail ou compte Google, jetons de session | Contrat | Jusqu'à suppression du compte | Firebase Auth |
| T2 | Profil | Présenter le membre aux autres | Prénom ou pseudonyme, âge (la date de naissance exacte n'est lisible que par le membre, `user_status`), genre, genres recherchés, ville, pays, description, centres d'intérêt, profession, taille, niveau d'études, enfants, tabac, alcool, intention relationnelle | Contrat ; **consentement explicite pour les données de l'art. 9** (voir §3) | Jusqu'à suppression du compte | Firestore `users`, `user_status` |
| T3 | Photos de profil | Présenter le membre | Fichiers image, statut de modération, indicateur « visage détecté », scores SafeSearch | Contrat ; intérêt légitime (sécurité de la communauté) | Jusqu'à suppression par le membre ou du compte. Les photos refusées sont supprimées automatiquement 30 jours après le refus (`purgeRejectedPhotos`) | Storage `profile_photos`, Firestore `users/{uid}/photos` |
| T4 | Modération automatique des photos | Refuser les contenus sensibles, exiger un visage | Image envoyée à Google Cloud Vision (SafeSearch, détection de visage — pas de reconnaissance d'identité) | Intérêt légitime | Résultat conservé avec la photo | Cloud Functions → Cloud Vision |
| T5 | Vérification d'identité (facultative) | Badge « vérifié » | Selfie, décision du modérateur | Consentement | Le selfie est **supprimé dès la décision du modérateur** (seuls `isVerified`, le statut, la date et le décideur sont conservés) — déployé le 14/11/2026 | Storage `identity_verifications`, `user_status.isVerified` |
| T6 | Géolocalisation (« Ma position ») | Filtrer par distance, afficher pays et ville détectés | Dernière latitude et longitude (`user_status`, lisibles par le seul membre), date de mise à jour | **Consentement** (permission système + bouton « Ma position », retirable à tout moment) | Dernier point seulement, jusqu'à suppression du compte | Firestore `user_status` ; géocodage inverse effectué sur l'appareil |
| T7 | Découverte, likes, matchs | Proposer des profils, créer des matchs | Swipes (like, super like, passage), matchs, score de compatibilité, dernière action | Contrat | Jusqu'à suppression du compte. Un « retour » (Premium) supprime le dernier passage | Firestore `swipes`, `matches` |
| T8 | Messagerie | Échanger entre matchs | Messages texte, photos de conversation, accusés de lecture | Contrat | Jusqu'à suppression du compte (de l'un ou l'autre des deux membres) | Firestore `matches/{id}/messages`, Storage `chat_photos` |
| T9 | Notifications push | Prévenir d'un message, match, like, réponse | Jeton FCM de l'appareil | Consentement (permission système) | Jusqu'à déconnexion ou suppression | `user_status.fcmTokens`, Firebase Cloud Messaging |
| T10 | Communauté | Publications, événements, participations, avis, j'aime, réponses | Contenus rédigés, lieux, participations, avis | Contrat ; consentement pour le lieu précis partagé | Jusqu'à suppression du compte | Firestore `community_posts` et sous-collections |
| T11 | Questionnaires (filtrage à l'inscription, compatibilité) | Valider l'adhésion à la charte, calculer une compatibilité | Réponses, score, statut | Contrat ; intérêt légitime | Jusqu'à suppression du compte | `filtrage_attempts`, `compat_answers` |
| T12 | Sécurité et modération | Signalements, blocages, sanctions, anti-multi-comptes | Signalements (auteur, cible, motif), blocages, sanctions, identifiant d'appareil (`device_signals`), journal des actions d'administration | Intérêt légitime ; obligation légale (hébergeur) | Signalements et journaux : **[DÉCISION]** durée non fixée (proposé : 12 mois après traitement) | `moderation_requests`, `blocks`, `device_signals`, `admin_action_logs` |
| T13 | Paiements (**en pause**) | Premium, jetons | Aucun paiement actif à ce jour. Prévu : Google Play Billing, PayPal, Stripe | Contrat | — | — |
| T14 | Journaux techniques | Diagnostic et sécurité | Journaux des Cloud Functions (identifiant du membre, erreurs) | Intérêt légitime | Durée par défaut de Cloud Logging (30 jours) | Google Cloud Logging |

## 3. Données sensibles (art. 9)

- **Orientation sexuelle** : MERUT ne demande jamais « quelle est votre orientation » mais la combinaison *genre* + *genres recherchés* la révèle. Ces données relèvent de l'art. 9 : un **consentement explicite et séparé** est requis, avec possibilité de le retirer. **Implanté le 14/11/2026 :** écran dédié (`sensitive_consent_screen.dart`, branché dans `auth_gate.dart` avant l'assistant de profil, aussi pour les comptes existants), case à cocher distincte des conditions, lien vers la politique de confidentialité, refus = suppression du compte ou déconnexion ; consentement enregistré **côté serveur** (`recordSensitiveConsent` → `user_status.sensitiveConsent` : accord, version du texte, date ; le client envoie la version qu'il a affichée, le serveur refuse un consentement donné sur un autre texte) et **exigé côté serveur** (`shared/consent.ts`) par `saveProfil`, la découverte, les likes, les swipes et l'envoi de messages — un client modifié ne peut donc pas contourner l'écran ; retrait depuis Paramètres → le profil disparaît de la découverte (`getCandidates`) et l'écran de consentement revient. La version du texte (`SENSITIVE_CONSENT_VERSION` côté serveur, `kSensitiveConsentVersion` côté appli — à changer ensemble) s'incrémente à chaque changement : l'écran de consentement revient et le serveur refuse tout ce qui précède. Sans consentement valide, le membre n'est **montré à personne** (découverte, likes, swipe d'une carte restée affichée). **Limites assumées** : le document public du profil (`users/{uid}`, genre et genres recherchés) reste lisible par un membre connecté qui connaît l'identifiant jusqu'à la suppression du compte ; l'ordre réel du parcours est inscription, questionnaire de filtrage, consentement, assistant de profil (le consentement arrive donc après le questionnaire, qui ne porte pas sur les données sensibles). Déployé le 14/11/2026.
- **Identité culturelle** : le questionnaire de filtrage porte sur la connaissance de la culture et de l'histoire, jamais sur l'origine ni l'apparence (la charte le dit explicitement). L'appartenance à la communauté peut cependant révéler une origine ou des convictions : traiter avec la même prudence (consentement explicite).
- **Photos et selfies** : l'analyse de visage sert uniquement à vérifier qu'un visage est présent. Aucun gabarit biométrique n'est créé ni comparé automatiquement ; la comparaison selfie / photos est faite par un modérateur humain. Cette position doit rester vraie : toute reconnaissance faciale automatique relèverait de l'art. 9 (données biométriques).
- **Santé** : non collectée.

## 4. Sous-traitants et transferts hors Union européenne

Sous-traitant principal : **Google LLC / Google Cloud** (Firebase Auth, Firestore, Storage, Cloud Functions, Cloud Messaging, Cloud Vision, Cloud Logging). Un contrat de traitement (DPA) est inclus dans les conditions Google Cloud/Firebase ; il doit être **accepté et conservé** par l'éditeur.

**Localisation réellement configurée (vérifiée le 2026-11-13)** :

| Composant | Région | Conséquence |
|---|---|---|
| Cloud Functions | `europe-west1` (Belgique) | Traitement en UE |
| **Firestore** | **`nam5` (États-Unis, multi-région)** | **Données hors UE** |
| **Storage** | **`US-WEST1` (États-Unis)** | **Photos hors UE** |

- **[ÉCART]** Les données des membres européens (profil, messages, photos) sont stockées aux États-Unis. Un transfert est possible sous le cadre de protection des données UE-États-Unis (Google est certifié) et les clauses contractuelles types, mais cela doit être documenté, mentionné dans la politique de confidentialité, et reste un point de vigilance pour une application traitant des données sensibles.
- **[DÉCISION recommandée]** Créer le projet de **production** avec Firestore et Storage en **région européenne** (ex. `eur3`, `europe-west1`). La région d'une base Firestore et d'un bucket est **définitive** : on ne peut pas la changer sur ce projet. Cela rejoint le besoin déjà identifié d'un projet séparé pour la production (le projet actuel `djama-1c7f8` sert aussi de projet de test à une autre application de l'éditeur). Faire ce choix **avant** l'ouverture au public évite une migration de données de membres réels.
- Cloud Vision : l'appel part des fonctions européennes ; l'endpoint par défaut est global. **[À VÉRIFIER/DÉCISION]** utiliser le point d'accès européen de Vision (`eu-vision.googleapis.com`) pour que les images ne quittent pas l'UE.
- Notifications push : transitent par les serveurs Google (FCM).

## 5. Droits des personnes : ce qui est implanté

| Droit | Où dans l'app | État |
|---|---|---|
| Accès et portabilité (art. 15, 20) | Paramètres → export (`exportMyData`, fichier JSON) | **Complet (déployé le 14/11/2026)** : profil, statut (dont consentement et préférences), réponses de compatibilité, photos **en fichier** (le lien de téléchargement que l'appli utilise déjà pour afficher la photo à son propriétaire) avec statut et raison de refus, likes et passes envoyés, nombre de likes reçus, **messages envoyés**, matchs, publications, **réponses et j'aime de la Communauté**, participations, **avis**, **signalements faits** (sans désigner la personne visée), nombre de blocages. plus événements en favori, tentatives de filtrage, identifiants d'appareil et e-mail. Jamais le nom ni les messages d'un autre membre (seuls figurent, pour les likes envoyés et les matchs, les identifiants techniques des personnes concernées) ; les jetons de notification sont remplacés par un nombre d'appareils, et les identifiants d'administrateurs ou du dernier profil passé sont retirés du statut |
| Rectification (art. 16) | Profil → Modifier mon profil | Conforme. L'âge est recalculé côté serveur ; changer la date de naissance est possible via le profil |
| Effacement (art. 17) | Paramètres → supprimer mon compte (`deleteAccount`) | **Conforme pour le périmètre listé en §6** ; points restants en §6 |
| Limitation / opposition (art. 18, 21) | — | **[ÉCART]** pas de parcours dédié ; suppression du compte ou contact du responsable de traitement |
| Retrait du consentement | Bouton « Ma position », permission de notifications, masquage du profil, **Paramètres → Consentement aux données sensibles** | Conforme (art. 9 : déployé le 14/11/2026, §3) |
| Décision automatisée (art. 22) | Questionnaire de filtrage : recours humain (`requestFiltrageReview`). Photos : pas de recours, décision du propriétaire (§7 bis point 3) | Filtrage conforme ; photos : **risque assumé** et atténué (§7 bis) |
| Information (art. 13-14) | Paramètres → Informations (conditions, confidentialité, mentions légales) ; lien depuis l'écran de consentement | Textes **provisoires** affichés avec un bandeau (`kLegalDraft`) ; **[ÉCART restant]** relecture par un juriste, identité de l'éditeur et contact à publier |

## 6. Effacement de compte : périmètre exact

La suppression est écrite **une seule fois** (`shared/eraseAccount.ts`) et utilisée à la fois par `deleteAccount` (demande du membre) et par `purgeInactiveAccounts` (comptes inactifs). Aucune erreur n'est avalée (la suppression est rejouable ; un compte d'authentification déjà absent n'est pas une erreur). Elle supprime, dans cet ordre : photos de profil, selfie de vérification et affiches d'événements (Storage) ; documents de photos ; swipes envoyés et reçus ; matchs avec leurs messages **et leurs photos de conversation** ; blocages posés ; publications du membre avec leurs participations et lieu privé ; participations faites ailleurs ; **j'aime et réponses laissés sur les publications des autres** ; **référence du membre dans les signaux d'appareil** ; **avis laissés sur des événements**, **événements en favori**, **blocages dont le membre est la cible**, **listes d'invités** où il figure, **codes d'invitation partageables** de ses événements, tout le contenu de ses publications (sous-collections incluses, `recursiveDelete`), **jetons d'achat** et **compteurs de fréquence** (`rate_limits`) — ces ajouts datent du 14/11/2026 ; une place d'événement **confirmée** est libérée proprement (compteur de participants remis à jour, liste d'attente promue) ; tentatives de filtrage ; réponses de compatibilité ; profil et statut ; enfin le compte d'authentification.

À noter :
- Les **messages sont supprimés pour les deux membres** du match (la conversation est un objet unique). **[DÉCISION]** alternative : ne supprimer que les messages du membre qui part (conserver ceux de l'interlocuteur).
- **Conservés volontairement** : signalements (`moderation_requests`) où le membre est auteur ou cible, et journal des actions d'administration — pour la sécurité des autres membres et la preuve de modération. **[DÉCISION]** durée de conservation à fixer et mention dans la politique de confidentialité ; proposé : 12 mois après la clôture du signalement, puis anonymisation.
- Les journaux Cloud Logging expirent d'eux-mêmes (30 jours par défaut).
- Sauvegardes : aucune sauvegarde planifiée de Firestore n'a été configurée par l'éditeur (vérifié le 2026-11-13) ; à réexaminer si une sauvegarde est activée un jour (elle devrait alors être purgée selon les mêmes durées).

## 7. Durées de conservation : état et proposition

| Donnée | Aujourd'hui | Proposition (la plus protectrice) |
|---|---|---|
| Compte inactif | Profil masqué des autres après 30 jours (`INACTIVE_ACCOUNT_DAYS`), jamais supprimé **[ÉCART]** | Prévenir puis supprimer après 24 mois d'inactivité — **déployé le 14/11/2026** : `purgeInactiveAccounts` (quotidienne) avertit par notification après 23 mois sans activité (`INACTIVE_ACCOUNT_WARNING_MONTHS`) puis supprime 30 jours plus tard si le membre n'est pas revenu (`INACTIVE_ACCOUNT_GRACE_DAYS`) ; 25 comptes au plus par exécution ; l'état du compte est relu juste avant toute action ; comptes administrateur jamais purgés (et ignorés si leur compte d'authentification ne peut pas être lu). **Le compte à rebours ne démarre que si la notification a réellement atteint un appareil** : sans appareil joignable (jeton retiré à la déconnexion ou périmé, cas fréquent après 23 mois) le compte n'est **pas** supprimé, il reste masqué des autres membres. **Limites / décision du propriétaire** : (1) un canal fiable (e-mail) est nécessaire pour purger ces comptes — l'appli n'envoie aucun e-mail à ce jour ; (2) un compte jamais arrivé à l'écran principal (sans date d'activité) n'est pas couvert |
| Photo refusée | Supprimée automatiquement 30 jours après le refus (`purgeRejectedPhotos`) ; suppression immédiate possible par le membre | Décidé et implanté |
| Selfie de vérification | Tout le dossier du membre est supprimé dès la décision du modérateur (une seule décision par demande) ; seuls `isVerified`, le statut, la date et le décideur restent (déployé le 14/11/2026) | Décidé et implanté |
| Match sans message | Marqué « expiré » après 7 jours, jamais supprimé | Supprimer après 90 jours |
| Signalements et journaux d'administration | Non fixée | 12 mois après clôture |
| Position | Dernier point seulement | Inchangé ; envisager l'effacement après 30 jours sans mise à jour |

Restent à implanter : la suppression des matchs sans message après 90 jours, l'anonymisation des signalements après 12 mois (durées à valider par le propriétaire) et l'effacement de la position après 30 jours sans mise à jour.

## 7 bis. Photo refusée : parcours actuel et recommandation

Parcours **actuel** : l'analyse automatique (Cloud Vision) refuse immédiatement une photo dont le contenu est jugé sensible (nudité, tenue suggestive, violence) ; un modérateur peut aussi refuser. Le membre voit la photo (elle seule lui reste visible), la mention « Refusée », la raison (automatique ou modérateur) et un bouton « Supprimer cette photo ». Les autres membres ne la voient jamais.

**Recommandations** (par ordre de priorité) :
1. **Expliquer clairement** la raison et ce qui est attendu (photo de soi, visage visible, tenue correcte) — **fait** (visionneuse du Profil).
2. **Permettre de supprimer et de remplacer** en un geste — **fait** (bouton dans la visionneuse).
3. **Recours humain : décision du propriétaire du 2026-11-13 — aucun recours pour les photos, sauf à l'inscription** (le questionnaire de filtrage garde son recours humain, `requestFiltrageReview`). Le refus d'une photo ne bloque pas le compte : le membre supprime la photo et en envoie une autre. Risque à connaître : le refus automatique est une décision fondée uniquement sur un traitement automatisé (art. 22). Les atténuations retenues sont que la décision ne porte que sur une photo (jamais sur l'accès au compte), que la raison est expliquée au membre, et qu'il peut remplacer la photo immédiatement. Un modérateur humain peut toujours refuser ou valider une photo en attente depuis l'espace admin.
4. **Purge automatique des photos refusées 30 jours après le refus** (minimisation, §7) — `purgeRejectedPhotos`, tâche quotidienne : supprime le fichier Storage puis le document. Le membre peut la supprimer lui-même avant. Aucune suspension de la purge, puisqu'il n'y a pas de recours. **[Implantée dans le dépôt ; état de déploiement : voir `docs/suivi-developpement.md`.]**
5. **Notifier** le membre (notification push) quand une photo est refusée, pour qu'il n'ait pas à ouvrir l'onglet Profil. Non implanté.
6. Ne pas compter une photo refusée dans la limite de 6 photos. Non implanté.

## 8. Mineurs

L'accès est réservé aux majeurs : l'âge minimum de 18 ans est vérifié **côté serveur** (`saveProfil`), jamais seulement dans l'app. Il n'y a pas de contrôle d'âge renforcé (pièce d'identité) : la date de naissance est déclarative. Les boutiques d'applications exigent d'indiquer une classification 18+.

## 9. Sécurité (art. 32)

En place : règles Firestore et Storage versionnées et vérifiées identiques à la production (`scripts/verify_deployed.py`) ; écriture exclusivement par des fonctions serveur pour les données sensibles (profil, swipes, matchs, modération, communauté) ; données privées illisibles par les autres membres (date de naissance, position, jetons de notification) ; URL signées de 10 minutes pour les selfies de vérification ; rôle administrateur par claim d'authentification, actions d'administration journalisées ; blocages respectés partout ; limites de fréquence sur les actions sensibles ; messages limités à 2 000 caractères ; tests réels des j'aime, réponses et retour (`scripts/test_post_interactions.py`, `scripts/test_undo_swipe.py`).

**Limites de fréquence déployées le 14/11/2026** : messages 20 par minute et 600 par jour (`sendMessage`, seul chemin d'envoi : les règles Firestore refusent désormais la création directe d'un message), signalements 10 par heure et 30 par jour (quota commun aux deux fonctions), réponses de la Communauté 20 par heure — un seul mécanisme (`shared/rateLimit.ts`, compteurs `rate_limits`). **App Check : code prêt, volontairement désactivé** (`ENFORCE_APP_CHECK = false` dans `shared/appCheck.ts`, appliqué à toutes les fonctions appelables, y compris les quatre de paiement mises en pause) : l'activer avant l'enregistrement de l'appli dans la console Firebase (Play Integrity, empreinte SHA-256 de la version publiée) couperait l'accès à tous les membres. Écarts : **App Check non activé en production** (un script externe peut encore appeler les fonctions, avec les limites ci-dessus) ; pas de projet de test séparé de la production ; pas d'intégration continue ; chiffrement : TLS en transit et chiffrement au repos par défaut chez Google, pas de chiffrement applicatif des messages.

## 10. Documents et démarches à produire (non rédigés à ce jour)

1. **Politique de confidentialité** (art. 13-14) accessible dans l'app et sur la fiche des boutiques : finalités, bases légales, destinataires, transferts, durées (§7), droits et contact, droit de réclamation auprès de la CNIL.
2. **Conditions générales d'utilisation** et **mentions légales** de l'éditeur.
3. **Recueil du consentement explicite** (art. 9) à l'inscription, séparé de la charte, retirable (§3).
4. **Analyse d'impact (AIPD/DPIA)** : recommandée, voire obligatoire (données sensibles, grande échelle, profilage, géolocalisation).
5. **Procédure de violation de données** : notification à la CNIL sous 72 heures, information des membres si risque élevé ; désigner qui décide et qui contacte.
6. **Accord de traitement Google Cloud/Firebase** accepté et archivé ; vérifier les clauses pour les transferts (§4).
7. **Formulaires des boutiques** : « Sécurité des données » (Google Play) et « Confidentialité de l'app » (Apple), cohérents avec le §2.
8. Procédure interne de réponse aux demandes de droits (délai d'un mois).

## 11. Plan d'action priorisé

| Priorité | Action | Type |
|---|---|---|
| P0 avant ouverture | Créer le projet de production avec Firestore/Storage en **UE** (§4) | Décision + infrastructure |
| P0 avant ouverture | Politique de confidentialité et mentions légales : textes provisoires affichés, **relecture juridique et identité de l'éditeur à publier** (§10) ; consentement art. 9 : écran déployé le 14/11/2026 | Rédaction + validation |
| P1 | Purges : selfie après décision et comptes inactifs implantés (déployés le 14/11/2026) ; restent matchs sans message, signalements, position (§7) | Développement |
| P1 | Export des données complété (§5) — déployé le 14/11/2026 | Développement |
| P1 | Limites de fréquence déployées le 14/11/2026 ; **activer App Check** : action de console Firebase puis `ENFORCE_APP_CHECK = true` (§9) | Développement + console |
| P2 | AIPD, procédure de violation, DPO à décider, durées des signalements | Juridique |
| P2 | Point d'accès européen de Cloud Vision | Développement |

*Mise à jour : à chaque fonctionnalité touchant des données personnelles (règlement permanent, sections 19 et 21), mettre à jour §2, §6 et §7 en même temps que `docs/architecture-technique.md` §7.*
