import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';

/// Demande la permission et récupère la position une seule fois (pas de
/// suivi en arrière-plan, volontairement — voir le choix explicite de ne
/// pas reproduire Happn dans docs/regles-complementaires-concurrents.md
/// section 4). La position brute ne quitte jamais l'appareil autrement
/// que vers cette Cloud Function, qui seule peut la lire côté serveur.
class LocationService {
  LocationService(this._functions);

  final FirebaseFunctions _functions;

  Future<bool> updateMyLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    await _functions.httpsCallable('updateMyLocation').call({
      'lat': position.latitude,
      'lng': position.longitude,
    });
    return true;
  }

  /// Retrait du consentement : la position enregistrée est supprimée côté
  /// serveur (updateMyLocation.ts, `clear: true`), pas seulement ignorée.
  Future<void> clearMyLocation() async {
    await _functions.httpsCallable('updateMyLocation').call({'clear': true});
  }
}
