import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/emergency_sheet.dart';
import '../../../../core/widgets/report_reasons.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';

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
        title: Text(widget.post.title ?? context.l10n.postTypeGeneric),
        actions: [
          PopupMenuButton<String>(
            onSelected: (reason) async {
              await ref.read(communauteControllerProvider).report(widget.post.id, reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.l10n.reportSent)));
              }
            },
            itemBuilder: (_) => reportReasonLabels(context.l10n)
                .entries
                .map((e) => PopupMenuItem(value: e.key, child: Text(context.l10n.reportWithReason(e.value))))
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
                context.l10n.eventDateAndParticipants(
                  widget.post.eventDate != null
                      ? "${widget.post.eventDate!.day}/${widget.post.eventDate!.month}/${widget.post.eventDate!.year}"
                      : '',
                  widget.post.participantsCount,
                  widget.post.capacity?.toString() ?? '-',
                ),
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
                      child: Text(context.l10n.requestToParticipate),
                    );
                  }
                  if (status == 'accepted') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.requestAccepted, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final loc = await ref
                                .read(communauteControllerProvider)
                                .getPreciseLocation(widget.post.id);
                            setState(() => _preciseLocation = loc);
                          },
                          child: Text(context.l10n.seePreciseLocation),
                        ),
                        if (_preciseLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_preciseLocation!),
                          ),
                        if (participation?['checkinCode'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(context.l10n.checkinCodeLabel(participation?['checkinCode'] as String)),
                          ),
                        const SizedBox(height: 8),
                        // Toujours visible sur un événement accepté
                        // (docs/regles-complementaires-concurrents.md
                        // section 1), jamais caché derrière une autre action.
                        TextButton.icon(
                          onPressed: () => showEmergencySheet(context, ref, eventPostId: widget.post.id),
                          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
                          label: Text(context.l10n.reportImmediateDanger,
                              style: const TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    );
                  }
                  return Text(context.l10n.statusLabel(status), style: const TextStyle(color: AppColors.muted));
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
      error: (e, st) => Text(context.l10n.requestsLoadFailed),
      data: (participations) {
        final pending = participations.where((p) => p['status'] == 'pending').toList();
        final accepted = participations
            .where((p) => p['status'] == 'accepted' && p['checkedIn'] != true)
            .toList();
        if (pending.isEmpty && accepted.isEmpty) {
          return Text(context.l10n.noPendingRequests);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty) ...[
              Text(context.l10n.pendingRequestsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        child: Text(context.l10n.acceptButton),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(communauteControllerProvider)
                            .respond(post.id, p['uid'] as String, false),
                        child: Text(context.l10n.declineButton),
                      ),
                    ],
                  ),
                ),
            ],
            if (accepted.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(context.l10n.validateEntryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final p in accepted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(p['uid'] as String)),
                      TextButton(
                        onPressed: () => _checkInDialog(context, ref, post.id, p['uid'] as String),
                        child: Text(context.l10n.enterCodeButton),
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
      title: Text(context.l10n.checkinCodeTitle),
      content: TextField(
        controller: codeController,
        decoration: InputDecoration(labelText: context.l10n.checkinCodeFieldLabel),
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancelButton)),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            try {
              await ref
                  .read(communauteControllerProvider)
                  .checkIn(postId, targetUid, codeController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.l10n.checkinValidated)));
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.l10n.checkinInvalidCode)));
              }
            }
          },
          child: Text(context.l10n.validateButton),
        ),
      ],
    ),
  );
}
