import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/locale_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profil/presentation/photo_controller.dart';
import '../data/decouvrir_repository.dart';
import '../data/location_service.dart';
import '../domain/candidate.dart';

final decouvrirRepositoryProvider = Provider<DecouvrirRepository>((ref) {
  return DecouvrirRepository(ref.watch(cloudFunctionsProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(cloudFunctionsProvider));
});

/// Photo (approuvée) d'un candidat affiché sur la carte Découvrir —
/// jusqu'ici jamais reliée, la carte montrait juste une icône silhouette
/// quelle que soit la personne (remarqué par le propriétaire le 11/11 :
/// "ça ne ressemble pas à une app de rencontres"). Lecture directe
/// Firestore : une photo approuvée est lisible par tout membre connecté
/// (firestore.rules), pas besoin d'une Cloud Function dédiée.
final candidateFirstPhotoUrlProvider = FutureProvider.autoDispose.family<String?, String>((ref, uid) async {
  final paths = await ref.watch(photoRepositoryProvider).getApprovedPhotoStoragePaths(uid, limit: 1);
  if (paths.isEmpty) return null;
  // Ce FutureProvider ne se relance jamais tout seul (pas un Stream) — si
  // le tout premier appel Storage échoue à cause d'une course au
  // démarrage à froid (jeton App Check/Play Integrity pas encore prêt),
  // la carte resterait sans photo pour le reste de la session (bug
  // remarqué le 11/11 sur l'onglet Profil, qui appelle ce même provider
  // en tout premier à l'ouverture de l'app) — retryAsync déjà appliqué
  // dans PhotoRepository.getDownloadUrl.
  return ref.watch(photoRepositoryProvider).getDownloadUrl(paths.first);
});

/// Filtres manuels de Découvrir (docs/regles-complementaires-concurrents.md
/// section 3) — tranche d'âge et distance. Réinitialisés à chaque
/// lancement de l'app ; la persistance (les garder d'une session à
/// l'autre) pourra être ajoutée plus tard si besoin.
final discoverFiltersProvider = StateProvider<DiscoverFilters>((ref) {
  return const DiscoverFilters();
});

class DecouvrirState {
  const DecouvrirState({required this.candidates, this.justMatchedWith, this.errorMessage});

  final List<Candidate> candidates;
  final Candidate? justMatchedWith;
  final String? errorMessage;
}

String _readableSwipeError(Object error, Locale? locale) {
  final l10n = l10nFor(locale);
  final text = error.toString();
  if (text.contains('super-like-jetons-insuffisants')) {
    return l10n.superLikeRequiresJetonOrPremium;
  }
  if (text.contains('resource-exhausted')) {
    return l10n.dailyLikeLimitReached;
  }
  if (text.contains('already-exists')) {
    return l10n.profileAlreadySwiped;
  }
  return l10n.genericError;
}

class DecouvrirController extends AsyncNotifier<DecouvrirState> {
  bool _swipeInFlight = false;

  @override
  Future<DecouvrirState> build() async {
    final filters = ref.watch(discoverFiltersProvider);
    final candidates = await ref.read(decouvrirRepositoryProvider).getCandidates(filters);
    return DecouvrirState(candidates: candidates);
  }

  Future<void> swipe(String action) async {
    if (_swipeInFlight) return; // ignore un double-tap pendant l'appel réseau en cours
    final current = state.value;
    if (current == null || current.candidates.isEmpty) return;
    final target = current.candidates.first;
    final remaining = current.candidates.sublist(1);

    _swipeInFlight = true;
    try {
      final matched = await ref.read(decouvrirRepositoryProvider).swipe(target.uid, action);
      state = AsyncData(
        DecouvrirState(candidates: remaining, justMatchedWith: matched ? target : null),
      );
    } catch (e) {
      // Le profil est retiré de la pile dans tous les cas (on ne le
      // représente pas), mais la liste de candidats reste affichée —
      // seul un message d'erreur s'ajoute, sans faire planter tout
      // l'état de l'écran comme le ferait un AsyncError ici.
      state = AsyncData(
        DecouvrirState(
          candidates: remaining,
          errorMessage: _readableSwipeError(e, ref.read(localeControllerProvider)),
        ),
      );
    } finally {
      _swipeInFlight = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final filters = ref.read(discoverFiltersProvider);
      final candidates = await ref.read(decouvrirRepositoryProvider).getCandidates(filters);
      state = AsyncData(DecouvrirState(candidates: candidates));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final decouvrirControllerProvider =
    AsyncNotifierProvider<DecouvrirController, DecouvrirState>(DecouvrirController.new);
