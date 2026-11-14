import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/core/theme/app_background.dart';
import 'package:merut/core/theme/app_theme.dart';

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {'sombre': AppPalette.dark, 'clair': AppPalette.light}.entries) {
    final p = entry.value;
    final dark = entry.key == 'sombre';
    // Fond et cartes sont translucides sur le dégradé : on teste le pire
    // cas, c'est-à-dire chaque teinte du dégradé, avec et sans carte posée.
    final surfaces = <Color>[
      for (final t in AppBackground.tints(dark: dark)) ...[t, Color.alphaBlend(p.backgroundSoft, t)],
    ];
    group('contrastes du thème ${entry.key}', () {
      test('texte principal sur fond et sur carte : au moins 7:1', () {
        for (final s in surfaces) {
          expect(contrast(p.ink, s), greaterThanOrEqualTo(7), reason: 'sur $s');
        }
      });
      test('texte secondaire sur fond et sur carte : au moins 4,5:1', () {
        for (final s in surfaces) {
          expect(contrast(p.muted, s), greaterThanOrEqualTo(4.5), reason: 'sur $s');
        }
      });
      test("or d'accent lisible (icônes, libellés en gras) : au moins 3:1", () {
        for (final s in surfaces) {
          expect(contrast(p.accent, s), greaterThanOrEqualTo(3), reason: 'sur $s');
        }
      });
      test('texte noir sur un bouton or : au moins 4:1', () {
        expect(contrast(AppColors.noirProfond, p.accent), greaterThanOrEqualTo(4));
      });
      test('barre du bas : onglet inactif lisible', () {
        final nav = Color.alphaBlend(p.navBackground, AppBackground.tints(dark: dark).first);
        expect(contrast(p.navUnselected.withAlpha(255), nav), greaterThanOrEqualTo(4.5));
      });
    });
  }
}
