/// Reessaie une opération asynchrone qui peut échouer de façon
/// transitoire (ex. appel réseau Storage juste après le démarrage à
/// froid de l'app, avant que le jeton App Check/Play Integrity soit
/// prêt) — jamais pour masquer une vraie erreur permanente : après
/// [attempts] essais, l'erreur d'origine remonte normalement.
Future<T> retryAsync<T>(
  Future<T> Function() action, {
  int attempts = 3,
  Duration initialDelay = const Duration(milliseconds: 400),
}) async {
  for (var i = 0; i < attempts; i++) {
    try {
      return await action();
    } catch (_) {
      if (i == attempts - 1) rethrow;
      await Future.delayed(initialDelay * (i + 1));
    }
  }
  throw StateError('unreachable');
}
