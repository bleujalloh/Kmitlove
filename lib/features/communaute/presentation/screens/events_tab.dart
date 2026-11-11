import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'my_participations_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_request_screen.dart';
import 'post_detail_screen.dart';

const _conferenceCategories = ['conference', 'rencontre', 'debat', 'projection'];

/// Onglet "Événements" (spec Communauté section 1/10, 11/11/2026) — à la
/// une, à venir, près de moi, privés, conférences et rencontres, tous
/// les événements avec filtres. Remplace l'ancien fil générique pour les
/// événements uniquement ; le fil de publications classique reste sur
/// l'onglet "Communauté".
class EventsTab extends ConsumerStatefulWidget {
  const EventsTab({super.key});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  String? _categoryFilter;
  String? _formatFilter;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allPublishedEventsProvider);
    final myProfil = ref.watch(profilProvider).value;
    final organizerStatus = ref.watch(myOrganizerStatusProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navEvents),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyParticipationsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.noirProfond,
        icon: Icon(organizerStatus == 'approved' ? Icons.add : Icons.campaign_outlined),
        label: Text(organizerStatus == 'approved' ? context.l10n.createEventButton : context.l10n.becomeOrganizerTitle),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => organizerStatus == 'approved'
                ? const OrganizerDashboardScreen()
                : const OrganizerRequestScreen(),
          ),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.feedLoadFailed)),
        data: (events) {
          if (events.isEmpty) {
            return Center(child: Text(context.l10n.nothingToShowYet));
          }
          final now = DateTime.now();
          final upcoming = events.where((e) => e.eventDate == null || e.eventDate!.isAfter(now)).toList()
            ..sort((a, b) => (a.eventDate ?? now).compareTo(b.eventDate ?? now));
          // "À la une" : les plus proches dans le temps, approximation
          // raisonnable faute d'un champ "mis en avant" dédié dans la
          // spec (section 6 ne liste pas de drapeau "featured").
          final featured = upcoming.take(5).toList();
          final nearMe = myProfil?.city != null
              ? upcoming.where((e) => e.city?.toLowerCase() == myProfil!.city.toLowerCase()).toList()
              : <CommunityPost>[];
          final private = upcoming.where((e) => e.type == 'evenement_prive').toList();
          final conferences = upcoming.where((e) => _conferenceCategories.contains(e.category)).toList();
          final filtered = upcoming.where((e) {
            if (_categoryFilter != null && e.category != _categoryFilter) return false;
            if (_formatFilter != null && e.format != _formatFilter) return false;
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            children: [
              if (featured.isNotEmpty) ...[
                _SectionTitle(context.l10n.eventsFeaturedTitle),
                _HorizontalEventList(events: featured),
                const SizedBox(height: 22),
              ],
              _SectionTitle(context.l10n.eventsUpcomingTitle),
              _HorizontalEventList(events: upcoming.take(10).toList()),
              const SizedBox(height: 22),
              if (nearMe.isNotEmpty) ...[
                _SectionTitle(context.l10n.eventsNearMeTitle),
                _HorizontalEventList(events: nearMe),
                const SizedBox(height: 22),
              ],
              if (private.isNotEmpty) ...[
                _SectionTitle(context.l10n.eventsPrivateTitle),
                _HorizontalEventList(events: private),
                const SizedBox(height: 22),
              ],
              if (conferences.isNotEmpty) ...[
                _SectionTitle(context.l10n.eventsConferencesTitle),
                _HorizontalEventList(events: conferences),
                const SizedBox(height: 22),
              ],
              _SectionTitle(context.l10n.eventsAllTitle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._eventCategories.map((c) => FilterChip(
                        label: Text(eventCategoryLabel(c, context.l10n)),
                        selected: _categoryFilter == c,
                        onSelected: (v) => setState(() => _categoryFilter = v ? c : null),
                      )),
                  FilterChip(
                    label: Text(context.l10n.eventFormatPresentiel),
                    selected: _formatFilter == 'presentiel',
                    onSelected: (v) => setState(() => _formatFilter = v ? 'presentiel' : null),
                  ),
                  FilterChip(
                    label: Text(context.l10n.eventFormatEnLigne),
                    selected: _formatFilter == 'en_ligne',
                    onSelected: (v) => setState(() => _formatFilter = v ? 'en_ligne' : null),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final e in filtered) _EventListTile(event: e),
            ],
          );
        },
      ),
    );
  }
}

const _eventCategories = ['soiree', 'conference', 'atelier', 'exposition', 'debat', 'projection', 'rencontre'];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppTypography.editorialTitle(fontSize: 17)),
    );
  }
}

class _HorizontalEventList extends StatelessWidget {
  const _HorizontalEventList({required this.events});
  final List<CommunityPost> events;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _EventCard(event: events[i]),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});
  final CommunityPost event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterUrl =
        event.posterStoragePath != null ? ref.watch(eventPosterUrlProvider(event.posterStoragePath!)).value : null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: event)),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              color: AppColors.placeholder,
              child: posterUrl != null
                  ? Image.network(posterUrl, fit: BoxFit.cover)
                  : const Icon(Icons.event_outlined, color: AppColors.placeholderIcon),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? event.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  if (event.city != null)
                    Text(event.city!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({required this.event});
  final CommunityPost event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(event.title ?? event.text, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          [
            if (event.category != null) eventCategoryLabel(event.category!, context.l10n),
            if (event.city != null) event.city!,
          ].join(' · '),
        ),
        trailing: Text('${event.participantsCount}/${event.capacity ?? "-"}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: event)),
        ),
      ),
    );
  }
}
