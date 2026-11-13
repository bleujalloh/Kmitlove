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
| T3 | Photos de profil | Présenter le membre | Fichiers image, statut de modération, indicateur « visage détecté », scores SafeSearch | Contrat ; intérêt légitime (sécurité de la communauté) | Jusqu'à suppression par le membre ou du compte. **[ÉCART]** les photos refusées ne sont jamais purgées automatiquement | Storage `profile_photos`, Firestore `users/{uid}/photos` |
| T4 | Modération automatique des photos | Refuser les contenus sensibles, exiger un visage | Image envoyée à Google Cloud Vision (SafeSearch, détection de visage — pas de reconnaissance d'identité) | Intérêt légitime | Résultat conservé avec la photo | Cloud Functions → Cloud Vision |
| T5 | Vérification d'identité (facultative) | Badge « vérifié » | Selfie, décision du modérateur | Consentement | **[ÉCART]** le selfie reste en Storage jusqu'à suppression du compte, même après la décision | Storage `identity_verifications`, `user_status.isVerified` |
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

- **Orientation sexuelle** : MERUT ne demande jamais « quelle est votre orientation » mais la combinaison *genre* + *genres recherchés* la révèle. Ces données relèvent de l'art. 9 : un **consentement explicite et séparé** est requis à l'inscription, avec possibilité de le retirer. **[ÉCART]** l'inscription ne comporte aujourd'hui qu'une case « charte et conditions d'utilisation » (`onboarding_screen.dart`), sans consentement spécifique ni lien vers une politique de confidentialité.
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
| Accès et portabilité (art. 15, 20) | Paramètres → export (`exportMyData`, fichier JSON) | **Partiel [ÉCART]** : exporte profil, statut, réponses de compatibilité, liste des photos (identifiant et statut), likes envoyés, publications, matchs. **Manque** : messages envoyés, photos en fichier, j'aime et réponses laissés dans la Communauté, participations et avis, signalements faits, raison de refus des photos |
| Rectification (art. 16) | Profil → Modifier mon profil | Conforme. L'âge est recalculé côté serveur ; changer la date de naissance est possible via le profil |
| Effacement (art. 17) | Paramètres → supprimer mon compte (`deleteAccount`) | **Conforme pour le périmètre listé en §6** ; points restants en §6 |
| Limitation / opposition (art. 18, 21) | — | **[ÉCART]** pas de parcours dédié ; suppression du compte ou contact du responsable de traitement |
| Retrait du consentement | Bouton « Ma position », permission de notifications, masquage du profil | Conforme pour la position et les notifications. Pas de consentement art. 9 à retirer tant qu'il n'est pas recueilli (§3) |
| Décision automatisée (art. 22) | Questionnaire de filtrage : recours humain (`requestFiltrageReview`). Photos : voir §8 | Filtrage conforme ; photos **[ÉCART]** |
| Information (art. 13-14) | — | **[ÉCART]** aucune politique de confidentialité n'est affichée ni liée dans l'app |

## 6. Effacement de compte : périmètre exact

`deleteAccount` supprime, dans cet ordre : photos de profil, selfie de vérification et affiches d'événements (Storage) ; documents de photos ; swipes envoyés et reçus ; matchs avec leurs messages **et leurs photos de conversation** ; blocages posés ; publications du membre avec leurs participations et lieu privé ; participations faites ailleurs ; **j'aime et réponses laissés sur les publications des autres** ; **référence du membre dans les signaux d'appareil** ; tentatives de filtrage ; réponses de compatibilité ; profil et statut ; enfin le compte d'authentification.

À noter :
- Les **messages sont supprimés pour les deux membres** du match (la conversation est un objet unique). **[DÉCISION]** alternative : ne supprimer que les messages du membre qui part (conserver ceux de l'interlocuteur).
- **Conservés volontairement** : signalements (`moderation_requests`) où le membre est auteur ou cible, et journal des actions d'administration — pour la sécurité des autres membres et la preuve de modération. **[DÉCISION]** durée de conservation à fixer et mention dans la politique de confidentialité ; proposé : 12 mois après la clôture du signalement, puis anonymisation.
- Les journaux Cloud Logging expirent d'eux-mêmes (30 jours par défaut).
- Sauvegardes : aucune sauvegarde planifiée de Firestore n'a été configurée par l'éditeur (vérifié le 2026-11-13) ; à réexaminer si une sauvegarde est activée un jour (elle devrait alors être purgée selon les mêmes durées).

## 7. Durées de conservation : état et proposition

| Donnée | Aujourd'hui | Proposition (la plus protectrice) |
|---|---|---|
| Compte inactif | Profil masqué des autres après 30 jours (`INACTIVE_ACCOUNT_DAYS`), jamais supprimé **[ÉCART]** | Prévenir puis supprimer après 24 mois d'inactivité |
| Photo refusée | Conservée indéfiniment | Purger 30 jours après le refus (le membre peut la supprimer immédiatement) |
| Selfie de vérification | Conservé jusqu'à suppression du compte | Supprimer dès la décision du modérateur ; ne garder que `isVerified` |
| Match sans message | Marqué « expiré » après 7 jours, jamais supprimé | Supprimer après 90 jours |
| Signalements et journaux d'administration | Non fixée | 12 mois après clôture |
| Position | Dernier point seulement | Inchangé ; envisager l'effacement après 30 jours sans mise à jour |

Ces purges automatiques **ne sont pas encore implantées** : elles nécessitent des fonctions planifiées supplémentaires.

## 7 bis. Photo refusée : parcours actuel et recommandation

Parcours **actuel** : l'analyse automatique (Cloud Vision) refuse immédiatement une photo dont le contenu est jugé sensible (nudité, tenue suggestive, violence) ; un modérateur peut aussi refuser. Le membre voit la photo (elle seule lui reste visible), la mention « Refusée », la raison (automatique ou modérateur) et un bouton « Supprimer cette photo ». Les autres membres ne la voient jamais.

**Recommandations** (par ordre de priorité) :
1. **Expliquer clairement** la raison et ce qui est attendu (photo de soi, visage visible, tenue correcte) — **fait** (visionneuse du Profil).
2. **Permettre de supprimer et de remplacer** en un geste — **fait** (bouton dans la visionneuse).
3. **Offrir un recours humain** : un refus automatique est une décision automatisée qui limite l'accès au service (art. 22) ; l'analyse automatique peut se tromper (faux positifs fréquents sur les photos de sport ou de plage). Ajouter un bouton « Demander une révision » qui place la photo dans la file des modérateurs (`adminListPendingPhotos`, déjà existante), **sans** approbation automatique à 48 heures pour ces photos. **[DÉCISION] non implanté.**
4. **Purger automatiquement** les photos refusées après 30 jours (minimisation, §7). **[DÉCISION] non implanté.**
5. **Notifier** le membre (notification push) quand une photo est refusée, pour qu'il n'ait pas à ouvrir l'onglet Profil. Non implanté.
6. Ne pas compter une photo refusée dans la limite de 6 photos. Non implanté.

## 8. Mineurs

L'accès est réservé aux majeurs : l'âge minimum de 18 ans est vérifié **côté serveur** (`saveProfil`), jamais seulement dans l'app. Il n'y a pas de contrôle d'âge renforcé (pièce d'identité) : la date de naissance est déclarative. Les boutiques d'applications exigent d'indiquer une classification 18+.

## 9. Sécurité (art. 32)

En place : règles Firestore et Storage versionnées et vérifiées identiques à la production (`scripts/verify_deployed.py`) ; écriture exclusivement par des fonctions serveur pour les données sensibles (profil, swipes, matchs, modération, communauté) ; données privées illisibles par les autres membres (date de naissance, position, jetons de notification) ; URL signées de 10 minutes pour les selfies de vérification ; rôle administrateur par claim d'authentification, actions d'administration journalisées ; blocages respectés partout ; limites de fréquence sur les actions sensibles ; messages limités à 2 000 caractères ; tests réels des j'aime, réponses et retour (`scripts/test_post_interactions.py`, `scripts/test_undo_swipe.py`).

Écarts : **App Check non activé** (un script externe peut appeler les fonctions) ; pas de limite de fréquence sur l'envoi de messages et les signalements ; pas de projet de test séparé de la production ; pas d'intégration continue ; chiffrement : TLS en transit et chiffrement au repos par défaut chez Google, pas de chiffrement applicatif des messages.

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
| P0 avant ouverture | Politique de confidentialité, consentement art. 9, mentions légales (§10) | Rédaction + écran |
| P1 | Recours humain pour les photos refusées (§7 bis, point 3) | Développement |
| P1 | Purges : photos refusées, selfie après décision, comptes inactifs (§7) | Développement |
| P1 | Compléter l'export des données (§5) | Développement |
| P1 | Activer App Check ; limiter les messages et signalements (§9) | Développement |
| P2 | AIPD, procédure de violation, DPO à décider, durées des signalements | Juridique |
| P2 | Point d'accès européen de Cloud Vision | Développement |

*Mise à jour : à chaque fonctionnalité touchant des données personnelles (règlement permanent, sections 19 et 21), mettre à jour §2, §6 et §7 en même temps que `docs/architecture-technique.md` §7.*
