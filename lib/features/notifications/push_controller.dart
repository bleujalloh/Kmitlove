import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/presentation/auth_controller.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

/// Demande la permission de notification (obligatoire Android 13+/iOS),
/// récupère le jeton FCM de cet appareil et l'enregistre côté serveur
/// (registerFcmToken.ts) — jusqu'ici `firebase_messaging` était dans
/// pubspec.yaml sans jamais être utilisé : aucune notification (nouveau
/// match, message, like) n'était donc jamais envoyée
/// (docs/suivi-developpement.md section du 11/11/2026). Rejoué à chaque
/// lancement de MainShell : enregistrer deux fois le même jeton est sans
/// effet (arrayUnion), donc sans danger.
final pushRegistrationProvider = FutureProvider<void>((ref) async {
  final messaging = ref.watch(firebaseMessagingProvider);
  final settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.denied) return;

  // onRegistered couvre à la fois le tout premier enregistrement et tout
  // renouvellement ultérieur (réinstallation, rotation Firebase) — sans
  // ça, un appareil pourrait cesser de recevoir des notifications
  // silencieusement jusqu'à la prochaine ouverture d'app.
  ref.read(_lastKnownTokenProvider.notifier).state = null;
  messaging.onRegistered.listen((token) {
    ref.read(_lastKnownTokenProvider.notifier).state = token;
    ref.read(cloudFunctionsProvider).httpsCallable('registerFcmToken').call({'token': token});
  });
  await messaging.register();
});

/// Dernier jeton connu de cet appareil — retiré côté serveur à la
/// déconnexion (sinon un appareil où plus personne n'est connecté avec
/// ce compte continuerait à recevoir ses notifications).
final _lastKnownTokenProvider = StateProvider<String?>((ref) => null);

Future<void> unregisterCurrentPushToken(Ref ref) async {
  try {
    final token = ref.read(_lastKnownTokenProvider);
    if (token == null) return;
    await ref.read(cloudFunctionsProvider).httpsCallable('unregisterFcmToken').call({'token': token});
  } catch (_) {
    // Best-effort : jamais bloquant pour la déconnexion elle-même.
  }
}
