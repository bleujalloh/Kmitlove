import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Repli générique quand aucun message précis n'est connu pour l'erreur.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessaie.'**
  String get genericError;

  /// Repli générique avec code technique court, pour diagnostiquer depuis une simple capture d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessaie. ({code})'**
  String genericErrorWithCode(String code);

  /// Erreur technique inattendue (flux Firestore en erreur), placeholder brut.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String unexpectedError(String error);

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveButton;

  /// No description provided for @closeButton.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @deleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// No description provided for @onboardingTagline.
  ///
  /// In fr, this message translates to:
  /// **'rencontres et communauté kamites'**
  String get onboardingTagline;

  /// No description provided for @onboardingBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get onboardingBeforeStart;

  /// No description provided for @onboardingIntro.
  ///
  /// In fr, this message translates to:
  /// **'Cette application rassemble des personnes qui se reconnaissent dans l\'identité et les valeurs kamites, pour des rencontres amoureuses sérieuses. L\'adhésion repose sur ta connaissance et ton engagement envers cette culture — jamais sur ton origine ou ton apparence.'**
  String get onboardingIntro;

  /// No description provided for @onboardingCharterTitle.
  ///
  /// In fr, this message translates to:
  /// **'CHARTE COMMUNAUTAIRE'**
  String get onboardingCharterTitle;

  /// No description provided for @onboardingCharter1.
  ///
  /// In fr, this message translates to:
  /// **'Je m\'identifie à la communauté et à l\'histoire kamite et je m\'engage à la respecter.'**
  String get onboardingCharter1;

  /// No description provided for @onboardingCharter2.
  ///
  /// In fr, this message translates to:
  /// **'Je comprends qu\'un questionnaire de connaissance et de valeurs valide mon inscription.'**
  String get onboardingCharter2;

  /// No description provided for @onboardingCharter3.
  ///
  /// In fr, this message translates to:
  /// **'Je m\'engage au respect, à l\'honnêteté et à la bonne conduite envers les autres membres.'**
  String get onboardingCharter3;

  /// No description provided for @onboardingAcceptCharter.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et j\'accepte la charte communautaire ainsi que les conditions d\'utilisation.'**
  String get onboardingAcceptCharter;

  /// No description provided for @homeWelcomeHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte activé et profil créé.\nProchaine étape : Découvrir, Likes, Messages, Communauté.'**
  String get homeWelcomeHint;

  /// No description provided for @navDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get navDiscover;

  /// No description provided for @navLikes.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get navLikes;

  /// No description provided for @navMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navPremium.
  ///
  /// In fr, this message translates to:
  /// **'Premium & jetons'**
  String get navPremium;

  /// No description provided for @navCompatTest.
  ///
  /// In fr, this message translates to:
  /// **'Faire le test de compatibilité'**
  String get navCompatTest;

  /// No description provided for @navIdentityVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité'**
  String get navIdentityVerification;

  /// No description provided for @navAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get navAdmin;

  /// No description provided for @becomeAdminSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tu es maintenant administrateur.'**
  String get becomeAdminSuccess;

  /// No description provided for @becomeAdminAlreadyExists.
  ///
  /// In fr, this message translates to:
  /// **'Un administrateur existe déjà sur ce projet.'**
  String get becomeAdminAlreadyExists;

  /// No description provided for @becomeAdminFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de devenir admin, réessaie ({code}).'**
  String becomeAdminFailed(String code);

  /// No description provided for @networkErrorRetry.
  ///
  /// In fr, this message translates to:
  /// **'Erreur réseau, réessaie.'**
  String get networkErrorRetry;

  /// No description provided for @becomeFirstAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Devenir le premier administrateur'**
  String get becomeFirstAdmin;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible (8 caractères minimum).'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect.'**
  String get authErrorWrongCredentials;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessaie dans quelques minutes.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Ce mode de connexion n\'est pas encore activé côté serveur (à vérifier dans la console Firebase).'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet, vérifie ton réseau.'**
  String get authErrorNetwork;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail invalide'**
  String get invalidEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères minimum'**
  String get passwordMinLength;

  /// No description provided for @orSeparator.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get orSeparator;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @signInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à ton compte MERUT'**
  String get signInSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get noAccountYet;

  /// No description provided for @signUpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins la communauté MERUT'**
  String get signUpSubtitle;

  /// No description provided for @mustConfirmAdult.
  ///
  /// In fr, this message translates to:
  /// **'Tu dois confirmer avoir 18 ans ou plus.'**
  String get mustConfirmAdult;

  /// No description provided for @confirmAdult.
  ///
  /// In fr, this message translates to:
  /// **'Je confirme avoir 18 ans ou plus.'**
  String get confirmAdult;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get alreadyHaveAccount;

  /// No description provided for @verificationEmailResent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de vérification renvoyé.'**
  String get verificationEmailResent;

  /// No description provided for @yourAddressFallback.
  ///
  /// In fr, this message translates to:
  /// **'ton adresse'**
  String get yourAddressFallback;

  /// No description provided for @checkYourInbox.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta boîte mail'**
  String get checkYourInbox;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un lien de confirmation a été envoyé à {email}. Clique sur le lien, cette page se met à jour automatiquement.'**
  String verificationEmailSentTo(String email);

  /// No description provided for @sendingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Envoi...'**
  String get sendingEllipsis;

  /// No description provided for @resendEmail.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien reçu, renvoyer l\'e-mail'**
  String get resendEmail;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSentHint.
  ///
  /// In fr, this message translates to:
  /// **'Si cette adresse existe, un e-mail de réinitialisation vient d\'être envoyé. Pense à vérifier tes spams.'**
  String get resetPasswordSentHint;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Indique ton adresse e-mail, on t\'envoie un lien pour choisir un nouveau mot de passe.'**
  String get resetPasswordInstructions;

  /// No description provided for @sendLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendLink;

  /// No description provided for @startButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startButton;

  /// No description provided for @finishButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finishButton;

  /// No description provided for @nextQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get nextQuestion;

  /// No description provided for @filtrageIntroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'engagement'**
  String get filtrageIntroTitle;

  /// No description provided for @filtrageIntroBody.
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'accéder à MERUT, quelques questions sur la culture, l\'histoire et les valeurs kamites. Jamais sur ton apparence ou ton origine.'**
  String get filtrageIntroBody;

  /// No description provided for @filtrageStartFailedWithCode.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer le questionnaire pour le moment. ({code})'**
  String filtrageStartFailedWithCode(String code);

  /// No description provided for @filtrageHeaderTitle.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION D\'ENGAGEMENT'**
  String get filtrageHeaderTitle;

  /// No description provided for @questionCounter.
  ///
  /// In fr, this message translates to:
  /// **'Question {current}/{total}'**
  String questionCounter(int current, int total);

  /// No description provided for @filtrageDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Ce questionnaire porte uniquement sur la culture, l\'histoire et les valeurs — jamais sur ton apparence ou ton origine. Un score minimum est requis pour activer ton compte ; en cas d\'échec, tu peux demander une révision par un modérateur.'**
  String get filtrageDisclaimer;

  /// No description provided for @reviewInProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Révision en cours'**
  String get reviewInProgressTitle;

  /// No description provided for @nextAttemptSoonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel essai bientôt disponible'**
  String get nextAttemptSoonTitle;

  /// No description provided for @reviewInProgressBody.
  ///
  /// In fr, this message translates to:
  /// **'Un modérateur va revoir ta situation. Tu reçois une notification dès que c\'est traité.'**
  String get reviewInProgressBody;

  /// No description provided for @canRetryNow.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux retenter le questionnaire dès maintenant.'**
  String get canRetryNow;

  /// No description provided for @canRetryFrom.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux retenter le questionnaire à partir du {date}.'**
  String canRetryFrom(String date);

  /// No description provided for @retryFiltrageButton.
  ///
  /// In fr, this message translates to:
  /// **'Retenter le questionnaire'**
  String get retryFiltrageButton;

  /// No description provided for @filtragePassedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans la communauté'**
  String get filtragePassedTitle;

  /// No description provided for @filtrageFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas passé cette fois'**
  String get filtrageFailedTitle;

  /// No description provided for @filtragePassedBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton engagement envers la culture et les valeurs kamites est confirmé. Ton compte est activé.'**
  String get filtragePassedBody;

  /// No description provided for @filtrageFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Score obtenu : {score} %. Tu peux retenter dans quelques jours, ou demander une révision par un modérateur si tu penses qu\'il y a une erreur.'**
  String filtrageFailedBody(int score);

  /// No description provided for @requestHumanReview.
  ///
  /// In fr, this message translates to:
  /// **'Demander une révision humaine'**
  String get requestHumanReview;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @bannedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu définitivement'**
  String get bannedTitle;

  /// No description provided for @suspendedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu temporairement'**
  String get suspendedTitle;

  /// No description provided for @suspendedUntilDate.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte redevient actif à partir du {date}.'**
  String suspendedUntilDate(String date);

  /// No description provided for @sanctionFollowsReports.
  ///
  /// In fr, this message translates to:
  /// **'Cette décision fait suite à un ou plusieurs signalements confirmés.'**
  String get sanctionFollowsReports;

  /// No description provided for @sanctionAppealHint.
  ///
  /// In fr, this message translates to:
  /// **'Si tu penses que c\'est une erreur, tu peux demander qu\'un modérateur réexamine cette décision.'**
  String get sanctionAppealHint;

  /// No description provided for @appealSent.
  ///
  /// In fr, this message translates to:
  /// **'Recours envoyé, un modérateur va l\'examiner.'**
  String get appealSent;

  /// No description provided for @appealSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer le recours, réessaie.'**
  String get appealSendFailed;

  /// No description provided for @appealPending.
  ///
  /// In fr, this message translates to:
  /// **'Recours en cours de traitement'**
  String get appealPending;

  /// No description provided for @contestSanction.
  ///
  /// In fr, this message translates to:
  /// **'Contester cette sanction'**
  String get contestSanction;

  /// No description provided for @safetyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get safetyTitle;

  /// No description provided for @emergencyNumbersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Numéros d\'urgence'**
  String get emergencyNumbersTitle;

  /// No description provided for @emergencyNumbersFrance.
  ///
  /// In fr, this message translates to:
  /// **'17 (Police/Gendarmerie) · 112 (urgences Europe)'**
  String get emergencyNumbersFrance;

  /// No description provided for @emergencyNumbersBelgium.
  ///
  /// In fr, this message translates to:
  /// **'101 (Police) · 112 (urgences Europe)'**
  String get emergencyNumbersBelgium;

  /// No description provided for @emergencyNumbersFallback.
  ///
  /// In fr, this message translates to:
  /// **'112 (fonctionne dans la plupart des pays via un réseau mobile) — vérifie aussi le numéro d\'urgence local de ton pays de résidence'**
  String get emergencyNumbersFallback;

  /// No description provided for @emergencySheetDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Si quelqu\'un te met en danger immédiat, préviens la modération en priorité absolue. Ce bouton n\'appelle jamais les secours à ta place — compose un numéro ci-dessus si tu es en danger maintenant.'**
  String get emergencySheetDisclaimer;

  /// No description provided for @emergencySendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi, réessaie — ou appelle directement un numéro ci-dessous.'**
  String get emergencySendFailed;

  /// No description provided for @moderationNotified.
  ///
  /// In fr, this message translates to:
  /// **'Modération prévenue'**
  String get moderationNotified;

  /// No description provided for @reportImmediateDanger.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un danger immédiat'**
  String get reportImmediateDanger;

  /// No description provided for @relationshipIntentSerieuse.
  ///
  /// In fr, this message translates to:
  /// **'Relation sérieuse'**
  String get relationshipIntentSerieuse;

  /// No description provided for @relationshipIntentFamille.
  ///
  /// In fr, this message translates to:
  /// **'Relation durable en vue d\'une famille'**
  String get relationshipIntentFamille;

  /// No description provided for @relationshipIntentDecouverte.
  ///
  /// In fr, this message translates to:
  /// **'Découverte amoureuse'**
  String get relationshipIntentDecouverte;

  /// No description provided for @relationshipIntentMariage.
  ///
  /// In fr, this message translates to:
  /// **'Mariage'**
  String get relationshipIntentMariage;

  /// No description provided for @lifestyleHabitNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get lifestyleHabitNever;

  /// No description provided for @lifestyleHabitSometimes.
  ///
  /// In fr, this message translates to:
  /// **'Parfois'**
  String get lifestyleHabitSometimes;

  /// No description provided for @lifestyleHabitOften.
  ///
  /// In fr, this message translates to:
  /// **'Souvent'**
  String get lifestyleHabitOften;

  /// No description provided for @childrenStatusHas.
  ///
  /// In fr, this message translates to:
  /// **'A déjà des enfants'**
  String get childrenStatusHas;

  /// No description provided for @childrenStatusWants.
  ///
  /// In fr, this message translates to:
  /// **'Veut des enfants'**
  String get childrenStatusWants;

  /// No description provided for @childrenStatusDoesNotWant.
  ///
  /// In fr, this message translates to:
  /// **'Ne veut pas d\'enfants'**
  String get childrenStatusDoesNotWant;

  /// No description provided for @childrenStatusNotSure.
  ///
  /// In fr, this message translates to:
  /// **'Ne sait pas encore'**
  String get childrenStatusNotSure;

  /// No description provided for @qualityFunny.
  ///
  /// In fr, this message translates to:
  /// **'Drôle'**
  String get qualityFunny;

  /// No description provided for @qualityAmbitious.
  ///
  /// In fr, this message translates to:
  /// **'Ambitieux(se)'**
  String get qualityAmbitious;

  /// No description provided for @qualityCalm.
  ///
  /// In fr, this message translates to:
  /// **'Calme'**
  String get qualityCalm;

  /// No description provided for @qualityAdventurous.
  ///
  /// In fr, this message translates to:
  /// **'Aventurier(ère)'**
  String get qualityAdventurous;

  /// No description provided for @qualityRomantic.
  ///
  /// In fr, this message translates to:
  /// **'Romantique'**
  String get qualityRomantic;

  /// No description provided for @qualityGenerous.
  ///
  /// In fr, this message translates to:
  /// **'Généreux(se)'**
  String get qualityGenerous;

  /// No description provided for @qualitySincere.
  ///
  /// In fr, this message translates to:
  /// **'Sincère'**
  String get qualitySincere;

  /// No description provided for @qualitySpiritual.
  ///
  /// In fr, this message translates to:
  /// **'Spirituel(le)'**
  String get qualitySpiritual;

  /// No description provided for @qualityCaring.
  ///
  /// In fr, this message translates to:
  /// **'Attentionné(e)'**
  String get qualityCaring;

  /// No description provided for @qualityDetermined.
  ///
  /// In fr, this message translates to:
  /// **'Déterminé(e)'**
  String get qualityDetermined;

  /// No description provided for @qualityCreative.
  ///
  /// In fr, this message translates to:
  /// **'Créatif(ve)'**
  String get qualityCreative;

  /// No description provided for @qualityLoyal.
  ///
  /// In fr, this message translates to:
  /// **'Loyal(e)'**
  String get qualityLoyal;

  /// No description provided for @qualityPatient.
  ///
  /// In fr, this message translates to:
  /// **'Patient(e)'**
  String get qualityPatient;

  /// No description provided for @qualityOptimistic.
  ///
  /// In fr, this message translates to:
  /// **'Optimiste'**
  String get qualityOptimistic;

  /// No description provided for @genderWoman.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get genderWoman;

  /// No description provided for @genderMan.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get genderMan;

  /// No description provided for @genderOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get genderOther;

  /// No description provided for @birthDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indique ta date de naissance.'**
  String get birthDateRequired;

  /// No description provided for @mustBeAdult.
  ///
  /// In fr, this message translates to:
  /// **'MERUT est réservé aux personnes de 18 ans et plus.'**
  String get mustBeAdult;

  /// No description provided for @pickSeekingPreference.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins une préférence de recherche.'**
  String get pickSeekingPreference;

  /// No description provided for @yourProfile.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil'**
  String get yourProfile;

  /// No description provided for @firstNameOrNickname.
  ///
  /// In fr, this message translates to:
  /// **'Prénom ou pseudonyme'**
  String get firstNameOrNickname;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get requiredField;

  /// No description provided for @birthDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDateLabel;

  /// No description provided for @chooseDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get chooseDate;

  /// No description provided for @genderLabel.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get genderLabel;

  /// No description provided for @iAmSeeking.
  ///
  /// In fr, this message translates to:
  /// **'Je recherche'**
  String get iAmSeeking;

  /// No description provided for @countryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get cityLabel;

  /// No description provided for @bioLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description personnelle'**
  String get bioLabel;

  /// No description provided for @professionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Profession (facultatif)'**
  String get professionLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langues parlées (séparées par des virgules)'**
  String get languagesLabel;

  /// No description provided for @interestsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Centres d\'intérêt (séparés par des virgules)'**
  String get interestsLabel;

  /// No description provided for @culturalOriginsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Origines culturelles déclarées (facultatif)'**
  String get culturalOriginsLabel;

  /// No description provided for @valuesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Présentation de tes valeurs (facultatif)'**
  String get valuesLabel;

  /// No description provided for @relationshipIntentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Intention relationnelle'**
  String get relationshipIntentLabel;

  /// No description provided for @yourFicheSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'TA FICHE'**
  String get yourFicheSectionTitle;

  /// No description provided for @heightLabel.
  ///
  /// In fr, this message translates to:
  /// **'Taille en cm (facultatif)'**
  String get heightLabel;

  /// No description provided for @educationLevelLabel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études (facultatif)'**
  String get educationLevelLabel;

  /// No description provided for @smokingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tabac (facultatif)'**
  String get smokingLabel;

  /// No description provided for @drinkingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Alcool (facultatif)'**
  String get drinkingLabel;

  /// No description provided for @childrenLabel.
  ///
  /// In fr, this message translates to:
  /// **'Enfants (facultatif)'**
  String get childrenLabel;

  /// No description provided for @lookingForLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu recherches chez l\'autre (facultatif)'**
  String get lookingForLabel;

  /// No description provided for @qualitiesSectionHint.
  ///
  /// In fr, this message translates to:
  /// **'Tes qualités (facultatif, choisis-en quelques-unes)'**
  String get qualitiesSectionHint;

  /// No description provided for @profileSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer ton profil, vérifie ta connexion et réessaie.'**
  String get profileSaveFailed;

  /// No description provided for @saveMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer mon profil'**
  String get saveMyProfile;

  /// No description provided for @photosSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'PHOTOS'**
  String get photosSectionTitle;

  /// No description provided for @photosLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les photos.'**
  String get photosLoadFailed;

  /// No description provided for @photoRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get photoRejected;

  /// No description provided for @photoPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get photoPending;

  /// No description provided for @deletePhotoConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get deletePhotoConfirmTitle;

  /// No description provided for @photoDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer, réessaie.'**
  String get photoDeleteFailed;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takeAPhoto;

  /// No description provided for @photoUploadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer la photo, réessaie.'**
  String get photoUploadFailed;

  /// No description provided for @identityVerificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité'**
  String get identityVerificationTitle;

  /// No description provided for @identityIntro.
  ///
  /// In fr, this message translates to:
  /// **'Prends un selfie clair, visage visible, pour obtenir le badge vérifié et pouvoir organiser des événements physiques.'**
  String get identityIntro;

  /// No description provided for @identityPrivacyHint.
  ///
  /// In fr, this message translates to:
  /// **'Jamais vu par un autre membre — uniquement par un modérateur, et jamais obligatoire pour le reste de l\'app.'**
  String get identityPrivacyHint;

  /// No description provided for @takeASelfie.
  ///
  /// In fr, this message translates to:
  /// **'Prendre un selfie'**
  String get takeASelfie;

  /// No description provided for @identitySubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé, un modérateur va vérifier.'**
  String get identitySubmitted;

  /// No description provided for @identitySubmitFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer, réessaie.'**
  String get identitySubmitFailed;

  /// No description provided for @compatTestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Test de compatibilité'**
  String get compatTestTitle;

  /// No description provided for @compatQuestionsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les questions.'**
  String get compatQuestionsLoadFailed;

  /// No description provided for @compatTestNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Le test de compatibilité n\'est pas encore disponible.'**
  String get compatTestNotAvailable;

  /// No description provided for @compatTestInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Note chaque affirmation de 1 (pas du tout d\'accord) à 5 (tout à fait d\'accord). Tes réponses détaillées ne sont jamais visibles par les autres membres — seul un score de compatibilité est partagé.'**
  String get compatTestInstructions;

  /// No description provided for @saveMyAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer mes réponses'**
  String get saveMyAnswers;

  /// No description provided for @answersSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réponses enregistrées.'**
  String get answersSaved;

  /// No description provided for @answersSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer, vérifie ta connexion et réessaie.'**
  String get answersSaveFailed;

  /// No description provided for @compatThemeVisionCouple.
  ///
  /// In fr, this message translates to:
  /// **'Vision du couple'**
  String get compatThemeVisionCouple;

  /// No description provided for @compatThemeValeursCulture.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs et culture'**
  String get compatThemeValeursCulture;

  /// No description provided for @compatThemeFamille.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get compatThemeFamille;

  /// No description provided for @compatThemeModeVie.
  ///
  /// In fr, this message translates to:
  /// **'Mode de vie'**
  String get compatThemeModeVie;

  /// No description provided for @compatThemeCommunication.
  ///
  /// In fr, this message translates to:
  /// **'Communication'**
  String get compatThemeCommunication;

  /// No description provided for @refreshButton.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refreshButton;

  /// No description provided for @applyButton.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get applyButton;

  /// No description provided for @itsAMatch.
  ///
  /// In fr, this message translates to:
  /// **'C\'est un match !'**
  String get itsAMatch;

  /// No description provided for @mutualLikeWith.
  ///
  /// In fr, this message translates to:
  /// **'Toi et {name} vous êtes mutuellement likés.'**
  String mutualLikeWith(String name);

  /// No description provided for @great.
  ///
  /// In fr, this message translates to:
  /// **'Super'**
  String get great;

  /// No description provided for @profilesLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les profils.'**
  String get profilesLoadFailed;

  /// No description provided for @noMoreProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Plus de profils pour l\'instant, repasse plus tard.'**
  String get noMoreProfiles;

  /// No description provided for @compatScoreBadge.
  ///
  /// In fr, this message translates to:
  /// **'{score} % compatible'**
  String compatScoreBadge(int score);

  /// No description provided for @cityCountryWithDistance.
  ///
  /// In fr, this message translates to:
  /// **'{city}, {country} · à {distance} km'**
  String cityCountryWithDistance(String city, String country, int distance);

  /// No description provided for @cityCountry.
  ///
  /// In fr, this message translates to:
  /// **'{city}, {country}'**
  String cityCountry(String city, String country);

  /// No description provided for @filtersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filtersTitle;

  /// No description provided for @ageRangeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Âge : {min} - {max} ans'**
  String ageRangeLabel(int min, int max);

  /// No description provided for @maxDistanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Distance max : {distance} km'**
  String maxDistanceLabel(int distance);

  /// No description provided for @locationUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Position mise à jour.'**
  String get locationUpdated;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible (permission refusée ?).'**
  String get locationUnavailable;

  /// No description provided for @locatingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Localisation...'**
  String get locatingEllipsis;

  /// No description provided for @updateMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour ma position'**
  String get updateMyLocation;

  /// No description provided for @locationFilterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chercher dans un autre pays'**
  String get locationFilterTitle;

  /// No description provided for @locationFilterHint.
  ///
  /// In fr, this message translates to:
  /// **'Renseigne un pays (et, si tu veux, une ville) pour voir des profils hors de ton rayon GPS — remplace le filtre de distance tant que c\'est rempli.'**
  String get locationFilterHint;

  /// No description provided for @dailyLikeLimitReached.
  ///
  /// In fr, this message translates to:
  /// **'Limite de likes quotidienne atteinte, reviens demain ou passe en Premium.'**
  String get dailyLikeLimitReached;

  /// No description provided for @profileAlreadySwiped.
  ///
  /// In fr, this message translates to:
  /// **'Ce profil a déjà été swipé.'**
  String get profileAlreadySwiped;

  /// No description provided for @likesLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les likes.'**
  String get likesLoadFailed;

  /// No description provided for @likedYouTab.
  ///
  /// In fr, this message translates to:
  /// **'T\'ont liké · {count}'**
  String likedYouTab(int count);

  /// No description provided for @myLikesTab.
  ///
  /// In fr, this message translates to:
  /// **'Mes likes'**
  String get myLikesTab;

  /// No description provided for @noOneLikedYouYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun like pour le moment'**
  String get noOneLikedYouYet;

  /// No description provided for @noOneLikedYouYetHint.
  ///
  /// In fr, this message translates to:
  /// **'Les membres qui aiment ton profil apparaîtront ici.'**
  String get noOneLikedYouYetHint;

  /// No description provided for @seeWhoLikedYou.
  ///
  /// In fr, this message translates to:
  /// **'Voir qui t\'a liké'**
  String get seeWhoLikedYou;

  /// No description provided for @unlockProfilesWithPremium.
  ///
  /// In fr, this message translates to:
  /// **'Débloque les {count} profils avec Premium'**
  String unlockProfilesWithPremium(int count);

  /// No description provided for @premiumTeaserPrice.
  ///
  /// In fr, this message translates to:
  /// **'9,99 €'**
  String get premiumTeaserPrice;

  /// No description provided for @noPendingLikesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun like envoyé'**
  String get noPendingLikesYet;

  /// No description provided for @noPendingLikesYetHint.
  ///
  /// In fr, this message translates to:
  /// **'Les profils que tu likes, en attente de réponse, apparaîtront ici.'**
  String get noPendingLikesYetHint;

  /// No description provided for @retractLikeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce like ?'**
  String get retractLikeConfirmTitle;

  /// No description provided for @retractLikeConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne liked plus {name}.'**
  String retractLikeConfirmBody(String name);

  /// No description provided for @retractLikeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer ce like, réessaie.'**
  String get retractLikeFailed;

  /// No description provided for @retractButton.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get retractButton;

  /// No description provided for @conversationsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les conversations.'**
  String get conversationsLoadFailed;

  /// No description provided for @noMatchesYet.
  ///
  /// In fr, this message translates to:
  /// **'Tes prochains matchs commencent ici'**
  String get noMatchesYet;

  /// No description provided for @noMatchesYetHint.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil et explore Découvrir pour obtenir tes premiers matchs.'**
  String get noMatchesYetHint;

  /// No description provided for @sayHelloPreview.
  ///
  /// In fr, this message translates to:
  /// **'Dites bonjour 👋'**
  String get sayHelloPreview;

  /// No description provided for @beforeSendingPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'envoyer une photo'**
  String get beforeSendingPhotoTitle;

  /// No description provided for @beforeSendingPhotoBody.
  ///
  /// In fr, this message translates to:
  /// **'Respecte la charte communautaire : pas de contenu inapproprié. La personne en face peut te signaler.'**
  String get beforeSendingPhotoBody;

  /// No description provided for @blockButton.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get blockButton;

  /// No description provided for @reportButton.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reportButton;

  /// No description provided for @conversationNoLongerAccessible.
  ///
  /// In fr, this message translates to:
  /// **'Cette conversation n\'est plus accessible.'**
  String get conversationNoLongerAccessible;

  /// No description provided for @blockedProfilesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes blocages'**
  String get blockedProfilesTitle;

  /// No description provided for @noBlockedProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as bloqué personne pour le moment.'**
  String get noBlockedProfiles;

  /// No description provided for @unblockButton.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get unblockButton;

  /// No description provided for @unblockConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer ce profil ?'**
  String get unblockConfirmTitle;

  /// No description provided for @unblockConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} pourra à nouveau apparaître dans Découvrir et te contacter.'**
  String unblockConfirmBody(String name);

  /// No description provided for @blockProfileAction.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer ce profil'**
  String get blockProfileAction;

  /// No description provided for @blockProfileConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer ce profil ?'**
  String get blockProfileConfirmTitle;

  /// No description provided for @blockProfileConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne pourra plus voir ton profil ni te contacter, et toi non plus.'**
  String blockProfileConfirmBody(String name);

  /// No description provided for @blockProfileSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil bloqué.'**
  String get blockProfileSuccess;

  /// No description provided for @blockProfileFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de bloquer ce profil, réessaie.'**
  String get blockProfileFailed;

  /// No description provided for @messagesLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les messages.'**
  String get messagesLoadFailed;

  /// No description provided for @readReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get readReceipt;

  /// No description provided for @sentReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get sentReceipt;

  /// No description provided for @messageHint.
  ///
  /// In fr, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @blockMemberConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer ce membre ?'**
  String get blockMemberConfirmTitle;

  /// No description provided for @blockMemberConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'La conversation deviendra inaccessible pour vous deux, immédiatement.'**
  String get blockMemberConfirmBody;

  /// No description provided for @reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé.'**
  String get reportSent;

  /// No description provided for @showPhotoButton.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la photo'**
  String get showPhotoButton;

  /// No description provided for @reportReasonFakeProfile.
  ///
  /// In fr, this message translates to:
  /// **'Faux profil'**
  String get reportReasonFakeProfile;

  /// No description provided for @reportReasonAbusiveBehavior.
  ///
  /// In fr, this message translates to:
  /// **'Comportement abusif'**
  String get reportReasonAbusiveBehavior;

  /// No description provided for @reportReasonInappropriateContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié'**
  String get reportReasonInappropriateContent;

  /// No description provided for @reportReasonScam.
  ///
  /// In fr, this message translates to:
  /// **'Arnaque'**
  String get reportReasonScam;

  /// No description provided for @reportReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reportReasonOther;

  /// No description provided for @feedLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le fil.'**
  String get feedLoadFailed;

  /// No description provided for @nothingToShowYet.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher pour le moment.'**
  String get nothingToShowYet;

  /// No description provided for @postTypePublication.
  ///
  /// In fr, this message translates to:
  /// **'Publication (fil)'**
  String get postTypePublication;

  /// No description provided for @postTypePublicAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Annonce publique'**
  String get postTypePublicAnnouncement;

  /// No description provided for @postTypePrivateAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Annonce privée'**
  String get postTypePrivateAnnouncement;

  /// No description provided for @postTypeFreeAnnouncement.
  ///
  /// In fr, this message translates to:
  /// **'Annonce libre'**
  String get postTypeFreeAnnouncement;

  /// No description provided for @postTypePublicEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement public'**
  String get postTypePublicEvent;

  /// No description provided for @postTypePrivateEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement privé'**
  String get postTypePrivateEvent;

  /// No description provided for @postTypeGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get postTypeGeneric;

  /// No description provided for @eventDateAndCapacityRequired.
  ///
  /// In fr, this message translates to:
  /// **'Date et capacité requises pour un événement.'**
  String get eventDateAndCapacityRequired;

  /// No description provided for @preciseLocationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Lieu précis requis.'**
  String get preciseLocationRequired;

  /// No description provided for @postPendingReview.
  ///
  /// In fr, this message translates to:
  /// **'Envoyé — en attente de validation par un modérateur.'**
  String get postPendingReview;

  /// No description provided for @postPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié !'**
  String get postPublished;

  /// No description provided for @postFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de publier : {reason}'**
  String postFailed(String reason);

  /// No description provided for @postErrorTooManyActive.
  ///
  /// In fr, this message translates to:
  /// **'tu as déjà 3 annonces actives.'**
  String get postErrorTooManyActive;

  /// No description provided for @postErrorVerifiedOnly.
  ///
  /// In fr, this message translates to:
  /// **'réservé aux membres vérifiés.'**
  String get postErrorVerifiedOnly;

  /// No description provided for @postErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'réessaie.'**
  String get postErrorGeneric;

  /// No description provided for @newPostTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle publication'**
  String get newPostTitle;

  /// No description provided for @typeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @eventTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'événement'**
  String get eventTitleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @dateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @capacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité (nombre de places)'**
  String get capacityLabel;

  /// No description provided for @preciseLocationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lieu précis (masqué jusqu\'à acceptation)'**
  String get preciseLocationLabel;

  /// No description provided for @eventVerifiedOnlyHint.
  ///
  /// In fr, this message translates to:
  /// **'Les événements physiques sont réservés aux membres vérifiés et passent toujours par une revue humaine avant publication.'**
  String get eventVerifiedOnlyHint;

  /// No description provided for @publishButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publishButton;

  /// No description provided for @reportWithReason.
  ///
  /// In fr, this message translates to:
  /// **'Signaler : {reason}'**
  String reportWithReason(String reason);

  /// No description provided for @eventDateAndParticipants.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {count}/{capacity} participants'**
  String eventDateAndParticipants(String date, int count, String capacity);

  /// No description provided for @requestToParticipate.
  ///
  /// In fr, this message translates to:
  /// **'Demander à participer'**
  String get requestToParticipate;

  /// No description provided for @requestAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Demande acceptée !'**
  String get requestAccepted;

  /// No description provided for @seePreciseLocation.
  ///
  /// In fr, this message translates to:
  /// **'Voir le lieu précis'**
  String get seePreciseLocation;

  /// No description provided for @checkinCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de présence : {code}'**
  String checkinCodeLabel(String code);

  /// No description provided for @statusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut : {status}'**
  String statusLabel(String status);

  /// No description provided for @requestsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les demandes.'**
  String get requestsLoadFailed;

  /// No description provided for @noPendingRequests.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente.'**
  String get noPendingRequests;

  /// No description provided for @pendingRequestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes en attente'**
  String get pendingRequestsTitle;

  /// No description provided for @acceptButton.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get acceptButton;

  /// No description provided for @declineButton.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get declineButton;

  /// No description provided for @validateEntryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Valider l\'entrée'**
  String get validateEntryTitle;

  /// No description provided for @enterCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Entrer le code'**
  String get enterCodeButton;

  /// No description provided for @checkinCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de présence'**
  String get checkinCodeTitle;

  /// No description provided for @checkinCodeFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code donné par le participant'**
  String get checkinCodeFieldLabel;

  /// No description provided for @checkinValidated.
  ///
  /// In fr, this message translates to:
  /// **'Entrée validée.'**
  String get checkinValidated;

  /// No description provided for @checkinInvalidCode.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide.'**
  String get checkinInvalidCode;

  /// No description provided for @validateButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validateButton;

  /// No description provided for @boostActivated.
  ///
  /// In fr, this message translates to:
  /// **'Boost activé pour 30 minutes !'**
  String get boostActivated;

  /// No description provided for @boostPremiumOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le Boost est réservé aux membres Premium.'**
  String get boostPremiumOnly;

  /// No description provided for @boostAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Ton Boost gratuit de la semaine a déjà été utilisé.'**
  String get boostAlreadyUsed;

  /// No description provided for @boostActivateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'activer le Boost, réessaie.'**
  String get boostActivateFailed;

  /// No description provided for @boostTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boost'**
  String get boostTitle;

  /// No description provided for @boostDescription.
  ///
  /// In fr, this message translates to:
  /// **'30 minutes de visibilité prioritaire, inclus 1x/semaine en Premium'**
  String get boostDescription;

  /// No description provided for @activateButton.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activateButton;

  /// No description provided for @shopUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Boutique indisponible pour le moment.'**
  String get shopUnavailable;

  /// No description provided for @noSubscriptionOffersYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre d\'abonnement disponible pour l\'instant.'**
  String get noSubscriptionOffersYet;

  /// No description provided for @exportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'exporter, réessaie.'**
  String get exportFailed;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ton compte ?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil, tes photos, tes messages, tes matchs, tes annonces et tes réponses sont supprimés sans retour possible.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deletePermanentlyButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deletePermanentlyButton;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le compte, réessaie.'**
  String get deleteAccountFailed;

  /// No description provided for @chooseLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get chooseLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'appareil'**
  String get systemLanguage;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @warningBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte a reçu un avertissement suite à un signalement confirmé.'**
  String get warningBannerTitle;

  /// No description provided for @editMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get editMyProfile;

  /// No description provided for @identityVerifiedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée'**
  String get identityVerifiedTitle;

  /// No description provided for @profileCompletionPercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String profileCompletionPercent(int percent);

  /// No description provided for @profileCompletionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une profession, tes centres d\'intérêt, tes habitudes de vie ou une 3e photo pour un profil plus complet.'**
  String get profileCompletionHint;

  /// No description provided for @jetonsCounterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jetons'**
  String get jetonsCounterLabel;

  /// No description provided for @boostCounterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Boost'**
  String get boostCounterLabel;

  /// No description provided for @boostCounterIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Inclus'**
  String get boostCounterIncluded;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @exportMyData.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get exportMyData;

  /// No description provided for @gdprPortabilityRight.
  ///
  /// In fr, this message translates to:
  /// **'Droit RGPD à la portabilité'**
  String get gdprPortabilityRight;

  /// No description provided for @deleteMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteMyAccount;

  /// No description provided for @privacySectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'CONFIDENTIALITÉ'**
  String get privacySectionTitle;

  /// No description provided for @showReadReceiptsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur de lecture'**
  String get showReadReceiptsTitle;

  /// No description provided for @showReadReceiptsHint.
  ///
  /// In fr, this message translates to:
  /// **'Montrer aux autres quand tu as lu leurs messages (réciproque : désactivé aussi de leur côté)'**
  String get showReadReceiptsHint;

  /// No description provided for @compatVisibilityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité du score de compatibilité'**
  String get compatVisibilityTitle;

  /// No description provided for @compatVisibilityHint.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les autres membres à voir un score de compatibilité avec toi sur Découvrir'**
  String get compatVisibilityHint;

  /// No description provided for @wizardIdentityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment tu t\'appelles, et tu es né(e) quand ?'**
  String get wizardIdentityTitle;

  /// No description provided for @wizardGenderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu es...'**
  String get wizardGenderTitle;

  /// No description provided for @wizardSeekingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui souhaites-tu rencontrer ?'**
  String get wizardSeekingTitle;

  /// No description provided for @wizardIntentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce que tu recherches ?'**
  String get wizardIntentTitle;

  /// No description provided for @wizardLocationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où habites-tu ?'**
  String get wizardLocationTitle;

  /// No description provided for @wizardBioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parle-nous un peu de toi'**
  String get wizardBioTitle;

  /// No description provided for @wizardBioSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques lignes suffisent pour donner envie d\'en savoir plus.'**
  String get wizardBioSubtitle;

  /// No description provided for @wizardQualitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelles sont tes qualités ?'**
  String get wizardQualitiesTitle;

  /// No description provided for @wizardInterestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes centres d\'intérêt'**
  String get wizardInterestsTitle;

  /// No description provided for @wizardDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encore quelques détails'**
  String get wizardDetailsTitle;

  /// No description provided for @wizardLifestyleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton mode de vie'**
  String get wizardLifestyleTitle;

  /// No description provided for @wizardPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes photos'**
  String get wizardPhotosTitle;

  /// No description provided for @confirmAdultDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation d\'âge'**
  String get confirmAdultDialogTitle;

  /// No description provided for @confirmAdultDialogBody.
  ///
  /// In fr, this message translates to:
  /// **'MERUT est réservé aux personnes de 18 ans et plus. Confirmes-tu avoir 18 ans ou plus ?'**
  String get confirmAdultDialogBody;

  /// No description provided for @confirmAdultDialogDecline.
  ///
  /// In fr, this message translates to:
  /// **'Non, annuler'**
  String get confirmAdultDialogDecline;

  /// No description provided for @confirmAdultDialogAccept.
  ///
  /// In fr, this message translates to:
  /// **'Oui, je confirme'**
  String get confirmAdultDialogAccept;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
