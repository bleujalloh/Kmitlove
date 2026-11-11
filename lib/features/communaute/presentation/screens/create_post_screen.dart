import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';

const _postTypes = [
  'publication',
  'annonce_publique',
  'annonce_privee',
  'annonce_libre',
  'evenement_public',
  'evenement_prive',
];

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  String _type = 'publication';
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _eventDate;
  bool _submitting = false;

  bool get _isEvent => _type == 'evenement_public' || _type == 'evenement_prive';
  bool get _needsLocation => _isEvent || _type == 'annonce_privee';

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    if (_isEvent && (_eventDate == null || _capacityController.text.trim().isEmpty)) {
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
      final status = await ref.read(communauteControllerProvider).createPost(
            type: _type,
            text: _textController.text.trim(),
            title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            eventDate: _eventDate,
            capacity: _capacityController.text.trim().isEmpty
                ? null
                : int.tryParse(_capacityController.text.trim()),
            preciseLocation:
                _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.newPostTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: context.l10n.typeLabel),
              items: _postTypes
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
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(labelText: context.l10n.descriptionLabel),
            ),
            if (_isEvent) ...[
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
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.capacityLabel),
              ),
            ],
            if (_needsLocation) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: context.l10n.preciseLocationLabel,
                ),
              ),
            ],
            if (_isEvent) ...[
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
