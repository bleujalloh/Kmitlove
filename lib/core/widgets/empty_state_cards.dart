import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Profil existant affiché dans un état vide : sa photo si elle existe,
/// sinon une silhouette, et toujours son prénom.
typedef EmptyStateProfile = ({String name, String? photoUrl});

/// État vide des listes (Likes, Messages) : un titre, une phrase d'aide et,
/// quand Découvrir en propose, jusqu'à trois profils existants alignés
/// (`suggestedProfilesProvider`) — jamais des profils que le membre ne
/// verrait pas déjà. Plus de cartes empilées en éventail ni d'icône dans
/// une forme décorative : sans profil à montrer, seul le texte s'affiche.
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
  // Conservé pour les appelants existants, plus affiché.
  final IconData icon;
  final List<EmptyStateProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profiles.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < profiles.length && i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _ProfileSquare(profile: profiles[i]),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
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
}

class _ProfileSquare extends StatelessWidget {
  const _ProfileSquare({required this.profile});

  final EmptyStateProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (profile.photoUrl != null)
            Image.network(profile.photoUrl!, fit: BoxFit.cover)
          else
            Center(child: Icon(Icons.person_outline, color: AppColors.placeholderIcon, size: 36)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
              child: Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
