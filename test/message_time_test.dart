import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:merut/core/utils/message_time.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final now = DateTime(2026, 11, 13, 18, 0);
  String fmt(DateTime at) =>
      formatMessageTime(at, now, locale: 'fr', yesterdayLabel: 'hier');

  test('même jour : l\'heure', () {
    expect(fmt(DateTime(2026, 11, 13, 14, 2)), '14:02');
  });
  test('la veille : le libellé traduit', () {
    expect(fmt(DateTime(2026, 11, 12, 23, 59)), 'hier');
  });
  test('moins d\'une semaine : le jour abrégé', () {
    expect(fmt(DateTime(2026, 11, 9, 10, 0)), 'lun.');
  });
  test('plus ancien : jour et mois', () {
    expect(fmt(DateTime(2026, 10, 1, 10, 0)), '01/10');
  });
}
