import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n_extensions.dart';

/// Exécute une action serveur déclenchée par un bouton ET en annonce toujours
/// le résultat : confirmation (si `success` est fourni), limite de fréquence
/// atteinte, ou échec. Sans cela, une action qui échoue — réseau, refus du
/// serveur, plantage — ne disait rien du tout : l'erreur partait dans le vide
/// et le membre croyait que le bouton n'avait rien fait ou avait réussi
/// (audit des défauts cachés du 14/11/2026 : annulation de participation,
/// invitation, acceptation d'une demande, lieu précis, favori).
///
/// Renvoie `true` si l'action a réussi.
Future<bool> runWithFeedback(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  String? failure,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    await action();
    if (success != null) messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } catch (e) {
    final rateLimited = e is FirebaseFunctionsException && e.code == 'resource-exhausted';
    messenger.showSnackBar(
      SnackBar(content: Text(rateLimited ? l10n.messageRateLimited : (failure ?? l10n.genericError))),
    );
    return false;
  }
}
