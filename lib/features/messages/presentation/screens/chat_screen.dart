import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/emergency_sheet.dart';
import '../../../../core/widgets/report_reasons.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/message.dart';
import '../messages_controller.dart';

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
          title: Text(context.l10n.beforeSendingPhotoTitle),
          content: Text(
            context.l10n.beforeSendingPhotoBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.continueButton),
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
          IconButton(
            tooltip: context.l10n.safetyTitle,
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () => showEmergencySheet(context, ref, matchId: widget.matchId),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') _confirmBlock(context);
              if (value == 'report') _openReportSheet(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'block', child: Text(context.l10n.blockButton)),
              PopupMenuItem(value: 'report', child: Text(context.l10n.reportButton)),
            ],
          ),
        ],
      ),
      body: isBlockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (blocked) {
          if (blocked) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.conversationNoLongerAccessible,
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
                  error: (e, st) => Center(child: Text(context.l10n.messagesLoadFailed)),
                  data: (messages) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _markVisibleMessagesAsRead(messages, myUid));
                    if (messages.isEmpty) {
                      return Center(child: Text(context.l10n.sayHelloPreview));
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
                                    onReport: isMine ? null : () => _openReportSheet(context, messageId: m.id),
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
                                      read ? context.l10n.readReceipt : context.l10n.sentReceipt,
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
                          decoration: InputDecoration(hintText: context.l10n.messageHint),
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
        title: Text(context.l10n.blockMemberConfirmTitle),
        content: Text(context.l10n.blockMemberConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancelButton)),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(messagesControllerProvider).block(widget.matchId);
            },
            child: Text(context.l10n.blockButton),
          ),
        ],
      ),
    );
  }

  void _openReportSheet(BuildContext context, {String? messageId}) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: reportReasonLabels(context.l10n)
              .entries
              .map((entry) => ListTile(
                    title: Text(entry.value),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref.read(messagesControllerProvider).report(
                            targetUid: widget.otherUid,
                            reason: entry.key,
                            matchId: widget.matchId,
                            messageId: messageId,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.reportSent)),
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
  const _MessageImage({
    required this.storagePath,
    required this.blurred,
    required this.onReveal,
    this.onReport,
  });

  final String storagePath;
  final bool blurred;
  final VoidCallback onReveal;
  // Signalement en un geste d'une photo reçue précise (docs/regles-
  // messagerie-securite.md section 2) — null pour ses propres photos.
  final VoidCallback? onReport;

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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        context.l10n.showPhotoButton,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            if (onReport != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onReport,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.flag_outlined, color: Colors.white, size: 16),
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
