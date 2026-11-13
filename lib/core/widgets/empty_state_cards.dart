import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Illustration pour les listes vides (Likes/Matchs) — trois cartes
/// empilées en éventail, comme sur les applications de rencontre
/// courantes. Quand `photoUrls` est fourni, les cartes montrent de vrais
/// profils existants (ceux que Découvrir propose déjà au membre :
/// `suggestedProfilePhotosProvider`), jamais des profils qu'il ne pourrait
/// pas déjà voir ; sans photo disponible, retour à la forme générique de
/// la palette MERUT.
class EmptyStateCards extends StatelessWidget {
  const EmptyStateCards({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.favorite,
    this.photoUrls = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> photoUrls;

  String? _photo(int i) => i < photoUrls.length ? photoUrls[i] : null;

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
                _card(angle: -0.18, offsetX: -38, color: AppColors.placeholder, photo: _photo(1)),
                _card(angle: 0.16, offsetX: 36, color: AppColors.accentSoft, photo: _photo(2)),
                _card(angle: 0, offsetX: 0, color: AppColors.backgroundSoft, elevated: true, photo: _photo(0)),
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

  Widget _card({required double angle, required double offsetX, required Color color, bool elevated = false, String? photo}) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 108,
          height: 140,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: elevated
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))]
                : null,
          ),
          child: photo != null
              ? Image.network(photo, fit: BoxFit.cover, width: 108, height: 140)
              : Center(child: Icon(icon, color: AppColors.accent, size: 28)),
        ),
      ),
    );
  }
}
