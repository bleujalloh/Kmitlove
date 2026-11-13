import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/core/utils/distance.dart';
import 'package:merut/features/communaute/domain/community_post.dart';
import 'package:merut/features/communaute/domain/event_filters.dart';

CommunityPost event(
  String id, {
  DateTime? date,
  String? country,
  String? city,
  String? category,
  String? format,
  String? accessMode,
  int participants = 0,
  int? capacity,
}) {
  return CommunityPost(
    id: id,
    type: 'evenement_public',
    authorUid: 'a',
    text: id,
    status: 'published',
    eventDate: date,
    country: country,
    city: city,
    category: category,
    format: format,
    accessMode: accessMode,
    participantsCount: participants,
    capacity: capacity,
  );
}

void main() {
  final now = DateTime(2026, 11, 13, 18, 0);
  final today = event('today', date: DateTime(2026, 11, 13, 20));
  final inThreeDays = event('d3', date: DateTime(2026, 11, 16, 19), country: 'France', city: 'Paris');
  final inTwoWeeks = event('w2', date: DateTime(2026, 11, 27, 19), country: 'France', city: 'Lyon');
  final inTwoMonths = event('m2', date: DateTime(2027, 1, 20, 19), country: 'Belgique', city: 'Bruxelles');
  final all = [today, inThreeDays, inTwoWeeks, inTwoMonths];

  List<String> ids(EventFilters f, {Map<String, double> d = const {}}) =>
      applyEventFilters(all, f, now, distancesKm: d).map((e) => e.id).toList();

  test('sans filtre, tout passe', () {
    expect(ids(const EventFilters()), ['today', 'd3', 'w2', 'm2']);
  });

  test('date : aujourd\'hui, 7 jours, 30 jours, plage choisie', () {
    expect(ids(const EventFilters(dateMode: EventDateMode.today)), ['today']);
    expect(ids(const EventFilters(dateMode: EventDateMode.week)), ['today', 'd3']);
    expect(ids(const EventFilters(dateMode: EventDateMode.month)), ['today', 'd3', 'w2']);
    final range = DateTimeRange(start: DateTime(2026, 11, 25), end: DateTime(2026, 11, 27));
    expect(ids(EventFilters(dateMode: EventDateMode.custom, customRange: range)), ['w2']);
  });

  test('pays et ville (sans tenir compte de la casse)', () {
    expect(ids(const EventFilters(country: 'france')), ['d3', 'w2']);
    expect(ids(const EventFilters(city: 'LYO')), ['w2']);
    expect(ids(const EventFilters(country: 'Belgique', city: 'paris')), isEmpty);
  });

  test('distance : seuls les événements à portée, ceux sans distance sont exclus', () {
    final d = {'d3': 12.0, 'w2': 390.0};
    expect(ids(const EventFilters(maxDistanceKm: 50), d: d), ['d3']);
    expect(ids(const EventFilters(maxDistanceKm: 500), d: d), ['d3', 'w2']);
    expect(ids(const EventFilters(maxDistanceKm: 500)), isEmpty);
  });

  test('catégorie, format, accès, places disponibles', () {
    final list = [
      event('a', category: 'soiree', format: 'presentiel', accessMode: 'public', participants: 5, capacity: 5),
      event('b', category: 'atelier', format: 'en_ligne', accessMode: 'sur_demande', participants: 1, capacity: 5),
    ];
    List<String> run(EventFilters f) => applyEventFilters(list, f, now).map((e) => e.id).toList();
    expect(run(const EventFilters(category: 'atelier')), ['b']);
    expect(run(const EventFilters(format: 'presentiel')), ['a']);
    expect(run(const EventFilters(accessMode: 'sur_demande')), ['b']);
    expect(run(const EventFilters(onlyAvailable: true)), ['b']);
  });

  test('activeCount et copyWith', () {
    const f = EventFilters();
    expect(f.isActive, isFalse);
    final g = f.copyWith(country: () => 'France', onlyAvailable: true);
    expect(g.activeCount, 2);
    expect(g.copyWith(country: () => null).activeCount, 1);
  });

  test('haversine : Paris - Lyon ≈ 392 km', () {
    final km = haversineKm(48.8566, 2.3522, 45.7640, 4.8357);
    expect(km, inInclusiveRange(385, 400));
  });
}
