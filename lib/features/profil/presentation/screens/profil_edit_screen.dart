import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/profil.dart';
import '../profil_controller.dart';
import 'photos_section.dart';

const _genders = ['Femme', 'Homme', 'Autre'];

/// Création/édition du profil (cahier des charges section 4.2), avec les
/// photos (validation humaine/délai 48h, docs/regles-messagerie-securite.md).
class ProfilEditScreen extends ConsumerStatefulWidget {
  const ProfilEditScreen({super.key, this.existing});

  final Profil? existing;

  @override
  ConsumerState<ProfilEditScreen> createState() => _ProfilEditScreenState();
}

class _ProfilEditScreenState extends ConsumerState<ProfilEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.displayName);
  late final _countryController = TextEditingController(text: widget.existing?.country);
  late final _cityController = TextEditingController(text: widget.existing?.city);
  late final _bioController = TextEditingController(text: widget.existing?.bio);
  late final _professionController = TextEditingController(text: widget.existing?.profession);
  late final _languagesController =
      TextEditingController(text: widget.existing?.languages.join(', '));
  late final _interestsController =
      TextEditingController(text: widget.existing?.interests.join(', '));
  late final _culturalOriginsController =
      TextEditingController(text: widget.existing?.culturalOrigins.join(', '));
  late final _valuesController = TextEditingController(text: widget.existing?.values);
  late final _heightController =
      TextEditingController(text: widget.existing?.heightCm?.toString());
  late final _educationController = TextEditingController(text: widget.existing?.educationLevel);
  late final _lookingForController = TextEditingController(text: widget.existing?.lookingFor);

  DateTime? _birthDate;
  String _gender = _genders.first;
  final Set<String> _seekingGenders = {};
  String _relationshipIntent = RelationshipIntent.serieuse;
  String? _smokingHabit;
  String? _drinkingHabit;
  String? _childrenStatus;
  final Set<String> _qualities = {};

  @override
  void initState() {
    super.initState();
    _birthDate = widget.existing?.birthDate;
    _gender = widget.existing?.gender ?? _genders.first;
    _seekingGenders.addAll(widget.existing?.seekingGenders ?? []);
    _relationshipIntent = widget.existing?.relationshipIntent ?? RelationshipIntent.serieuse;
    _smokingHabit = widget.existing?.smokingHabit;
    _drinkingHabit = widget.existing?.drinkingHabit;
    _childrenStatus = widget.existing?.childrenStatus;
    _qualities.addAll(widget.existing?.qualities ?? []);
  }

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
    _valuesController.dispose();
    _heightController.dispose();
    _educationController.dispose();
    _lookingForController.dispose();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Indique ta date de naissance.')));
      return;
    }
    if (!_isAdult(_birthDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MERUT est réservé aux personnes de 18 ans et plus.')),
      );
      return;
    }
    if (_seekingGenders.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choisis au moins une préférence de recherche.')));
      return;
    }

    final profil = Profil(
      displayName: _nameController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender,
      seekingGenders: _seekingGenders.toList(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      relationshipIntent: _relationshipIntent,
      profession: _professionController.text.trim().isEmpty
          ? null
          : _professionController.text.trim(),
      languages: _splitCsv(_languagesController.text),
      interests: _splitCsv(_interestsController.text),
      culturalOrigins: _splitCsv(_culturalOriginsController.text),
      values: _valuesController.text.trim().isEmpty ? null : _valuesController.text.trim(),
      heightCm: int.tryParse(_heightController.text.trim()),
      educationLevel:
          _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
      smokingHabit: _smokingHabit,
      drinkingHabit: _drinkingHabit,
      childrenStatus: _childrenStatus,
      lookingFor:
          _lookingForController.text.trim().isEmpty ? null : _lookingForController.text.trim(),
      qualities: _qualities.toList(),
    );

    await ref.read(profilControllerProvider.notifier).save(profil);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ton profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const PhotosSection(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Prénom ou pseudonyme'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date de naissance'),
                  child: Text(
                    _birthDate == null
                        ? 'Choisir une date'
                        : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v ?? _gender),
              ),
              const SizedBox(height: 14),
              const Text('Je recherche', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Wrap(
                spacing: 8,
                children: _genders.map((g) {
                  final selected = _seekingGenders.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: AppColors.accentSoft,
                    onSelected: (v) => setState(
                      () => v ? _seekingGenders.add(g) : _seekingGenders.remove(g),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Pays'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description personnelle'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(labelText: 'Profession (facultatif)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(labelText: 'Langues parlées (séparées par des virgules)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _interestsController,
                decoration: const InputDecoration(labelText: "Centres d'intérêt (séparés par des virgules)"),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _culturalOriginsController,
                decoration: const InputDecoration(
                  labelText: 'Origines culturelles déclarées (facultatif)',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _valuesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Présentation de tes valeurs (facultatif)'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _relationshipIntent,
                decoration: const InputDecoration(labelText: 'Intention relationnelle'),
                items: RelationshipIntent.all
                    .map((v) => DropdownMenuItem(value: v, child: Text(RelationshipIntent.label(v))))
                    .toList(),
                onChanged: (v) => setState(() => _relationshipIntent = v ?? _relationshipIntent),
              ),
              const SizedBox(height: 24),
              const Text(
                'TA FICHE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 0.5),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Taille en cm (facultatif)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(labelText: "Niveau d'études (facultatif)"),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _smokingHabit,
                decoration: const InputDecoration(labelText: 'Tabac (facultatif)'),
                items: LifestyleHabit.all
                    .map((v) => DropdownMenuItem(value: v, child: Text(LifestyleHabit.label(v))))
                    .toList(),
                onChanged: (v) => setState(() => _smokingHabit = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _drinkingHabit,
                decoration: const InputDecoration(labelText: 'Alcool (facultatif)'),
                items: LifestyleHabit.all
                    .map((v) => DropdownMenuItem(value: v, child: Text(LifestyleHabit.label(v))))
                    .toList(),
                onChanged: (v) => setState(() => _drinkingHabit = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _childrenStatus,
                decoration: const InputDecoration(labelText: 'Enfants (facultatif)'),
                items: ChildrenStatus.all
                    .map((v) => DropdownMenuItem(value: v, child: Text(ChildrenStatus.label(v))))
                    .toList(),
                onChanged: (v) => setState(() => _childrenStatus = v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lookingForController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ce que tu recherches chez l\'autre (facultatif)',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Tes qualités (facultatif, choisis-en quelques-unes)',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PersonalQuality.all.map((q) {
                  final selected = _qualities.contains(q);
                  return FilterChip(
                    label: Text(q),
                    selected: selected,
                    selectedColor: AppColors.accentSoft,
                    onSelected: (v) => setState(
                      () => v ? _qualities.add(q) : _qualities.remove(q),
                    ),
                  );
                }).toList(),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 8),
                const Text(
                  "Impossible d'enregistrer ton profil, vérifie ta connexion et réessaie.",
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer mon profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
