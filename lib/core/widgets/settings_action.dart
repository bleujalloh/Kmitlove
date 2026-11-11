import 'package:flutter/material.dart';

import '../../features/parametres/presentation/screens/parametres_screen.dart';

/// Icône Paramètres partagée par les 4 onglets principaux (Découvrir,
/// Likes, Messages, Communauté) — seul point d'accès aux réglages et aux
/// fonctionnalités secondaires (Premium, test de compatibilité,
/// vérification d'identité, administration), toutes regroupées dans
/// Paramètres plutôt qu'éparpillées, comme sur les applications de
/// rencontre courantes.
Widget buildSettingsAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ParametresScreen()),
    ),
  );
}
