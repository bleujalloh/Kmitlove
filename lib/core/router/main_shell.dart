import 'package:flutter/material.dart';

import '../../features/communaute/presentation/screens/communaute_screen.dart';
import '../../features/decouvrir/presentation/screens/decouvrir_screen.dart';
import '../../features/likes/presentation/screens/likes_screen.dart';
import '../../features/messages/presentation/screens/matches_list_screen.dart';
import '../../features/profil/presentation/screens/mon_profil_screen.dart';
import '../../l10n/l10n_extensions.dart';

/// Vraie navigation principale à 5 onglets (Découvrir/Likes/Messages/
/// Communauté/Profil), fidèle au prototype visuel validé — remplace
/// l'ancien PlaceholderHomeScreen (liste de boutons provisoire, jamais
/// prévue comme écran final, voir docs/suivi-developpement.md). Les
/// fonctionnalités secondaires (Premium, test de compatibilité,
/// vérification d'identité, administration) vivent maintenant sur
/// l'onglet Profil plutôt que dans Paramètres (remarqué le 11/11 : rien
/// ne montrait jamais la fiche elle-même d'un coup d'œil).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // IndexedStack (pas un simple swap de widget) pour garder l'état de
  // chaque onglet en mémoire en changeant d'onglet — sinon Découvrir
  // relancerait un tirage de candidats à chaque retour dessus.
  static const _screens = [
    DecouvrirScreen(),
    LikesScreen(),
    MatchesListScreen(),
    CommunauteScreen(),
    MonProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: context.l10n.navDiscover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: context.l10n.navLikes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: context.l10n.navMessages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: context.l10n.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
