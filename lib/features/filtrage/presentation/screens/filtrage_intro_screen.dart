import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../filtrage_controller.dart';

class FiltrageIntroScreen extends ConsumerWidget {
  const FiltrageIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fact_check_outlined, size: 56, color: AppColors.accent),
                const SizedBox(height: 18),
                Text(
                  context.l10n.filtrageIntroTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.filtrageIntroBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ref.read(filtrageControllerProvider.notifier).startAttempt(),
                    child: Text(context.l10n.startButton),
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
