// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get genericError => 'Something went wrong, try again.';

  @override
  String genericErrorWithCode(String code) {
    return 'Something went wrong, try again. ($code)';
  }

  @override
  String unexpectedError(String error) {
    return 'Error: $error';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get closeButton => 'Close';

  @override
  String get retryButton => 'Retry';

  @override
  String get deleteButton => 'Delete';

  @override
  String get onboardingTagline => 'kamite dating and community';

  @override
  String get onboardingBeforeStart => 'Before you start';

  @override
  String get onboardingIntro =>
      'This app brings together people who recognize themselves in kamite identity and values, for serious romantic relationships. Membership is based on your knowledge of and commitment to this culture — never on your origin or appearance.';

  @override
  String get onboardingCharterTitle => 'COMMUNITY CHARTER';

  @override
  String get onboardingCharter1 =>
      'I identify with the kamite community and history and commit to respecting it.';

  @override
  String get onboardingCharter2 =>
      'I understand that a knowledge and values questionnaire validates my sign-up.';

  @override
  String get onboardingCharter3 =>
      'I commit to respect, honesty and good conduct toward other members.';

  @override
  String get onboardingAcceptCharter =>
      'I have read and accept the community charter and the terms of use.';

  @override
  String get homeWelcomeHint =>
      'Account activated and profile created.\nNext step: Discover, Likes, Messages, Community.';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navLikes => 'Likes';

  @override
  String get navMessages => 'Messages';

  @override
  String get navCommunity => 'Community';

  @override
  String get navPremium => 'Premium & tokens';

  @override
  String get navCompatTest => 'Take the compatibility test';

  @override
  String get navIdentityVerification => 'Identity verification';

  @override
  String get navAdmin => 'Administration';

  @override
  String get becomeAdminSuccess => 'You are now an administrator.';

  @override
  String get becomeAdminAlreadyExists =>
      'An administrator already exists for this project.';

  @override
  String becomeAdminFailed(String code) {
    return 'Couldn\'t become admin, try again ($code).';
  }

  @override
  String get networkErrorRetry => 'Network error, try again.';

  @override
  String get becomeFirstAdmin => 'Become the first administrator';

  @override
  String get authErrorEmailInUse => 'This email address is already in use.';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorWeakPassword =>
      'Password too weak (8 characters minimum).';

  @override
  String get authErrorWrongCredentials => 'Wrong email or password.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts, try again in a few minutes.';

  @override
  String get authErrorOperationNotAllowed =>
      'This sign-in method isn\'t enabled on the server yet.';

  @override
  String get authErrorNetwork => 'No internet connection, check your network.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get passwordMinLength => '8 characters minimum';

  @override
  String get orSeparator => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to your MERUT account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get noAccountYet => 'No account yet? Create one';

  @override
  String get signUpTitle => 'Create an account';

  @override
  String get signUpSubtitle => 'Join the MERUT community';

  @override
  String get mustConfirmAdult => 'You must confirm you are 18 or older.';

  @override
  String get confirmAdult => 'I confirm I am 18 or older.';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get verificationEmailResent => 'Verification email resent.';

  @override
  String get yourAddressFallback => 'your address';

  @override
  String get checkYourInbox => 'Check your inbox';

  @override
  String verificationEmailSentTo(String email) {
    return 'A confirmation link was sent to $email. Click the link, this page updates automatically.';
  }

  @override
  String get sendingEllipsis => 'Sending...';

  @override
  String get resendEmail => 'I didn\'t get anything, resend the email';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSentHint =>
      'If this address exists, a reset email was just sent. Check your spam folder too.';

  @override
  String get resetPasswordInstructions =>
      'Enter your email address, we\'ll send you a link to choose a new password.';

  @override
  String get sendLink => 'Send link';

  @override
  String get startButton => 'Start';

  @override
  String get finishButton => 'Finish';

  @override
  String get nextQuestion => 'Next question';

  @override
  String get filtrageIntroTitle => 'Commitment check';

  @override
  String get filtrageIntroBody =>
      'Before accessing MERUT, a few questions about kamite culture, history and values. Never about your appearance or origin.';

  @override
  String get filtrageStartFailed => 'Can\'t start the questionnaire right now.';

  @override
  String get filtrageHeaderTitle => 'COMMITMENT CHECK';

  @override
  String questionCounter(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get filtrageDisclaimer =>
      'This questionnaire is only about culture, history and values — never about your appearance or origin. A minimum score is required to activate your account; if you don\'t pass, you can ask a moderator for a review.';

  @override
  String get reviewInProgressTitle => 'Review in progress';

  @override
  String get nextAttemptSoonTitle => 'New attempt available soon';

  @override
  String get reviewInProgressBody =>
      'A moderator will review your situation. You\'ll get a notification once it\'s handled.';

  @override
  String get canRetryNow => 'You can retry the questionnaire right now.';

  @override
  String canRetryFrom(String date) {
    return 'You can retry the questionnaire starting $date.';
  }

  @override
  String get retryFiltrageButton => 'Retry the questionnaire';

  @override
  String get filtragePassedTitle => 'Welcome to the community';

  @override
  String get filtrageFailedTitle => 'Not this time';

  @override
  String get filtragePassedBody =>
      'Your commitment to kamite culture and values is confirmed. Your account is activated.';

  @override
  String filtrageFailedBody(int score) {
    return 'Score: $score%. You can retry in a few days, or ask a moderator for a review if you think there\'s an error.';
  }

  @override
  String get requestHumanReview => 'Request a human review';

  @override
  String get signOut => 'Sign out';

  @override
  String get bannedTitle => 'Account permanently suspended';

  @override
  String get suspendedTitle => 'Account temporarily suspended';

  @override
  String suspendedUntilDate(String date) {
    return 'Your account becomes active again on $date.';
  }

  @override
  String get sanctionFollowsReports =>
      'This decision follows one or more confirmed reports.';

  @override
  String get sanctionAppealHint =>
      'If you think this is a mistake, you can ask a moderator to review this decision.';

  @override
  String get appealSent => 'Appeal sent, a moderator will review it.';

  @override
  String get appealSendFailed => 'Couldn\'t send the appeal, try again.';

  @override
  String get appealPending => 'Appeal under review';

  @override
  String get contestSanction => 'Contest this sanction';

  @override
  String get safetyTitle => 'Safety';

  @override
  String get emergencyNumbersTitle => 'Emergency numbers';

  @override
  String get emergencyNumbersFrance =>
      '17 (Police) · 112 (Europe-wide emergency)';

  @override
  String get emergencyNumbersBelgium =>
      '101 (Police) · 112 (Europe-wide emergency)';

  @override
  String get emergencyNumbersFallback =>
      '112 (works in most countries over a mobile network) — also check the local emergency number for your country of residence';

  @override
  String get emergencySheetDisclaimer =>
      'If someone is putting you in immediate danger, notify moderation as top priority. This button never calls emergency services for you — dial a number above if you are in danger right now.';

  @override
  String get emergencySendFailed =>
      'Couldn\'t send, try again — or call a number below directly.';

  @override
  String get moderationNotified => 'Moderation notified';

  @override
  String get reportImmediateDanger => 'Report immediate danger';

  @override
  String get relationshipIntentSerieuse => 'Serious relationship';

  @override
  String get relationshipIntentFamille =>
      'Long-term relationship aiming for a family';

  @override
  String get relationshipIntentDecouverte => 'Romantic exploration';

  @override
  String get relationshipIntentMariage => 'Marriage';

  @override
  String get lifestyleHabitNever => 'Never';

  @override
  String get lifestyleHabitSometimes => 'Sometimes';

  @override
  String get lifestyleHabitOften => 'Often';

  @override
  String get childrenStatusHas => 'Already has children';

  @override
  String get childrenStatusWants => 'Wants children';

  @override
  String get childrenStatusDoesNotWant => 'Doesn\'t want children';

  @override
  String get childrenStatusNotSure => 'Not sure yet';

  @override
  String get qualityFunny => 'Funny';

  @override
  String get qualityAmbitious => 'Ambitious';

  @override
  String get qualityCalm => 'Calm';

  @override
  String get qualityAdventurous => 'Adventurous';

  @override
  String get qualityRomantic => 'Romantic';

  @override
  String get qualityGenerous => 'Generous';

  @override
  String get qualitySincere => 'Sincere';

  @override
  String get qualitySpiritual => 'Spiritual';

  @override
  String get qualityCaring => 'Caring';

  @override
  String get qualityDetermined => 'Determined';

  @override
  String get qualityCreative => 'Creative';

  @override
  String get qualityLoyal => 'Loyal';

  @override
  String get qualityPatient => 'Patient';

  @override
  String get qualityOptimistic => 'Optimistic';

  @override
  String get genderWoman => 'Woman';

  @override
  String get genderMan => 'Man';

  @override
  String get genderOther => 'Other';

  @override
  String get birthDateRequired => 'Enter your date of birth.';

  @override
  String get mustBeAdult => 'MERUT is reserved for people 18 and older.';

  @override
  String get pickSeekingPreference => 'Choose at least one preference.';

  @override
  String get yourProfile => 'Your profile';

  @override
  String get firstNameOrNickname => 'First name or nickname';

  @override
  String get requiredField => 'Required';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get genderLabel => 'Gender';

  @override
  String get iAmSeeking => 'I\'m looking for';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get bioLabel => 'About you';

  @override
  String get professionLabel => 'Profession (optional)';

  @override
  String get languagesLabel => 'Languages spoken (comma-separated)';

  @override
  String get interestsLabel => 'Interests (comma-separated)';

  @override
  String get culturalOriginsLabel => 'Declared cultural origins (optional)';

  @override
  String get valuesLabel => 'Describe your values (optional)';

  @override
  String get relationshipIntentLabel => 'Relationship intent';

  @override
  String get yourFicheSectionTitle => 'YOUR PROFILE SHEET';

  @override
  String get heightLabel => 'Height in cm (optional)';

  @override
  String get educationLevelLabel => 'Education level (optional)';

  @override
  String get smokingLabel => 'Smoking (optional)';

  @override
  String get drinkingLabel => 'Drinking (optional)';

  @override
  String get childrenLabel => 'Children (optional)';

  @override
  String get lookingForLabel =>
      'What you\'re looking for in a partner (optional)';

  @override
  String get qualitiesSectionHint => 'Your qualities (optional, pick a few)';

  @override
  String get profileSaveFailed =>
      'Couldn\'t save your profile, check your connection and try again.';

  @override
  String get saveMyProfile => 'Save my profile';

  @override
  String get photosSectionTitle => 'PHOTOS';

  @override
  String get photosLoadFailed => 'Couldn\'t load photos.';

  @override
  String get photoRejected => 'Rejected';

  @override
  String get photoPending => 'Pending';

  @override
  String get deletePhotoConfirmTitle => 'Delete this photo?';

  @override
  String get photoDeleteFailed => 'Couldn\'t delete, try again.';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get photoUploadFailed => 'Couldn\'t upload the photo, try again.';

  @override
  String get identityVerificationTitle => 'Identity verification';

  @override
  String get identityIntro =>
      'Take a clear selfie, face visible, to get the verified badge and be able to organize in-person events.';

  @override
  String get identityPrivacyHint =>
      'Never seen by other members — only by a moderator, and never required for the rest of the app.';

  @override
  String get takeASelfie => 'Take a selfie';

  @override
  String get identitySubmitted => 'Sent, a moderator will review it.';

  @override
  String get identitySubmitFailed => 'Couldn\'t send, try again.';

  @override
  String get compatTestTitle => 'Compatibility test';

  @override
  String get compatQuestionsLoadFailed => 'Couldn\'t load the questions.';

  @override
  String get compatTestNotAvailable =>
      'The compatibility test isn\'t available yet.';

  @override
  String get compatTestInstructions =>
      'Rate each statement from 1 (strongly disagree) to 5 (strongly agree). Your detailed answers are never visible to other members — only a compatibility score is shared.';

  @override
  String get saveMyAnswers => 'Save my answers';

  @override
  String get answersSaved => 'Answers saved.';

  @override
  String get answersSaveFailed =>
      'Couldn\'t save, check your connection and try again.';

  @override
  String get compatThemeVisionCouple => 'Vision of a couple';

  @override
  String get compatThemeValeursCulture => 'Values and culture';

  @override
  String get compatThemeFamille => 'Family';

  @override
  String get compatThemeModeVie => 'Lifestyle';

  @override
  String get compatThemeCommunication => 'Communication';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get applyButton => 'Apply';

  @override
  String get itsAMatch => 'It\'s a match!';

  @override
  String mutualLikeWith(String name) {
    return 'You and $name liked each other.';
  }

  @override
  String get great => 'Great';

  @override
  String get profilesLoadFailed => 'Couldn\'t load profiles.';

  @override
  String get noMoreProfiles => 'No more profiles for now, check back later.';

  @override
  String compatScoreBadge(int score) {
    return '$score% compatible';
  }

  @override
  String cityCountryWithDistance(String city, String country, int distance) {
    return '$city, $country · $distance km away';
  }

  @override
  String cityCountry(String city, String country) {
    return '$city, $country';
  }

  @override
  String get filtersTitle => 'Filters';

  @override
  String ageRangeLabel(int min, int max) {
    return 'Age: $min - $max years';
  }

  @override
  String maxDistanceLabel(int distance) {
    return 'Max distance: $distance km';
  }

  @override
  String get locationUpdated => 'Location updated.';

  @override
  String get locationUnavailable =>
      'Location unavailable (permission denied?).';

  @override
  String get locatingEllipsis => 'Locating...';

  @override
  String get updateMyLocation => 'Update my location';

  @override
  String get dailyLikeLimitReached =>
      'Daily like limit reached, come back tomorrow or go Premium.';

  @override
  String get profileAlreadySwiped => 'This profile was already swiped.';

  @override
  String get likesLoadFailed => 'Couldn\'t load likes.';

  @override
  String likedYouTab(int count) {
    return 'Liked you · $count';
  }

  @override
  String get myLikesTab => 'My likes';

  @override
  String get noOneLikedYouYet => 'No one has liked you yet.';

  @override
  String get seeWhoLikedYou => 'See who liked you';

  @override
  String unlockProfilesWithPremium(int count) {
    return 'Unlock $count profiles with Premium';
  }

  @override
  String get premiumTeaserPrice => '€9.99';

  @override
  String get noPendingLikesYet =>
      'You haven\'t liked any profile awaiting a response yet.';

  @override
  String get retractLikeConfirmTitle => 'Retract this like?';

  @override
  String retractLikeConfirmBody(String name) {
    return 'You\'ll no longer like $name.';
  }

  @override
  String get retractLikeFailed => 'Couldn\'t retract this like, try again.';

  @override
  String get retractButton => 'Retract';

  @override
  String get conversationsLoadFailed => 'Couldn\'t load conversations.';

  @override
  String get noMatchesYet => 'No matches yet — go check out Discover.';

  @override
  String get sayHelloPreview => 'Say hello 👋';

  @override
  String get beforeSendingPhotoTitle => 'Before sending a photo';

  @override
  String get beforeSendingPhotoBody =>
      'Respect the community charter: no inappropriate content. The other person can report you.';

  @override
  String get blockButton => 'Block';

  @override
  String get reportButton => 'Report';

  @override
  String get conversationNoLongerAccessible =>
      'This conversation is no longer accessible.';

  @override
  String get messagesLoadFailed => 'Couldn\'t load messages.';

  @override
  String get readReceipt => 'Read';

  @override
  String get sentReceipt => 'Sent';

  @override
  String get messageHint => 'Message...';

  @override
  String get blockMemberConfirmTitle => 'Block this member?';

  @override
  String get blockMemberConfirmBody =>
      'The conversation will become inaccessible for both of you, immediately.';

  @override
  String get reportSent => 'Report sent.';

  @override
  String get showPhotoButton => 'Show photo';

  @override
  String get reportReasonFakeProfile => 'Fake profile';

  @override
  String get reportReasonAbusiveBehavior => 'Abusive behavior';

  @override
  String get reportReasonInappropriateContent => 'Inappropriate content';

  @override
  String get reportReasonScam => 'Scam';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get feedLoadFailed => 'Couldn\'t load the feed.';

  @override
  String get nothingToShowYet => 'Nothing to show for now.';

  @override
  String get postTypePublication => 'Post (feed)';

  @override
  String get postTypePublicAnnouncement => 'Public announcement';

  @override
  String get postTypePrivateAnnouncement => 'Private announcement';

  @override
  String get postTypeFreeAnnouncement => 'Free-form announcement';

  @override
  String get postTypePublicEvent => 'Public event';

  @override
  String get postTypePrivateEvent => 'Private event';

  @override
  String get postTypeGeneric => 'Post';

  @override
  String get eventDateAndCapacityRequired =>
      'Date and capacity are required for an event.';

  @override
  String get preciseLocationRequired => 'Precise location required.';

  @override
  String get postPendingReview => 'Sent — awaiting moderator approval.';

  @override
  String get postPublished => 'Published!';

  @override
  String postFailed(String reason) {
    return 'Couldn\'t publish: $reason';
  }

  @override
  String get postErrorTooManyActive =>
      'you already have 3 active announcements.';

  @override
  String get postErrorVerifiedOnly => 'reserved for verified members.';

  @override
  String get postErrorGeneric => 'try again.';

  @override
  String get newPostTitle => 'New post';

  @override
  String get typeLabel => 'Type';

  @override
  String get eventTitleLabel => 'Event title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get dateLabel => 'Date';

  @override
  String get capacityLabel => 'Capacity (number of seats)';

  @override
  String get preciseLocationLabel => 'Precise location (hidden until accepted)';

  @override
  String get eventVerifiedOnlyHint =>
      'In-person events are reserved for verified members and always go through human review before publishing.';

  @override
  String get publishButton => 'Publish';

  @override
  String reportWithReason(String reason) {
    return 'Report: $reason';
  }

  @override
  String eventDateAndParticipants(String date, int count, String capacity) {
    return '$date · $count/$capacity participants';
  }

  @override
  String get requestToParticipate => 'Request to participate';

  @override
  String get requestAccepted => 'Request accepted!';

  @override
  String get seePreciseLocation => 'See precise location';

  @override
  String checkinCodeLabel(String code) {
    return 'Check-in code: $code';
  }

  @override
  String statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get requestsLoadFailed => 'Couldn\'t load requests.';

  @override
  String get noPendingRequests => 'No pending requests.';

  @override
  String get pendingRequestsTitle => 'Pending requests';

  @override
  String get acceptButton => 'Accept';

  @override
  String get declineButton => 'Decline';

  @override
  String get validateEntryTitle => 'Validate entry';

  @override
  String get enterCodeButton => 'Enter the code';

  @override
  String get checkinCodeTitle => 'Check-in code';

  @override
  String get checkinCodeFieldLabel => 'Code given by the participant';

  @override
  String get checkinValidated => 'Entry validated.';

  @override
  String get checkinInvalidCode => 'Invalid code.';

  @override
  String get validateButton => 'Validate';

  @override
  String get boostActivated => 'Boost activated for 30 minutes!';

  @override
  String get boostPremiumOnly => 'Boost is reserved for Premium members.';

  @override
  String get boostAlreadyUsed =>
      'Your free weekly Boost has already been used.';

  @override
  String get boostActivateFailed => 'Couldn\'t activate Boost, try again.';

  @override
  String get boostTitle => 'Boost';

  @override
  String get boostDescription =>
      '30 minutes of priority visibility, included once a week with Premium';

  @override
  String get activateButton => 'Activate';

  @override
  String get shopUnavailable => 'Shop unavailable right now.';

  @override
  String get noSubscriptionOffersYet => 'No subscription offers available yet.';

  @override
  String get exportFailed => 'Couldn\'t export, try again.';

  @override
  String get deleteAccountConfirmTitle => 'Permanently delete your account?';

  @override
  String get deleteAccountConfirmBody =>
      'Your profile, photos, messages, matches, posts and answers are deleted with no way back.';

  @override
  String get deletePermanentlyButton => 'Delete permanently';

  @override
  String get deleteAccountFailed => 'Couldn\'t delete the account, try again.';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get warningBannerTitle =>
      'Your account received a warning following a confirmed report.';

  @override
  String get editMyProfile => 'Edit my profile';

  @override
  String get language => 'Language';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get gdprPortabilityRight => 'GDPR right to portability';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get privacySectionTitle => 'PRIVACY';

  @override
  String get showReadReceiptsTitle => 'Read receipts';

  @override
  String get showReadReceiptsHint =>
      'Show others when you\'ve read their messages (mutual: also off on their side)';

  @override
  String get compatVisibilityTitle => 'Compatibility score visibility';

  @override
  String get compatVisibilityHint =>
      'Let other members see a compatibility score with you on Discover';
}
