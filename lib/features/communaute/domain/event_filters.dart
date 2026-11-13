import 'package:flutter/foundation.dart' show ValueGetter;
import 'package:flutter/material.dart' show DateTimeRange;

import 'community_post.dart';

/// Fenêtre de date choisie dans les filtres de l'onglet Événements.
enum EventDateMode { any, today, week, month, custom }

/// Filtres de l'onglet Événements (demande du propriétaire, 13/11/2026 :
/// distance, pays, ville, date, etc.). Les catégories et formats
/// existaient déjà ; s'y ajoutent date, pays, ville, distance, mode
/// d'accès et places disponibles.
class EventFilters {
  const EventFilters({
    this.dateMode = EventDateMode.any,
    this.customRange,
    this.country,
    this.city,
    this.maxDistanceKm,
    this.category,
    this.format,
    this.accessMode,
    this.onlyAvailable = false,
  });

  final EventDateMode dateMode;
  final DateTimeRange? customRange;
  final String? country;
  final String? city;
  final int? maxDistanceKm;
  final String? category;
  final String? format; // presentiel | en_ligne
  final String? accessMode; // public | sur_demande | sur_invitation
  final bool onlyAvailable;

  int get activeCount =>
      (dateMode != EventDateMode.any ? 1 : 0) +
      (country != null ? 1 : 0) +
      ((city?.trim().isNotEmpty ?? false) ? 1 : 0) +
      (maxDistanceKm != null ? 1 : 0) +
      (category != null ? 1 : 0) +
      (format != null ? 1 : 0) +
      (accessMode != null ? 1 : 0) +
      (onlyAvailable ? 1 : 0);

  bool get isActive => activeCount > 0;

  /// Les champs optionnels se passent par fonction (`() => null` remet à
  /// zéro, absence = inchangé) : un simple `null` ne permettrait pas de
  /// distinguer « ne pas toucher » de « effacer ».
  EventFilters copyWith({
    EventDateMode? dateMode,
    ValueGetter<DateTimeRange?>? customRange,
    ValueGetter<String?>? country,
    ValueGetter<String?>? city,
    ValueGetter<int?>? maxDistanceKm,
    ValueGetter<String?>? category,
    ValueGetter<String?>? format,
    ValueGetter<String?>? accessMode,
    bool? onlyAvailable,
  }) {
    return EventFilters(
      dateMode: dateMode ?? this.dateMode,
      customRange: customRange != null ? customRange() : this.customRange,
      country: country != null ? country() : this.country,
      city: city != null ? city() : this.city,
      maxDistanceKm: maxDistanceKm != null ? maxDistanceKm() : this.maxDistanceKm,
      category: category != null ? category() : this.category,
      format: format != null ? format() : this.format,
      accessMode: accessMode != null ? accessMode() : this.accessMode,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}

String _norm(String value) => value.trim().toLowerCase();

/// Applique les filtres à une liste d'événements. `distancesKm` associe
/// l'identifiant d'un événement à sa distance (km) depuis la position du
/// membre ; un événement sans distance connue (en ligne, ville
/// introuvable) est exclu quand le filtre de distance est actif.
List<CommunityPost> applyEventFilters(
  List<CommunityPost> events,
  EventFilters filters,
  DateTime now, {
  Map<String, double> distancesKm = const {},
}) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  DateTime? rangeStart;
  DateTime? rangeEnd; // exclusif
  switch (filters.dateMode) {
    case EventDateMode.any:
      break;
    case EventDateMode.today:
      rangeStart = startOfToday;
      rangeEnd = startOfToday.add(const Duration(days: 1));
    case EventDateMode.week:
      rangeStart = startOfToday;
      rangeEnd = startOfToday.add(const Duration(days: 7));
    case EventDateMode.month:
      rangeStart = startOfToday;
      rangeEnd = startOfToday.add(const Duration(days: 30));
    case EventDateMode.custom:
      final range = filters.customRange;
      if (range != null) {
        rangeStart = DateTime(range.start.year, range.start.month, range.start.day);
        rangeEnd = DateTime(range.end.year, range.end.month, range.end.day).add(const Duration(days: 1));
      }
  }
  final city = filters.city == null ? '' : _norm(filters.city!);

  return events.where((e) {
    if (rangeStart != null && rangeEnd != null) {
      final date = e.eventDate?.toLocal();
      if (date == null || date.isBefore(rangeStart) || !date.isBefore(rangeEnd)) return false;
    }
    if (filters.country != null && _norm(e.country ?? '') != _norm(filters.country!)) return false;
    if (city.isNotEmpty && !_norm(e.city ?? '').contains(city)) return false;
    if (filters.maxDistanceKm != null) {
      final d = distancesKm[e.id];
      if (d == null || d > filters.maxDistanceKm!) return false;
    }
    if (filters.category != null && e.category != filters.category) return false;
    if (filters.format != null && e.format != filters.format) return false;
    if (filters.accessMode != null && e.accessMode != filters.accessMode) return false;
    if (filters.onlyAvailable && e.isFull) return false;
    return true;
  }).toList();
}
