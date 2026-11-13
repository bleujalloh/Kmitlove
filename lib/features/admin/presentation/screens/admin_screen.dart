import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../communaute/presentation/communaute_controller.dart';
import '../admin_controller.dart';

/// Espace admin (cahier des charges section 6) : signalements (avec
/// escalade et alertes d'urgence en tête de file), révisions de filtrage,
/// recours contre une sanction, annonces/événements en attente, photos,
/// vérification d'identité, gestion des utilisateurs et journal des
/// actions admin. Ne couvre pas encore les abonnements ni les
/// statistiques — voir docs/suivi-developpement.md.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administration'),
          actions: [
            Consumer(
              builder: (context, ref, _) => IconButton(
                tooltip: 'Charger les banques de questions',
                icon: const Icon(Icons.cloud_upload_outlined),
                onPressed: () async {
                  try {
                    final result = await ref
                        .read(cloudFunctionsProvider)
                        .httpsCallable('adminSeedQuestionBanks')
                        .call();
                    final data = result.data as Map<Object?, Object?>;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Banques chargées : ${data['filtrageCount']} questions de filtrage, '
                            '${data['compatCount']} de compatibilité.',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Échec du chargement, réessaie.')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Signalements'),
              Tab(text: 'Publications'),
              Tab(text: 'Organisateurs'),
              Tab(text: 'Photos'),
              Tab(text: 'Identité'),
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Journal'),
              Tab(text: 'Conseils'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ModerationTab(),
            _PendingPostsTab(),
            _OrganizerRequestsTab(),
            _PendingPhotosTab(),
            _IdentityTab(),
            _UsersTab(),
            _ActionLogTab(),
            _TipsManagementTab(),
          ],
        ),
      ),
    );
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(moderationRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les signalements.')),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) => _ModerationRequestTile(request: requests[i]),
        );
      },
    );
  }
}

class _ModerationRequestTile extends ConsumerWidget {
  const _ModerationRequestTile({required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final type = r['type'] as String? ?? '';
    final isEmergency = type == 'emergency_alert';
    final isAppeal = type == 'sanction_appeal';
    final isFiltrageReview = type == 'filtrage_review';
    final confirmedCount = r['targetConfirmedReportCount'] as int? ?? 0;

    void refresh() => ref.invalidate(moderationRequestsProvider);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: isEmergency
          ? BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isEmergency) Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 18),
              if (isEmergency) const SizedBox(width: 6),
              Text(
                isEmergency ? 'DANGER IMMÉDIAT' : type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEmergency ? AppColors.accent : null,
                ),
              ),
            ],
          ),
          if (r['reason'] != null) Text('Motif : ${r['reason']}'),
          if (r['uid'] != null) Text('Membre : ${r['uid']}'),
          if (r['reporterUid'] != null) Text('Signalé par : ${r['reporterUid']}'),
          if (r['targetUid'] != null) Text('Visé : ${r['targetUid']}'),
          if (!isEmergency && r['targetUid'] != null)
            Text(
              'Signalements confirmés déjà sur ce compte : $confirmedCount'
              '${r['targetSanctionLevel'] != null && r['targetSanctionLevel'] != 'none' ? ' (actuellement : ${r['targetSanctionLevel']})' : ''}',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          if (r['lastScore'] != null) Text('Score filtrage : ${r['lastScore']}'),
          if (isAppeal) Text('Sanction contestée : ${r['sanctionLevel'] ?? 'suspension (ancienne donnée)'}'),
          if (isEmergency && r['context'] != null) ..._emergencyContextLines(r['context'] as Map),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: isFiltrageReview
                ? [
                    TextButton(
                      onPressed: () => ref
                          .read(adminRepositoryProvider)
                          .resolveFiltrageReview(r['id'] as String, true)
                          .then((_) => refresh()),
                      child: const Text('Activer le compte'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(adminRepositoryProvider)
                          .resolveFiltrageReview(r['id'] as String, false)
                          .then((_) => refresh()),
                      child: const Text('Maintenir le refus'),
                    ),
                  ]
                : isAppeal
                    ? [
                        TextButton(
                          onPressed: () => ref
                              .read(adminRepositoryProvider)
                              .resolveSanctionAppeal(r['id'] as String, true)
                              .then((_) => refresh()),
                          child: const Text('Lever la sanction'),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(adminRepositoryProvider)
                              .resolveSanctionAppeal(r['id'] as String, false)
                              .then((_) => refresh()),
                          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                          child: const Text('Maintenir'),
                        ),
                      ]
                    : isEmergency
                        ? [
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'handled')
                                  .then((_) => refresh()),
                              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text('Marquer traité'),
                            ),
                          ]
                        : [
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'dismiss')
                                  .then((_) => refresh()),
                              child: const Text('Classer sans suite'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'warn')
                                  .then((_) => refresh()),
                              child: const Text('Avertir'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'suspend')
                                  .then((_) => refresh()),
                              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text('Suspendre (30j)'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'ban')
                                  .then((_) => refresh()),
                              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text('Bannir définitivement'),
                            ),
                          ],
          ),
        ],
      ),
    );
  }

  List<Widget> _emergencyContextLines(Map context) {
    const unknown = 'inconnu (compte ou publication supprimé depuis)';
    final lines = <Widget>[];
    if (context['eventPostId'] != null) {
      lines.add(Text('Événement en cours : ${context['eventPostId']} '
          '(organisateur : ${context['eventOrganizerUid'] ?? unknown})'));
    }
    if (context['matchId'] != null) {
      lines.add(Text('Conversation en cours : avec ${context['matchOtherUid'] ?? unknown}'));
    }
    if (context['lastActiveMatchId'] != null) {
      lines.add(Text('Dernière conversation active : avec ${context['lastActiveMatchOtherUid'] ?? unknown}'));
    }
    return lines;
  }
}

class _PendingPostsTab extends ConsumerWidget {
  const _PendingPostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(pendingCommunityPostsProvider);
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les publications.')),
      data: (posts) {
        if (posts.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final p = posts[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'] as String? ?? p['type'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(p['text'] as String? ?? ''),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewCommunityPost(p['id'] as String, true)
                            .then((_) => ref.invalidate(pendingCommunityPostsProvider)),
                        child: const Text('Valider'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewCommunityPost(p['id'] as String, false)
                            .then((_) => ref.invalidate(pendingCommunityPostsProvider)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        child: const Text('Refuser'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Demandes de statut organisateur (spec Communauté section 3,
/// 11/11/2026) — validation humaine obligatoire avant toute première
/// publication d'événement, pas d'abonnement pour l'instant.
class _OrganizerRequestsTab extends ConsumerWidget {
  const _OrganizerRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingOrganizerRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les demandes.')),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final r = requests[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['organizerName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('uid : ${r['uid']}', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(r['organizerDescription'] as String? ?? ''),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewOrganizerRequest(r['uid'] as String, true)
                            .then((_) => ref.invalidate(pendingOrganizerRequestsProvider)),
                        child: const Text('Valider'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewOrganizerRequest(r['uid'] as String, false)
                            .then((_) => ref.invalidate(pendingOrganizerRequestsProvider)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        child: const Text('Refuser'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingPhotosTab extends ConsumerWidget {
  const _PendingPhotosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(pendingPhotosProvider);
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les photos.')),
      data: (photos) {
        if (photos.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: photos.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final p = photos[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Membre : ${p['userId']}')),
                  TextButton(
                    onPressed: () => ref
                        .read(adminRepositoryProvider)
                        .reviewPhoto(p['userId'] as String, p['id'] as String, true)
                        .then((_) => ref.invalidate(pendingPhotosProvider)),
                    child: const Text('Valider'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(adminRepositoryProvider)
                        .reviewPhoto(p['userId'] as String, p['id'] as String, false)
                        .then((_) => ref.invalidate(pendingPhotosProvider)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                    child: const Text('Refuser'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _IdentityTab extends ConsumerWidget {
  const _IdentityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(pendingIdentityVerificationsProvider);
    return verificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les demandes.')),
      data: (verifications) {
        if (verifications.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: verifications.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final v = verifications[i];
            final url = v['url'] as String?;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Membre : ${v['uid']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (url != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(url, height: 160, fit: BoxFit.cover),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewIdentityVerification(v['uid'] as String, true)
                            .then((_) => ref.invalidate(pendingIdentityVerificationsProvider)),
                        child: const Text('Vérifier'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewIdentityVerification(v['uid'] as String, false)
                            .then((_) => ref.invalidate(pendingIdentityVerificationsProvider)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        child: const Text('Refuser'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher par prénom/pseudonyme',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (v) => ref.read(adminUserSearchProvider.notifier).state = v,
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Impossible de charger les membres.')),
            data: (users) {
              if (users.isEmpty) return const Center(child: Text('Aucun membre trouvé.'));
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final suspended = u['filtrageStatus'] == 'suspended';
                  final banned = u['sanctionLevel'] == 'banned';
                  return ListTile(
                    title: Text(u['displayName'] as String? ?? ''),
                    subtitle: Text(
                      '${u['city'] ?? ''}, ${u['country'] ?? ''} — ${banned ? 'banni' : u['filtrageStatus'] ?? 'inconnu'}'
                      '${u['isPremium'] == true ? ' · Premium' : ''}'
                      '${u['isVerified'] == true ? ' · Vérifié' : ''}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        // Un bannissement est une décision plus lourde
                        // qu'une simple suspension temporaire — confirmer
                        // explicitement avant de l'annuler en un clic
                        // depuis cet outil général, en dehors de tout
                        // recours examiné (admin/resolveSanctionAppeal.ts).
                        if (suspended && banned) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Lever ce bannissement définitif ?'),
                              content: const Text(
                                "Ce membre a été banni définitivement (pas juste suspendu temporairement). "
                                "Réactiver son compte annule cette décision.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                  child: const Text('Lever le bannissement'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                        }
                        await ref
                            .read(adminRepositoryProvider)
                            .setSuspension(u['uid'] as String, !suspended);
                        ref.invalidate(adminUsersProvider);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: suspended ? AppColors.online : AppColors.accent,
                      ),
                      child: Text(suspended ? 'Réactiver' : 'Suspendre'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

const _tipCategories = ['culture', 'relation', 'securite', 'communaute'];

/// Contenu éditorial de l'onglet "Conseils" de la Communauté (maquette
/// visuelle validée le 11/11/2026) — rédigé exclusivement ici, jamais par
/// les membres (functions/src/admin/manageTips.ts).
class _TipsManagementTab extends ConsumerWidget {
  const _TipsManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(communityTipsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => _createTipDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.noirProfond),
      ),
      body: tipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Impossible de charger les conseils.')),
        data: (tips) {
          if (tips.isEmpty) return const Center(child: Text('Aucun conseil publié.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tips.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final tip = tips[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tip['title']} (${tip['category']})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(tip['body'] as String? ?? ''),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(adminRepositoryProvider).deleteTip(tip['id'] as String),
                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createTipDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String category = _tipCategories.first;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nouveau conseil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titre')),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Contenu'),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _tipCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) return;
                Navigator.of(dialogContext).pop();
                await ref.read(adminRepositoryProvider).createTip(
                      titleController.text.trim(),
                      bodyController.text.trim(),
                      category,
                    );
              },
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Journal des actions admin (section 4.8 — journalisation), lecture
/// seule : qui a fait quoi, quand, sur quel compte.
class _ActionLogTab extends ConsumerWidget {
  const _ActionLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminActionLogsProvider);
    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger le journal.')),
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('Aucune action enregistrée.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final l = logs[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['action'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Par : ${l['adminUid']}', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (l['targetUid'] != null)
                    Text('Sur : ${l['targetUid']}', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
