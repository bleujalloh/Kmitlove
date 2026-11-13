import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/country_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../../domain/event_filters.dart';
import '../communaute_controller.dart';

const _eventCategories = ['soiree', 'conference', 'atelier', 'exposition', 'debat', 'projection', 'rencontre'];
const _accessModes = ['public', 'sur_demande', 'sur_invitation'];

/// Ouvre la feuille de filtres de l'onglet Événements.
Future<void> showEventFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (_) => const _EventFiltersSheet(),
  );
}

class _EventFiltersSheet extends ConsumerStatefulWidget {
  const _EventFiltersSheet();

  @override
  ConsumerState<_EventFiltersSheet> createState() => _EventFiltersSheetState();
}

class _EventFiltersSheetState extends ConsumerState<_EventFiltersSheet> {
  late EventFilters _draft = ref.read(eventFiltersProvider);
  late final TextEditingController _cityController = TextEditingController(text: _draft.city ?? '');

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  String _dateLabel(EventDateMode mode) {
    switch (mode) {
      case EventDateMode.any:
        return context.l10n.eventsDateAny;
      case EventDateMode.today:
        return context.l10n.eventsDateToday;
      case EventDateMode.week:
        return context.l10n.eventsDateWeek;
      case EventDateMode.month:
        return context.l10n.eventsDateMonth;
      case EventDateMode.custom:
        final r = _draft.customRange;
        if (r == null) return context.l10n.eventsDateCustom;
        final loc = MaterialLocalizations.of(context);
        return '${loc.formatShortDate(r.start)} → ${loc.formatShortDate(r.end)}';
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _draft.customRange,
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(dateMode: EventDateMode.custom, customRange: () => picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(userStatusProvider).value;
    final hasPosition = status?['locationLat'] is num && status?['locationLng'] is num;
    final distance = _draft.maxDistanceKm;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent)),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scroll) => Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: [
                    Text(context.l10n.eventsFiltersTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    label(context.l10n.eventsFilterDate),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mode in EventDateMode.values)
                          ChoiceChip(
                            label: Text(_dateLabel(mode)),
                            selected: _draft.dateMode == mode,
                            onSelected: (_) {
                              if (mode == EventDateMode.custom) {
                                _pickRange();
                              } else {
                                setState(() => _draft = _draft.copyWith(dateMode: mode, customRange: () => null));
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: CountryField(
                            label: context.l10n.eventsFilterCountry,
                            value: _draft.country,
                            onChanged: (c) => setState(() => _draft = _draft.copyWith(country: () => c)),
                          ),
                        ),
                        if (_draft.country != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _draft = _draft.copyWith(country: () => null)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(hintText: context.l10n.eventsFilterCity),
                      onChanged: (v) => _draft = _draft.copyWith(city: () => v.trim().isEmpty ? null : v.trim()),
                    ),
                    label(context.l10n.eventsFilterDistance),
                    if (!hasPosition)
                      Text(context.l10n.eventsDistanceNeedsPosition,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4))
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              min: 5,
                              max: 500,
                              divisions: 99,
                              value: (distance ?? 50).toDouble().clamp(5, 500),
                              label: context.l10n.eventsDistanceValue((distance ?? 50)),
                              onChanged: (v) =>
                                  setState(() => _draft = _draft.copyWith(maxDistanceKm: () => v.round())),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              distance == null ? '—' : context.l10n.eventsDistanceValue(distance),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          if (distance != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _draft = _draft.copyWith(maxDistanceKm: () => null)),
                            ),
                        ],
                      ),
                      Text(context.l10n.eventsDistanceApproximate,
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    ],
                    label(context.l10n.eventsFilterCategory),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _eventCategories)
                          FilterChip(
                            label: Text(eventCategoryLabel(c, context.l10n)),
                            selected: _draft.category == c,
                            onSelected: (v) => setState(() => _draft = _draft.copyWith(category: () => v ? c : null)),
                          ),
                      ],
                    ),
                    label(context.l10n.eventsFilterFormat),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(context.l10n.eventFormatPresentiel),
                          selected: _draft.format == 'presentiel',
                          onSelected: (v) =>
                              setState(() => _draft = _draft.copyWith(format: () => v ? 'presentiel' : null)),
                        ),
                        FilterChip(
                          label: Text(context.l10n.eventFormatEnLigne),
                          selected: _draft.format == 'en_ligne',
                          onSelected: (v) =>
                              setState(() => _draft = _draft.copyWith(format: () => v ? 'en_ligne' : null)),
                        ),
                      ],
                    ),
                    label(context.l10n.eventsFilterAccess),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final a in _accessModes)
                          FilterChip(
                            label: Text(eventAccessModeLabel(a, context.l10n)),
                            selected: _draft.accessMode == a,
                            onSelected: (v) => setState(() => _draft = _draft.copyWith(accessMode: () => v ? a : null)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.eventsFilterAvailable),
                      value: _draft.onlyAvailable,
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(onlyAvailable: v)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () {
                        ref.read(eventFiltersProvider.notifier).state = const EventFilters();
                        Navigator.of(context).pop();
                      },
                      child: Text(context.l10n.eventsFiltersReset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(eventFiltersProvider.notifier).state = _draft;
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.eventsFiltersApply),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
