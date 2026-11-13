import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/locale_provider.dart';

/// Pays et ville correspondant à la position GPS déjà enregistrée pour ce
/// membre — affichés (jamais appliqués comme filtre) dans les pilules Pays
/// et Ville de Découvrir quand "Ma position" est active (demande explicite
/// du propriétaire, 13/11/2026 : "il faut les afficher"). Un filtre pays
/// remplace la distance côté serveur (getCandidates.ts) : l'appliquer
/// automatiquement aurait transformé "Ma position" en filtre par ville.
typedef DetectedPlace = ({String? country, String? city});

/// Conversion pure d'un résultat de géocodage inverse : ville = localité,
/// à défaut le département/la zone administrative secondaire ; une valeur
/// vide est traitée comme absente plutôt qu'affichée comme un texte vide.
DetectedPlace placeFromPlacemark(Placemark placemark) {
  String? clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  return (
    country: clean(placemark.country),
    city: clean(placemark.locality) ?? clean(placemark.subAdministrativeArea),
  );
}

/// Résolu sur l'appareil (géocodeur de la plateforme), à partir des
/// coordonnées lisibles par leur seul propriétaire dans user_status — rien
/// n'est stocké ni envoyé en plus au serveur. Ne dépend que de la latitude
/// et de la longitude, pour ne pas relancer un géocodage à chaque mise à
/// jour sans rapport du statut (dernière activité...).
final detectedPlaceProvider = FutureProvider.autoDispose<DetectedPlace?>((
  ref,
) async {
  final lat = ref.watch(
    userStatusProvider.select((status) => status.value?['locationLat']),
  );
  final lng = ref.watch(
    userStatusProvider.select((status) => status.value?['locationLng']),
  );
  if (lat is! num || lng is! num) return null;
  // Noms de pays/ville dans la langue choisie dans l'app (à défaut, celle
  // de l'appareil).
  final locale = ref.watch(localeControllerProvider);
  try {
    final placemarks = await Geocoding().placemarkFromCoordinates(
      lat.toDouble(),
      lng.toDouble(),
      locale: locale,
    );
    if (placemarks.isEmpty) return null;
    return placeFromPlacemark(placemarks.first);
  } catch (_) {
    // Géocodeur indisponible ou aucun résultat : les pilules gardent leur
    // libellé neutre plutôt qu'afficher un lieu inventé.
    return null;
  }
});
