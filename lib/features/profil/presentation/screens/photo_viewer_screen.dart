import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/profil_photo.dart';
import '../photo_controller.dart';

/// Visionneuse plein écran de MES photos, y compris celles encore « en
/// attente » ou refusées (invisibles pour les autres membres, donc
/// impossibles à voir ailleurs dans l'app). Balayage entre les photos,
/// zoom au pincement, statut et visibilité indiqués sous la photo.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({super.key, required this.photos, required this.initialIndex});

  final List<ProfilPhoto> photos;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return context.l10n.photoApproved;
      case 'rejected':
        return context.l10n.photoRejected;
      default:
        return context.l10n.photoPending;
    }
  }

  String _visibilityLabel(BuildContext context, ProfilPhoto photo) {
    switch (photo.status) {
      case 'approved':
        return context.l10n.photoVisibleToOthers;
      case 'rejected':
        final why = photo.rejectedBy == 'auto_moderation'
            ? context.l10n.photoRejectedAutoReason
            : context.l10n.photoRejectedManualReason;
        return '$why\n${context.l10n.photoRejectedHint}';
      default:
        return context.l10n.photoPendingHint;
    }
  }

  /// Suppression avec confirmation (même contrôleur que l'appui long de la
  /// galerie : PhotoController.delete). La visionneuse se ferme ensuite :
  /// la liste de photos qu'elle affiche n'est plus à jour.
  void _confirmDelete(ProfilPhoto photo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePhotoConfirmTitle),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancelButton)),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final messenger = ScaffoldMessenger.of(context);
              final failedText = context.l10n.photoDeleteFailed;
              try {
                await ref.read(photoControllerProvider).delete(photo);
                if (mounted) Navigator.of(context).pop();
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text(failedText)));
              }
            },
            child: Text(context.l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}', style: const TextStyle(fontSize: 14)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = ref.watch(photoDownloadUrlProvider(widget.photos[i].storagePath));
                return url.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Text(context.l10n.photosLoadFailed, style: const TextStyle(color: Colors.white70)),
                  ),
                  data: (u) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: Image.network(u, fit: BoxFit.contain)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: current.status == 'approved' ? AppColors.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      _statusLabel(context, current.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: current.status == 'approved' ? AppColors.noirProfond : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _visibilityLabel(context, current),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(current),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(context.l10n.deletePhotoButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
