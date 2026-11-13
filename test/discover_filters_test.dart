import 'package:flutter_test/flutter_test.dart';
import 'package:merut/features/decouvrir/domain/candidate.dart';

void main() {
  group('DiscoverFilters.toMap', () {
    test('valeurs par défaut : rien d\'optionnel n\'est envoyé', () {
      expect(const DiscoverFilters().toMap(), {'maxDistanceKm': 100});
    });

    test('genre et "Ma position" coupée sont envoyés', () {
      final map = const DiscoverFilters(
        gender: 'Femme',
        useMyLocation: false,
      ).toMap();
      expect(map['gender'], 'Femme');
      expect(map['useMyLocation'], false);
    });
  });

  group('DiscoverFilters.copyWith', () {
    const base = DiscoverFilters(
      country: 'France',
      city: 'Paris',
      gender: 'Homme',
    );

    test('clearGender retire le genre', () {
      expect(base.copyWith(clearGender: true).gender, isNull);
    });

    test('clearCity retire la ville mais garde le pays', () {
      final next = base.copyWith(clearCity: true);
      expect(next.city, isNull);
      expect(next.country, 'France');
    });

    test('clearLocation retire pays et ville mais garde le genre', () {
      final next = base.copyWith(clearLocation: true);
      expect(next.country, isNull);
      expect(next.city, isNull);
      expect(next.gender, 'Homme');
    });

    test('un changement de pays peut effacer la ville en une fois', () {
      final next = base.copyWith(country: 'Belgique', clearCity: true);
      expect(next.country, 'Belgique');
      expect(next.city, isNull);
    });
  });
}
