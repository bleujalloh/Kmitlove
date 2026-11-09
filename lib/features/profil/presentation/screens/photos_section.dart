import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/profil_photo.dart';
import '../photo_controller.dart';

/// Galerie de photos avec statut visible (en attente/validée), ajout et
/// suppression — docs/regles-messagerie-securite.md section 1 : la
/// photo n'est jamais vue par les autres tant qu'elle est "en attente".
class PhotosSection extends ConsumerWidget {
  const PhotosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(myPhotosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PHOTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        photosAsync.when(
          loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
          error: (e, st) => const Text('Impossible de charger les photos.'),
          data: (photos) => SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final photo in photos) _PhotoTile(photo: photo),
                _AddPhotoTile(count: photos.length),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.photo});

  final ProfilPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onLongPress: () => _confirmDelete(context, ref),
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                final urlAsync = ref.watch(photoDownloadUrlProvider(photo.storagePath));
                final url = urlAsync.value;
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.placeholder,
                    borderRadius: BorderRadius.circular(14),
                    image: url != null
                        ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                        : null,
                  ),
                  child: url == null
                      ? const Icon(Icons.person_outline, color: Color(0xFFC9C0B2))
                      : null,
                );
              },
            ),
            if (photo.status != 'approved')
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: photo.status == 'rejected' ? AppColors.accent : Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    photo.status == 'rejected' ? 'Refusée' : 'En attente',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(photoControllerProvider).delete(photo);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible de supprimer, réessaie.')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends ConsumerWidget {
  const _AddPhotoTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (count >= 6) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _showPickerSheet(context, ref),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add, color: AppColors.muted),
      ),
    );
  }

  void _showPickerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadWithFeedback(context, ref, fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadWithFeedback(context, ref, fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _uploadWithFeedback(BuildContext context, WidgetRef ref, {required bool fromCamera}) async {
  try {
    await ref.read(photoControllerProvider).pickAndUpload(fromCamera: fromCamera);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Impossible d'envoyer la photo, réessaie.")));
    }
  }
}
