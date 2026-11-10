import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:merut/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:merut/l10n/app_localizations.dart';

void main() {
  testWidgets('MERUT affiche son nom et la charte sur l\'accueil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(onAccepted: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MERUT'), findsOneWidget);
    expect(find.text('CHARTE COMMUNAUTAIRE'), findsOneWidget);
  });
}
