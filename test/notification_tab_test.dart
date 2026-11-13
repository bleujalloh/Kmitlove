import 'package:flutter_test/flutter_test.dart';
import 'package:merut/core/router/main_shell.dart';

void main() {
  test('chaque type de notification ouvre le bon onglet', () {
    expect(tabForNotificationType('message'), 2);
    expect(tabForNotificationType('match'), 2);
    expect(tabForNotificationType('like'), 1);
    expect(tabForNotificationType('event_reminder'), isNull);
    expect(tabForNotificationType(null), isNull);
  });
}
