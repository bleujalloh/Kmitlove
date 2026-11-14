import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../auth/presentation/auth_controller.dart';

/// Types de notification réglables (Paramètres → Notifications). Les clés
/// sont celles que lit `functions/src/shared/push.ts`.
const notificationTypeKeys = ['likes', 'messages', 'matches', 'community', 'events'];

/// Un de mes signalements (liste « Signalements »).
class MyReport {
  const MyReport({
    required this.id,
    required this.type,
    required this.reason,
    required this.createdAt,
    required this.resolved,
  });

  final String id;
  final String type; // user_report | post_report | ...
  final String reason;
  final DateTime? createdAt;
  final bool resolved;
}

/// Préférences de notification du membre, lues sur `user_status` (lisible
/// par son seul propriétaire) ; une clé absente vaut « activée ».
final notificationPrefsProvider = Provider<Map<String, bool>>((ref) {
  final raw = ref.watch(userStatusProvider).value?['notificationPrefs'];
  final map = raw is Map ? raw : const {};
  return {for (final k in notificationTypeKeys) k: map[k] != false};
});

/// Vrai quand le membre a masqué son profil de la découverte.
final profileHiddenProvider = Provider<bool>((ref) {
  return ref.watch(userStatusProvider).value?['profileHidden'] == true;
});

/// Vrai quand le membre a donné un consentement valide au traitement de ses
/// données sensibles (RGPD art. 9) — voir recordSensitiveConsent côté serveur.
bool hasSensitiveConsent(Map<String, dynamic>? status) {
  final c = status?['sensitiveConsent'];
  return c is Map && c['granted'] == true && c['version'] == kSensitiveConsentVersion;
}

/// Version du texte de consentement affichée par l'application — miroir de
/// `SENSITIVE_CONSENT_VERSION` (functions/src/config.ts), à changer ENSEMBLE.
/// Une version différente de celle du serveur fait redemander le consentement
/// (porte de l'écran) et le serveur refuse un consentement donné sur un autre
/// texte (recordSensitiveConsent).
const kSensitiveConsentVersion = 1;

final myReportsProvider = FutureProvider.autoDispose<List<MyReport>>((ref) async {
  final result = await ref.watch(cloudFunctionsProvider).httpsCallable('listMyReports').call();
  final data = Map<String, dynamic>.from(result.data as Map);
  return [
    for (final r in (data['reports'] as List))
      () {
        final m = Map<String, dynamic>.from(r as Map);
        final ms = (m['createdAtMs'] as num?)?.toInt() ?? 0;
        return MyReport(
          id: m['id'] as String,
          type: m['type'] as String? ?? '',
          reason: m['reason'] as String? ?? '',
          createdAt: ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null,
          resolved: m['resolved'] == true,
        );
      }(),
  ];
});

class SettingsController {
  SettingsController(this.ref);
  final Ref ref;

  Future<void> setNotificationPreference(String key, bool enabled) {
    return ref.read(cloudFunctionsProvider).httpsCallable('setNotificationPreferences').call({key: enabled});
  }

  Future<void> setSensitiveConsent(bool granted) {
    return ref
        .read(cloudFunctionsProvider)
        .httpsCallable('recordSensitiveConsent')
        .call({'granted': granted, 'version': kSensitiveConsentVersion});
  }

  Future<void> setProfileHidden(bool hidden) {
    return ref.read(cloudFunctionsProvider).httpsCallable('setProfileVisibility').call({'hidden': hidden});
  }
}

final settingsControllerProvider = Provider<SettingsController>(SettingsController.new);
