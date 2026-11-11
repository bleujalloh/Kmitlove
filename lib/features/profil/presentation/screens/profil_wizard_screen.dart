import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/profil.dart';
import '../profil_controller.dart';
import 'photos_section.dart';

/// Création du profil en plusieurs étapes, une question à la fois —
/// remarqué le 11/11 : l'ancien formulaire (un seul grand écran à faire
/// défiler) ne ressemblait à aucune application de rencontre connue.
/// Structure inspirée des parcours d'inscription courants (Tinder, Happn,
/// Meetic), adaptée à l'identité visuelle de MERUT et aux valeurs du
/// cahier des charges : genre limité à Homme/Femme, aucune option
/// contraire aux valeurs kamites (pas de "relation libre", pas de tags
/// hors sujet) n'a jamais existé dans ce modèle de données pour commencer.
/// Réservé à la création initiale — modifier un profil existant reste
/// sur l'écran à défilement unique (profil_edit_screen.dart), plus adapté
/// à un ajustement ponctuel qu'à un nouveau parcours complet.
class ProfilWizardScreen extends ConsumerStatefulWidget {
  const ProfilWizardScreen({super.key});

  @override
  ConsumerState<ProfilWizardScreen> createState() => _ProfilWizardScreenState();
}

enum _Step {
  identite,
  genre,
  recherche,
  intention,
  lieu,
  bio,
  qualites,
  interets,
  details,
  modeDeVie,
  photos,
}

class _ProfilWizardScreenState extends ConsumerState<ProfilWizardScreen> {
  int _stepIndex = 0;

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _professionController = TextEditingController();
  final _languagesController = TextEditingController();
  final _interestsController = TextEditingController();
  final _culturalOriginsController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _heightController = TextEditingController();
  final _educationController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  final Set<String> _seekingGenders = {};
  String? _relationshipIntent;
  String? _smokingHabit;
  String? _drinkingHabit;
  String? _childrenStatus;
  final Set<String> _qualities = {};

  static const _steps = _Step.values;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _professionController.dispose();
    _languagesController.dispose();
    _interestsController.dispose();
    _culturalOriginsController.dispose();
    _lookingForController.dispose();
    _heightController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  bool _isAdult(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age -= 1;
    }
    return age >= 18;
  }

  Future<void> _pickBirthDate() async {
    final eighteenYearsAgo = DateTime(
      DateTime.now().year - 18,
      DateTime.now().month,
      DateTime.now().day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: eighteenYearsAgo,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  bool get _canProceed {
    switch (_steps[_stepIndex]) {
      case _Step.identite:
        return _nameController.text.trim().isNotEmpty &&
            _birthDate != null &&
            _isAdult(_birthDate!);
      case _Step.genre:
        return _gender != null;
      case _Step.recherche:
        return _seekingGenders.isNotEmpty;
      case _Step.intention:
        return _relationshipIntent != null;
      case _Step.lieu:
        return _countryController.text.trim().isNotEmpty && _cityController.text.trim().isNotEmpty;
      case _Step.bio:
        return _bioController.text.trim().isNotEmpty;
      // Les étapes suivantes sont facultatives (cahier des charges
      // section 4.2) : toujours possible d'avancer sans rien remplir.
      case _Step.qualites:
      case _Step.interets:
      case _Step.details:
      case _Step.modeDeVie:
      case _Step.photos:
        return true;
    }
  }

  void _next() {
    if (_stepIndex == _steps.length - 1) {
      _finish();
      return;
    }
    if (_birthDate != null && !_isAdult(_birthDate!) && _steps[_stepIndex] == _Step.identite) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.mustBeAdult)));
      return;
    }
    setState(() => _stepIndex += 1);
  }

  void _back() {
    if (_stepIndex == 0) return;
    setState(() => _stepIndex -= 1);
  }

  Future<void> _finish() async {
    final profil = Profil(
      displayName: _nameController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender!,
      seekingGenders: _seekingGenders.toList(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      relationshipIntent: _relationshipIntent!,
      profession: _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
      languages: _splitCsv(_languagesController.text),
      interests: _splitCsv(_interestsController.text),
      culturalOrigins: _splitCsv(_culturalOriginsController.text),
      heightCm: int.tryParse(_heightController.text.trim()),
      educationLevel: _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
      smokingHabit: _smokingHabit,
      drinkingHabit: _drinkingHabit,
      childrenStatus: _childrenStatus,
      lookingFor: _lookingForController.text.trim().isEmpty ? null : _lookingForController.text.trim(),
      qualities: _qualities.toList(),
    );
    await ref.read(profilControllerProvider.notifier).save(profil);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilControllerProvider);
    final isLast = _stepIndex == _steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _stepIndex == 0 ? null : _back,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_stepIndex + 1) / _steps.length,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: SingleChildScrollView(child: _buildStep(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                children: [
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        context.l10n.profileSaveFailed,
                        style: const TextStyle(color: AppColors.accent, fontSize: 13),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_canProceed && !state.isLoading) ? _next : null,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isLast ? context.l10n.saveMyProfile : context.l10n.continueButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_steps[_stepIndex]) {
      case _Step.identite:
        return _StepIdentite(
          nameController: _nameController,
          birthDate: _birthDate,
          onPickBirthDate: _pickBirthDate,
          onChanged: () => setState(() {}),
        );
      case _Step.genre:
        return _StepChoiceList(
          title: context.l10n.wizardGenderTitle,
          options: Gender.all,
          labelOf: (v) => Gender.label(v, context.l10n),
          selected: _gender,
          onSelect: (v) => setState(() => _gender = v),
        );
      case _Step.recherche:
        return _StepMultiChoiceList(
          title: context.l10n.wizardSeekingTitle,
          options: Gender.all,
          labelOf: (v) => Gender.label(v, context.l10n),
          selected: _seekingGenders,
          onToggle: (v, sel) => setState(
            () => sel ? _seekingGenders.add(v) : _seekingGenders.remove(v),
          ),
        );
      case _Step.intention:
        return _StepChoiceList(
          title: context.l10n.wizardIntentTitle,
          options: RelationshipIntent.all,
          labelOf: (v) => RelationshipIntent.label(v, context.l10n),
          selected: _relationshipIntent,
          onSelect: (v) => setState(() => _relationshipIntent = v),
        );
      case _Step.lieu:
        return _StepLieu(
          countryController: _countryController,
          cityController: _cityController,
          onChanged: () => setState(() {}),
        );
      case _Step.bio:
        return _StepBio(bioController: _bioController, onChanged: () => setState(() {}));
      case _Step.qualites:
        return _StepMultiChoiceWrap(
          title: context.l10n.wizardQualitiesTitle,
          subtitle: context.l10n.qualitiesSectionHint,
          options: PersonalQuality.all,
          labelOf: (v) => PersonalQuality.label(v, context.l10n),
          selected: _qualities,
          onToggle: (v, sel) => setState(() => sel ? _qualities.add(v) : _qualities.remove(v)),
        );
      case _Step.interets:
        return _StepInterets(
          interestsController: _interestsController,
          culturalOriginsController: _culturalOriginsController,
          lookingForController: _lookingForController,
        );
      case _Step.details:
        return _StepDetails(
          professionController: _professionController,
          languagesController: _languagesController,
          heightController: _heightController,
          educationController: _educationController,
        );
      case _Step.modeDeVie:
        return _StepModeDeVie(
          smokingHabit: _smokingHabit,
          drinkingHabit: _drinkingHabit,
          childrenStatus: _childrenStatus,
          onSmokingChanged: (v) => setState(() => _smokingHabit = v),
          onDrinkingChanged: (v) => setState(() => _drinkingHabit = v),
          onChildrenChanged: (v) => setState(() => _childrenStatus = v),
        );
      case _Step.photos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.wizardPhotosTitle, style: _titleStyle),
            const SizedBox(height: 18),
            const PhotosSection(),
          ],
        );
    }
  }
}

const _titleStyle = TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.2);

class _StepIdentite extends StatelessWidget {
  const _StepIdentite({
    required this.nameController,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardIdentityTitle, style: _titleStyle),
        const SizedBox(height: 24),
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: context.l10n.firstNameOrNickname),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: () async {
            onPickBirthDate();
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: context.l10n.birthDateLabel),
            child: Text(
              birthDate == null
                  ? context.l10n.chooseDate
                  : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
            ),
          ),
        ),
      ],
    );
  }
}

class _StepLieu extends StatelessWidget {
  const _StepLieu({
    required this.countryController,
    required this.cityController,
    required this.onChanged,
  });

  final TextEditingController countryController;
  final TextEditingController cityController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardLocationTitle, style: _titleStyle),
        const SizedBox(height: 24),
        TextField(
          controller: countryController,
          decoration: InputDecoration(labelText: context.l10n.countryLabel),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: cityController,
          decoration: InputDecoration(labelText: context.l10n.cityLabel),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _StepBio extends StatelessWidget {
  const _StepBio({required this.bioController, required this.onChanged});

  final TextEditingController bioController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardBioTitle, style: _titleStyle),
        const SizedBox(height: 8),
        Text(context.l10n.wizardBioSubtitle, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        TextField(
          controller: bioController,
          maxLines: 5,
          decoration: InputDecoration(labelText: context.l10n.bioLabel),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _StepInterets extends StatelessWidget {
  const _StepInterets({
    required this.interestsController,
    required this.culturalOriginsController,
    required this.lookingForController,
  });

  final TextEditingController interestsController;
  final TextEditingController culturalOriginsController;
  final TextEditingController lookingForController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardInterestsTitle, style: _titleStyle),
        const SizedBox(height: 24),
        TextField(
          controller: interestsController,
          decoration: InputDecoration(labelText: context.l10n.interestsLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: culturalOriginsController,
          decoration: InputDecoration(labelText: context.l10n.culturalOriginsLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: lookingForController,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.lookingForLabel),
        ),
      ],
    );
  }
}

class _StepDetails extends StatelessWidget {
  const _StepDetails({
    required this.professionController,
    required this.languagesController,
    required this.heightController,
    required this.educationController,
  });

  final TextEditingController professionController;
  final TextEditingController languagesController;
  final TextEditingController heightController;
  final TextEditingController educationController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardDetailsTitle, style: _titleStyle),
        const SizedBox(height: 24),
        TextField(
          controller: professionController,
          decoration: InputDecoration(labelText: context.l10n.professionLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: languagesController,
          decoration: InputDecoration(labelText: context.l10n.languagesLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: heightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: context.l10n.heightLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: educationController,
          decoration: InputDecoration(labelText: context.l10n.educationLevelLabel),
        ),
      ],
    );
  }
}

class _StepModeDeVie extends StatelessWidget {
  const _StepModeDeVie({
    required this.smokingHabit,
    required this.drinkingHabit,
    required this.childrenStatus,
    required this.onSmokingChanged,
    required this.onDrinkingChanged,
    required this.onChildrenChanged,
  });

  final String? smokingHabit;
  final String? drinkingHabit;
  final String? childrenStatus;
  final ValueChanged<String?> onSmokingChanged;
  final ValueChanged<String?> onDrinkingChanged;
  final ValueChanged<String?> onChildrenChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardLifestyleTitle, style: _titleStyle),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: smokingHabit,
          decoration: InputDecoration(labelText: context.l10n.smokingLabel),
          items: LifestyleHabit.all
              .map((v) => DropdownMenuItem(value: v, child: Text(LifestyleHabit.label(v, context.l10n))))
              .toList(),
          onChanged: onSmokingChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: drinkingHabit,
          decoration: InputDecoration(labelText: context.l10n.drinkingLabel),
          items: LifestyleHabit.all
              .map((v) => DropdownMenuItem(value: v, child: Text(LifestyleHabit.label(v, context.l10n))))
              .toList(),
          onChanged: onDrinkingChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: childrenStatus,
          decoration: InputDecoration(labelText: context.l10n.childrenLabel),
          items: ChildrenStatus.all
              .map((v) => DropdownMenuItem(value: v, child: Text(ChildrenStatus.label(v, context.l10n))))
              .toList(),
          onChanged: onChildrenChanged,
        ),
      ],
    );
  }
}

class _StepChoiceList extends StatelessWidget {
  const _StepChoiceList({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String Function(String) labelOf;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 24),
        ...options.map((o) {
          final isSelected = o == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelect(o),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentSoft : Colors.white,
                  border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelOf(o),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StepMultiChoiceList extends StatelessWidget {
  const _StepMultiChoiceList({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final String Function(String) labelOf;
  final Set<String> selected;
  final void Function(String, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 24),
        ...options.map((o) {
          final isSelected = selected.contains(o);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onToggle(o, !isSelected),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentSoft : Colors.white,
                  border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelOf(o),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StepMultiChoiceWrap extends StatelessWidget {
  const _StepMultiChoiceWrap({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final String Function(String) labelOf;
  final Set<String> selected;
  final void Function(String, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isSelected = selected.contains(o);
            return FilterChip(
              label: Text(labelOf(o)),
              selected: isSelected,
              selectedColor: AppColors.accentSoft,
              onSelected: (v) => onToggle(o, v),
            );
          }).toList(),
        ),
      ],
    );
  }
}
