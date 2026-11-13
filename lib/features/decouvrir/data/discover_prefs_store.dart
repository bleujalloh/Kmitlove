import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/candidate.dart';

/// Préférences de rencontre enregistrées sur l'appareil, par compte
/// (Paramètres → Préférences de rencontre) : elles servent de valeurs de
/// départ aux filtres de Découvrir à chaque ouverture de l'appli. Les
/// filtres rapides de Découvrir restent des réglages de la session.
class DiscoverPrefsStore {
  static String _key(String uid) => 'discover_prefs_$uid';

  static Future<void> save(String uid, DiscoverFilters f) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid),
      jsonEncode({
        'minAge': f.minAge,
        'maxAge': f.maxAge,
        'maxDistanceKm': f.maxDistanceKm,
        'country': f.country,
        'city': f.city,
        'gender': f.gender,
        'useMyLocation': f.useMyLocation,
      }),
    );
  }

  static Future<DiscoverFilters?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return DiscoverFilters(
        minAge: (m['minAge'] as num?)?.toInt(),
        maxAge: (m['maxAge'] as num?)?.toInt(),
        maxDistanceKm: (m['maxDistanceKm'] as num?)?.toInt() ?? 100,
        country: m['country'] as String?,
        city: m['city'] as String?,
        gender: m['gender'] as String?,
        useMyLocation: m['useMyLocation'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }
}
