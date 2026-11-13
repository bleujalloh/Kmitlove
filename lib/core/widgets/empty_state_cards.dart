import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profil existant affiché sur une carte de l'éventail : sa photo si elle
/// existe, sinon une silhouette, et toujours son prénom.
typedef EmptyStateProfile = ({String name, String? photoUrl});

/// Illustration pour les listes vides (Likes/Matchs) — trois cartes
/// empilées en éventail, comme sur les applications de rencontre
/// courantes. Quand `profiles` est fourni, les cartes montrent de vrais
/// profils existants (ceux que Découvrir propose déjà au membre :
/// `suggestedProfilesProvider`), jamais des profils qu'il ne pourrait pas
/// déjà voir ; sans profil disponible, retour à la forme générique de la
/// palette MERUT.
class EmptyStateCards extends StatelessWidget {
  const EmptyStateCards({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.favorite,
    this.profiles = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<EmptyStateProfile> profiles;

  EmptyStateProfile? _profile(int i) => i < profiles.length ? profiles[i] : null;

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
                _card(angle: -0.18, offsetX: -38, color: AppColors.placeholder, profile: _profile(1)),
                _card(angle: 0.16, offsetX: 36, color: AppColors.accentSoft, profile: _profile(2)),
                _card(angle: 0, offsetX: 0, color: AppColors.backgroundSoft, elevated: true, profile: _profile(0)),
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

  Widget _card({required double angle, required double offsetX, required Color color, bool elevated = false, EmptyStateProfile? profile}) {
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
          child: profile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (profile.photoUrl != null)
                      Image.network(profile.photoUrl!, fit: BoxFit.cover)
                    else
                      const Center(
                        child: Icon(Icons.person_outline, color: AppColors.placeholderIcon, size: 44),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.noirProfond.withValues(alpha: 0.85)],
                          ),
                        ),
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(child: Icon(icon, color: AppColors.accent, size: 28)),
        ),
      ),
    );
  }
}
