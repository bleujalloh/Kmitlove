import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kamalove/main.dart';

void main() {
  testWidgets('Kamalove démarre et affiche son nom', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KamaloveApp()));

    expect(find.text('Kamalove'), findsOneWidget);
  });
}
