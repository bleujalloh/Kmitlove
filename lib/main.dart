import 'package:country_picker/country_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/providers/locale_provider.dart';
import 'core/router/auth_gate.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_sync.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Anti-bot (docs/regles-du-projet.md section 2) : Play Integrity en
  // production, fournisseur de débogage en dev (sinon toutes les
  // Cloud Functions protégées échoueraient sur un appareil de test non
  // enregistré). iOS utilise DeviceCheck, protégé de la même façon.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );
  // Obligatoire avant tout appel à GoogleSignIn.instance.authenticate()
  // (sinon "undefined behavior" selon le plugin) — serverClientId est le
  // client OAuth *Web* (type 3 de google-services.json), pas celui
  // Android : c'est lui que Firebase attend comme audience du jeton
  // d'identité, sinon la connexion Google échoue silencieusement.
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '741720031453-khnmn8gbfousa7k8meihcmlhgf4ersd0.apps.googleusercontent.com',
  );
  runApp(const ProviderScope(child: MerutApp()));
}

class MerutApp extends ConsumerWidget {
  const MerutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MERUT',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) => ThemeSync(child: child ?? const SizedBox.shrink()),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Noms de pays du sélecteur pays (country_picker, 12/11/2026) —
        // suit la même locale fr/en que le reste de l'app, jamais figé.
        CountryLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
