import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    group('contrastes du thème ${entry.key}', () {
      test('texte principal sur fond et sur carte : au moins 7:1', () {
        expect(contrast(p.ink, p.background), greaterThanOrEqualTo(7));
        expect(contrast(p.ink, p.backgroundSoft), greaterThanOrEqualTo(7));
      });
      test('texte secondaire sur fond et sur carte : au moins 4,5:1', () {
        expect(contrast(p.muted, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.muted, p.backgroundSoft), greaterThanOrEqualTo(4.5));
      });
      test('or d\'accent lisible (icônes, libellés en gras) : au moins 3:1', () {
        expect(contrast(p.accent, p.background), greaterThanOrEqualTo(3));
        expect(contrast(p.accent, p.backgroundSoft), greaterThanOrEqualTo(3));
      });
      test('texte noir sur un bouton or : au moins 4:1', () {
        expect(contrast(AppColors.noirProfond, p.accent), greaterThanOrEqualTo(4));
      });
      test('barre du bas : onglet inactif lisible', () {
        expect(contrast(p.navUnselected.withAlpha(255), p.navBackground), greaterThanOrEqualTo(4.5));
      });
    });
  }
}
