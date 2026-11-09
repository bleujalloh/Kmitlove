import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Écran d'accueil et charte communautaire — fidèle au prototype visuel
/// validé (artifact Kamalove, Main.dc.html).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _accepted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kamalove',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'rencontres et communauté kamites',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(width: 36, height: 3, color: AppColors.accent),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                children: [
                  const Text(
                    'Avant de commencer',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Cette application rassemble des personnes qui se reconnaissent dans l'identité et les valeurs kamites, pour des rencontres amoureuses sérieuses. "
                    "L'adhésion repose sur ta connaissance et ton engagement envers cette culture — jamais sur ton origine ou ton apparence.",
                    style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A4038)),
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
                      children: const [
                        Text(
                          'CHARTE COMMUNAUTAIRE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 14),
                        _CharteItem(
                          "Je m'identifie à la communauté et à l'histoire kamite et je m'engage à la respecter.",
                        ),
                        SizedBox(height: 14),
                        _CharteItem(
                          'Je comprends qu\'un questionnaire de connaissance et de valeurs valide mon inscription.',
                        ),
                        SizedBox(height: 14),
                        _CharteItem(
                          "Je m'engage au respect, à l'honnêteté et à la bonne conduite envers les autres membres.",
                        ),
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
                    title: const Text(
                      "J'ai lu et j'accepte la charte communautaire ainsi que les conditions d'utilisation.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF4A4038)),
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
                  child: const Text('Continuer'),
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
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF4A4038)),
          ),
        ),
      ],
    );
  }
}
