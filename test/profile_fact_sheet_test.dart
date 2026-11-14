import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/core/widgets/profile_fact_sheet.dart';
import 'package:merut/features/compatibilite/domain/compat_result.dart';
import 'package:merut/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    ...AppLocalizations.localizationsDelegates,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))),
);

void main() {
  testWidgets('une fiche complète montre TOUS les contenus saisis, dans l\'ordre voulu', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const ProfileFactSheet(
          bio: 'Je suis posée et curieuse.',
          interests: ['Histoire', 'Cuisine'],
          age: 29,
          heightCm: 170,
          educationLevel: 'Master',
          profession: 'Architecte',
          relationshipIntent: 'relation_serieuse',
          childrenStatus: 'veut_des_enfants',
          smokingHabit: 'jamais',
          drinkingHabit: 'parfois',
          values: 'La loyauté avant tout.',
          lookingFor: 'Quelqu\'un de sincère.',
          qualities: ['Calme', 'Loyal(e)'],
          languages: ['Français', 'Anglais'],
          culturalOrigins: ['Guinée'],
          compatThemes: [CompatThemeScore(theme: 'famille', score: 90)],
        ),
      ),
    );
    await tester.pump();

    for (final text in [
      'Recherche : Relation sérieuse',
      'Vous vous accordez surtout sur : Famille',
      'Présentation',
      'Je suis posée et curieuse.',
      'Ce que je recherche chez l\'autre',
      'Quelqu\'un de sincère.',
      'Mes valeurs',
      'La loyauté avant tout.',
      'Mes qualités',
      'Calme',
      'Centres d\'intérêt',
      'Histoire',
      'En bref',
      'Français, Anglais',
      'Origines culturelles',
      'Guinée',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    // Ordre : intention, présentation, citations, qualités, intérêts, en bref, origines.
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    final order = [
      y('Recherche : Relation sérieuse'),
      y('Présentation'),
      y('Ce que je recherche chez l\'autre'),
      y('Mes valeurs'),
      y('Mes qualités'),
      y('Centres d\'intérêt'),
      y('En bref'),
      y('Origines culturelles'),
    ];
    expect(order, orderedEquals([...order]..sort()));
  });

  testWidgets('une fiche presque vide n\'affiche aucun titre sans contenu', (tester) async {
    await tester.pumpWidget(_app(const ProfileFactSheet(bio: '', interests: [], age: 31)));
    await tester.pump();

    for (final title in [
      'Présentation',
      'Ce que je recherche chez l\'autre',
      'Mes valeurs',
      'Mes qualités',
      'Centres d\'intérêt',
      'Origines culturelles',
    ]) {
      expect(find.text(title), findsNothing, reason: title);
    }
    expect(find.text('En bref'), findsOneWidget); // l'âge est toujours connu
  });

  test('CompatResult.strongest garde les deux meilleurs thèmes au-dessus du seuil', () {
    final result = CompatResult.fromMap({
      'score': 80,
      'themes': [
        {'theme': 'famille', 'score': 95},
        {'theme': 'mode_vie', 'score': 60},
        {'theme': 'valeurs_culture', 'score': 85},
        {'theme': 'communication', 'score': 72},
      ],
    });
    expect(result.strongest().map((t) => t.theme), ['famille', 'valeurs_culture']);
    expect(CompatResult.fromMap({'score': null}).strongest(), isEmpty);
  });
}
