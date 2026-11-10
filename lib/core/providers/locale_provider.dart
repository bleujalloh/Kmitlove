import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

const supportedLocales = [Locale('fr'), Locale('en')];
const _prefsKey = 'app_locale_code';

/// Langue choisie manuellement par l'utilisateur (écran Paramètres).
/// `null` tant qu'aucun choix explicite n'a été fait : l'app suit alors la
/// langue de l'appareil, avec repli automatique sur le français si celle-ci
/// n'est ni le français ni l'anglais (ordre de `supportedLocales`, voir
/// main.dart).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Pour les messages d'erreur produits en dehors d'un `BuildContext`
/// (contrôleurs Riverpod) : mêmes traductions que `context.l10n`, à partir
/// de la langue actuellement choisie. Tant qu'aucun choix explicite n'a
/// été fait (`locale` null), reproduit exactement la résolution de
/// MaterialApp (main.dart) plutôt qu'un repli français fixe — sinon un
/// appareil en anglais verrait l'UI en anglais mais les erreurs de
/// contrôleur (ex. decouvrir_controller.dart) rester en français.
AppLocalizations l10nFor(Locale? locale) => lookupAppLocalizations(locale ?? _systemLocaleFallback());

Locale _systemLocaleFallback() {
  final deviceCode = PlatformDispatcher.instance.locale.languageCode;
  final supported = supportedLocales.any((l) => l.languageCode == deviceCode);
  return supported ? Locale(deviceCode) : const Locale('fr');
}
