import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/message.dart';
import '../messages_controller.dart';

const _reportReasons = {
  'faux_profil': 'Faux profil',
  'comportement_abusif': 'Comportement abusif',
  'contenu_inapproprie': 'Contenu inapproprié',
  'arnaque': 'Arnaque',
  'autre': 'Autre',
};

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUid,
    required this.otherDisplayName,
  });

  final String matchId;
  final String otherUid;
  final String otherDisplayName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final Set<String> _alreadyMarking = {};
  final Set<String> _revealedImageIds = {};

  Future<void> _sendImage(List<ChatMessage> currentMessages, String myUid) async {
    // Avertissement avant le TOUT premier envoi de photo de cette
    // conversation, de mon côté (docs/regles-messagerie-securite.md
    // section 2) — pas à chaque photo, seulement la première fois.
    final alreadySentImage = currentMessages.any((m) => m.hasImage && m.fromUid == myUid);
    if (!alreadySentImage) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Avant d\'envoyer une photo'),
          content: const Text(
            'Respecte la charte communautaire : pas de contenu inapproprié. La personne en face peut te signaler.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    await ref.read(messagesControllerProvider).sendImage(widget.matchId, File(picked.path));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markVisibleMessagesAsRead(List<ChatMessage> messages, String myUid) {
    final toMark = messages
        .where((m) => m.fromUid != myUid && !m.readBy.contains(myUid) && !_alreadyMarking.contains(m.id))
        .map((m) => m.id)
        .toList();
    if (toMark.isEmpty) return;
    _alreadyMarking.addAll(toMark);
    ref.read(messagesControllerProvider).markManyRead(widget.matchId, toMark);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final isBlockedAsync = ref.watch(isBlockedProvider(widget.matchId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.matchId));
    final myReceipts = ref.watch(showReadReceiptsProvider(myUid)).value ?? true;
    final theirReceipts = ref.watch(showReadReceiptsProvider(widget.otherUid)).value ?? true;
    final showReceipts = myReceipts && theirReceipts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherDisplayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _confirmBlock(context);
              if (value == 'report') _openReportSheet(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'block', child: Text('Bloquer')),
              PopupMenuItem(value: 'report', child: Text('Signaler')),
            ],
          ),
        ],
      ),
      body: isBlockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Erreur.')),
        data: (blocked) {
          if (blocked) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cette conversation n\'est plus accessible.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Center(child: Text('Impossible de charger les messages.')),
                  data: (messages) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _markVisibleMessagesAsRead(messages, myUid));
                    if (messages.isEmpty) {
                      return const Center(child: Text('Dites bonjour 👋'));
                    }
                    // La liste est triée du plus récent au plus ancien : la
                    // première photo CHRONOLOGIQUEMENT de l'autre personne
                    // est donc la dernière de cette liste parmi ses photos.
                    final firstOtherImageId = messages
                        .where((m) => m.hasImage && m.fromUid == widget.otherUid)
                        .lastOrNull
                        ?.id;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final isMine = m.fromUid == myUid;
                        final read = m.readBy.any((u) => u != m.fromUid);
                        final blurred = !isMine &&
                            m.id == firstOtherImageId &&
                            !_revealedImageIds.contains(m.id);
                        return Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: m.hasImage
                                ? const EdgeInsets.all(4)
                                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            decoration: BoxDecoration(
                              color: isMine ? AppColors.accent : AppColors.backgroundSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (m.hasImage)
                                  _MessageImage(
                                    storagePath: m.imageStoragePath!,
                                    blurred: blurred,
                                    onReveal: () => setState(() => _revealedImageIds.add(m.id)),
                                  )
                                else
                                  Text(
                                    m.text,
                                    style: TextStyle(color: isMine ? Colors.white : AppColors.ink),
                                  ),
                                if (isMine && showReceipts)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, right: 4),
                                    child: Text(
                                      read ? 'Lu' : 'Envoyé',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: m.hasImage ? AppColors.muted : Colors.white70,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image_outlined, color: AppColors.muted),
                        onPressed: () => _sendImage(
                          messagesAsync.value ?? const [],
                          myUid,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Message...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppColors.accent),
                        onPressed: () {
                          ref.read(messagesControllerProvider).send(widget.matchId, _controller.text);
                          _controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bloquer ce membre ?'),
        content: const Text('La conversation deviendra inaccessible pour vous deux, immédiatement.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(messagesControllerProvider).block(widget.matchId);
            },
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reportReasons.entries
              .map((entry) => ListTile(
                    title: Text(entry.value),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref.read(messagesControllerProvider).report(
                            targetUid: widget.otherUid,
                            reason: entry.key,
                            matchId: widget.matchId,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signalement envoyé.')),
                        );
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// Photo d'une conversation — floutée tant que `blurred` est vrai, avec
/// un bouton "Afficher" explicite (docs/regles-messagerie-securite.md
/// section 2 et docs/regles-complementaires-concurrents.md section 1 :
/// le choix revient au destinataire, jamais imposé).
class _MessageImage extends ConsumerWidget {
  const _MessageImage({required this.storagePath, required this.blurred, required this.onReveal});

  final String storagePath;
  final bool blurred;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(messageImageUrlProvider(storagePath));
    final url = urlAsync.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              Container(color: AppColors.placeholder)
            else if (blurred)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Image.network(url, fit: BoxFit.cover),
              )
            else
              Image.network(url, fit: BoxFit.cover),
            if (blurred)
              Material(
                color: Colors.black26,
                child: InkWell(
                  onTap: onReveal,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Afficher la photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
