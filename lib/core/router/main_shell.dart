import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/decouvrir/presentation/screens/decouvrir_screen.dart';
import '../../features/likes/presentation/screens/likes_screen.dart';
import '../../features/messages/presentation/screens/matches_list_screen.dart';
import '../../features/notifications/push_controller.dart';
import '../../features/profil/presentation/screens/mon_profil_screen.dart';
import '../../l10n/l10n_extensions.dart';

/// Vraie navigation principale à 4 onglets (Découvrir/Likes/Messages/
/// Profil), fidèle au prototype visuel validé — remplace l'ancien
/// PlaceholderHomeScreen (liste de boutons provisoire, jamais prévue
/// comme écran final, voir docs/suivi-developpement.md). Les
/// fonctionnalités secondaires (Premium, test de compatibilité,
/// vérification d'identité, administration) vivent maintenant sur
/// l'onglet Profil plutôt que dans Paramètres (remarqué le 11/11 : rien
/// ne montrait jamais la fiche elle-même d'un coup d'œil). Communauté
/// n'est plus un onglet de la barre du bas (demande confirmée du
/// propriétaire, capture d'écran annotée, 12/11/2026) : accessible
/// depuis une pilule dans l'AppBar de Messages (matches_list_screen.dart).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

/// Onglet à ouvrir pour un type de notification, ou null si inconnu
/// (rappel d'événement, etc. : l'app reste où elle s'ouvre).
int? tabForNotificationType(String? type) {
  switch (type) {
    case 'match':
    case 'message':
      return 2;
    case 'like':
      return 1;
    default:
      return null;
  }
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  // IndexedStack (pas un simple swap de widget) pour garder l'état de
  // chaque onglet en mémoire en changeant d'onglet — sinon Découvrir
  // relancerait un tirage de candidats à chaque retour dessus.
  static const _screens = [
    DecouvrirScreen(),
    LikesScreen(),
    MatchesListScreen(),
    MonProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Notification affichée pendant que l'app est ouverte (FCM ne montre
    // rien tout seul dans ce cas, contrairement à l'app fermée/en arrière-
    // plan, géré nativement) — docs/suivi-developpement.md section du
    // 11/11/2026.
    FirebaseMessaging.onMessage.listen((message) {
      if (!mounted || message.notification == null) return;
      final title = message.notification!.title;
      final body = message.notification!.body;
      final text = [title, body].whereType<String>().join(' — ');
      if (text.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });
    // Toucher une notification reçue app en arrière-plan ou fermée : on
    // amène le membre sur l'onglet concerné (match/message → Messages,
    // like → Likes) au lieu de le laisser sur l'onglet quelconque où
    // l'app s'ouvre. Le type vient du champ `data.type` posé par le
    // serveur (shared/push.ts).
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromNotification);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openFromNotification(message);
    });
  }

  void _openFromNotification(RemoteMessage message) {
    final tab = tabForNotificationType(message.data['type'] as String?);
    if (!mounted || tab == null) return;
    setState(() => _index = tab);
  }

  @override
  Widget build(BuildContext context) {
    // Démarrés une seule fois par session (FutureProvider, pas re-déclenché
    // par les changements d'onglet grâce à l'IndexedStack) : le signal
    // "dernière activité" (masquage des comptes inactifs) n'était en fait
    // jamais appelé nulle part ailleurs dans l'app avant ce correctif
    // (docs/suivi-developpement.md section du 11/11/2026), et
    // l'enregistrement du jeton de notifications push.
    ref.watch(activityHeartbeatProvider);
    ref.watch(pushRegistrationProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
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
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: context.l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
