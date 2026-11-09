import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';

const _reportReasons = {
  'faux_profil': 'Faux profil',
  'comportement_abusif': 'Comportement abusif',
  'contenu_inapproprie': 'Contenu inapproprié',
  'arnaque': 'Arnaque',
  'autre': 'Autre',
};

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  String? _preciseLocation;

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isOrganizer = myUid == widget.post.authorUid;
    final myParticipationAsync =
        ref.watch(myParticipationProvider(widget.post.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title ?? 'Publication'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (reason) async {
              await ref.read(communauteControllerProvider).report(widget.post.id, reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Signalement envoyé.')));
              }
            },
            itemBuilder: (_) => _reportReasons.entries
                .map((e) => PopupMenuItem(value: e.key, child: Text('Signaler : ${e.value}')))
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.post.text, style: const TextStyle(fontSize: 14.5, height: 1.5)),
            if (widget.post.isEvent) ...[
              const SizedBox(height: 14),
              Text(
                '${widget.post.eventDate != null ? "${widget.post.eventDate!.day}/${widget.post.eventDate!.month}/${widget.post.eventDate!.year}" : ''} · ${widget.post.participantsCount}/${widget.post.capacity ?? '-'} participants',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            if (!isOrganizer && widget.post.needsParticipationRequest)
              myParticipationAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const SizedBox.shrink(),
                data: (participation) {
                  final status = participation?['status'] as String?;
                  if (status == null) {
                    return ElevatedButton(
                      onPressed: () =>
                          ref.read(communauteControllerProvider).requestParticipation(widget.post.id),
                      child: const Text('Demander à participer'),
                    );
                  }
                  if (status == 'accepted') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Demande acceptée !', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final loc = await ref
                                .read(communauteControllerProvider)
                                .getPreciseLocation(widget.post.id);
                            setState(() => _preciseLocation = loc);
                          },
                          child: const Text('Voir le lieu précis'),
                        ),
                        if (_preciseLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_preciseLocation!),
                          ),
                        if (participation?['checkinCode'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Code de présence : ${participation?['checkinCode']}'),
                          ),
                      ],
                    );
                  }
                  return Text('Statut : $status', style: const TextStyle(color: AppColors.muted));
                },
              ),
            if (isOrganizer && widget.post.needsParticipationRequest) _OrganizerPanel(post: widget.post),
          ],
        ),
      ),
    );
  }
}

class _OrganizerPanel extends ConsumerWidget {
  const _OrganizerPanel({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(participationsProvider(post.id));
    return participationsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => const Text('Impossible de charger les demandes.'),
      data: (participations) {
        final pending = participations.where((p) => p['status'] == 'pending').toList();
        final accepted = participations
            .where((p) => p['status'] == 'accepted' && p['checkedIn'] != true)
            .toList();
        if (pending.isEmpty && accepted.isEmpty) {
          return const Text('Aucune demande en attente.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty) ...[
              const Text('Demandes en attente', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final p in pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(p['uid'] as String)),
                      TextButton(
                        onPressed: () => ref
                            .read(communauteControllerProvider)
                            .respond(post.id, p['uid'] as String, true),
                        child: const Text('Accepter'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(communauteControllerProvider)
                            .respond(post.id, p['uid'] as String, false),
                        child: const Text('Refuser'),
                      ),
                    ],
                  ),
                ),
            ],
            if (accepted.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Valider l'entrée", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final p in accepted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(p['uid'] as String)),
                      TextButton(
                        onPressed: () => _checkInDialog(context, ref, post.id, p['uid'] as String),
                        child: const Text('Entrer le code'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

void _checkInDialog(BuildContext context, WidgetRef ref, String postId, String targetUid) {
  final codeController = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Code de présence"),
      content: TextField(
        controller: codeController,
        decoration: const InputDecoration(labelText: 'Code donné par le participant'),
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            try {
              await ref
                  .read(communauteControllerProvider)
                  .checkIn(postId, targetUid, codeController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Entrée validée.')));
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Code invalide.')));
              }
            }
          },
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}
