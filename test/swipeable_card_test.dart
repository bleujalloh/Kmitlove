import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/features/decouvrir/presentation/widgets/swipeable_card.dart';

Widget host({
  required Future<bool> Function() onLike,
  required Future<bool> Function() onPass,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SwipeableCard(
        onSwipeLike: onLike,
        onSwipePass: onPass,
        likeLabel: 'LIKE',
        passLabel: 'PASSE',
        child: const SizedBox(key: Key('carte'), width: 300, height: 400),
      ),
    ),
  );
}

void main() {
  const carte = Key('carte');

  testWidgets('un coup de doigt rapide vers la droite = like, une seule fois', (tester) async {
    var likes = 0;
    var passes = 0;
    await tester.pumpWidget(host(onLike: () async => ++likes > 0, onPass: () async => ++passes > 0));
    await tester.fling(find.byKey(carte), const Offset(120, 0), 2000);
    await tester.pumpAndSettle();
    expect(likes, 1);
    expect(passes, 0);
  });

  testWidgets('un glissement long vers la gauche = passe', (tester) async {
    var passes = 0;
    await tester.pumpWidget(host(onLike: () async => true, onPass: () async => ++passes > 0));
    await tester.drag(find.byKey(carte), const Offset(-220, 0));
    await tester.pumpAndSettle();
    expect(passes, 1);
  });

  testWidgets('un petit glissement lent ne valide rien et la carte revient', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(onLike: () async => ++calls > 0, onPass: () async => ++calls > 0));
    final start = tester.getTopLeft(find.byKey(carte));
    await tester.drag(find.byKey(carte), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.getTopLeft(find.byKey(carte)).dx, closeTo(start.dx, 0.5));
  });

  testWidgets('action refusée (false) : la carte revient au centre', (tester) async {
    await tester.pumpWidget(host(onLike: () async => false, onPass: () async => false));
    final start = tester.getTopLeft(find.byKey(carte));
    await tester.drag(find.byKey(carte), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(carte)).dx, closeTo(start.dx, 0.5));
  });

  testWidgets('action qui échoue (exception) : pas de plantage, la carte revient', (tester) async {
    await tester.pumpWidget(host(onLike: () async => throw StateError('réseau'), onPass: () async => true));
    final start = tester.getTopLeft(find.byKey(carte));
    await tester.drag(find.byKey(carte), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.byKey(carte)).dx, closeTo(start.dx, 0.5));
  });

  testWidgets('pendant qu\'une action est en cours, un second geste est ignoré', (tester) async {
    var likes = 0;
    final slow = <Future<bool> Function()>[];
    await tester.pumpWidget(host(
      onLike: () {
        likes++;
        return Future<bool>.delayed(const Duration(seconds: 1), () => true);
      },
      onPass: () async => true,
    ));
    slow.clear();
    await tester.drag(find.byKey(carte), const Offset(250, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byKey(carte), const Offset(250, 0), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(likes, 1);
  });

  testWidgets('la carte retirée pendant l\'action ne provoque aucune erreur', (tester) async {
    await tester.pumpWidget(host(
      onLike: () => Future<bool>.delayed(const Duration(milliseconds: 500), () => false),
      onPass: () async => true,
    ));
    await tester.drag(find.byKey(carte), const Offset(250, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
