import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Onglet : du texte seul. L'onglet actif est en gras et en or, les autres en
/// gris — ni pastille, ni contour, ni trait de soulignement, ni pictogramme
/// (demande du propriétaire, 13-14/11/2026 : « pas de bordure arrondie »,
/// puis « supprime toutes les lignes, sous-lignes et pictogrammes »). Le
/// paramètre `icon` est conservé pour les appelants mais n'est plus affiché.
class AppTab extends StatelessWidget {
  const AppTab({super.key, this.icon, required this.label, required this.selected, required this.onTap});

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.accent : AppColors.muted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
