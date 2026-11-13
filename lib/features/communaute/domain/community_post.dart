import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../l10n/app_localizations.dart';

/// Libellé affiché pour chaque type de publication — partagé entre
/// communaute_screen.dart (fil) et create_post_screen.dart (sélecteur),
/// pour éviter que les deux dérivent l'un de l'autre. Les valeurs de
/// `type` stockées restent ces codes français (jamais traduites).
String postTypeLabel(String type, AppLocalizations l10n) {
  switch (type) {
    case 'publication':
      return l10n.postTypePublication;
    case 'annonce_publique':
      return l10n.postTypePublicAnnouncement;
    case 'annonce_privee':
      return l10n.postTypePrivateAnnouncement;
    case 'annonce_libre':
      return l10n.postTypeFreeAnnouncement;
    case 'evenement_public':
      return l10n.postTypePublicEvent;
    case 'evenement_prive':
      return l10n.postTypePrivateEvent;
    default:
      return l10n.postTypeGeneric;
  }
}

/// Catégories d'événement (spec Communauté section 2/6, 11/11/2026) —
/// liste fermée, vérifiée côté serveur (createCommunityPost.ts) ; ce
/// libellé n'est qu'un miroir d'affichage.
String eventCategoryLabel(String category, AppLocalizations l10n) {
  switch (category) {
    case 'soiree':
      return l10n.eventCategorySoiree;
    case 'conference':
      return l10n.eventCategoryConference;
    case 'atelier':
      return l10n.eventCategoryAtelier;
    case 'exposition':
      return l10n.eventCategoryExposition;
    case 'debat':
      return l10n.eventCategoryDebat;
    case 'projection':
      return l10n.eventCategoryProjection;
    case 'rencontre':
      return l10n.eventCategoryRencontre;
    default:
      return category;
  }
}

String eventAccessModeLabel(String accessMode, AppLocalizations l10n) {
  switch (accessMode) {
    case 'public':
      return l10n.eventAccessPublic;
    case 'sur_demande':
      return l10n.eventAccessOnRequest;
    case 'sur_invitation':
      return l10n.eventAccessOnInvitation;
    default:
      return accessMode;
  }
}

String eventStateLabel(String eventState, AppLocalizations l10n) {
  switch (eventState) {
    case 'prevu':
      return l10n.eventStateScheduled;
    case 'complet':
      return l10n.eventStateFull;
    case 'annule':
      return l10n.eventStateCancelled;
    case 'termine':
      return l10n.eventStateFinished;
    default:
      return eventState;
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.type,
    required this.authorUid,
    required this.text,
    required this.status,
    this.title,
    this.eventDate,
    this.eventEndDate,
    this.capacity,
    required this.participantsCount,
    this.createdAt,
    this.category,
    this.format,
    this.city,
    this.country,
    this.ageMinimum,
    this.conditions,
    this.contactChannel,
    this.posterStoragePath,
    this.accessMode,
    this.parentEventId,
    this.eventState,
    this.recurrenceGroupId,
    this.recurrenceFrequency,
  });

  final String id;
  final String type; // publication | annonce_publique | annonce_privee | annonce_libre | evenement_public | evenement_prive
  final String authorUid;
  final String text;
  final String status; // published | pending_review | rejected
  final String? title;
  final DateTime? eventDate;
  final DateTime? eventEndDate;
  final int? capacity;
  final int participantsCount;
  final DateTime? createdAt;
  final String? category;
  final String? format; // presentiel | en_ligne
  final String? city;
  final String? country;
  final int? ageMinimum;
  final String? conditions;
  final String? contactChannel;
  final String? posterStoragePath;
  final String? accessMode; // public | sur_demande | sur_invitation
  final String? parentEventId;
  final String? eventState; // prevu | complet | annule | termine
  final String? recurrenceGroupId;
  final String? recurrenceFrequency; // hebdomadaire | mensuel | null

  bool get isEvent => type == 'evenement_public' || type == 'evenement_prive';
  // Vrai pour TOUT événement, y compris public : le bouton "Demander à
  // participer" reste affiché, c'est le serveur (participation.ts) qui
  // décide d'accepter aussitôt (public/sur invitation) ou de mettre en
  // attente l'organisateur (sur demande) — jamais une décision cliente.
  // Bug trouvé par revue de code : une première version excluait les
  // événements publics d'ici, masquant le bouton pour le cas le plus
  // courant.
  bool get needsParticipationRequest => isEvent || type == 'annonce_privee';
  bool get isFull => capacity != null && participantsCount >= capacity!;
  bool get isOnline => format == 'en_ligne';

  factory CommunityPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityPost(
      id: doc.id,
      type: data['type'] as String,
      authorUid: data['authorUid'] as String,
      text: data['text'] as String,
      status: data['status'] as String,
      title: data['title'] as String?,
      eventDate: data['eventDate'] != null ? DateTime.tryParse(data['eventDate'] as String) : null,
      eventEndDate: data['eventEndDate'] != null ? DateTime.tryParse(data['eventEndDate'] as String) : null,
      capacity: (data['capacity'] as num?)?.toInt(),
      participantsCount: (data['participantsCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      category: data['category'] as String?,
      format: data['format'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      ageMinimum: (data['ageMinimum'] as num?)?.toInt(),
      conditions: data['conditions'] as String?,
      contactChannel: data['contactChannel'] as String?,
      posterStoragePath: data['posterStoragePath'] as String?,
      accessMode: data['accessMode'] as String?,
      parentEventId: data['parentEventId'] as String?,
      eventState: data['eventState'] as String?,
      recurrenceGroupId: data['recurrenceGroupId'] as String?,
      recurrenceFrequency: data['recurrenceFrequency'] as String?,
    );
  }
}

String tipCategoryLabel(String category, AppLocalizations l10n) {
  switch (category) {
    case 'culture':
      return l10n.tipCategoryCulture;
    case 'relation':
      return l10n.tipCategoryRelation;
    case 'securite':
      return l10n.tipCategorySecurite;
    case 'communaute':
      return l10n.tipCategoryCommunaute;
    default:
      return category;
  }
}

String eventRecurrenceLabel(String frequency, AppLocalizations l10n) {
  switch (frequency) {
    case 'hebdomadaire':
      return l10n.eventRecurrenceWeekly;
    case 'mensuel':
      return l10n.eventRecurrenceMonthly;
    default:
      return frequency;
  }
}

/// Réponse à une publication du fil (prototype Communaute.dc.html :
/// « 9 réponses »). Écrite uniquement par la fonction replyToPost.
class PostReply {
  const PostReply({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  factory PostReply.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostReply(
      id: doc.id,
      authorUid: data['authorUid'] as String,
      authorName: data['authorName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
