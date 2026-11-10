import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/admin_controller.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../compatibilite/presentation/screens/compat_screen.dart';
import '../../../decouvrir/presentation/screens/decouvrir_screen.dart';
import '../../../likes/presentation/screens/likes_screen.dart';
import '../../../communaute/presentation/screens/communaute_screen.dart';
import '../../../identite/presentation/screens/identite_screen.dart';
import '../../../messages/presentation/screens/matches_list_screen.dart';
import '../../../parametres/presentation/screens/parametres_screen.dart';
import '../../../premium/presentation/screens/premium_screen.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Écran temporaire après connexion + vérification d'e-mail, en attendant
/// le questionnaire de filtrage (docs/suivi-developpement.md) et la vraie
/// navigation à 4 onglets (Likes/Messages/Découvrir/Communauté).
class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityHeartbeatProvider); // une fois par session, voir auth_controller.dart
    return Scaffold(
      appBar: AppBar(
        title: const Text('MERUT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParametresScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.homeWelcomeHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DecouvrirScreen()),
                ),
                child: Text(context.l10n.navDiscover),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LikesScreen()),
                ),
                child: Text(context.l10n.navLikes),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchesListScreen()),
                ),
                child: Text(context.l10n.navMessages),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunauteScreen()),
                ),
                child: Text(context.l10n.navCommunity),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                child: Text(context.l10n.navPremium),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CompatScreen()),
                ),
                child: Text(context.l10n.navCompatTest),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IdentiteScreen()),
                ),
                child: Text(context.l10n.navIdentityVerification),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final isAdmin = ref.watch(isAdminProvider).value ?? false;
                  if (isAdmin) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
                        ),
                        child: Text(context.l10n.navAdmin),
                      ),
                    );
                  }
                  // Ne fonctionne qu'une seule fois pour tout le projet —
                  // disparaît dès qu'un admin existe quelque part.
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(adminRepositoryProvider).bootstrapFirstAdmin();
                          ref.invalidate(isAdminProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.becomeAdminSuccess)),
                            );
                          }
                        } on FirebaseFunctionsException catch (e) {
                          if (context.mounted) {
                            final message = e.code == 'already-exists'
                                ? context.l10n.becomeAdminAlreadyExists
                                : context.l10n.becomeAdminFailed(e.code);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.networkErrorRetry)),
                            );
                          }
                        }
                      },
                      child: Text(context.l10n.becomeFirstAdmin),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
