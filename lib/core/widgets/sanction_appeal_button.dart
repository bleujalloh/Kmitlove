import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

/// Bouton de recours contre une sanction (docs/regles-messagerie-
/// securite.md section 3) — réutilisé par ParametresScreen (pour un
/// simple avertissement, qui laisse le compte actif) et SanctionScreen
/// (pour une suspension/un bannissement, qui n'atteint jamais Paramètres
/// — voir core/router/auth_gate.dart).
class SanctionAppealButton extends ConsumerStatefulWidget {
  const SanctionAppealButton({super.key, required this.appealPending});

  final bool appealPending;

  @override
  ConsumerState<SanctionAppealButton> createState() => _SanctionAppealButtonState();
}

class _SanctionAppealButtonState extends ConsumerState<SanctionAppealButton> {
  bool _sending = false;

  Future<void> _requestAppeal() async {
    setState(() => _sending = true);
    try {
      await ref.read(cloudFunctionsProvider).httpsCallable('requestSanctionAppeal').call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recours envoyé, un modérateur va l\'examiner.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer le recours, réessaie.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: widget.appealPending || _sending ? null : _requestAppeal,
      child: Text(widget.appealPending ? 'Recours en cours de traitement' : 'Contester cette sanction'),
    );
  }
}
