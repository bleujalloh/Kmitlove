import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/country_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../communaute_controller.dart';

const _postTypes = [
  'publication',
  'annonce_publique',
  'annonce_privee',
  'annonce_libre',
  'evenement_public',
  'evenement_prive',
];

const _eventTypes = ['evenement_public', 'evenement_prive'];

const _eventCategories = [
  'soiree',
  'conference',
  'atelier',
  'exposition',
  'debat',
  'projection',
  'rencontre',
];

const _eventFormats = ['presentiel', 'en_ligne'];
const _privateAccessModes = ['sur_demande', 'sur_invitation'];
const _recurrenceFrequencies = ['hebdomadaire', 'mensuel'];
const _recurrenceMaxOccurrences = 6;

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.organizerMode = false});

  /// Ouvert depuis l'espace organisateur (spec Communauté section 8) :
  /// ne propose que les types événement, pré-sélectionnés.
  final bool organizerMode;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late String _type = widget.organizerMode ? 'evenement_public' : 'publication';
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ville et pays de l'événement préremplis depuis le profil (le membre les
    // a déjà donnés à l'inscription) ; modifiables.
    final profil = ref.read(profilProvider).value;
    if (profil != null) {
      _cityController.text = profil.city;
      _countryController.text = profil.country;
    }
  }
  final _ageMinimumController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _contactController = TextEditingController();
  DateTime? _eventDate;
  DateTime? _eventEndDate;
  String _category = _eventCategories.first;
  String _format = _eventFormats.first;
  String _accessMode = _privateAccessModes.first;
  String? _parentEventId;
  String? _recurrence;
  int _recurrenceCount = 1;
  File? _posterFile;
  // Chemin déjà envoyé pour _posterFile — évite de ré-uploader (et de
  // laisser un doublon orphelin) si l'utilisateur corrige un champ et
  // republie sans changer l'affiche (trouvé par revue de code).
  String? _uploadedPosterPath;
  bool _submitting = false;

  bool get _isEvent => _eventTypes.contains(_type);
  bool get _needsLocation => _isEvent || _type == 'annonce_privee';
  bool get _isPrivateEvent => _type == 'evenement_prive';

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _ageMinimumController.dispose();
    _conditionsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _posterFile = File(picked.path);
        _uploadedPosterPath = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    if (_isEvent &&
        (_eventDate == null ||
            _capacityController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty ||
            _countryController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.eventDateAndCapacityRequired)));
      return;
    }
    if (_needsLocation && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.preciseLocationRequired)));
      return;
    }

    setState(() => _submitting = true);
    try {
      String? posterStoragePath = _uploadedPosterPath;
      if (_isEvent && _posterFile != null && posterStoragePath == null) {
        posterStoragePath = await ref.read(communauteControllerProvider).uploadEventPoster(_posterFile!);
        _uploadedPosterPath = posterStoragePath;
      }
      // Fuseau de l'organisateur au moment de la création (hypothèse
      // raisonnable : l'événement se déroule là où il le crée) — vérifié
      // côté serveur contre la vraie liste IANA, jamais une confiance
      // aveugle à cette valeur (createCommunityPost.ts).
      String? timezone;
      if (_isEvent) {
        timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
      }
      final status = await ref.read(communauteControllerProvider).createPost(
            type: _type,
            text: _textController.text.trim(),
            title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            eventDate: _eventDate,
            eventEndDate: _eventEndDate,
            capacity: _capacityController.text.trim().isEmpty
                ? null
                : int.tryParse(_capacityController.text.trim()),
            preciseLocation:
                _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            category: _isEvent ? _category : null,
            format: _isEvent ? _format : null,
            city: _isEvent ? _cityController.text.trim() : null,
            country: _isEvent ? _countryController.text.trim() : null,
            ageMinimum: _ageMinimumController.text.trim().isEmpty
                ? null
                : int.tryParse(_ageMinimumController.text.trim()),
            conditions: _conditionsController.text.trim().isEmpty ? null : _conditionsController.text.trim(),
            contactChannel: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
            posterStoragePath: posterStoragePath,
            accessMode: _isPrivateEvent ? _accessMode : null,
            parentEventId: _parentEventId,
            recurrence: _isEvent ? _recurrence : null,
            recurrenceCount: _isEvent && _recurrence != null ? _recurrenceCount : null,
            timezone: timezone,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'pending_review'
                ? context.l10n.postPendingReview
                : context.l10n.postPublished,
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // L'affiche déjà envoyée ne sert plus à rien si la publication
      // elle-même échoue pour un motif qui n'a rien à voir avec elle
      // (ex. ville manquante) : on la retire plutôt que de la laisser
      // orpheline dans Storage, et on efface le cache pour qu'une
      // nouvelle tentative en réenvoie une propre si besoin.
      final orphanedPoster = _uploadedPosterPath;
      if (orphanedPoster != null) {
        _uploadedPosterPath = null;
        unawaited(ref.read(communauteControllerProvider).deleteEventPoster(orphanedPoster));
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.postFailed(_readableError(e, context)))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _readableError(Object e, BuildContext context) {
    final text = e.toString();
    if (text.contains('resource-exhausted')) return context.l10n.postErrorTooManyActive;
    if (text.contains('permission-denied')) return context.l10n.postErrorVerifiedOnly;
    return context.l10n.postErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final myEvents = widget.organizerMode ? ref.watch(myOrganizedEventsProvider).value ?? [] : <CommunityPost>[];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newPostTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!widget.organizerMode)
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: context.l10n.typeLabel),
                items: _postTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(postTypeLabel(t, context.l10n))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(labelText: context.l10n.typeLabel),
                items: _eventTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(postTypeLabel(t, context.l10n))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            if (_isEvent) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: context.l10n.eventTitleLabel),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickPoster,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    image: _posterFile != null
                        ? DecorationImage(image: FileImage(_posterFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _posterFile == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_outlined, color: AppColors.muted),
                              const SizedBox(height: 6),
                              Text(context.l10n.addPosterButton, style: const TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(labelText: context.l10n.descriptionLabel),
            ),
            if (_isEvent) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: context.l10n.eventCategoryLabel),
                items: _eventCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(eventCategoryLabel(c, context.l10n))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _format,
                decoration: InputDecoration(labelText: context.l10n.eventFormatLabel),
                items: _eventFormats
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f == 'presentiel' ? context.l10n.eventFormatPresentiel : context.l10n.eventFormatEnLigne),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _format = v ?? _format),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _eventDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: context.l10n.dateLabel),
                  child: Text(_eventDate == null
                      ? context.l10n.chooseDate
                      : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                // Désactivé tant que la date de début n'est pas choisie :
                // sans elle, aucun plancher cohérent n'existe pour la
                // date de fin (trouvé par revue de code).
                onTap: _eventDate == null
                    ? null
                    : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventEndDate ?? _eventDate!,
                    firstDate: _eventDate!,
                    lastDate: DateTime.now().add(const Duration(days: 400)),
                  );
                  if (picked != null) setState(() => _eventEndDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: context.l10n.eventEndDateLabel),
                  child: Text(_eventEndDate == null
                      ? context.l10n.chooseDate
                      : '${_eventEndDate!.day}/${_eventEndDate!.month}/${_eventEndDate!.year}'),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.capacityLabel),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CityField(
                      controller: _cityController,
                      country: _countryController.text.isEmpty ? null : _countryController.text,
                      label: context.l10n.eventCityLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // Même sélecteur fermé que le profil (le serveur refuse
                    // tout pays hors liste, createCommunityPost.ts).
                    child: CountryField(
                      value: _countryController.text,
                      label: context.l10n.countryLabel,
                      onChanged: (v) => setState(() => _countryController.text = v),
                    ),
                  ),
                ],
              ),
            ],
            if (_needsLocation) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: context.l10n.preciseLocationLabel),
              ),
            ],
            if (_isPrivateEvent) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _accessMode,
                decoration: InputDecoration(labelText: context.l10n.eventAccessModeLabel),
                items: _privateAccessModes
                    .map((a) => DropdownMenuItem(value: a, child: Text(eventAccessModeLabel(a, context.l10n))))
                    .toList(),
                onChanged: (v) => setState(() => _accessMode = v ?? _accessMode),
              ),
            ],
            if (_isEvent) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _ageMinimumController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.eventAgeMinimumLabel),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _conditionsController,
                maxLines: 2,
                decoration: InputDecoration(labelText: context.l10n.eventConditionsLabel),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: context.l10n.eventContactLabel),
              ),
              if (myEvents.isNotEmpty) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: _parentEventId,
                  decoration: InputDecoration(labelText: context.l10n.linkedEventsTitle),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...myEvents
                        .where((e) => e.isEvent)
                        .map((e) => DropdownMenuItem(value: e.id, child: Text(e.title ?? e.text))),
                  ],
                  onChanged: (v) => setState(() => _parentEventId = v),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: _recurrence,
                decoration: InputDecoration(labelText: context.l10n.recurrenceLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.l10n.recurrenceNone)),
                  ..._recurrenceFrequencies.map(
                    (f) => DropdownMenuItem(value: f, child: Text(eventRecurrenceLabel(f, context.l10n))),
                  ),
                ],
                onChanged: (v) => setState(() => _recurrence = v),
              ),
              if (_recurrence != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Text(context.l10n.recurrenceCountLabel)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _recurrenceCount > 1
                          ? () => setState(() => _recurrenceCount -= 1)
                          : null,
                    ),
                    Text('$_recurrenceCount'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _recurrenceCount < _recurrenceMaxOccurrences
                          ? () => setState(() => _recurrenceCount += 1)
                          : null,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.eventVerifiedOnlyHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                    )
                  : Text(context.l10n.publishButton),
            ),
          ],
        ),
      ),
    );
  }
}
