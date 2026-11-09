import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../filtrage_controller.dart';

class FiltrageResultScreen extends ConsumerWidget {
  const FiltrageResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = ref.watch(filtrageControllerProvider).value;
    final result = attempt?.result;
    if (result == null) return const SizedBox.shrink();
    final (passed, score) = result;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.celebration_outlined : Icons.info_outline,
                  size: 56,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  passed ? 'Bienvenue dans la communauté' : "Ce n'est pas passé cette fois",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? 'Ton engagement envers la culture et les valeurs kamites est confirmé. Ton compte est activé.'
                      : "Score obtenu : ${(score * 100).round()} %. Tu peux retenter dans quelques jours, ou demander une révision par un modérateur si tu penses qu'il y a une erreur.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (passed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ref.read(filtrageControllerProvider.notifier).reset(),
                      child: const Text('Continuer'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(filtrageRepositoryProvider).requestReview();
                        ref.read(filtrageControllerProvider.notifier).reset();
                      },
                      child: const Text('Demander une révision humaine'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
