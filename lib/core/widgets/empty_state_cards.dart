import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Illustration pour les listes vides (Likes/Matchs) — trois cartes
/// empilées en éventail plutôt qu'un simple texte ou une icône isolée,
/// comme sur les applications de rencontre courantes. Jamais de vraie
/// photo ici : une simple forme générique dans la palette MERUT, pour ne
/// jamais laisser croire qu'un vrai profil a disparu.
class EmptyStateCards extends StatelessWidget {
  const EmptyStateCards({super.key, required this.title, required this.subtitle, this.icon = Icons.favorite});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            width: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _card(angle: -0.18, offsetX: -38, color: AppColors.placeholder),
                _card(angle: 0.16, offsetX: 36, color: AppColors.accentSoft),
                _card(angle: 0, offsetX: 0, color: AppColors.backgroundSoft, elevated: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _card({required double angle, required double offsetX, required Color color, bool elevated = false}) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 108,
          height: 140,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: elevated
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))]
                : null,
          ),
          child: Center(child: Icon(icon, color: AppColors.accent, size: 28)),
        ),
      ),
    );
  }
}
