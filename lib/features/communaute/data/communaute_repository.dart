import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/community_post.dart';

/// Le fil se lit directement en Firestore (filtré par les règles de
/// sécurité : publié, ou propre publication en attente). Toute création
/// ou action de modération passe par des Cloud Functions, jamais une
/// écriture directe (firestore.rules, docs/regles-annonces-evenements.md).
class CommunauteRepository {
  CommunauteRepository(this._firestore, this._functions, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  /// Affiche de l'événement (spec section 6) — déposée AVANT la création
  /// du post lui-même, qui ne reçoit que le chemin déjà en place
  /// (storage.rules : rangée par uid, jamais sensible).
  Future<String> uploadEventPoster(String uid, File file) async {
    final path = 'event_posters/$uid/${const Uuid().v4()}.jpg';
    await _storage.ref(path).putFile(file);
    return path;
  }

  Future<String> getPosterDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }

  /// Nettoyage best-effort si la création du post échoue après l'envoi
  /// de l'affiche (trouvé par revue de code : sans ça, chaque tentative
  /// ratée laissait un fichier orphelin dans Storage).
  Future<void> deleteEventPoster(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // Best-effort : un fichier orphelin résiduel n'est pas grave, mais
      // une erreur de nettoyage ne doit jamais empêcher d'afficher
      // l'erreur réelle à l'utilisateur.
    }
  }

  Stream<List<CommunityPost>> watchFeed() {
    return _firestore
        .collection('community_posts')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  /// Tous les événements publiés (spec Communauté section 1/10) — filtre
  /// côté client sur un lot un peu plus large plutôt qu'un nouvel index
  /// composite dédié, proportionné tant que le volume reste modeste
  /// (même raisonnement que le pool de candidats Découvrir).
  Stream<List<CommunityPost>> watchAllPublishedEvents() {
    return _firestore
        .collection('community_posts')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).where((p) => p.isEvent).toList());
  }

  Future<String> createPost({
    required String type,
    required String text,
    String? title,
    DateTime? eventDate,
    DateTime? eventEndDate,
    int? capacity,
    String? preciseLocation,
    String? category,
    String? format,
    String? city,
    String? country,
    int? ageMinimum,
    String? conditions,
    String? contactChannel,
    String? posterStoragePath,
    String? accessMode,
    String? parentEventId,
    String? recurrence,
    int? recurrenceCount,
    String? timezone,
  }) async {
    final result = await _functions.httpsCallable('createCommunityPost').call({
      'type': type,
      'text': text,
      'title': title,
      'eventDate': eventDate?.toIso8601String(),
      'eventEndDate': eventEndDate?.toIso8601String(),
      'capacity': capacity,
      'preciseLocation': preciseLocation,
      'category': category,
      'format': format,
      'city': city,
      'country': country,
      'ageMinimum': ageMinimum,
      'conditions': conditions,
      'contactChannel': contactChannel,
      'posterStoragePath': posterStoragePath,
      'accessMode': accessMode,
      'parentEventId': parentEventId,
      'recurrence': recurrence,
      'recurrenceCount': recurrenceCount,
      'timezone': timezone,
    });
    final data = result.data as Map<Object?, Object?>;
    return data['status'] as String;
  }

  Future<void> requestParticipation(String postId) {
    return _functions.httpsCallable('requestParticipation').call({'postId': postId});
  }

  /// Annulation par le membre lui-même (spec section 9 : liste d'attente
  /// — promotion automatique gérée entièrement côté serveur, voir
  /// cancelParticipation.ts).
  Future<void> cancelParticipation(String postId) {
    return _functions.httpsCallable('cancelParticipation').call({'postId': postId});
  }

  Future<void> respondToParticipation(String postId, String targetUid, bool accept) {
    return _functions.httpsCallable('respondToParticipation').call({
      'postId': postId,
      'targetUid': targetUid,
      'accept': accept,
    });
  }

  Future<void> checkIn(String postId, String targetUid, String code) {
    return _functions.httpsCallable('checkInParticipant').call({
      'postId': postId,
      'targetUid': targetUid,
      'code': code,
    });
  }

  Future<String?> getPreciseLocation(String postId) async {
    final result = await _functions.httpsCallable('getEventLocation').call({'postId': postId});
    final data = result.data as Map<Object?, Object?>;
    return data['preciseLocation'] as String?;
  }

  Future<void> report(String postId, String reason, {String? details}) {
    return _functions
        .httpsCallable('reportCommunityPost')
        .call({'postId': postId, 'reason': reason, 'details': details});
  }

  Stream<List<Map<String, dynamic>>> watchParticipations(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('participations')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Stream<Map<String, dynamic>?> watchMyParticipation(String postId, String uid) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('participations')
        .doc(uid)
        .snapshots()
        .map((s) => s.data());
  }

  /// "Mes participations" (spec Communauté section 10) — toutes mes
  /// demandes/inscriptions, tous posts confondus, via une requête de
  /// groupe de collections (index déjà déclaré dans firestore.indexes.json,
  /// jamais câblée côté client jusqu'ici).
  Stream<List<Map<String, dynamic>>> watchMyParticipations(String uid) {
    return _firestore
        .collectionGroup('participations')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {
                  'postId': d.reference.parent.parent!.id,
                  ...d.data(),
                })
            .toList());
  }

  // --- Organisateur (spec section 3 et 8) ---

  Future<void> requestOrganizerStatus(String organizerName, String organizerDescription) {
    return _functions.httpsCallable('requestOrganizerStatus').call({
      'organizerName': organizerName,
      'organizerDescription': organizerDescription,
    });
  }

  Future<void> inviteToEvent(String postId, String targetUid) {
    return _functions.httpsCallable('inviteToEvent').call({'postId': postId, 'targetUid': targetUid});
  }

  Future<void> updateEventState(String postId, String eventState) {
    return _functions.httpsCallable('updateEventState').call({'postId': postId, 'eventState': eventState});
  }

  /// Mes événements en tant qu'organisateur (espace organisateur, section 8).
  Stream<List<CommunityPost>> watchMyEvents(String uid) {
    return _firestore
        .collection('community_posts')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  // --- Favoris (section 9) : préférence personnelle, écriture directe ---

  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> setFavorite(String uid, String postId, bool favorite) {
    final ref = _firestore.collection('users').doc(uid).collection('favorites').doc(postId);
    if (favorite) {
      return ref.set({'savedAt': FieldValue.serverTimestamp()});
    }
    return ref.delete();
  }

  // --- Événements liés (section 7) ---

  Stream<List<CommunityPost>> watchLinkedEvents(String parentEventId) {
    return _firestore
        .collection('community_posts')
        .where('parentEventId', isEqualTo: parentEventId)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  // --- Avis après événement (section 9) ---

  Future<void> submitReview(String postId, int rating, {String? comment}) {
    return _functions
        .httpsCallable('submitEventReview')
        .call({'postId': postId, 'rating': rating, 'comment': comment});
  }

  Stream<List<Map<String, dynamic>>> watchReviews(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // --- Événements récurrents (section 10) ---

  Stream<List<CommunityPost>> watchRecurrenceSeries(String recurrenceGroupId) {
    return _firestore
        .collection('community_posts')
        .where('recurrenceGroupId', isEqualTo: recurrenceGroupId)
        .orderBy('eventDate')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  // --- Partage privé d'une invitation (section 2) ---

  Future<String> getEventShareCode(String postId) async {
    final result = await _functions.httpsCallable('getEventShareCode').call({'postId': postId});
    final data = result.data as Map<Object?, Object?>;
    return data['shareCode'] as String;
  }

  Future<String> redeemEventInviteCode(String code) async {
    final result = await _functions.httpsCallable('redeemEventInviteCode').call({'code': code});
    final data = result.data as Map<Object?, Object?>;
    return data['postId'] as String;
  }

  // --- Conseils (onglet "Conseils", contenu éditorial admin) ---

  Stream<List<Map<String, dynamic>>> watchTips() {
    return _firestore
        .collection('community_tips')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
