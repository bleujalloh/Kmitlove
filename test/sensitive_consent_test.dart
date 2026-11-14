import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/core/widgets/image_viewer.dart';
import 'package:merut/features/parametres/settings_controller.dart';

void main() {
  group('hasSensitiveConsent (porte d\'entrée RGPD art. 9)', () {
    test('statut absent ou sans consentement : refusé', () {
      expect(hasSensitiveConsent(null), isFalse);
      expect(hasSensitiveConsent(<String, dynamic>{}), isFalse);
      expect(hasSensitiveConsent({'sensitiveConsent': null}), isFalse);
      expect(hasSensitiveConsent({'sensitiveConsent': 'oui'}), isFalse);
    });

    test('consentement retiré : refusé', () {
      expect(hasSensitiveConsent({'sensitiveConsent': {'granted': false, 'version': 1}}), isFalse);
    });

    test('consentement donné : accepté', () {
      expect(hasSensitiveConsent({'sensitiveConsent': {'granted': true, 'version': 1}}), isTrue);
    });
  });

  testWidgets('ZoomPager affiche l\'image courante et défile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomPager(
            itemCount: 3,
            itemBuilder: (context, i) => Text('image $i'),
          ),
        ),
      ),
    );
    expect(find.text('image 0'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('image 1'), findsOneWidget);
  });
}
