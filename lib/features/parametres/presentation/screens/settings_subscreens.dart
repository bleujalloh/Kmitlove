import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/country_field.dart';
import '../../../../core/widgets/report_reasons.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../decouvrir/data/discover_prefs_store.dart';
import '../../../decouvrir/domain/candidate.dart';
import '../../../decouvrir/presentation/decouvrir_controller.dart';
import '../../../notifications/push_controller.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../../legal_texts.dart';
import '../../settings_controller.dart';

/// Pages ouvertes depuis Paramètres (prototype « Paramètres ») :
/// Notifications, Préférences de rencontre, Visibilité du profil,
/// Signalements, documents juridiques et À propos.

Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
    );

// ---------------------------------------------------------------- Notifications

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final systemOn = ref.watch(notificationsEnabledProvider).value ?? true;
    final labels = {
      'likes': context.l10n.notifTypeLikes,
      'messages': context.l10n.notifTypeMessages,
      'matches': context.l10n.notifTypeMatches,
      'community': context.l10n.notifTypeCommunity,
      'events': context.l10n.notifTypeEvents,
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsNotificationsTitle)),
      body: ListView(
        children: [
          if (!systemOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(context.l10n.notificationsOff, style: TextStyle(color: AppColors.accent, height: 1.4)),
            ),
          for (final key in notificationTypeKeys)
            SwitchListTile(
              title: Text(labels[key]!),
              value: prefs[key] ?? true,
              onChanged: (v) async {
                try {
                  await ref.read(settingsControllerProvider).setNotificationPreference(key, v);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.genericError)));
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- Préférences de rencontre

class DatingPreferencesScreen extends ConsumerWidget {
  const DatingPreferencesScreen({super.key});

  void _update(WidgetRef ref, DiscoverFilters next) {
    ref.read(discoverFiltersProvider.notifier).state = next;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) DiscoverPrefsStore.save(uid, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(discoverFiltersProvider);
    final profil = ref.watch(profilProvider).value;
    final hasPosition = ref.watch(userStatusProvider).value?['locationLat'] is num;
    final range = RangeValues((filters.minAge ?? 18).toDouble(), (filters.maxAge ?? 60).toDouble());
    final seeking = profil?.seekingGenders.join(', ') ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.datingPrefsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _sectionTitle(context.l10n.datingPrefsSeekingLabel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$seeking · ${context.l10n.datingPrefsSeekingHint}',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
          _sectionTitle('${context.l10n.datingPrefsAge} · ${range.start.round()}–${range.end.round()}'),
          RangeSlider(
            values: range,
            min: 18,
            max: 80,
            divisions: 62,
            labels: RangeLabels('${range.start.round()}', '${range.end.round()}'),
            onChanged: (v) => _update(ref, filters.copyWith(minAge: v.start.round(), maxAge: v.end.round())),
          ),
          _sectionTitle('${context.l10n.datingPrefsDistance} · ${filters.maxDistanceKm} km'),
          if (!hasPosition)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(context.l10n.datingPrefsDistanceNeedsPosition, style: TextStyle(color: AppColors.muted, height: 1.4)),
            )
          else
            Slider(
              value: filters.maxDistanceKm.toDouble().clamp(5, 500),
              min: 5,
              max: 500,
              divisions: 99,
              label: '${filters.maxDistanceKm} km',
              onChanged: (v) => _update(ref, filters.copyWith(maxDistanceKm: v.round())),
            ),
          _sectionTitle(context.l10n.datingPrefsPlace),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                CountryField(
                  value: filters.country,
                  label: context.l10n.countryLabel,
                  onChanged: (v) => _update(ref, filters.copyWith(country: v, clearCity: true)),
                ),
                const SizedBox(height: 12),
                if (filters.country != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _update(ref, filters.copyWith(clearLocation: true)),
                      child: Text(context.l10n.datingPrefsClearPlace),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: OutlinedButton(
              onPressed: () {
                final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
                ref.read(discoverFiltersProvider.notifier).state = const DiscoverFilters();
                if (uid != null) DiscoverPrefsStore.clear(uid);
              },
              child: Text(context.l10n.eventsFiltersReset),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- Visibilité

class ProfileVisibilityScreen extends ConsumerWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(profileHiddenProvider);
    Future<void> choose(bool value) async {
      try {
        await ref.read(settingsControllerProvider).setProfileHidden(value);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.genericError)));
        }
      }
    }

    Widget option(bool value, String title, String hint) => ListTile(
          onTap: () => choose(value),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(hint)),
          trailing: hidden == value ? Icon(Icons.check, color: AppColors.accent) : null,
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileVisibilityTitle)),
      body: ListView(
        children: [
          option(false, context.l10n.visibilityVisible, context.l10n.visibilityVisibleHint),
          option(true, context.l10n.visibilityHidden, context.l10n.visibilityHiddenHint),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Signalements

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final reasons = reportReasonLabels(context.l10n);
    String kind(String type) {
      switch (type) {
        case 'user_report':
          return context.l10n.reportKindUser;
        case 'post_report':
          return context.l10n.reportKindPost;
        default:
          return context.l10n.reportKindOther;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myReportsTitle)),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.myReportsEmpty, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ),
            );
          }
          final loc = MaterialLocalizations.of(context);
          return ListView(
            children: [
              for (final r in reports)
                ListTile(
                  title: Text('${kind(r.type)} · ${reasons[r.reason] ?? r.reason}'),
                  subtitle: Text(r.createdAt == null ? '' : loc.formatMediumDate(r.createdAt!)),
                  trailing: Text(
                    r.resolved ? context.l10n.reportStatusDone : context.l10n.reportStatusOpen,
                    style: TextStyle(color: r.resolved ? AppColors.muted : AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------- Documents juridiques

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.kind});

  final String title;
  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final doc = legalDocument(kind, Localizations.localeOf(context).languageCode);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (kLegalDraft)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadii.md)),
              child: Text(context.l10n.legalDraftBanner, style: TextStyle(color: AppColors.ink, height: 1.4)),
            ),
          for (final s in doc.sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Text(s.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Text(s.body, style: TextStyle(height: 1.5, color: AppColors.ink)),
          ],
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.aboutTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MERUT', style: AppTypography.brand(fontSize: 34)),
            const SizedBox(height: 4),
            Text(context.l10n.onboardingTagline, style: AppTypography.tagline()),
            const SizedBox(height: 24),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Text(
                snap.hasData ? context.l10n.aboutVersion('${snap.data!.version} (${snap.data!.buildNumber})') : '',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
