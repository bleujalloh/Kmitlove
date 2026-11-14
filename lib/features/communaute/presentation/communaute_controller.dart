import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profil/presentation/photo_controller.dart';
import '../../../core/utils/distance.dart';
import '../data/communaute_repository.dart';
import '../domain/community_post.dart';
import '../domain/event_filters.dart';

// Sous-onglet actif (Communauté/Événements/Actualités/Conseils) gardé ici
// plutôt qu'en état local de CommunauteScreen : depuis que Communauté
// n'est plus un onglet de la barre du bas (12/11/2026) mais atteint via
// Navigator.push (pilule de l'AppBar Messages), l'écran est détruit à
// chaque retour en arrière puis recréé à la prochaine ouverture — un
// StateProvider (jamais réinitialisé tant que l'app tourne) garde le
// sous-onglet choisi d'une visite à l'autre, comme discoverFiltersProvider
// le fait déjà pour les filtres Découvrir (trouvé par revue de code :
// sans ça, revenir sur Communauté retombait toujours sur le fil social
// même si on avait quitté depuis "Conseils").
final communauteTabProvider = StateProvider<int>((ref) => 0);

// Même raisonnement que communauteTabProvider ci-dessus, appliqué aux
// filtres du sous-onglet Événements (EventsTab) : gardés ici plutôt
// qu'en état local, pour ne pas se réinitialiser à chaque retour en
// arrière depuis Communauté (trouvé par revue de code : le premier
// passage ne corrigeait que le sous-onglet actif, pas ces filtres-là,
// qui subissaient exactement le même défaut).
// Filtres de l'onglet Événements (date, pays, ville, distance, catégorie,
// format, accès, places) — un seul objet immuable, voir
// domain/event_filters.dart.
final eventFiltersProvider = StateProvider<EventFilters>((ref) => const EventFilters());

/// Cache de session des coordonnées (centre) d'une ville d'événement :
/// géocodage direct sur l'appareil, jamais redemandé deux fois.
final _cityCoordsCache = <String, ({double lat, double lng})?>{};

Future<({double lat, double lng})?> _cityCoords(String city, String country) async {
  final key = '${city.trim().toLowerCase()}|${country.trim().toLowerCase()}';
  if (_cityCoordsCache.containsKey(key)) return _cityCoordsCache[key];
  try {
    final results = await Geocoding().locationFromAddress('$city, $country');
    final coords = results.isEmpty ? null : (lat: results.first.latitude, lng: results.first.longitude);
    _cityCoordsCache[key] = coords;
    return coords;
  } catch (_) {
    return null; // pas mis en cache : l'échec peut être passager (réseau)
  }
}

/// Distance (km, à vol d'oiseau, depuis la position enregistrée du membre
/// jusqu'au centre de la ville de l'événement) de chaque événement
/// présentiel — calculée seulement quand le filtre de distance est actif.
/// Approximative par construction : les événements n'ont que ville et
/// pays publics (le lieu précis reste privé, firestore.rules).
final eventDistancesProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final maxKm = ref.watch(eventFiltersProvider.select((f) => f.maxDistanceKm));
  if (maxKm == null) return const {};
  final lat = ref.watch(userStatusProvider.select((s) => s.value?['locationLat']));
  final lng = ref.watch(userStatusProvider.select((s) => s.value?['locationLng']));
  if (lat is! num || lng is! num) return const {};
  final events = await ref.watch(allPublishedEventsProvider.future);
  final result = <String, double>{};
  final cities = <String, ({double lat, double lng})?>{};
  for (final e in events) {
    final city = e.city;
    final country = e.country;
    if (e.isOnline || city == null || country == null) continue;
    final key = '$city|$country';
    if (!cities.containsKey(key)) cities[key] = await _cityCoords(city, country);
    final c = cities[key];
    if (c != null) result[e.id] = haversineKm(lat.toDouble(), lng.toDouble(), c.lat, c.lng);
  }
  return result;
});

final communauteRepositoryProvider = Provider<CommunauteRepository>((ref) {
  return CommunauteRepository(
    ref.watch(firestoreProvider),
    ref.watch(cloudFunctionsProvider),
    ref.watch(firebaseStorageProvider),
  );
});

/// Compteurs affichés sur les cartes du fil (relancés après un j'aime ou
/// une réponse, voir CommunauteController).
final postLikeCountProvider = FutureProvider.autoDispose.family<int, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).likeCount(postId);
});

final postReplyCountProvider = FutureProvider.autoDispose.family<int, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).replyCount(postId);
});

final postMyLikeProvider = StreamProvider.autoDispose.family<bool, String>((ref, postId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyLike(postId, uid);
});

final postRepliesProvider = StreamProvider.autoDispose.family<List<PostReply>, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).watchReplies(postId);
});

/// Nom d'affichage de l'auteur d'une publication (profil lisible par tout
/// membre connecté, firestore.rules).
final memberDisplayNameProvider = FutureProvider.autoDispose.family<String?, String>((ref, uid) async {
  final doc = await ref.watch(firestoreProvider).collection('users').doc(uid).get();
  return doc.data()?['displayName'] as String?;
});

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchFeed();
});

final allPublishedEventsProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchAllPublishedEvents();
});

final participationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).watchParticipations(postId);
});

final myParticipationProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, postId) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyParticipation(postId, uid);
});

/// "Mes participations" (spec Communauté section 10).
final myParticipationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyParticipations(uid);
});

/// Statut organisateur du membre courant (spec section 3) — none/pending/
/// approved/rejected/suspended, lu depuis user_status (jamais modifiable
/// depuis le client, voir firestore.rules).
final myOrganizerStatusProvider = StreamProvider<String?>((ref) {
  final status = ref.watch(userStatusProvider);
  return status.when(
    data: (s) => Stream.value(s?['organizerStatus'] as String?),
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});

/// Mes événements en tant qu'organisateur (espace organisateur, section 8).
final myOrganizedEventsProvider = StreamProvider<List<CommunityPost>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyEvents(uid);
});

final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchFavoriteIds(uid);
});

final linkedEventsProvider = StreamProvider.family<List<CommunityPost>, String>((ref, parentEventId) {
  return ref.watch(communauteRepositoryProvider).watchLinkedEvents(parentEventId);
});

final eventReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).watchReviews(postId);
});

/// Autres dates d'une série d'événements récurrents (spec section 10).
final recurrenceSeriesProvider =
    StreamProvider.family<List<CommunityPost>, String>((ref, recurrenceGroupId) {
  return ref.watch(communauteRepositoryProvider).watchRecurrenceSeries(recurrenceGroupId);
});

/// Conseils (onglet "Conseils" de la Communauté) — contenu éditorial admin.
final communityTipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchTips();
});

/// Affiche d'un événement (URL de téléchargement depuis son chemin
/// Storage) — même raisonnement de mise en cache par chemin que les
/// autres photos de l'app (profil/presentation/photo_controller.dart).
final eventPosterUrlProvider = FutureProvider.family<String, String>((ref, storagePath) {
  return ref.watch(communauteRepositoryProvider).getPosterDownloadUrl(storagePath);
});

class CommunauteController {
  CommunauteController(this.ref);
  final Ref ref;

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
  }) {
    return ref.read(communauteRepositoryProvider).createPost(
          type: type,
          text: text,
          title: title,
          eventDate: eventDate,
          eventEndDate: eventEndDate,
          capacity: capacity,
          preciseLocation: preciseLocation,
          category: category,
          format: format,
          city: city,
          country: country,
          ageMinimum: ageMinimum,
          conditions: conditions,
          contactChannel: contactChannel,
          posterStoragePath: posterStoragePath,
          accessMode: accessMode,
          parentEventId: parentEventId,
          recurrence: recurrence,
          recurrenceCount: recurrenceCount,
          timezone: timezone,
        );
  }

  Future<void> cancelParticipation(String postId) {
    return ref.read(communauteRepositoryProvider).cancelParticipation(postId);
  }

  Future<String> getEventShareCode(String postId) {
    return ref.read(communauteRepositoryProvider).getEventShareCode(postId);
  }

  Future<String> redeemEventInviteCode(String code) {
    return ref.read(communauteRepositoryProvider).redeemEventInviteCode(code);
  }

  Future<String> uploadEventPoster(File file) async {
    final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
    return ref.read(communauteRepositoryProvider).uploadEventPoster(uid, file);
  }

  Future<void> deleteEventPoster(String storagePath) {
    return ref.read(communauteRepositoryProvider).deleteEventPoster(storagePath);
  }

  Future<void> requestParticipation(String postId) {
    return ref.read(communauteRepositoryProvider).requestParticipation(postId);
  }

  Future<void> respond(String postId, String targetUid, bool accept) {
    return ref.read(communauteRepositoryProvider).respondToParticipation(postId, targetUid, accept);
  }

  Future<void> checkIn(String postId, String targetUid, String code) {
    return ref.read(communauteRepositoryProvider).checkIn(postId, targetUid, code);
  }

  Future<String?> getPreciseLocation(String postId) {
    return ref.read(communauteRepositoryProvider).getPreciseLocation(postId);
  }

  Future<void> report(String postId, String reason, {String? replyId}) {
    return ref.read(communauteRepositoryProvider).report(postId, reason, replyId: replyId);
  }

  Future<void> toggleLike(String postId) async {
    await ref.read(communauteRepositoryProvider).toggleLike(postId);
    ref.invalidate(postLikeCountProvider(postId));
  }

  Future<void> reply(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await ref.read(communauteRepositoryProvider).reply(postId, trimmed);
    ref.invalidate(postReplyCountProvider(postId));
  }

  Future<void> requestOrganizerStatus(String name, String description) {
    return ref.read(communauteRepositoryProvider).requestOrganizerStatus(name, description);
  }

  Future<void> inviteToEvent(String postId, String targetUid) {
    return ref.read(communauteRepositoryProvider).inviteToEvent(postId, targetUid);
  }

  Future<List<InvitableMember>> searchMembersToInvite(String query) {
    return ref.read(communauteRepositoryProvider).searchMembersToInvite(query);
  }

  Future<void> updateEventState(String postId, String eventState) {
    return ref.read(communauteRepositoryProvider).updateEventState(postId, eventState);
  }

  Future<void> toggleFavorite(String postId, bool favorite) {
    final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
    return ref.read(communauteRepositoryProvider).setFavorite(uid, postId, favorite);
  }

  Future<void> submitReview(String postId, int rating, {String? comment}) {
    return ref.read(communauteRepositoryProvider).submitReview(postId, rating, comment: comment);
  }
}

final communauteControllerProvider = Provider((ref) => CommunauteController(ref));
