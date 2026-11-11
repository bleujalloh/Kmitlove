import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/kamite_motif.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Écran d'accueil et charte communautaire — fidèle au prototype visuel
/// validé (artifact MERUT, Main.dc.html).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Décoché par défaut : la charte/CGU ne sont pas réputées acceptées
  // tant que le membre ne coche pas lui-même la case (bug trouvé sur
  // appareil réel le 10/11 — la case partait cochée, rendant
  // l'acceptation purement décorative).
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KamiteMotif(height: 150),
                  const SizedBox(height: 8),
                  Text('MERUT', style: AppTypography.brand(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(context.l10n.onboardingTagline, style: AppTypography.tagline()),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                children: [
                  Text(
                    context.l10n.onboardingBeforeStart,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.onboardingIntro,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.onboardingCharterTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _CharteItem(context.l10n.onboardingCharter1),
                        const SizedBox(height: 14),
                        _CharteItem(context.l10n.onboardingCharter2),
                        const SizedBox(height: 14),
                        _CharteItem(context.l10n.onboardingCharter3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accent,
                    title: Text(
                      context.l10n.onboardingAcceptCharter,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepted ? widget.onAccepted : null,
                  child: Text(context.l10n.continueButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharteItem extends StatelessWidget {
  const _CharteItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 12, color: AppColors.noirProfond),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}
