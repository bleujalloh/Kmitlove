import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kamalove/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  testWidgets('Kamalove affiche son nom et la charte sur l\'accueil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onAccepted: () {})),
    );

    expect(find.text('Kamalove'), findsOneWidget);
    expect(find.text('CHARTE COMMUNAUTAIRE'), findsOneWidget);
  });
}
