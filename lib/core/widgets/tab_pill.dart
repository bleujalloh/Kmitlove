import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pilule d'onglet — système de design déjà en place (Communauté,
/// `_TabPill` dans communaute_screen.dart), extrait ici pour être
/// réutilisé tel quel par l'écran Likes plutôt que dupliqué (demande
/// explicite du propriétaire, 12/11/2026 : aligner Likes sur ce système
/// de pilules existant ailleurs dans l'app). `icon` reste optionnel : le
/// prototype visuel de Likes ("Reçus"/"Envoyés") n'en affiche aucun,
/// contrairement aux pilules de Communauté.
class TabPill extends StatelessWidget {
  const TabPill({super.key, this.icon, required this.label, required this.selected, required this.onTap});

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? AppColors.noirProfond : AppColors.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.noirProfond : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
