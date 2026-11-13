import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:merut/features/decouvrir/presentation/detected_place_provider.dart';

void main() {
  group('placeFromPlacemark', () {
    test('prend le pays et la localité', () {
      final place = placeFromPlacemark(
        const Placemark(country: 'France', locality: 'Paris'),
      );
      expect(place.country, 'France');
      expect(place.city, 'Paris');
    });

    test('à défaut de localité, utilise la zone administrative secondaire', () {
      final place = placeFromPlacemark(
        const Placemark(
          country: 'France',
          locality: '  ',
          subAdministrativeArea: 'Hauts-de-Seine',
        ),
      );
      expect(place.city, 'Hauts-de-Seine');
    });

    test('une valeur vide ou absente est traitée comme absente', () {
      final place = placeFromPlacemark(
        const Placemark(country: '', locality: null),
      );
      expect(place.country, isNull);
      expect(place.city, isNull);
    });
  });
}
