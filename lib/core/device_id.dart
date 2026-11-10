import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _prefsKey = 'device_signal_id';

/// Identifiant d'appareil persistant, généré une seule fois à
/// l'installation — uniquement un indice anti-abus best-effort (limite de
/// comptes par appareil, voir functions/src/account/registerDeviceSignal.ts),
/// jamais un identifiant fiable : réinitialisé à la réinstallation, et
/// peut être partagé légitimement par plusieurs membres d'un même foyer.
Future<String> getDeviceSignalId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_prefsKey);
  if (existing != null) return existing;
  final generated = const Uuid().v4();
  await prefs.setString(_prefsKey, generated);
  return generated;
}
