// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get genericError => 'Une erreur est survenue, réessaie.';

  @override
  String genericErrorWithCode(String code) {
    return 'Une erreur est survenue, réessaie. ($code)';
  }

  @override
  String unexpectedError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get continueButton => 'Continuer';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get closeButton => 'Fermer';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get onboardingTagline => 'rencontres et communauté kamites';

  @override
  String get onboardingBeforeStart => 'Avant de commencer';

  @override
  String get onboardingIntro =>
      'Cette application rassemble des personnes qui se reconnaissent dans l\'identité et les valeurs kamites, pour des rencontres amoureuses sérieuses. L\'adhésion repose sur ta connaissance et ton engagement envers cette culture — jamais sur ton origine ou ton apparence.';

  @override
  String get onboardingCharterTitle => 'CHARTE COMMUNAUTAIRE';

  @override
  String get onboardingCharter1 =>
      'Je m\'identifie à la communauté et à l\'histoire kamite et je m\'engage à la respecter.';

  @override
  String get onboardingCharter2 =>
      'Je comprends qu\'un questionnaire de connaissance et de valeurs valide mon inscription.';

  @override
  String get onboardingCharter3 =>
      'Je m\'engage au respect, à l\'honnêteté et à la bonne conduite envers les autres membres.';

  @override
  String get onboardingAcceptCharter =>
      'J\'ai lu et j\'accepte la charte communautaire ainsi que les conditions d\'utilisation.';

  @override
  String get homeWelcomeHint =>
      'Compte activé et profil créé.\nProchaine étape : Découvrir, Likes, Messages, Communauté.';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navLikes => 'Likes';

  @override
  String get navMessages => 'Messages';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get navProfile => 'Profil';

  @override
  String get navPremium => 'Premium & jetons';

  @override
  String get navCompatTest => 'Faire le test de compatibilité';

  @override
  String get navIdentityVerification => 'Vérification d\'identité';

  @override
  String get navAdmin => 'Administration';

  @override
  String get becomeAdminSuccess => 'Tu es maintenant administrateur.';

  @override
  String get becomeAdminAlreadyExists =>
      'Un administrateur existe déjà sur ce projet.';

  @override
  String becomeAdminFailed(String code) {
    return 'Impossible de devenir admin, réessaie ($code).';
  }

  @override
  String get networkErrorRetry => 'Erreur réseau, réessaie.';

  @override
  String get becomeFirstAdmin => 'Devenir le premier administrateur';

  @override
  String get authErrorEmailInUse => 'Cette adresse e-mail est déjà utilisée.';

  @override
  String get authErrorInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get authErrorWeakPassword =>
      'Mot de passe trop faible (8 caractères minimum).';

  @override
  String get authErrorWrongCredentials => 'E-mail ou mot de passe incorrect.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives, réessaie dans quelques minutes.';

  @override
  String get authErrorOperationNotAllowed =>
      'Ce mode de connexion n\'est pas encore activé côté serveur (à vérifier dans la console Firebase).';

  @override
  String get authErrorNetwork =>
      'Pas de connexion internet, vérifie ton réseau.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get invalidEmail => 'E-mail invalide';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get passwordMinLength => '8 caractères minimum';

  @override
  String get orSeparator => 'ou';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get signInTitle => 'Content de te revoir';

  @override
  String get signInSubtitle => 'Connecte-toi à ton compte MERUT';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get noAccountYet => 'Pas encore de compte ? Créer un compte';

  @override
  String get signUpTitle => 'Créer un compte';

  @override
  String get signUpSubtitle => 'Rejoins la communauté MERUT';

  @override
  String get mustConfirmAdult => 'Tu dois confirmer avoir 18 ans ou plus.';

  @override
  String get confirmAdult => 'Je confirme avoir 18 ans ou plus.';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get verificationEmailResent => 'E-mail de vérification renvoyé.';

  @override
  String get yourAddressFallback => 'ton adresse';

  @override
  String get checkYourInbox => 'Vérifie ta boîte mail';

  @override
  String verificationEmailSentTo(String email) {
    return 'Un lien de confirmation a été envoyé à $email. Clique sur le lien, cette page se met à jour automatiquement.';
  }

  @override
  String get sendingEllipsis => 'Envoi...';

  @override
  String get resendEmail => 'Je n\'ai rien reçu, renvoyer l\'e-mail';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordSentHint =>
      'Si cette adresse existe, un e-mail de réinitialisation vient d\'être envoyé. Pense à vérifier tes spams.';

  @override
  String get resetPasswordInstructions =>
      'Indique ton adresse e-mail, on t\'envoie un lien pour choisir un nouveau mot de passe.';

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String get startButton => 'Commencer';

  @override
  String get finishButton => 'Terminer';

  @override
  String get nextQuestion => 'Question suivante';

  @override
  String get filtrageIntroTitle => 'Vérification d\'engagement';

  @override
  String get filtrageIntroBody =>
      'Avant d\'accéder à MERUT, quelques questions sur la culture, l\'histoire et les valeurs kamites. Jamais sur ton apparence ou ton origine.';

  @override
  String filtrageStartFailedWithCode(String code) {
    return 'Impossible de démarrer le questionnaire pour le moment. ($code)';
  }

  @override
  String get filtrageHeaderTitle => 'VÉRIFICATION D\'ENGAGEMENT';

  @override
  String questionCounter(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get filtrageDisclaimer =>
      'Ce questionnaire porte uniquement sur la culture, l\'histoire et les valeurs — jamais sur ton apparence ou ton origine. Un score minimum est requis pour activer ton compte ; en cas d\'échec, tu peux demander une révision par un modérateur.';

  @override
  String get reviewInProgressTitle => 'Révision en cours';

  @override
  String get nextAttemptSoonTitle => 'Nouvel essai bientôt disponible';

  @override
  String get reviewInProgressBody =>
      'Un modérateur va revoir ta situation. Tu reçois une notification dès que c\'est traité.';

  @override
  String get canRetryNow => 'Tu peux retenter le questionnaire dès maintenant.';

  @override
  String canRetryFrom(String date) {
    return 'Tu peux retenter le questionnaire à partir du $date.';
  }

  @override
  String get retryFiltrageButton => 'Retenter le questionnaire';

  @override
  String get filtragePassedTitle => 'Bienvenue dans la communauté';

  @override
  String get filtrageFailedTitle => 'Ce n\'est pas passé cette fois';

  @override
  String get filtragePassedBody =>
      'Ton engagement envers la culture et les valeurs kamites est confirmé. Ton compte est activé.';

  @override
  String filtrageFailedBody(int score) {
    return 'Score obtenu : $score %. Tu peux retenter dans quelques jours, ou demander une révision par un modérateur si tu penses qu\'il y a une erreur.';
  }

  @override
  String get requestHumanReview => 'Demander une révision humaine';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get bannedTitle => 'Compte suspendu définitivement';

  @override
  String get suspendedTitle => 'Compte suspendu temporairement';

  @override
  String suspendedUntilDate(String date) {
    return 'Ton compte redevient actif à partir du $date.';
  }

  @override
  String get sanctionFollowsReports =>
      'Cette décision fait suite à un ou plusieurs signalements confirmés.';

  @override
  String get sanctionAppealHint =>
      'Si tu penses que c\'est une erreur, tu peux demander qu\'un modérateur réexamine cette décision.';

  @override
  String get appealSent => 'Recours envoyé, un modérateur va l\'examiner.';

  @override
  String get appealSendFailed => 'Impossible d\'envoyer le recours, réessaie.';

  @override
  String get appealPending => 'Recours en cours de traitement';

  @override
  String get contestSanction => 'Contester cette sanction';

  @override
  String get safetyTitle => 'Sécurité';

  @override
  String get emergencyNumbersTitle => 'Numéros d\'urgence';

  @override
  String get emergencyNumbersFrance =>
      '17 (Police/Gendarmerie) · 112 (urgences Europe)';

  @override
  String get emergencyNumbersBelgium => '101 (Police) · 112 (urgences Europe)';

  @override
  String get emergencyNumbersFallback =>
      '112 (fonctionne dans la plupart des pays via un réseau mobile) — vérifie aussi le numéro d\'urgence local de ton pays de résidence';

  @override
  String get emergencySheetDisclaimer =>
      'Si quelqu\'un te met en danger immédiat, préviens la modération en priorité absolue. Ce bouton n\'appelle jamais les secours à ta place — compose un numéro ci-dessus si tu es en danger maintenant.';

  @override
  String get emergencySendFailed =>
      'Échec de l\'envoi, réessaie — ou appelle directement un numéro ci-dessous.';

  @override
  String get moderationNotified => 'Modération prévenue';

  @override
  String get reportImmediateDanger => 'Signaler un danger immédiat';

  @override
  String get relationshipIntentSerieuse => 'Relation sérieuse';

  @override
  String get relationshipIntentFamille =>
      'Relation durable en vue d\'une famille';

  @override
  String get relationshipIntentDecouverte => 'Découverte amoureuse';

  @override
  String get relationshipIntentMariage => 'Mariage';

  @override
  String get lifestyleHabitNever => 'Jamais';

  @override
  String get lifestyleHabitSometimes => 'Parfois';

  @override
  String get lifestyleHabitOften => 'Souvent';

  @override
  String get childrenStatusHas => 'A déjà des enfants';

  @override
  String get childrenStatusWants => 'Veut des enfants';

  @override
  String get childrenStatusDoesNotWant => 'Ne veut pas d\'enfants';

  @override
  String get childrenStatusNotSure => 'Ne sait pas encore';

  @override
  String get qualityFunny => 'Drôle';

  @override
  String get qualityAmbitious => 'Ambitieux(se)';

  @override
  String get qualityCalm => 'Calme';

  @override
  String get qualityAdventurous => 'Aventurier(ère)';

  @override
  String get qualityRomantic => 'Romantique';

  @override
  String get qualityGenerous => 'Généreux(se)';

  @override
  String get qualitySincere => 'Sincère';

  @override
  String get qualitySpiritual => 'Spirituel(le)';

  @override
  String get qualityCaring => 'Attentionné(e)';

  @override
  String get qualityDetermined => 'Déterminé(e)';

  @override
  String get qualityCreative => 'Créatif(ve)';

  @override
  String get qualityLoyal => 'Loyal(e)';

  @override
  String get qualityPatient => 'Patient(e)';

  @override
  String get qualityOptimistic => 'Optimiste';

  @override
  String get genderWoman => 'Femme';

  @override
  String get genderMan => 'Homme';

  @override
  String get genderOther => 'Autre';

  @override
  String get birthDateRequired => 'Indique ta date de naissance.';

  @override
  String get mustBeAdult =>
      'MERUT est réservé aux personnes de 18 ans et plus.';

  @override
  String get pickSeekingPreference =>
      'Choisis au moins une préférence de recherche.';

  @override
  String get yourProfile => 'Ton profil';

  @override
  String get firstNameOrNickname => 'Prénom ou pseudonyme';

  @override
  String get requiredField => 'Requis';

  @override
  String get birthDateLabel => 'Date de naissance';

  @override
  String get chooseDate => 'Choisir une date';

  @override
  String get genderLabel => 'Genre';

  @override
  String get iAmSeeking => 'Je recherche';

  @override
  String get countryLabel => 'Pays';

  @override
  String get cityLabel => 'Ville';

  @override
  String get bioLabel => 'Description personnelle';

  @override
  String get professionLabel => 'Profession (facultatif)';

  @override
  String get languagesLabel => 'Langues parlées (séparées par des virgules)';

  @override
  String get interestsLabel => 'Centres d\'intérêt (séparés par des virgules)';

  @override
  String get culturalOriginsLabel =>
      'Origines culturelles déclarées (facultatif)';

  @override
  String get valuesLabel => 'Présentation de tes valeurs (facultatif)';

  @override
  String get relationshipIntentLabel => 'Intention relationnelle';

  @override
  String get yourFicheSectionTitle => 'TA FICHE';

  @override
  String get heightLabel => 'Taille en cm (facultatif)';

  @override
  String get educationLevelLabel => 'Niveau d\'études (facultatif)';

  @override
  String get smokingLabel => 'Tabac (facultatif)';

  @override
  String get drinkingLabel => 'Alcool (facultatif)';

  @override
  String get childrenLabel => 'Enfants (facultatif)';

  @override
  String get lookingForLabel =>
      'Ce que tu recherches chez l\'autre (facultatif)';

  @override
  String get qualitiesSectionHint =>
      'Tes qualités (facultatif, choisis-en quelques-unes)';

  @override
  String get profileSaveFailed =>
      'Impossible d\'enregistrer ton profil, vérifie ta connexion et réessaie.';

  @override
  String get saveMyProfile => 'Enregistrer mon profil';

  @override
  String get photosSectionTitle => 'PHOTOS';

  @override
  String get photosLoadFailed => 'Impossible de charger les photos.';

  @override
  String get photoRejected => 'Refusée';

  @override
  String get photoPending => 'En attente';

  @override
  String get deletePhotoConfirmTitle => 'Supprimer cette photo ?';

  @override
  String get photoDeleteFailed => 'Impossible de supprimer, réessaie.';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get takeAPhoto => 'Prendre une photo';

  @override
  String get photoUploadFailed => 'Impossible d\'envoyer la photo, réessaie.';

  @override
  String get identityVerificationTitle => 'Vérification d\'identité';

  @override
  String get identityIntro =>
      'Prends un selfie clair, visage visible, pour obtenir le badge vérifié et pouvoir organiser des événements physiques.';

  @override
  String get identityPrivacyHint =>
      'Jamais vu par un autre membre — uniquement par un modérateur, et jamais obligatoire pour le reste de l\'app.';

  @override
  String get takeASelfie => 'Prendre un selfie';

  @override
  String get identitySubmitted => 'Envoyé, un modérateur va vérifier.';

  @override
  String get identitySubmitFailed => 'Impossible d\'envoyer, réessaie.';

  @override
  String get compatTestTitle => 'Test de compatibilité';

  @override
  String get compatQuestionsLoadFailed =>
      'Impossible de charger les questions.';

  @override
  String get compatTestNotAvailable =>
      'Le test de compatibilité n\'est pas encore disponible.';

  @override
  String get compatTestInstructions =>
      'Note chaque affirmation de 1 (pas du tout d\'accord) à 5 (tout à fait d\'accord). Tes réponses détaillées ne sont jamais visibles par les autres membres — seul un score de compatibilité est partagé.';

  @override
  String get saveMyAnswers => 'Enregistrer mes réponses';

  @override
  String get answersSaved => 'Réponses enregistrées.';

  @override
  String get answersSaveFailed =>
      'Impossible d\'enregistrer, vérifie ta connexion et réessaie.';

  @override
  String get compatThemeVisionCouple => 'Vision du couple';

  @override
  String get compatThemeValeursCulture => 'Valeurs et culture';

  @override
  String get compatThemeFamille => 'Famille';

  @override
  String get compatThemeModeVie => 'Mode de vie';

  @override
  String get compatThemeCommunication => 'Communication';

  @override
  String get refreshButton => 'Actualiser';

  @override
  String get applyButton => 'Appliquer';

  @override
  String get itsAMatch => 'C\'est un match !';

  @override
  String mutualLikeWith(String name) {
    return 'Toi et $name vous êtes mutuellement likés.';
  }

  @override
  String get great => 'Super';

  @override
  String get profilesLoadFailed => 'Impossible de charger les profils.';

  @override
  String get noMoreProfiles =>
      'Plus de profils pour l\'instant, repasse plus tard.';

  @override
  String compatScoreBadge(int score) {
    return '$score % compatible';
  }

  @override
  String cityCountryWithDistance(String city, String country, int distance) {
    return '$city, $country · à $distance km';
  }

  @override
  String cityCountry(String city, String country) {
    return '$city, $country';
  }

  @override
  String get filtersTitle => 'Filtres';

  @override
  String ageRangeLabel(int min, int max) {
    return 'Âge : $min - $max ans';
  }

  @override
  String maxDistanceLabel(int distance) {
    return 'Distance max : $distance km';
  }

  @override
  String get locationUpdated => 'Position mise à jour.';

  @override
  String get locationUnavailable =>
      'Position indisponible (permission refusée ?).';

  @override
  String get locatingEllipsis => 'Localisation...';

  @override
  String get updateMyLocation => 'Mettre à jour ma position';

  @override
  String get locationFilterTitle => 'Chercher dans un autre pays';

  @override
  String get locationFilterHint =>
      'Renseigne un pays (et, si tu veux, une ville) pour voir des profils hors de ton rayon GPS — remplace le filtre de distance tant que c\'est rempli.';

  @override
  String get dailyLikeLimitReached =>
      'Limite de likes quotidienne atteinte, reviens demain ou passe en Premium.';

  @override
  String get profileAlreadySwiped => 'Ce profil a déjà été swipé.';

  @override
  String get likesLoadFailed => 'Impossible de charger les likes.';

  @override
  String likedYouTab(int count) {
    return 'T\'ont liké · $count';
  }

  @override
  String get myLikesTab => 'Mes likes';

  @override
  String get noOneLikedYouYet => 'Aucun like pour le moment';

  @override
  String get noOneLikedYouYetHint =>
      'Les membres qui aiment ton profil apparaîtront ici.';

  @override
  String get seeWhoLikedYou => 'Voir qui t\'a liké';

  @override
  String unlockProfilesWithPremium(int count) {
    return 'Débloque les $count profils avec Premium';
  }

  @override
  String get premiumTeaserPrice => '9,99 €';

  @override
  String get noPendingLikesYet => 'Aucun like envoyé';

  @override
  String get noPendingLikesYetHint =>
      'Les profils que tu likes, en attente de réponse, apparaîtront ici.';

  @override
  String get retractLikeConfirmTitle => 'Retirer ce like ?';

  @override
  String retractLikeConfirmBody(String name) {
    return 'Tu ne liked plus $name.';
  }

  @override
  String get retractLikeFailed => 'Impossible de retirer ce like, réessaie.';

  @override
  String get retractButton => 'Retirer';

  @override
  String get conversationsLoadFailed =>
      'Impossible de charger les conversations.';

  @override
  String get noMatchesYet => 'Tes prochains matchs commencent ici';

  @override
  String get noMatchesYetHint =>
      'Complète ton profil et explore Découvrir pour obtenir tes premiers matchs.';

  @override
  String get sayHelloPreview => 'Dites bonjour 👋';

  @override
  String get beforeSendingPhotoTitle => 'Avant d\'envoyer une photo';

  @override
  String get beforeSendingPhotoBody =>
      'Respecte la charte communautaire : pas de contenu inapproprié. La personne en face peut te signaler.';

  @override
  String get blockButton => 'Bloquer';

  @override
  String get reportButton => 'Signaler';

  @override
  String get conversationNoLongerAccessible =>
      'Cette conversation n\'est plus accessible.';

  @override
  String get blockedProfilesTitle => 'Mes blocages';

  @override
  String get noBlockedProfiles => 'Tu n\'as bloqué personne pour le moment.';

  @override
  String get unblockButton => 'Débloquer';

  @override
  String get unblockConfirmTitle => 'Débloquer ce profil ?';

  @override
  String unblockConfirmBody(String name) {
    return '$name pourra à nouveau apparaître dans Découvrir et te contacter.';
  }

  @override
  String get blockProfileAction => 'Bloquer ce profil';

  @override
  String get blockProfileConfirmTitle => 'Bloquer ce profil ?';

  @override
  String blockProfileConfirmBody(String name) {
    return '$name ne pourra plus voir ton profil ni te contacter, et toi non plus.';
  }

  @override
  String get blockProfileSuccess => 'Profil bloqué.';

  @override
  String get blockProfileFailed => 'Impossible de bloquer ce profil, réessaie.';

  @override
  String get messagesLoadFailed => 'Impossible de charger les messages.';

  @override
  String get readReceipt => 'Lu';

  @override
  String get sentReceipt => 'Envoyé';

  @override
  String get messageHint => 'Message...';

  @override
  String get blockMemberConfirmTitle => 'Bloquer ce membre ?';

  @override
  String get blockMemberConfirmBody =>
      'La conversation deviendra inaccessible pour vous deux, immédiatement.';

  @override
  String get reportSent => 'Signalement envoyé.';

  @override
  String get showPhotoButton => 'Afficher la photo';

  @override
  String get reportReasonFakeProfile => 'Faux profil';

  @override
  String get reportReasonAbusiveBehavior => 'Comportement abusif';

  @override
  String get reportReasonInappropriateContent => 'Contenu inapproprié';

  @override
  String get reportReasonScam => 'Arnaque';

  @override
  String get reportReasonOther => 'Autre';

  @override
  String get feedLoadFailed => 'Impossible de charger le fil.';

  @override
  String get nothingToShowYet => 'Rien à afficher pour le moment.';

  @override
  String get postTypePublication => 'Publication (fil)';

  @override
  String get postTypePublicAnnouncement => 'Annonce publique';

  @override
  String get postTypePrivateAnnouncement => 'Annonce privée';

  @override
  String get postTypeFreeAnnouncement => 'Annonce libre';

  @override
  String get postTypePublicEvent => 'Événement public';

  @override
  String get postTypePrivateEvent => 'Événement privé';

  @override
  String get postTypeGeneric => 'Publication';

  @override
  String get eventDateAndCapacityRequired =>
      'Date et capacité requises pour un événement.';

  @override
  String get preciseLocationRequired => 'Lieu précis requis.';

  @override
  String get postPendingReview =>
      'Envoyé — en attente de validation par un modérateur.';

  @override
  String get postPublished => 'Publié !';

  @override
  String postFailed(String reason) {
    return 'Impossible de publier : $reason';
  }

  @override
  String get postErrorTooManyActive => 'tu as déjà 3 annonces actives.';

  @override
  String get postErrorVerifiedOnly => 'réservé aux membres vérifiés.';

  @override
  String get postErrorGeneric => 'réessaie.';

  @override
  String get newPostTitle => 'Nouvelle publication';

  @override
  String get typeLabel => 'Type';

  @override
  String get eventTitleLabel => 'Titre de l\'événement';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dateLabel => 'Date';

  @override
  String get capacityLabel => 'Capacité (nombre de places)';

  @override
  String get preciseLocationLabel =>
      'Lieu précis (masqué jusqu\'à acceptation)';

  @override
  String get eventVerifiedOnlyHint =>
      'Les événements physiques sont réservés aux membres vérifiés et passent toujours par une revue humaine avant publication.';

  @override
  String get publishButton => 'Publier';

  @override
  String reportWithReason(String reason) {
    return 'Signaler : $reason';
  }

  @override
  String eventDateAndParticipants(String date, int count, String capacity) {
    return '$date · $count/$capacity participants';
  }

  @override
  String get requestToParticipate => 'Demander à participer';

  @override
  String get requestAccepted => 'Demande acceptée !';

  @override
  String get seePreciseLocation => 'Voir le lieu précis';

  @override
  String checkinCodeLabel(String code) {
    return 'Code de présence : $code';
  }

  @override
  String statusLabel(String status) {
    return 'Statut : $status';
  }

  @override
  String get requestsLoadFailed => 'Impossible de charger les demandes.';

  @override
  String get noPendingRequests => 'Aucune demande en attente.';

  @override
  String get pendingRequestsTitle => 'Demandes en attente';

  @override
  String get acceptButton => 'Accepter';

  @override
  String get declineButton => 'Refuser';

  @override
  String get validateEntryTitle => 'Valider l\'entrée';

  @override
  String get enterCodeButton => 'Entrer le code';

  @override
  String get checkinCodeTitle => 'Code de présence';

  @override
  String get checkinCodeFieldLabel => 'Code donné par le participant';

  @override
  String get checkinValidated => 'Entrée validée.';

  @override
  String get checkinInvalidCode => 'Code invalide.';

  @override
  String get validateButton => 'Valider';

  @override
  String get boostActivated => 'Boost activé pour 30 minutes !';

  @override
  String get boostPremiumOnly => 'Le Boost est réservé aux membres Premium.';

  @override
  String get boostAlreadyUsed =>
      'Ton Boost gratuit de la semaine a déjà été utilisé.';

  @override
  String get boostActivateFailed => 'Impossible d\'activer le Boost, réessaie.';

  @override
  String get boostTitle => 'Boost';

  @override
  String get boostDescription =>
      '30 minutes de visibilité prioritaire, inclus 1x/semaine en Premium';

  @override
  String get activateButton => 'Activer';

  @override
  String get shopUnavailable => 'Boutique indisponible pour le moment.';

  @override
  String get noSubscriptionOffersYet =>
      'Aucune offre d\'abonnement disponible pour l\'instant.';

  @override
  String get exportFailed => 'Impossible d\'exporter, réessaie.';

  @override
  String get deleteAccountConfirmTitle =>
      'Supprimer définitivement ton compte ?';

  @override
  String get deleteAccountConfirmBody =>
      'Ton profil, tes photos, tes messages, tes matchs, tes annonces et tes réponses sont supprimés sans retour possible.';

  @override
  String get deletePermanentlyButton => 'Supprimer définitivement';

  @override
  String get deleteAccountFailed =>
      'Impossible de supprimer le compte, réessaie.';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get systemLanguage => 'Langue de l\'appareil';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get warningBannerTitle =>
      'Ton compte a reçu un avertissement suite à un signalement confirmé.';

  @override
  String get editMyProfile => 'Modifier mon profil';

  @override
  String get identityVerifiedTitle => 'Identité vérifiée';

  @override
  String profileCompletionPercent(int percent) {
    return '$percent %';
  }

  @override
  String get profileCompletionHint =>
      'Ajoute une profession, tes centres d\'intérêt, tes habitudes de vie ou une 3e photo pour un profil plus complet.';

  @override
  String get jetonsCounterLabel => 'Jetons';

  @override
  String get boostCounterLabel => 'Boost';

  @override
  String get boostCounterIncluded => 'Inclus';

  @override
  String get language => 'Langue';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get gdprPortabilityRight => 'Droit RGPD à la portabilité';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get privacySectionTitle => 'CONFIDENTIALITÉ';

  @override
  String get showReadReceiptsTitle => 'Indicateur de lecture';

  @override
  String get showReadReceiptsHint =>
      'Montrer aux autres quand tu as lu leurs messages (réciproque : désactivé aussi de leur côté)';

  @override
  String get compatVisibilityTitle => 'Visibilité du score de compatibilité';

  @override
  String get compatVisibilityHint =>
      'Autoriser les autres membres à voir un score de compatibilité avec toi sur Découvrir';

  @override
  String get wizardIdentityTitle =>
      'Comment tu t\'appelles, et tu es né(e) quand ?';

  @override
  String get wizardGenderTitle => 'Tu es...';

  @override
  String get wizardSeekingTitle => 'Qui souhaites-tu rencontrer ?';

  @override
  String get wizardIntentTitle => 'Qu\'est-ce que tu recherches ?';

  @override
  String get wizardLocationTitle => 'Où habites-tu ?';

  @override
  String get wizardBioTitle => 'Parle-nous un peu de toi';

  @override
  String get wizardBioSubtitle =>
      'Quelques lignes suffisent pour donner envie d\'en savoir plus.';

  @override
  String get wizardQualitiesTitle => 'Quelles sont tes qualités ?';

  @override
  String get wizardInterestsTitle => 'Tes centres d\'intérêt';

  @override
  String get wizardDetailsTitle => 'Encore quelques détails';

  @override
  String get wizardLifestyleTitle => 'Ton mode de vie';

  @override
  String get wizardPhotosTitle => 'Ajoute tes photos';

  @override
  String get confirmAdultDialogTitle => 'Confirmation d\'âge';

  @override
  String get confirmAdultDialogBody =>
      'MERUT est réservé aux personnes de 18 ans et plus. Confirmes-tu avoir 18 ans ou plus ?';

  @override
  String get confirmAdultDialogDecline => 'Non, annuler';

  @override
  String get confirmAdultDialogAccept => 'Oui, je confirme';
}
