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
  String get onboardingTagline => 'Love has its roots.';

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
  String get navProfile => 'Profile';

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
  String get authErrorNoAccountForSocialSignIn =>
      'No MERUT account is linked to this Google account. Sign up first.';

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
  String filtrageStartFailedWithCode(String code) {
    return 'Can\'t start the questionnaire right now. ($code)';
  }

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
  String get profileSaved => 'Profile saved.';

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
  String get locationFilterTitle => 'Search in another country';

  @override
  String get locationFilterHint =>
      'Enter a country (and, if you like, a city) to see profiles outside your GPS radius — replaces the distance filter while it\'s filled in.';

  @override
  String get dailyLikeLimitReached =>
      'Daily like limit reached, come back tomorrow or go Premium.';

  @override
  String get profileAlreadySwiped => 'This profile was already swiped.';

  @override
  String get superLikeRequiresJetonOrPremium =>
      'A Super Like costs one token (or go Premium for unlimited Super Likes).';

  @override
  String get swipeLikeStamp => 'LIKE';

  @override
  String get swipePassStamp => 'NOPE';

  @override
  String get likesLoadFailed => 'Couldn\'t load likes.';

  @override
  String likedYouTab(int count) {
    return 'Liked you · $count';
  }

  @override
  String get myLikesTab => 'My likes';

  @override
  String get noOneLikedYouYet => 'No likes yet';

  @override
  String get noOneLikedYouYetHint =>
      'Members who like your profile will show up here.';

  @override
  String get seeWhoLikedYou => 'See who liked you';

  @override
  String unlockProfilesWithPremium(int count) {
    return 'Unlock $count profiles with Premium';
  }

  @override
  String get premiumTeaserPrice => '€9.99';

  @override
  String get noPendingLikesYet => 'No likes sent';

  @override
  String get noPendingLikesYetHint =>
      'Profiles you\'ve liked, awaiting a response, will show up here.';

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
  String get noMatchesYet => 'Your next matches start here';

  @override
  String get noMatchesYetHint =>
      'Complete your profile and explore Discover to get your first matches.';

  @override
  String get skipQuestion => 'Skip';

  @override
  String get dontKnowOption => 'I don\'t know';

  @override
  String get replyHint => 'Write a reply…';

  @override
  String get replySendFailed => 'Couldn\'t send the reply.';

  @override
  String get likeFailed => 'Couldn\'t save your like.';

  @override
  String get repliesTitle => 'Replies';

  @override
  String get publicationByMember => 'Community post';

  @override
  String postRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String get rewindPremiumOnly => 'Going back is reserved for Premium members.';

  @override
  String get undoLastPassButton => 'Back to the last profile';

  @override
  String get photoApproved => 'Approved';

  @override
  String get photoVisibleToOthers => 'Other members can see this photo.';

  @override
  String get photoPendingHint =>
      'Pending review: other members can\'t see it yet.';

  @override
  String get viewMyProfileAsOthers => 'See my profile as others see it';

  @override
  String get profilePreviewBanner =>
      'Preview: this is what other members see. Only your approved photos are visible.';

  @override
  String get deletePhotoButton => 'Delete this photo';

  @override
  String get photoRejectedAutoReason =>
      'Automatically rejected: moderation detected sensitive content (nudity, suggestive outfit or violence).';

  @override
  String get photoRejectedManualReason => 'Rejected by a moderator.';

  @override
  String get photoRejectedHint =>
      'Other members can\'t see it. It will be deleted automatically 30 days after the refusal. Pick a photo of yourself with your face visible and appropriate clothing, then delete this one.';

  @override
  String get eventsFiltersButton => 'Filters';

  @override
  String get eventsFiltersTitle => 'Filter events';

  @override
  String get eventsFilterDate => 'Date';

  @override
  String get eventsDateAny => 'Any date';

  @override
  String get eventsDateToday => 'Today';

  @override
  String get eventsDateWeek => 'Next 7 days';

  @override
  String get eventsDateMonth => 'Next 30 days';

  @override
  String get eventsDateCustom => 'Pick dates';

  @override
  String get eventsFilterCountry => 'Country';

  @override
  String get eventsFilterCity => 'City';

  @override
  String get eventsFilterDistance => 'Maximum distance';

  @override
  String get eventsDistanceNeedsPosition =>
      'Turn on My location in Discover to filter by distance.';

  @override
  String get eventsDistanceApproximate =>
      'Approximate distance, measured to the centre of the event\'s city.';

  @override
  String get eventsFilterCategory => 'Category';

  @override
  String get eventsFilterFormat => 'Format';

  @override
  String get eventsFilterAccess => 'Access';

  @override
  String get eventsFilterAvailable => 'Only with spots left';

  @override
  String get eventsFiltersReset => 'Reset';

  @override
  String get eventsFiltersApply => 'Apply';

  @override
  String get eventsNoResults => 'No event matches these filters.';

  @override
  String eventsDistanceValue(int km) {
    return '$km km';
  }

  @override
  String eventsResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
      zero: 'No events',
    );
    return '$_temp0';
  }

  @override
  String get settingsLocationTitle => 'Use my location';

  @override
  String get settingsLocationHint =>
      'Used to compute distance in Discover. Turning it off deletes your saved location.';

  @override
  String get settingsLocationDenied =>
      'Location permission denied: allow it in your phone settings.';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off — change it in your phone settings';

  @override
  String get identityFieldLocked => 'Set at sign-up · contact support';

  @override
  String get youArePremium => 'You are a Premium member';

  @override
  String get compatTestDoneBadge => 'Done · edit';

  @override
  String get compatTestTodoBadge => 'To do';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get messageTimeYesterday => 'yesterday';

  @override
  String get sayHelloPreview => 'Say hello';

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
  String get blockedProfilesTitle => 'Blocked profiles';

  @override
  String get noBlockedProfiles => 'You haven\'t blocked anyone yet.';

  @override
  String get unblockButton => 'Unblock';

  @override
  String get unblockConfirmTitle => 'Unblock this profile?';

  @override
  String unblockConfirmBody(String name) {
    return '$name will be able to appear in Discover and contact you again.';
  }

  @override
  String get blockProfileAction => 'Block this profile';

  @override
  String get blockProfileConfirmTitle => 'Block this profile?';

  @override
  String blockProfileConfirmBody(String name) {
    return '$name won\'t be able to see your profile or contact you, and neither will you.';
  }

  @override
  String get blockProfileSuccess => 'Profile blocked.';

  @override
  String get blockProfileFailed => 'Couldn\'t block this profile, try again.';

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
  String get eventCategorySoiree => 'Party';

  @override
  String get eventCategoryConference => 'Conference';

  @override
  String get eventCategoryAtelier => 'Workshop';

  @override
  String get eventCategoryExposition => 'Exhibition';

  @override
  String get eventCategoryDebat => 'Debate';

  @override
  String get eventCategoryProjection => 'Screening';

  @override
  String get eventCategoryRencontre => 'Meetup';

  @override
  String get eventAccessPublic => 'Open access';

  @override
  String get eventAccessOnRequest => 'On request';

  @override
  String get eventAccessOnInvitation => 'By invitation';

  @override
  String get eventStateScheduled => 'Scheduled';

  @override
  String get eventStateFull => 'Full';

  @override
  String get eventStateCancelled => 'Cancelled';

  @override
  String get eventStateFinished => 'Finished';

  @override
  String get eventFormatPresentiel => 'In person';

  @override
  String get eventFormatEnLigne => 'Online';

  @override
  String get navEvents => 'Events';

  @override
  String get navNews => 'News';

  @override
  String get navTips => 'Tips';

  @override
  String get tipsComingSoon =>
      'Cultural tips and resources are coming soon to this space.';

  @override
  String get myParticipationsTitle => 'My participations';

  @override
  String get noParticipationsYet =>
      'You haven\'t requested to join any event yet.';

  @override
  String get becomeOrganizerTitle => 'Become an organizer';

  @override
  String get becomeOrganizerIntro =>
      'To publish an event, an administrator must first validate your organizer profile.';

  @override
  String get organizerNameLabel => 'Name (you or your organization)';

  @override
  String get organizerDescriptionLabel => 'Introduce yourself in a few lines';

  @override
  String get organizerRequestSubmitButton => 'Send my request';

  @override
  String get organizerRequestSentTitle => 'Request sent';

  @override
  String get organizerRequestSentBody =>
      'An administrator will review your request. You\'ll be able to publish events as soon as it\'s approved.';

  @override
  String get organizerStatusPending => 'Request under review';

  @override
  String get organizerStatusApproved => 'Approved organizer';

  @override
  String get organizerStatusRejected => 'Request rejected';

  @override
  String get organizerStatusSuspended => 'Organizer status suspended';

  @override
  String get organizerRequestFailed => 'Couldn\'t send the request, try again.';

  @override
  String get organizerDashboardTitle => 'Organizer space';

  @override
  String get myEventsEmpty => 'You haven\'t created any event yet.';

  @override
  String get createEventButton => 'Create an event';

  @override
  String get eventCategoryLabel => 'Category';

  @override
  String get eventFormatLabel => 'Format';

  @override
  String get eventAccessModeLabel => 'Access mode';

  @override
  String get eventCityLabel => 'City (shown publicly)';

  @override
  String get eventAgeMinimumLabel => 'Minimum age (optional)';

  @override
  String get eventConditionsLabel => 'Special conditions (optional)';

  @override
  String get eventContactLabel => 'Authorized contact (optional)';

  @override
  String get eventPosterLabel => 'Event poster';

  @override
  String get addPosterButton => 'Add a poster';

  @override
  String get eventEndDateLabel => 'End (optional)';

  @override
  String get linkedEventsTitle => 'Associated activities';

  @override
  String get addFavoriteButton => 'Save';

  @override
  String get removeFavoriteButton => 'Removed from favorites';

  @override
  String get favoritesTitle => 'My favorites';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get noReviewsYet => 'No reviews yet.';

  @override
  String get leaveReviewButton => 'Leave a review';

  @override
  String get reviewSubmitButton => 'Submit review';

  @override
  String get reviewSentSuccess => 'Review sent, thank you!';

  @override
  String get ticketTitle => 'My ticket';

  @override
  String get cancelEventButton => 'Cancel the event';

  @override
  String get markEventFinishedButton => 'Mark as finished';

  @override
  String get eventCancelledNotice =>
      'This event was cancelled by the organizer.';

  @override
  String get eventFullNotice => 'This event is full.';

  @override
  String get inviteMemberButton => 'Invite a member';

  @override
  String get inviteMemberHint => 'Member ID (uid) to invite';

  @override
  String get inviteSentSuccess => 'Invitation sent.';

  @override
  String get eventsFeaturedTitle => 'Featured';

  @override
  String get eventsUpcomingTitle => 'Upcoming events';

  @override
  String get eventsNearMeTitle => 'Near me';

  @override
  String get eventsPrivateTitle => 'Private events';

  @override
  String get eventsConferencesTitle => 'Conferences and meetups';

  @override
  String get eventsAllTitle => 'All events';

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
  String get postErrorVerifiedOnly =>
      'reserved for organizers approved by an administrator.';

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
      'Events are reserved for organizers approved by an administrator and always go through human review before publishing.';

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
  String get identityVerifiedTitle => 'Identity verified';

  @override
  String profileCompletionPercent(int percent) {
    return '$percent%';
  }

  @override
  String get profileCompletionHint =>
      'Add a profession, your interests, your lifestyle habits or a 3rd photo for a more complete profile.';

  @override
  String get jetonsCounterLabel => 'Tokens';

  @override
  String get boostCounterLabel => 'Boost';

  @override
  String get boostCounterIncluded => 'Included';

  @override
  String get boostYourProfileButton => 'Boost your profile';

  @override
  String get upgradeToPremiumButton => 'Upgrade to Premium';

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

  @override
  String get wizardIdentityTitle =>
      'What\'s your name, and when were you born?';

  @override
  String get wizardGenderTitle => 'You are...';

  @override
  String get wizardSeekingTitle => 'Who would you like to meet?';

  @override
  String get wizardIntentTitle => 'What are you looking for?';

  @override
  String get wizardLocationTitle => 'Where do you live?';

  @override
  String get wizardBioTitle => 'Tell us a bit about yourself';

  @override
  String get wizardBioSubtitle =>
      'A few lines are enough to make people want to know more.';

  @override
  String get wizardQualitiesTitle => 'What are your qualities?';

  @override
  String get wizardInterestsTitle => 'Your interests';

  @override
  String get wizardDetailsTitle => 'A few more details';

  @override
  String get wizardLifestyleTitle => 'Your lifestyle';

  @override
  String get wizardPhotosTitle => 'Add your photos';

  @override
  String get confirmAdultDialogTitle => 'Age confirmation';

  @override
  String get confirmAdultDialogBody =>
      'MERUT is reserved for people 18 and older. Do you confirm you are 18 or older?';

  @override
  String get confirmAdultDialogDecline => 'No, cancel';

  @override
  String get confirmAdultDialogAccept => 'Yes, I confirm';

  @override
  String get discoverSubtitle => 'Kamite souls who share your values.';

  @override
  String get filtersPillLabel => 'Filters';

  @override
  String get onlineBadgeLabel => 'Online';

  @override
  String get aboutMeSectionTitle => 'About me';

  @override
  String factAgeValue(int age) {
    return '$age y/o';
  }

  @override
  String get factAgeLabel => 'Age';

  @override
  String get factHeightLabel => 'Height';

  @override
  String get factEducationLabel => 'Education';

  @override
  String get factProfessionLabel => 'Occupation';

  @override
  String get factLookingForLabel => 'Looking for';

  @override
  String get factChildrenLabel => 'Children';

  @override
  String get factSmokingDrinkingLabel => 'Smoking / Drinking';

  @override
  String ageRangePill(int min, int max) {
    return '$min–$max y/o';
  }

  @override
  String maxDistancePill(int km) {
    return '≤ $km km';
  }

  @override
  String get genderFilterAll => 'Women and men';

  @override
  String get genderFilterMenPlural => 'Men';

  @override
  String get genderFilterWomenPlural => 'Women';

  @override
  String get myLocationPillLabel => 'My location';

  @override
  String get morePillLabel => 'More';

  @override
  String get selectCountryFirstHint => 'Pick a country first.';

  @override
  String get changeCountryOption => 'Change country';

  @override
  String get removeCountryFilterOption => 'Remove country filter';

  @override
  String get agePillPlaceholder => 'Age';

  @override
  String get cancelParticipationButton => 'Cancel my participation';

  @override
  String get cancelParticipationConfirmTitle => 'Cancel your participation?';

  @override
  String get cancelParticipationConfirmBody =>
      'If someone is on the waitlist, they will automatically take your place.';

  @override
  String get participationCancelledSuccess => 'Participation cancelled.';

  @override
  String get pendingRequestNotice =>
      'Your request is awaiting the organizer\'s approval.';

  @override
  String get waitlistedNotice =>
      'You\'re on the waitlist — you\'ll be notified if a spot opens up.';

  @override
  String get shareEventPrivatelyButton => 'Share privately';

  @override
  String shareEventCodeMessage(String code) {
    return 'Join my event on MERUT with this invite code: $code';
  }

  @override
  String get shareCodeFetchFailed => 'Couldn\'t retrieve the code, try again.';

  @override
  String get redeemInviteCodeButton => 'I have an invite code';

  @override
  String get redeemInviteCodeHint => 'Code received from the organizer';

  @override
  String get redeemInviteCodeSuccess =>
      'Invitation accepted! You can now request to participate.';

  @override
  String get redeemInviteCodeFailed => 'Invalid or expired code.';

  @override
  String get recurrenceLabel => 'Repeat this event';

  @override
  String get recurrenceNone => 'Don\'t repeat';

  @override
  String get eventRecurrenceWeekly => 'Every week';

  @override
  String get eventRecurrenceMonthly => 'Every month';

  @override
  String get recurrenceCountLabel =>
      'Number of additional occurrences (1 to 6)';

  @override
  String get recurrenceSeriesTitle => 'Other dates in this series';

  @override
  String get tipCategoryCulture => 'Culture';

  @override
  String get tipCategoryRelation => 'Relationships';

  @override
  String get tipCategorySecurite => 'Safety';

  @override
  String get tipCategoryCommunaute => 'Community';

  @override
  String get noTipsYet => 'No tips published yet.';
}
