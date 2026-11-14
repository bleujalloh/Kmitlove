import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/age.dart';
import '../../../../core/widgets/country_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/profil.dart';
import '../profil_controller.dart';
import 'photos_section.dart';

/// UNIQUE éditeur du profil (règlement permanent, section 19 : pas de doublon).
///
/// Création : une question à la fois — l'ancien formulaire (un seul grand écran
/// à défilement) ne ressemblait à aucune application de rencontre connue.
/// Structure inspirée des parcours d'inscription courants (Tinder, Happn,
/// Meetic), adaptée à l'identité visuelle de MERUT et aux valeurs du cahier des
/// charges : genre limité à Homme/Femme, aucune option contraire aux valeurs
/// kamites.
///
/// Modification (`existing` fourni, 14/11/2026) : au lieu d'un second formulaire
/// qui saisissait les mêmes champs avec du code recopié, la MÊME liste d'étapes
/// s'ouvre sur une vue d'ensemble (une ligne par rubrique, avec son résumé) ;
/// toucher une rubrique ouvre exactement l'écran de l'étape correspondante. Le
/// genre et la date de naissance restent figés (saveProfil.ts les refuse après
/// l'inscription).
class ProfilWizardScreen extends ConsumerStatefulWidget {
  const ProfilWizardScreen({super.key, this.existing});

  final Profil? existing;

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

  bool get _editMode => widget.existing != null;

  /// Rubrique ouverte en modification (null = vue d'ensemble).
  _Step? _editingStep;

  final _nameController = TextEditingController();
  String? _country;
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _professionController = TextEditingController();
  final _languagesController = TextEditingController();
  final _interestsController = TextEditingController();
  final _culturalOriginsController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _valuesController = TextEditingController();
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

  /// Rubriques proposées en modification : toutes sauf le genre (figé).
  static final _editSteps = _Step.values.where((s) => s != _Step.genre).toList();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _nameController.text = e.displayName;
    _birthDate = e.birthDate;
    _gender = e.gender;
    _seekingGenders.addAll(e.seekingGenders);
    _relationshipIntent = e.relationshipIntent;
    _country = e.country;
    _cityController.text = e.city;
    _bioController.text = e.bio;
    _professionController.text = e.profession ?? '';
    _languagesController.text = e.languages.join(', ');
    _interestsController.text = e.interests.join(', ');
    _culturalOriginsController.text = e.culturalOrigins.join(', ');
    _lookingForController.text = e.lookingFor ?? '';
    _valuesController.text = e.values ?? '';
    _heightController.text = e.heightCm?.toString() ?? '';
    _educationController.text = e.educationLevel ?? '';
    _smokingHabit = e.smokingHabit;
    _drinkingHabit = e.drinkingHabit;
    _childrenStatus = e.childrenStatus;
    _qualities.addAll(e.qualities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _professionController.dispose();
    _languagesController.dispose();
    _interestsController.dispose();
    _culturalOriginsController.dispose();
    _lookingForController.dispose();
    _valuesController.dispose();
    _heightController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  bool _isAdult(DateTime birthDate) => ageFromBirthDate(birthDate) >= 18;

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

  bool get _canProceed => _canProceedFor(_steps[_stepIndex]);

  bool _canProceedFor(_Step step) {
    switch (step) {
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
        return (_country?.trim().isNotEmpty ?? false) &&
            _cityController.text.trim().isNotEmpty;
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
    if (_birthDate != null &&
        !_isAdult(_birthDate!) &&
        _steps[_stepIndex] == _Step.identite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.mustBeAdult)));
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
      country: (_country ?? '').trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      relationshipIntent: _relationshipIntent!,
      profession: _professionController.text.trim().isEmpty
          ? null
          : _professionController.text.trim(),
      languages: _splitCsv(_languagesController.text),
      interests: _splitCsv(_interestsController.text),
      culturalOrigins: _splitCsv(_culturalOriginsController.text),
      heightCm: int.tryParse(_heightController.text.trim()),
      educationLevel: _educationController.text.trim().isEmpty
          ? null
          : _educationController.text.trim(),
      smokingHabit: _smokingHabit,
      drinkingHabit: _drinkingHabit,
      childrenStatus: _childrenStatus,
      lookingFor: _lookingForController.text.trim().isEmpty
          ? null
          : _lookingForController.text.trim(),
      qualities: _qualities.toList(),
      values: _valuesController.text.trim().isEmpty ? null : _valuesController.text.trim(),
    );
    final ok = await ref.read(profilControllerProvider.notifier).save(profil);
    // En modification : confirmation visible et retour à l'écran précédent (un
    // enregistrement réussi doit se voir). En création, AuthGate bascule seul
    // vers l'appli dès que le profil existe.
    if (ok && _editMode && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
      Navigator.of(context).pop();
    }
  }

  /// Résumé d'une rubrique (ligne de la vue d'ensemble) ; vide si rien à dire.
  String _summaryOf(_Step step) {
    final l10n = context.l10n;
    String join(Iterable<String> parts) => parts.where((p) => p.trim().isNotEmpty).join(' · ');
    switch (step) {
      case _Step.identite:
        return join([_nameController.text.trim()]);
      case _Step.genre:
        return _gender == null ? '' : Gender.label(_gender!, l10n);
      case _Step.recherche:
        return join(_seekingGenders.map((g) => Gender.label(g, l10n)));
      case _Step.intention:
        return _relationshipIntent == null ? '' : RelationshipIntent.label(_relationshipIntent!, l10n);
      case _Step.lieu:
        return join([_cityController.text.trim(), _country ?? '']);
      case _Step.bio:
        final bio = _bioController.text.trim();
        return bio.length > 70 ? '${bio.substring(0, 70)}…' : bio;
      case _Step.qualites:
        return _qualities.isEmpty ? '' : join(_qualities.map((q) => PersonalQuality.label(q, l10n)));
      case _Step.interets:
        return join([_interestsController.text.trim(), _culturalOriginsController.text.trim()]);
      case _Step.details:
        return join([_professionController.text.trim(), _languagesController.text.trim(), _educationController.text.trim()]);
      case _Step.modeDeVie:
        return join([
          if (_smokingHabit != null) LifestyleHabit.label(_smokingHabit!, l10n),
          if (_drinkingHabit != null) LifestyleHabit.label(_drinkingHabit!, l10n),
          if (_childrenStatus != null) ChildrenStatus.label(_childrenStatus!, l10n),
        ]);
      case _Step.photos:
        return '';
    }
  }

  String _sectionTitleOf(_Step step) {
    final l10n = context.l10n;
    switch (step) {
      case _Step.identite:
        return l10n.profileSectionIdentity;
      case _Step.genre:
        return l10n.profileSectionGender;
      case _Step.recherche:
        return l10n.profileSectionSeeking;
      case _Step.intention:
        return l10n.profileSectionIntent;
      case _Step.lieu:
        return l10n.profileSectionPlace;
      case _Step.bio:
        return l10n.aboutMeSectionTitle;
      case _Step.qualites:
        return l10n.profileSectionQualities;
      case _Step.interets:
        return l10n.profileSectionInterestsEtc;
      case _Step.details:
        return l10n.profileSectionDetails;
      case _Step.modeDeVie:
        return l10n.profileSectionLifestyle;
      case _Step.photos:
        return l10n.photosSectionTitle;
    }
  }

  Widget _buildEditor(BuildContext context) {
    final state = ref.watch(profilControllerProvider);
    final l10n = context.l10n;
    final step = _editingStep;

    if (step != null) {
      // Une rubrique : exactement l'écran de l'étape de création.
      return Scaffold(
        appBar: AppBar(
          title: Text(_sectionTitleOf(step)),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _editingStep = null)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                  child: _buildStep(context, step),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceedFor(step) ? () => setState(() => _editingStep = null) : null,
                    child: Text(l10n.profileSectionDone),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Vue d'ensemble : une ligne par rubrique.
    final allValid = _editSteps.every(_canProceedFor);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourProfile)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  for (final s in _editSteps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: AppColors.backgroundSoft,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          title: Text(_sectionTitleOf(s), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            _canProceedFor(s)
                                ? _summaryOf(s)
                                : l10n.profileSectionIncomplete,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _canProceedFor(s) ? AppColors.ink : AppColors.accent),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => setState(() => _editingStep = s),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(l10n.profileSaveFailed, style: TextStyle(color: AppColors.accent, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (allValid && !state.isLoading) ? _finish : null,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                            )
                          : Text(l10n.saveMyProfile),
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

  @override
  Widget build(BuildContext context) {
    if (_editMode) return _buildEditor(context);
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
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: LinearProgressIndicator(
                        value: (_stepIndex + 1) / _steps.length,
                        minHeight: 5,
                        backgroundColor: AppColors.accentSoft,
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
                child: SingleChildScrollView(child: _buildStep(context, _steps[_stepIndex])),
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
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_canProceed && !state.isLoading)
                          ? _next
                          : null,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.noirProfond,
                              ),
                            )
                          : Text(
                              isLast
                                  ? context.l10n.saveMyProfile
                                  : context.l10n.continueButton,
                            ),
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

  Widget _buildStep(BuildContext context, _Step step) {
    switch (step) {
      case _Step.identite:
        return _StepIdentite(
          nameController: _nameController,
          birthDate: _birthDate,
          // Fixée à l'inscription (saveProfil.ts refuse tout changement ensuite).
          onPickBirthDate: _editMode ? null : _pickBirthDate,
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
          country: _country,
          onCountryChanged: (v) => setState(() => _country = v),
          cityController: _cityController,
          onChanged: () => setState(() {}),
        );
      case _Step.bio:
        return _StepBio(
          bioController: _bioController,
          onChanged: () => setState(() {}),
        );
      case _Step.qualites:
        return _StepMultiChoiceWrap(
          title: context.l10n.wizardQualitiesTitle,
          subtitle: context.l10n.qualitiesSectionHint,
          options: PersonalQuality.all,
          labelOf: (v) => PersonalQuality.label(v, context.l10n),
          selected: _qualities,
          onToggle: (v, sel) =>
              setState(() => sel ? _qualities.add(v) : _qualities.remove(v)),
        );
      case _Step.interets:
        return _StepInterets(
          interestsController: _interestsController,
          culturalOriginsController: _culturalOriginsController,
          lookingForController: _lookingForController,
          valuesController: _valuesController,
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

final _titleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: AppColors.ink,
  height: 1.2,
);

class _StepIdentite extends StatelessWidget {
  const _StepIdentite({
    required this.nameController,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final DateTime? birthDate;

  /// null = date figée (modification : saveProfil.ts refuse tout changement).
  final VoidCallback? onPickBirthDate;
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
          decoration: InputDecoration(
            labelText: context.l10n.firstNameOrNickname,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: onPickBirthDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.birthDateLabel,
              helperText: onPickBirthDate == null ? context.l10n.identityFieldLocked : null,
              helperMaxLines: 2,
            ),
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
    required this.country,
    required this.onCountryChanged,
    required this.cityController,
    required this.onChanged,
  });

  final String? country;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController cityController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.wizardLocationTitle, style: _titleStyle),
        const SizedBox(height: 24),
        CountryField(
          value: country,
          label: context.l10n.countryLabel,
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 14),
        CityField(
          controller: cityController,
          country: country,
          label: context.l10n.cityLabel,
          onChanged: onChanged,
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
        Text(
          context.l10n.wizardBioSubtitle,
          style: TextStyle(color: AppColors.muted),
        ),
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
    required this.valuesController,
  });

  final TextEditingController interestsController;
  final TextEditingController culturalOriginsController;
  final TextEditingController lookingForController;
  final TextEditingController valuesController;

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
          decoration: InputDecoration(
            labelText: context.l10n.culturalOriginsLabel,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: lookingForController,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.lookingForLabel),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: valuesController,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.valuesLabel),
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
          decoration: InputDecoration(
            labelText: context.l10n.educationLevelLabel,
          ),
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
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(LifestyleHabit.label(v, context.l10n)),
                ),
              )
              .toList(),
          onChanged: onSmokingChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: drinkingHabit,
          decoration: InputDecoration(labelText: context.l10n.drinkingLabel),
          items: LifestyleHabit.all
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(LifestyleHabit.label(v, context.l10n)),
                ),
              )
              .toList(),
          onChanged: onDrinkingChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: childrenStatus,
          decoration: InputDecoration(labelText: context.l10n.childrenLabel),
          items: ChildrenStatus.all
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(ChildrenStatus.label(v, context.l10n)),
                ),
              )
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
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentSoft
                      : AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelOf(o),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppColors.accent),
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
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentSoft
                      : AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelOf(o),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppColors.accent),
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
        Text(subtitle, style: TextStyle(color: AppColors.muted)),
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
