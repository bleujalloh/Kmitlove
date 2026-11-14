import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../../domain/community_post.dart';
import '../../domain/event_filters.dart';
import '../communaute_controller.dart';
import 'my_participations_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_request_screen.dart';
import 'event_filters_sheet.dart';
import 'post_detail_screen.dart';

const _conferenceCategories = ['conference', 'rencontre', 'debat', 'projection'];

/// Onglet "Événements" (spec Communauté section 1/10, 11/11/2026) — à la
/// une, à venir, près de moi, privés, conférences et rencontres, tous
/// les événements avec filtres. Remplace l'ancien fil générique pour les
/// événements uniquement ; le fil de publications classique reste sur
/// l'onglet "Communauté".
class EventsTab extends ConsumerWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(eventFiltersProvider);
    final distancesAsync = ref.watch(eventDistancesProvider);
    final eventsAsync = ref.watch(allPublishedEventsProvider);
    final myProfil = ref.watch(profilProvider).value;
    final organizerStatus = ref.watch(myOrganizerStatusProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navEvents),
        // Communauté a maintenant sa propre AppBar avec retour (toujours
        // atteinte via Navigator.push depuis Messages, 12/11/2026) — cette
        // AppBar imbriquée (sous-onglet "Événements", affichée au milieu
        // de l'écran, pas tout en haut) verrait sinon apparaître SA
        // PROPRE flèche retour en plus de celle de l'AppBar englobante,
        // deux contrôles distincts faisant strictement la même chose
        // (trouvé par revue de code).
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: context.l10n.redeemInviteCodeButton,
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _redeemCodeDialog(context, ref),
          ),
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
          final filtered = applyEventFilters(
            upcoming,
            filters,
            now,
            distancesKm: distancesAsync.value ?? const {},
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            children: [
              _FiltersBar(filters: filters),
              const SizedBox(height: 14),
              if (filters.isActive) ...[
                if (filters.maxDistanceKm != null && distancesAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      context.l10n.eventsNoResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else ...[
                  _SectionTitle(context.l10n.eventsResultsCount(filtered.length)),
                  for (final e in filtered) _EventListTile(event: e),
                ],
              ] else ...[
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
                for (final e in upcoming) _EventListTile(event: e),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> _redeemCodeDialog(BuildContext context, WidgetRef ref) async {
  final codeController = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.redeemInviteCodeButton),
      content: TextField(
        controller: codeController,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: context.l10n.redeemInviteCodeHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancelButton)),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(codeController.text.trim()),
          child: Text(context.l10n.validateButton),
        ),
      ],
    ),
  );
  if (code == null || code.isEmpty || !context.mounted) return;
  try {
    await ref.read(communauteControllerProvider).redeemEventInviteCode(code);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.redeemInviteCodeSuccess)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.redeemInviteCodeFailed)));
    }
  }
}

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
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: event)),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  : Icon(Icons.event_outlined, color: AppColors.placeholderIcon),
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
                    Text(event.city!, style: TextStyle(fontSize: 11, color: AppColors.muted)),
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
        borderRadius: BorderRadius.circular(AppRadii.lg),
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

/// Bouton « Filtres » + une pastille supprimable par filtre actif.
class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.filters});
  final EventFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(eventFiltersProvider.notifier);
    void update(EventFilters f) => notifier.state = f;
    final chips = <Widget>[
      if (filters.dateMode != EventDateMode.any)
        InputChip(
          label: Text(_dateChipLabel(context, filters)),
          onDeleted: () => update(filters.copyWith(dateMode: EventDateMode.any, customRange: () => null)),
        ),
      if (filters.country != null)
        InputChip(label: Text(filters.country!), onDeleted: () => update(filters.copyWith(country: () => null))),
      if (filters.city?.trim().isNotEmpty ?? false)
        InputChip(label: Text(filters.city!), onDeleted: () => update(filters.copyWith(city: () => null))),
      if (filters.maxDistanceKm != null)
        InputChip(
          label: Text('≤ ${context.l10n.eventsDistanceValue(filters.maxDistanceKm!)}'),
          onDeleted: () => update(filters.copyWith(maxDistanceKm: () => null)),
        ),
      if (filters.category != null)
        InputChip(
          label: Text(eventCategoryLabel(filters.category!, context.l10n)),
          onDeleted: () => update(filters.copyWith(category: () => null)),
        ),
      if (filters.format != null)
        InputChip(
          label: Text(filters.format == 'en_ligne' ? context.l10n.eventFormatEnLigne : context.l10n.eventFormatPresentiel),
          onDeleted: () => update(filters.copyWith(format: () => null)),
        ),
      if (filters.accessMode != null)
        InputChip(
          label: Text(eventAccessModeLabel(filters.accessMode!, context.l10n)),
          onDeleted: () => update(filters.copyWith(accessMode: () => null)),
        ),
      if (filters.onlyAvailable)
        InputChip(
          label: Text(context.l10n.eventsFilterAvailable),
          onDeleted: () => update(filters.copyWith(onlyAvailable: false)),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: () => showEventFiltersSheet(context),
          child: Text(
            filters.isActive
                ? '${context.l10n.eventsFiltersButton} · ${filters.activeCount}'
                : context.l10n.eventsFiltersButton,
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: chips),
        ],
      ],
    );
  }
}

String _dateChipLabel(BuildContext context, EventFilters f) {
  switch (f.dateMode) {
    case EventDateMode.today:
      return context.l10n.eventsDateToday;
    case EventDateMode.week:
      return context.l10n.eventsDateWeek;
    case EventDateMode.month:
      return context.l10n.eventsDateMonth;
    case EventDateMode.custom:
      final r = f.customRange;
      if (r == null) return context.l10n.eventsDateCustom;
      final loc = MaterialLocalizations.of(context);
      return '${loc.formatShortDate(r.start)} → ${loc.formatShortDate(r.end)}';
    case EventDateMode.any:
      return '';
  }
}
