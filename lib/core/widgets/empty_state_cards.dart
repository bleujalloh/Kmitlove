import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profil existant affiché sur une carte de l'éventail : sa photo si elle
/// existe, sinon une silhouette, et toujours son prénom.
typedef EmptyStateProfile = ({String name, String? photoUrl});

/// Illustration pour les listes vides (Likes, Messages) — trois cartes qui se
/// chevauchent en éventail, comme sur les applications de rencontre
/// courantes (rétabli le 14/11/2026 : la passe « sans lignes » les avait
/// retirées par erreur, le propriétaire les a réclamées). Quand `profiles`
/// est fourni, les cartes montrent de vrais profils existants (ceux que
/// Découvrir propose déjà au membre : `suggestedProfilesProvider`), jamais
/// des profils qu'il ne pourrait pas déjà voir ; sans profil disponible, les
/// cartes restent en formes génériques aux couleurs de la charte. Aucun
/// contour : seuls la couleur, le chevauchement et une ombre douce font
/// ressortir les cartes.
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
            height: 160,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _card(angle: -0.18, offsetX: -46, color: AppColors.placeholder, profile: _profile(1)),
                _card(angle: 0.16, offsetX: 44, color: AppColors.accentSoft, profile: _profile(2)),
                _card(angle: 0, offsetX: 0, color: AppColors.surfaceSolid, elevated: true, profile: _profile(0)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required double angle,
    required double offsetX,
    required Color color,
    bool elevated = false,
    EmptyStateProfile? profile,
  }) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 112,
          height: 146,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: elevated ? 0.14 : 0.08),
                blurRadius: elevated ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: profile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (profile.photoUrl != null)
                      Image.network(profile.photoUrl!, fit: BoxFit.cover)
                    else
                      Center(child: Icon(Icons.person_outline, color: AppColors.placeholderIcon, size: 44)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                          ),
                        ),
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
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
