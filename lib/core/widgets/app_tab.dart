import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Onglet à soulignement (Communauté, Likes...) : texte seul, trait d'or de
/// 2 px sous l'onglet actif, aucune pastille ni contour arrondi (demande du
/// propriétaire, 13/11/2026 : pas de bordure arrondie sur les onglets et
/// sous-onglets). Remplace l'ancien `AppTab`. `icon` reste optionnel.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? AppColors.accent : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: selected ? AppColors.accent : AppColors.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
