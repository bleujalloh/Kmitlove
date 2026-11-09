import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../communaute_controller.dart';

const _typeLabels = {
  'publication': 'Publication (fil)',
  'annonce_publique': 'Annonce publique',
  'annonce_privee': 'Annonce privée',
  'annonce_libre': 'Annonce libre (texte libre, sans lieu ni date)',
  'evenement_public': 'Événement public',
  'evenement_prive': 'Événement privé',
};

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
          .showSnackBar(const SnackBar(content: Text('Date et capacité requises pour un événement.')));
      return;
    }
    if (_needsLocation && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lieu précis requis.')));
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
                ? 'Envoyé — en attente de validation par un modérateur.'
                : 'Publié !',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Impossible de publier : ${_readableError(e)}')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _readableError(Object e) {
    final text = e.toString();
    if (text.contains('resource-exhausted')) return 'tu as déjà 3 annonces actives.';
    if (text.contains('permission-denied')) return 'réservé aux membres vérifiés.';
    return 'réessaie.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle publication')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _typeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            if (_isEvent) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre de l\'événement'),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
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
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(_eventDate == null
                      ? 'Choisir une date'
                      : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacité (nombre de places)'),
              ),
            ],
            if (_needsLocation) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu précis (masqué jusqu\'à acceptation)',
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
                child: const Text(
                  'Les événements physiques sont réservés aux membres vérifiés et passent toujours par une revue humaine avant publication.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
