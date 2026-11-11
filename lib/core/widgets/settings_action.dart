import 'package:flutter/material.dart';

import '../../features/parametres/presentation/screens/parametres_screen.dart';

/// Icône Paramètres — réglages purs uniquement (langue, confidentialité,
/// export RGPD, déconnexion, suppression de compte). Les fonctionnalités
/// qui concernent la fiche elle-même (modifier le profil, Premium, test de
/// compatibilité, vérification d'identité, administration) vivent sur
/// l'onglet Profil, seul endroit d'où cette icône est maintenant
/// accessible (avant le 11/11, elle était dupliquée dans les 4 autres
/// onglets).
Widget buildSettingsAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ParametresScreen()),
    ),
  );
}
