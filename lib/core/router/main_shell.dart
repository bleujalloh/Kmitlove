import 'package:flutter/material.dart';

import '../../features/communaute/presentation/screens/communaute_screen.dart';
import '../../features/decouvrir/presentation/screens/decouvrir_screen.dart';
import '../../features/likes/presentation/screens/likes_screen.dart';
import '../../features/messages/presentation/screens/matches_list_screen.dart';
import '../../l10n/l10n_extensions.dart';

/// Vraie navigation principale à 4 onglets (Découvrir/Likes/Messages/
/// Communauté), fidèle au prototype visuel validé — remplace
/// l'ancien PlaceholderHomeScreen (liste de boutons provisoire, jamais
/// prévue comme écran final, voir docs/suivi-developpement.md). Les
/// fonctionnalités secondaires (Premium, test de compatibilité,
/// vérification d'identité, administration) vivent dans Paramètres,
/// accessible depuis chaque onglet — comme sur les applications de
/// rencontre courantes.
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
        ],
      ),
    );
  }
}
