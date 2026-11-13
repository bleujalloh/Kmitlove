/// Textes juridiques affichés dans Paramètres → Informations.
///
/// **Version provisoire** : rédigés à partir de ce que l'application fait
/// réellement (docs/rgpd-registre-des-traitements.md) mais pas encore
/// relus par un juriste ; `kLegalDraft` affiche un bandeau « en cours de
/// validation » sur chaque document tant qu'il vaut `true`. À passer à
/// `false` une fois les textes validés et l'identité de l'éditeur publiée.
const kLegalDraft = true;

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

class LegalDocument {
  const LegalDocument(this.sections);
  final List<LegalSection> sections;
}

enum LegalKind { terms, privacy, notice }

LegalDocument legalDocument(LegalKind kind, String languageCode) {
  final english = languageCode == 'en';
  switch (kind) {
    case LegalKind.terms:
      return english ? _termsEn : _termsFr;
    case LegalKind.privacy:
      return english ? _privacyEn : _privacyFr;
    case LegalKind.notice:
      return english ? _noticeEn : _noticeFr;
  }
}

const _termsFr = LegalDocument([
  LegalSection('1. Objet', "MERUT est une application de rencontres et de communauté pour les personnes qui se reconnaissent dans l'histoire et les valeurs kamites. Ces conditions encadrent son utilisation."),
  LegalSection('2. Accès et compte', "L'application est réservée aux personnes majeures (18 ans ou plus). L'inscription demande de réussir un questionnaire de connaissance et de valeurs, jamais fondé sur l'origine ou l'apparence ; un recours humain est possible en cas d'échec. Le genre et la date de naissance sont fixés à l'inscription. Les informations fournies doivent être exactes."),
  LegalSection('3. Règles de conduite', "Tu t'engages au respect, à l'honnêteté et à la bonne conduite envers les autres membres, conformément à la charte acceptée à l'inscription. Sont interdits : le harcèlement, les propos haineux, l'usurpation d'identité, les arnaques et toute demande d'argent, le contenu sexuel ou violent, et la création de comptes multiples."),
  LegalSection('4. Photos et contenus', "Chaque photo est analysée automatiquement puis peut être revue par un modérateur. Une photo n'est visible des autres membres qu'une fois validée ; une photo refusée n'est jamais visible et est supprimée au plus tard 30 jours après son refus. Tu restes responsable des contenus que tu publies."),
  LegalSection('5. Messagerie, blocage et signalement', "Tu peux bloquer un membre et signaler un profil, un message ou une publication à tout moment. Les signalements sont traités par la modération ; les abus peuvent conduire à un avertissement, une suspension ou la suppression du compte, avec une possibilité de recours."),
  LegalSection('6. Communauté et événements', "Les événements sont publiés par des organisateurs validés par un administrateur. Le lieu précis d'un événement n'est communiqué qu'aux participants acceptés. MERUT n'est pas l'organisateur des événements publiés par les membres."),
  LegalSection('7. Abonnements et jetons', "Les paiements ne sont pas encore ouverts. Lorsqu'ils le seront, les conditions de l'abonnement Premium, des jetons et du Boost seront précisées ici avant tout achat."),
  LegalSection('8. Suspension et suppression', "Tu peux supprimer ton compte à tout moment depuis Paramètres ; tes données sont alors effacées selon la politique de confidentialité. MERUT peut suspendre ou supprimer un compte qui ne respecte pas ces conditions."),
  LegalSection('9. Responsabilité', "MERUT met en place des moyens de sécurité et de modération mais ne peut garantir l'identité ni les intentions des membres. Reste prudent : ne partage jamais d'argent ni de documents d'identité et rencontre-toi dans un lieu public."),
  LegalSection('10. Évolution et droit applicable', "Ces conditions peuvent évoluer ; les changements importants te seront signalés dans l'application. Le droit applicable et le tribunal compétent seront précisés dès l'immatriculation de l'éditeur."),
]);

const _termsEn = LegalDocument([
  LegalSection('1. Purpose', "MERUT is a dating and community app for people who identify with kamite history and values. These terms govern its use."),
  LegalSection('2. Access and account', "The app is for adults only (18 or older). Signing up requires passing a knowledge and values questionnaire, never based on origin or appearance; a human review is available if you fail. Gender and date of birth are fixed at sign-up. The information you provide must be accurate."),
  LegalSection('3. Rules of conduct', "You commit to respect, honesty and good conduct towards other members, in line with the charter accepted at sign-up. Forbidden: harassment, hate speech, impersonation, scams and any request for money, sexual or violent content, and creating multiple accounts."),
  LegalSection('4. Photos and content', "Every photo is analysed automatically and may be reviewed by a moderator. A photo is only visible to other members once approved; a rejected photo is never visible and is deleted at the latest 30 days after rejection. You remain responsible for the content you publish."),
  LegalSection('5. Messaging, blocking and reporting', "You can block a member and report a profile, message or post at any time. Reports are handled by moderation; abuse can lead to a warning, a suspension or account deletion, with the possibility of an appeal."),
  LegalSection('6. Community and events', "Events are published by organisers approved by an administrator. The exact venue is only shared with accepted participants. MERUT is not the organiser of events published by members."),
  LegalSection('7. Subscriptions and tokens', "Payments are not open yet. When they are, the terms of the Premium subscription, tokens and Boost will be set out here before any purchase."),
  LegalSection('8. Suspension and deletion', "You can delete your account at any time from Settings; your data is then erased as described in the privacy policy. MERUT may suspend or delete an account that breaches these terms."),
  LegalSection('9. Liability', "MERUT provides security and moderation tools but cannot guarantee members' identity or intentions. Stay careful: never share money or identity documents, and meet in a public place."),
  LegalSection('10. Changes and governing law', "These terms may change; important changes will be announced in the app. The governing law and competent court will be specified once the publisher is registered."),
]);

const _privacyFr = LegalDocument([
  LegalSection('Qui est responsable de tes données', "L'éditeur de MERUT, dont l'identité complète est indiquée dans les mentions légales. Tu peux exercer tes droits en le contactant."),
  LegalSection('Les données que nous traitons', "Compte et connexion (identifiant, e-mail ou compte Google) ; profil (prénom, âge, genre, genres recherchés, ville, pays, description, centres d'intérêt, informations facultatives) ; photos ; position approximative si tu l'actives ; likes, matchs, messages et photos de conversation ; réponses aux questionnaires ; publications, participations et avis de la communauté ; jeton de notification de ton appareil ; signalements, blocages et mesures de sécurité."),
  LegalSection('Données sensibles', "Le genre et les genres recherchés peuvent révéler une orientation, et l'appartenance à la communauté peut révéler une origine ou des convictions. Ces informations ne servent qu'au fonctionnement de la rencontre et ne sont jamais vendues."),
  LegalSection('Pourquoi', "Faire fonctionner ton compte et la rencontre, assurer la sécurité et la modération de la communauté, calculer la distance et la compatibilité, t'envoyer les notifications que tu as choisies."),
  LegalSection('Photos et vérification', "Chaque photo est analysée automatiquement (contenu sensible, présence d'un visage) par un service Google ; aucune reconnaissance faciale d'identification n'est faite. La vérification d'identité par selfie, facultative, est examinée par un modérateur humain."),
  LegalSection('Position', "Ta position n'est enregistrée que si tu l'actives. Seule la dernière position est conservée, visible par toi seul. Tu peux la supprimer à tout moment dans Paramètres → Confidentialité."),
  LegalSection('Qui reçoit tes données', "Google (Firebase / Google Cloud) héberge et traite les données pour notre compte : authentification, base de données, stockage, fonctions, notifications, analyse d'images. Une partie de ces données est actuellement stockée aux États-Unis, sous le cadre de protection des données applicable aux transferts. Aucune donnée n'est vendue."),
  LegalSection('Combien de temps', "Tant que ton compte existe. Une photo refusée est supprimée sous 30 jours. À la suppression du compte, tes profil, photos, messages, matchs, publications, j'aime et réponses sont effacés ; les signalements peuvent être conservés pour la sécurité des autres membres."),
  LegalSection('Tes droits', "Accès et portabilité (Paramètres → Exporter mes données), rectification (Modifier mon profil), effacement (Supprimer mon compte), retrait de ton consentement (position, notifications), opposition et limitation en nous contactant. Tu peux saisir la CNIL (cnil.fr) en cas de difficulté."),
  LegalSection('Âge minimum', "L'application est réservée aux personnes de 18 ans ou plus."),
]);

const _privacyEn = LegalDocument([
  LegalSection('Who is responsible for your data', "The publisher of MERUT, whose full identity is given in the legal notice. You can exercise your rights by contacting them."),
  LegalSection('Data we process', "Account and sign-in (identifier, email or Google account); profile (first name, age, gender, genders sought, city, country, description, interests, optional details); photos; approximate location if you turn it on; likes, matches, messages and chat photos; questionnaire answers; community posts, participations and reviews; your device's notification token; reports, blocks and security measures."),
  LegalSection('Sensitive data', "Gender and genders sought may reveal an orientation, and community membership may reveal an origin or beliefs. This information is only used to make matching work and is never sold."),
  LegalSection('Why', "To run your account and matching, keep the community safe and moderated, compute distance and compatibility, and send the notifications you chose."),
  LegalSection('Photos and verification', "Each photo is analysed automatically (sensitive content, presence of a face) by a Google service; no identifying facial recognition is performed. The optional selfie identity check is reviewed by a human moderator."),
  LegalSection('Location', "Your location is only saved if you turn it on. Only the latest position is kept, visible to you alone. You can delete it at any time in Settings → Privacy."),
  LegalSection('Who receives your data', "Google (Firebase / Google Cloud) hosts and processes data on our behalf: authentication, database, storage, functions, notifications, image analysis. Part of this data is currently stored in the United States under the safeguards applicable to transfers. No data is sold."),
  LegalSection('How long', "As long as your account exists. A rejected photo is deleted within 30 days. When you delete your account, your profile, photos, messages, matches, posts, likes and replies are erased; reports may be kept for other members' safety."),
  LegalSection('Your rights', "Access and portability (Settings → Export my data), rectification (Edit my profile), erasure (Delete my account), withdrawal of consent (location, notifications), objection and restriction by contacting us. You may lodge a complaint with your data protection authority (in France, the CNIL: cnil.fr)."),
  LegalSection('Minimum age', "The app is for people aged 18 or over."),
]);

const _noticeFr = LegalDocument([
  LegalSection('Éditeur', "MERUT est édité par une société en cours d'immatriculation. Sa raison sociale, son adresse, son numéro d'immatriculation et le nom du responsable de publication seront publiés ici dès l'immatriculation."),
  LegalSection('Contact', "L'adresse de contact de l'éditeur pour toute question, signalement ou exercice de droits sera publiée ici avec les informations ci-dessus. En attendant, utilise la fonction de signalement de l'application."),
  LegalSection('Hébergement et services techniques', "Google LLC (Firebase / Google Cloud) : authentification, base de données, stockage de fichiers, fonctions serveur, notifications et analyse d'images."),
  LegalSection('Propriété intellectuelle', "Le nom MERUT, l'identité visuelle et le contenu éditorial de l'application sont la propriété de l'éditeur. Les photos et textes publiés par les membres restent leur propriété ; ils autorisent leur affichage dans l'application."),
]);

const _noticeEn = LegalDocument([
  LegalSection('Publisher', "MERUT is published by a company being registered. Its company name, address, registration number and the name of the publication director will be published here once registration is complete."),
  LegalSection('Contact', "The publisher's contact address for any question, report or exercise of rights will be published here with the information above. In the meantime, use the app's reporting feature."),
  LegalSection('Hosting and technical services', "Google LLC (Firebase / Google Cloud): authentication, database, file storage, server functions, notifications and image analysis."),
  LegalSection('Intellectual property', "The MERUT name, visual identity and editorial content belong to the publisher. Photos and texts posted by members remain theirs; they allow their display in the app."),
]);
