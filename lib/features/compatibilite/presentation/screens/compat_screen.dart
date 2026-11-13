import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/compat_question.dart';
import '../compat_controller.dart';

/// Test de compatibilité kamite (cahier des charges section 4.3).
/// Questions reformulées en affirmations notées de 1 à 5 pour permettre
/// le calcul de similarité (docs/banque-questions-compatibilite.md).
/// Optionnel : rien n'empêche d'utiliser l'app sans l'avoir complété,
/// seul le filtrage à l'inscription est bloquant.
class CompatScreen extends ConsumerStatefulWidget {
  const CompatScreen({super.key});

  @override
  ConsumerState<CompatScreen> createState() => _CompatScreenState();
}

class _CompatScreenState extends ConsumerState<CompatScreen> {
  final Map<String, int> _answers = {};
  bool _initialized = false;

  void _initializeFrom(Map<String, int> existing) {
    if (_initialized) return;
    _answers.addAll(existing);
    _initialized = true;
  }

  Future<void> _submit() async {
    final ok = await ref.read(compatControllerProvider.notifier).saveAnswers(_answers);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.answersSaved)),
      );
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.answersSaveFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAsync = ref.watch(compatQuestionBankProvider);
    final existingAsync = ref.watch(myCompatAnswersProvider);
    final saveState = ref.watch(compatControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compatTestTitle)),
      body: bankAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.compatQuestionsLoadFailed)),
        data: (questions) {
          existingAsync.whenData(_initializeFrom);

          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.compatTestNotAvailable,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final byTheme = <String, List<CompatQuestion>>{};
          for (final q in questions) {
            byTheme.putIfAbsent(q.theme, () => []).add(q);
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    children: [
                      Text(
                        context.l10n.compatTestInstructions,
                        style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      for (final entry in byTheme.entries) ...[
                        Text(
                          compatThemeLabel(entry.key, context.l10n).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final q in entry.value) _QuestionTile(
                              question: q,
                              value: _answers[q.id],
                              onChanged: (v) => setState(() => _answers[q.id] = v),
                            ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveState.isLoading ? null : _submit,
                      child: saveState.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                            )
                          : Text(context.l10n.saveMyAnswers),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.value, required this.onChanged});

  final CompatQuestion question;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: TextStyle(fontSize: 14.5, color: AppColors.ink)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final v = i + 1;
              final selected = value == v;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onChanged(v),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentSoft : AppColors.background,
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$v',
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
