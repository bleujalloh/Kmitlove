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

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.type,
    required this.authorUid,
    required this.text,
    required this.status,
    this.title,
    this.eventDate,
    this.capacity,
    required this.participantsCount,
    this.createdAt,
  });

  final String id;
  final String type; // publication | annonce_publique | annonce_privee | evenement_public | evenement_prive
  final String authorUid;
  final String text;
  final String status; // published | pending_review
  final String? title;
  final DateTime? eventDate;
  final int? capacity;
  final int participantsCount;
  final DateTime? createdAt;

  bool get isEvent => type == 'evenement_public' || type == 'evenement_prive';
  bool get needsParticipationRequest => isEvent || type == 'annonce_privee';

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
      capacity: (data['capacity'] as num?)?.toInt(),
      participantsCount: (data['participantsCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
