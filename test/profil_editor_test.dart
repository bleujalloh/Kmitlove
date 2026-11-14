import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/features/profil/domain/profil.dart';
import 'package:merut/features/profil/presentation/screens/profil_wizard_screen.dart';
import 'package:merut/l10n/app_localizations.dart';

Widget _app(Widget home) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Profil _profil({String bio = 'Je suis posée et curieuse.'}) => Profil(
  displayName: 'Awa',
  birthDate: DateTime(1995, 3, 14),
  gender: Gender.femme,
  seekingGenders: const [Gender.homme],
  country: 'France',
  city: 'Paris',
  bio: bio,
  relationshipIntent: RelationshipIntent.serieuse,
);

void main() {
  testWidgets('modifier le profil : vue d\'ensemble avec les rubriques de l\'assistant, sans le genre figé', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(ProfilWizardScreen(existing: _profil())));
    await tester.pump();

    expect(find.text('Ton profil'), findsOneWidget);
    for (final title in [
      'Prénom et date de naissance',
      'Je recherche',
      'Ce que je cherche',
      'Où j\'habite',
      'Présentation',
      'Mes qualités',
      'Intérêts, origines et valeurs',
      'Métier, langues, taille, études',
      'Mode de vie',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // Le genre est figé à l'inscription : aucune rubrique pour le modifier.
    expect(find.text('Genre'), findsNothing);
    // Les résumés viennent du profil existant.
    expect(find.text('Awa'), findsOneWidget);
    expect(find.text('Paris · France'), findsOneWidget);
    expect(find.text('Je suis posée et curieuse.'), findsOneWidget);
    expect(find.text('Enregistrer mon profil'), findsOneWidget);
  });

  testWidgets('une rubrique obligatoire vide est signalée et bloque l\'enregistrement', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(ProfilWizardScreen(existing: _profil(bio: ''))));
    await tester.pump();

    expect(find.text('À compléter'), findsOneWidget);
    final save = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enregistrer mon profil'));
    expect(save.onPressed, isNull);
  });

  testWidgets('toucher une rubrique ouvre son écran, « Terminé » revient à la vue d\'ensemble', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(ProfilWizardScreen(existing: _profil())));
    await tester.pump();

    await tester.tap(find.text('Présentation'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);

    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer mon profil'), findsOneWidget);
  });
}
