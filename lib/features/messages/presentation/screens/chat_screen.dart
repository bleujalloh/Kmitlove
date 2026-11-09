import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final isMine = m.fromUid == myUid;
                        final read = m.readBy.any((u) => u != m.fromUid);
                        return Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            decoration: BoxDecoration(
                              color: isMine ? AppColors.accent : AppColors.backgroundSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(color: isMine ? Colors.white : AppColors.ink),
                                ),
                                if (isMine && showReceipts)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      read ? 'Lu' : 'Envoyé',
                                      style: const TextStyle(fontSize: 10, color: Colors.white70),
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
