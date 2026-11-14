import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/action_feedback.dart';
import '../../../../core/widgets/emergency_sheet.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../core/widgets/report_reasons.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../profil/presentation/profil_detail_controller.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'post_interactions.dart';

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
    final myParticipationAsync = ref.watch(myParticipationProvider(widget.post.id));
    final favoriteIds = ref.watch(favoriteIdsProvider).value ?? <String>{};
    final isFavorite = favoriteIds.contains(widget.post.id);
    final posterUrl = widget.post.posterStoragePath != null
        ? ref.watch(eventPosterUrlProvider(widget.post.posterStoragePath!)).value
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title ?? context.l10n.postTypeGeneric),
        actions: [
          if (widget.post.isEvent && myUid != null)
            IconButton(
              icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, color: AppColors.accent),
              onPressed: () => runWithFeedback(
                context,
                () => ref.read(communauteControllerProvider).toggleFavorite(widget.post.id, !isFavorite),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (reason) => sendReportWithFeedback(
              context,
              () => ref.read(communauteControllerProvider).report(widget.post.id, reason),
            ),
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
            if (posterUrl != null) ...[
              GestureDetector(
                onTap: () => openImageViewer(context, [posterUrl]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Image.network(posterUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (widget.post.eventState != null && widget.post.eventState != 'prevu')
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
                  child: Text(
                    eventStateLabel(widget.post.eventState!, context.l10n),
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
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
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (widget.post.category != null) _InfoChip(eventCategoryLabel(widget.post.category!, context.l10n)),
                  if (widget.post.format != null)
                    _InfoChip(widget.post.format == 'presentiel'
                        ? context.l10n.eventFormatPresentiel
                        : context.l10n.eventFormatEnLigne),
                  if (widget.post.city != null) _InfoChip('${widget.post.city}, ${widget.post.country ?? ''}'),
                  if (widget.post.accessMode != null) _InfoChip(eventAccessModeLabel(widget.post.accessMode!, context.l10n)),
                  if (widget.post.ageMinimum != null) _InfoChip('${widget.post.ageMinimum}+'),
                ],
              ),
              if (widget.post.conditions?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(widget.post.conditions!, style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
              if (widget.post.contactChannel?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text('${context.l10n.eventContactLabel} : ${widget.post.contactChannel}',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ],
            const SizedBox(height: 18),
            if (!isOrganizer && widget.post.needsParticipationRequest)
              myParticipationAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const SizedBox.shrink(),
                data: (participation) {
                  final status = participation?['status'] as String?;
                  if (status == null) {
                    if (widget.post.eventState == 'annule') {
                      return Text(context.l10n.eventCancelledNotice, style: TextStyle(color: AppColors.muted));
                    }
                    if (widget.post.eventState == 'termine') {
                      return Text(context.l10n.eventStateFinished, style: TextStyle(color: AppColors.muted));
                    }
                    if (widget.post.isFull) {
                      return Text(context.l10n.eventFullNotice, style: TextStyle(color: AppColors.muted));
                    }
                    return ElevatedButton(
                      onPressed: () => runWithFeedback(
                        context,
                        () => ref.read(communauteControllerProvider).requestParticipation(widget.post.id),
                      ),
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
                            String? loc;
                            final ok = await runWithFeedback(
                              context,
                              () async => loc = await ref
                                  .read(communauteControllerProvider)
                                  .getPreciseLocation(widget.post.id),
                            );
                            if (ok && mounted) setState(() => _preciseLocation = loc);
                          },
                          child: Text(context.l10n.seePreciseLocation),
                        ),
                        if (_preciseLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_preciseLocation!),
                          ),
                        if (participation?['checkinCode'] != null) ...[
                          const SizedBox(height: 16),
                          _TicketCard(
                            title: context.l10n.ticketTitle,
                            code: participation!['checkinCode'] as String,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Toujours visible sur un événement accepté
                        // (docs/regles-complementaires-concurrents.md
                        // section 1), jamais caché derrière une autre action.
                        TextButton.icon(
                          onPressed: () => showEmergencySheet(context, ref, eventPostId: widget.post.id),
                          icon: Icon(Icons.warning_amber_rounded, color: AppColors.accent),
                          label: Text(context.l10n.reportImmediateDanger,
                              style: TextStyle(color: AppColors.accent)),
                        ),
                        const SizedBox(height: 8),
                        _CancelParticipationButton(postId: widget.post.id),
                        const SizedBox(height: 16),
                        _ReviewSection(postId: widget.post.id),
                      ],
                    );
                  }
                  if (status == 'pending') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.pendingRequestNotice, style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 8),
                        _CancelParticipationButton(postId: widget.post.id),
                      ],
                    );
                  }
                  if (status == 'waitlisted') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.waitlistedNotice, style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 8),
                        _CancelParticipationButton(postId: widget.post.id),
                      ],
                    );
                  }
                  return Text(context.l10n.statusLabel(status), style: TextStyle(color: AppColors.muted));
                },
              ),
            if (isOrganizer && widget.post.isEvent) _OrganizerEventControls(post: widget.post),
            if (isOrganizer && widget.post.needsParticipationRequest) _OrganizerPanel(post: widget.post),
            if (widget.post.isEvent) ...[
              const SizedBox(height: 20),
              _LinkedEventsSection(parentEventId: widget.post.id),
            ],
            if (widget.post.recurrenceGroupId != null) ...[
              const SizedBox(height: 20),
              _RecurrenceSeriesSection(
                recurrenceGroupId: widget.post.recurrenceGroupId!,
                currentPostId: widget.post.id,
              ),
            ],
            if (widget.post.isEvent && !isOrganizer) ...[
              const SizedBox(height: 20),
              _ReviewsList(postId: widget.post.id),
            ],
            if (widget.post.type == 'publication') ...[
              const SizedBox(height: 20),
              PostInteractionsRow(post: widget.post),
              const SizedBox(height: 16),
              PostRepliesSection(post: widget.post),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.5)),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.title, required this.code});
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.ivoire,
            child: QrImageView(data: code, size: 140, backgroundColor: AppColors.ivoire),
          ),
          const SizedBox(height: 10),
          Text(code, style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CancelParticipationButton extends ConsumerWidget {
  const _CancelParticipationButton({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.cancelParticipationConfirmTitle),
            content: Text(context.l10n.cancelParticipationConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: Text(context.l10n.cancelParticipationButton),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await runWithFeedback(
          context,
          () => ref.read(communauteControllerProvider).cancelParticipation(postId),
          success: context.l10n.participationCancelledSuccess,
        );
      },
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      child: Text(context.l10n.cancelParticipationButton),
    );
  }
}

class _RecurrenceSeriesSection extends ConsumerWidget {
  const _RecurrenceSeriesSection({required this.recurrenceGroupId, required this.currentPostId});
  final String recurrenceGroupId;
  final String currentPostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = (ref.watch(recurrenceSeriesProvider(recurrenceGroupId)).value ?? [])
        .where((p) => p.id != currentPostId)
        .toList();
    if (series.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.recurrenceSeriesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final e in series)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.title ?? e.text, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: e.eventDate != null
                ? Text('${e.eventDate!.day}/${e.eventDate!.month}/${e.eventDate!.year}')
                : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: e)),
            ),
          ),
      ],
    );
  }
}

class _LinkedEventsSection extends ConsumerWidget {
  const _LinkedEventsSection({required this.parentEventId});
  final String parentEventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(linkedEventsProvider(parentEventId)).value ?? [];
    if (linked.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.linkedEventsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final e in linked)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.title ?? e.text, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: e.eventDate != null
                ? Text('${e.eventDate!.day}/${e.eventDate!.month}/${e.eventDate!.year}')
                : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: e)),
            ),
          ),
      ],
    );
  }
}

class _ReviewSection extends ConsumerStatefulWidget {
  const _ReviewSection({required this.postId});
  final String postId;

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    // Le refus du serveur (événement pas encore passé, participation non
    // confirmée...) est annoncé au membre au lieu de disparaître en silence.
    final sent = await runWithFeedback(
      context,
      () => ref.read(communauteControllerProvider).submitReview(
            widget.postId,
            _rating,
            comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          ),
      success: context.l10n.reviewSentSuccess,
    );
    if (sent && mounted) _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.leaveReviewButton, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(star <= _rating ? Icons.star : Icons.star_border, color: AppColors.accent),
              onPressed: () => setState(() => _rating = star),
            );
          }),
        ),
        TextField(
          controller: _commentController,
          maxLines: 2,
          decoration: InputDecoration(hintText: context.l10n.reviewsTitle),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          child: Text(context.l10n.reviewSubmitButton),
        ),
      ],
    );
  }
}

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(eventReviewsProvider(postId)).value ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.reviewsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Text(context.l10n.noReviewsYet, style: TextStyle(color: AppColors.muted))
        else
          for (final r in reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < ((r['rating'] as num?)?.toInt() ?? 0) ? Icons.star : Icons.star_border,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (r['comment'] != null) Expanded(child: Text(r['comment'] as String, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
      ],
    );
  }
}

class _OrganizerEventControls extends ConsumerWidget {
  const _OrganizerEventControls({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post.eventState == 'annule' || post.eventState == 'termine') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (post.accessMode == 'sur_invitation') ...[
            OutlinedButton(
              onPressed: () => _inviteDialog(context, ref, post.id),
              child: Text(context.l10n.inviteMemberButton),
            ),
            OutlinedButton(
              onPressed: () => _sharePrivately(context, ref, post.id),
              child: Text(context.l10n.shareEventPrivatelyButton),
            ),
          ],
          OutlinedButton(
            onPressed: () => ref.read(communauteControllerProvider).updateEventState(post.id, 'termine'),
            child: Text(context.l10n.markEventFinishedButton),
          ),
          TextButton(
            onPressed: () => ref.read(communauteControllerProvider).updateEventState(post.id, 'annule'),
            child: Text(context.l10n.cancelEventButton, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePrivately(BuildContext context, WidgetRef ref, String postId) async {
    try {
      final code = await ref.read(communauteControllerProvider).getEventShareCode(postId);
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(text: context.l10n.shareEventCodeMessage(code)),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.shareCodeFetchFailed)));
      }
    }
  }

  void _inviteDialog(BuildContext context, WidgetRef ref, String postId) {
    final uidController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.inviteMemberButton),
        content: TextField(
          controller: uidController,
          decoration: InputDecoration(labelText: context.l10n.inviteMemberHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancelButton)),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (uidController.text.trim().isEmpty) return;
              if (!context.mounted) return;
              await runWithFeedback(
                context,
                () => ref.read(communauteControllerProvider).inviteToEvent(postId, uidController.text.trim()),
                success: context.l10n.inviteSentSuccess,
              );
            },
            child: Text(context.l10n.validateButton),
          ),
        ],
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
                      // Le prénom du membre, jamais son identifiant technique
                      // (l'organisateur voyait une suite de caractères
                      // illisible à la place du nom).
                      Expanded(
                        child: Text(
                          ref.watch(targetProfileProvider(p['uid'] as String)).value?.displayName ?? '…',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => runWithFeedback(
                          context,
                          () => ref.read(communauteControllerProvider).respond(post.id, p['uid'] as String, true),
                        ),
                        child: Text(context.l10n.acceptButton),
                      ),
                      TextButton(
                        onPressed: () => runWithFeedback(
                          context,
                          () => ref.read(communauteControllerProvider).respond(post.id, p['uid'] as String, false),
                        ),
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
