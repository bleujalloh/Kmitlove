import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Arrière-plan de toutes les pages : dégradé pastel doux (menthe en haut à
/// gauche, rose pâle en haut à droite, bleu clair en bas), copié de
/// l'écran « Alarme » fourni par le propriétaire (14/11/2026). Version
/// sombre : mêmes teintes, profondes. Les cartes (`AppColors.backgroundSoft`)
/// sont translucides pour laisser voir ce fond.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  static const _darkBase = [Color(0xFF151B21), Color(0xFF10161C)];
  static const _lightBase = [Color(0xFFF4F4F8), Color(0xFFE9F4F8)];
  static const _darkMint = Color(0xFF1A3F3D);
  static const _lightMint = Color(0xFFCDEDE6);
  static const _darkBlush = Color(0xFF40262E);
  static const _lightBlush = Color(0xFFF9DDD6);

  /// Toutes les teintes que le fond peut prendre : sert aux tests de contraste
  /// (le texte doit rester lisible sur la carte translucide quelle que soit
  /// la zone du dégradé).
  static List<Color> tints({required bool dark}) =>
      dark ? [..._darkBase, _darkMint, _darkBlush] : [..._lightBase, _lightMint, _lightBlush];

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final base = dark ? _darkBase : _lightBase;
    final mint = dark ? _darkMint : _lightMint;
    final blush = dark ? _darkBlush : _lightBlush;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: base),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1.0, -1.0),
              radius: 1.15,
              colors: [mint, mint.withValues(alpha: 0)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.0, -0.95),
              radius: 1.0,
              colors: [blush, blush.withValues(alpha: 0)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Habille chaque page poussée avec l'arrière-plan (opaque : aucune
/// transparence entre deux pages pendant la transition). S'appuie sur la
/// transition de page standard de la plateforme.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const _inner = ZoomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _inner.buildTransitions<T>(route, context, animation, secondaryAnimation, AppBackground(child: child));
  }
}
