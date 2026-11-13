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

/// Photos (au plus 3) des prochains profils que Découvrir propose déjà au
/// membre — illustre les écrans vides Likes/Messages avec de vrais profils
/// existants (EmptyStateCards). Réutilise la file de candidats et le
/// fournisseur de photos de Découvrir : aucune requête ni donnée en plus,
/// et aucun profil que le membre ne verrait pas déjà dans Découvrir.
final suggestedProfilePhotosProvider = Provider.autoDispose<List<String>>((ref) {
  final candidates = ref.watch(decouvrirControllerProvider).value?.candidates ?? const <Candidate>[];
  return [
    for (final c in candidates.take(3)) ref.watch(candidateFirstPhotoUrlProvider(c.uid)).value,
  ].whereType<String>().toList();
});

/// Filtres manuels de Découvrir (docs/regles-complementaires-concurrents.md
/// section 3) — tranche d'âge et distance. Réinitialisés à chaque
/// lancement de l'app ; la persistance (les garder d'une session à
/// l'autre) pourra être ajoutée plus tard si besoin.
final discoverFiltersProvider = StateProvider<DiscoverFilters>((ref) {
  return const DiscoverFilters();
});

class DecouvrirState {
  const DecouvrirState({
    required this.candidates,
    this.justMatchedWith,
    this.errorMessage,
    this.lastPassed,
  });

  final List<Candidate> candidates;
  final Candidate? justMatchedWith;
  final String? errorMessage;

  /// Dernier profil passé dans cette session, s'il est encore annulable
  /// (bouton « retour », undoLastSwipe côté serveur). Effacé par tout
  /// autre swipe.
  final Candidate? lastPassed;
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

String _readableUndoError(Object error, Locale? locale) {
  final l10n = l10nFor(locale);
  final text = error.toString();
  if (text.contains('permission-denied')) return l10n.rewindPremiumOnly;
  return l10n.genericError;
}

class DecouvrirController extends AsyncNotifier<DecouvrirState> {
  bool _swipeInFlight = false;
  // Uid actuellement en attente de réponse réseau dans `swipe()`, et si ce
  // candidat précis a été bloqué (`removeCandidate`) PENDANT cette attente
  // — jamais un Set qui persisterait entre deux appels : une première
  // version gardait les uids bloqués dans un Set jusqu'à ce qu'un swipe
  // correspondant les consomme, ce qui faisait planer indéfiniment un
  // blocage ancien sur un futur match bien réel si la personne était
  // débloquée puis reproposée plus tard (trouvé par revue de code). Ces
  // deux champs sont réinitialisés à chaque appel de `swipe()`, donc rien
  // ne peut jamais rester périmé d'un appel à l'autre.
  String? _inFlightTargetUid;
  bool _inFlightTargetBlocked = false;

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
    _inFlightTargetUid = target.uid;
    _inFlightTargetBlocked = false;
    try {
      final matched = await ref.read(decouvrirRepositoryProvider).swipe(target.uid, action);
      // Repart de la liste EN VIGUEUR au moment où l'appel réseau se
      // termine, pas de l'instantané `remaining` capturé avant l'attente
      // — si `removeCandidate` (blocage depuis le menu "⋮", resté
      // accessible sur la carte pendant l'attente) a modifié l'état
      // pendant ce swipe, écraser avec l'instantané périmé aurait fait
      // réapparaître un profil déjà bloqué, voire déclenché le dialogue
      // "C'est un match !" pour lui (trouvé par revue de code).
      final liveCandidates = state.value?.candidates ?? remaining;
      state = AsyncData(
        DecouvrirState(
          candidates: liveCandidates.where((c) => c.uid != target.uid).toList(),
          justMatchedWith: (matched && !_inFlightTargetBlocked) ? target : null,
          lastPassed: (action == 'pass' && !_inFlightTargetBlocked) ? target : null,
        ),
      );
    } catch (e) {
      // Le profil est retiré de la pile dans tous les cas (on ne le
      // représente pas), mais la liste de candidats reste affichée —
      // seul un message d'erreur s'ajoute, sans faire planter tout
      // l'état de l'écran comme le ferait un AsyncError ici.
      final liveCandidates = state.value?.candidates ?? remaining;
      state = AsyncData(
        DecouvrirState(
          candidates: liveCandidates.where((c) => c.uid != target.uid).toList(),
          errorMessage: _readableSwipeError(e, ref.read(localeControllerProvider)),
        ),
      );
    } finally {
      _swipeInFlight = false;
      _inFlightTargetUid = null;
    }
  }

  /// Retire immédiatement un candidat de la pile en mémoire sans
  /// resolliciter le serveur — utilisé après un blocage réussi (trouvé
  /// par audit : sans ça, la personne qu'on vient de bloquer depuis le
  /// menu "⋮" restait affichée et swipable tant que `build()` n'était pas
  /// relancé, ex. tant qu'on ne quittait pas puis revenait sur l'onglet).
  void removeCandidate(String uid) {
    if (uid == _inFlightTargetUid) _inFlightTargetBlocked = true;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      DecouvrirState(
        candidates: current.candidates.where((c) => c.uid != uid).toList(),
        justMatchedWith: current.justMatchedWith,
        lastPassed: current.lastPassed?.uid == uid ? null : current.lastPassed,
      ),
    );
  }

  /// « Retour » : annule le dernier passage côté serveur (Premium) puis
  /// remet le profil en tête de pile.
  Future<void> undoLastPass() async {
    final current = state.value;
    final target = current?.lastPassed;
    if (current == null || target == null || _swipeInFlight) return;
    _swipeInFlight = true;
    try {
      await ref.read(decouvrirRepositoryProvider).undoLastSwipe(target.uid);
      final live = state.value ?? current;
      state = AsyncData(
        DecouvrirState(candidates: [target, ...live.candidates.where((c) => c.uid != target.uid)]),
      );
    } catch (e) {
      final live = state.value ?? current;
      state = AsyncData(
        DecouvrirState(
          candidates: live.candidates,
          lastPassed: live.lastPassed,
          errorMessage: _readableUndoError(e, ref.read(localeControllerProvider)),
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
