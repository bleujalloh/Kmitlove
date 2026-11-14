import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_background.dart';

/// Système de design MERUT — identité afro-contemporaine inspirée de
/// l'héritage kamite (règlement permanent de qualité, section 7,
/// `docs/reglement-permanent-qualite-execution.md`, 2026-11-11).
/// Remplace l'ancienne palette orange corail/pastel, jugée générique et
/// incompatible avec l'identité voulue.
///
/// Les six couleurs ci-dessous sont la palette imposée telle quelle ;
/// les rôles sémantiques qui suivent (`background`, `muted`, `border`...)
/// en sont des usages ou des teintes dérivées — jamais une couleur hors
/// de cette famille noir/ivoire/or/brun. Tout le reste de l'app doit
/// passer par ces constantes, jamais une couleur en dur recopiée
/// ailleurs (règlement permanent section 8).
/// Ensemble complet des couleurs sémantiques d'un thème.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.backgroundSoft,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.placeholder,
    required this.placeholderIcon,
    required this.navBackground,
    required this.navUnselected,
  });

  final Color background;
  final Color backgroundSoft;
  final Color ink;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color placeholder;
  final Color placeholderIcon;
  final Color navBackground;
  final Color navUnselected;

  /// Thème sombre : gris anthracite neutre (plus de noir presque pur ni de
  /// brun), l'or reste l'unique couleur d'accent.
  static const dark = AppPalette(
    background: Color(0xFF171C22),
    backgroundSoft: Color(0x1FFFFFFF),
    ink: Color(0xFFF4F4F5),
    muted: Color(0xFFF4F4F5),
    border: Color(0x1FFFFFFF),
    accent: AppColors.orAntique,
    accentSoft: Color(0xFF2E2819),
    placeholder: Color(0xFF2E2819),
    placeholderIcon: Color(0xFFF4F4F5),
    navBackground: Color(0xE6171C22),
    navUnselected: Color(0xFFF4F4F5),
  );

  /// Thème clair : fond blanc (pas de crème), surfaces gris très clair,
  /// texte presque noir ; l'or est plus profond pour rester lisible comme
  /// texte sur blanc (contrastes vérifiés par test/theme_contrast_test.dart).
  static const light = AppPalette(
    background: Color(0xFFF2F7F8),
    backgroundSoft: Color(0xB8FFFFFF),
    ink: Color(0xFF18181B),
    muted: Color(0xFF18181B),
    border: Color(0xB8FFFFFF),
    accent: Color(0xFF9E7416),
    accentSoft: Color(0xFFF3ECD9),
    placeholder: Color(0xFFF3ECD9),
    placeholderIcon: Color(0xFF18181B),
    navBackground: Color(0xE6FFFFFF),
    navUnselected: Color(0xFF18181B),
  );
}

class AppColors {
  // Palette imposée.
  static const noirProfond = Color(0xFF11110F);
  static const ivoire = Color(0xFFF6F0E5);
  static const orAntique = Color(0xFFD7B66E);
  static const orDoux = Color(0xFFE0BD76);
  static const brunProfond = Color(0xFF29251D);
  static const brunTerre = Color(0xFF49351E);

  // Rôles sémantiques — utilisés partout dans l'app. Deux palettes
  // complètes, sombre (celle de la référence visuelle validée le
  // 11/11/2026 : fond noir profond, texte ivoire, accents or) et claire
  // (demande du propriétaire, 13/11/2026 : « pas que le noir, c'est très
  // sombre »). Le choix (Système / Clair / Sombre) vit dans
  // `themeModeProvider` ; `AppColors.use` fixe la palette active avant
  // chaque construction de l'interface (voir `ThemeSync`, main.dart). Les
  // rôles ci-dessous sont donc des accesseurs, plus des constantes.
  static AppPalette _palette = AppPalette.dark;

  static bool get isDark => identical(_palette, AppPalette.dark);

  static void use(Brightness brightness) {
    _palette = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  }

  static Color get background => _palette.background;
  static Color get backgroundSoft => _palette.backgroundSoft;
  /// Surface pleine (carte posée sur le fond) pour tout ce qui flotte au-dessus
  /// du contenu — menus, notifications — et ne doit jamais laisser voir ce
  /// qu'il y a derrière.
  static Color get surfaceSolid => Color.alphaBlend(_palette.backgroundSoft, _palette.background);
  static Color get ink => _palette.ink;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static Color get accent => _palette.accent;
  // Fond de puce/badge sélectionné quand il ne doit PAS être plein or
  // (ex. case cochée dans un formulaire) — plein or + texte sombre est
  // réservé à la sélection "principale" (onglets, voir chaque écran de
  // pilules de filtre).
  static Color get accentSoft => _palette.accentSoft;
  static Color get placeholder => _palette.placeholder;
  static Color get placeholderIcon => _palette.placeholderIcon;
  // Barre de navigation du bas : sombre en thème sombre, claire en thème
  // clair.
  static Color get navBackground => _palette.navBackground;
  static Color get navUnselected => _palette.navUnselected;

  // Surfaces "plein noir" restant sombres dans les deux thèmes — bandeaux
  // de marque, tuile Premium — pour une hiérarchie à trois paliers
  // (fond > carte > bandeau de marque).
  static const surfaceDark = noirProfond;
  static const surfaceDarkSoft = brunProfond;
  static const onSurfaceDark = ivoire;

  // Seule couleur hors palette imposée : le vert "actif/en ligne" est une
  // convention universelle (badge "En ligne" de Découvrir, bouton
  // "Réactiver" de l'admin) qu'aucune teinte or/ivoire/brun ne peut
  // remplacer sans perdre son sens immédiat. Centralisée ici (trouvée
  // dupliquée en `Colors.greenAccent`/`Colors.green` à deux endroits par
  // audit) plutôt que répétée en couleur Material brute à chaque écran.
  static const online = Color(0xFF4CAF7D);
}

/// Espacements et rayons centralisés — un seul endroit à changer pour
/// ajuster la densité ou l'arrondi de toute l'app, plutôt que des valeurs
/// recopiées à chaque écran.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

class AppRadii {
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  // Champs de saisie et boutons : arrondi plus généreux (14) que les petits
  // éléments (md = 8), plus discret que les cartes (lg = 20).
  static const field = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  // Réservé aux éléments réellement ronds (point, avatar) : plus aucun
  // onglet, bouton ni puce en forme de pilule.
  static const pill = 999.0;
}

/// Georgia (demandé pour l'identité de marque) n'existe pas sur Google
/// Fonts : Tinos en est le remplacement conçu pour être métriquement
/// compatible, c'est la meilleure approximation disponible. Réservé aux
/// moments de marque/titres éditoriaux (nom de l'app, grands titres
/// d'accueil) — jamais le contenu fonctionnel (formulaires, listes,
/// boutons), qui reste en sans-serif système pour rester lisible et
/// dense (règlement permanent section 7).
class AppTypography {
  /// Le nom "MERUT" lui-même — toujours doré sur la référence visuelle
  /// validée (capture d'écran Communauté, 2026-11-11), jamais ivoire.
  static TextStyle brand({double fontSize = 28, Color? color, FontWeight weight = FontWeight.bold}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color ?? AppColors.accent, fontWeight: weight);

  /// Baseline officielle de marque, toujours accolée au nom "MERUT" là où
  /// il apparaît en vitrine (onboarding, à propos...) — demandée par le
  /// propriétaire le 11/11/2026 en même temps que la référence visuelle.
  static TextStyle tagline({double fontSize = 14, Color? color}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color ?? AppColors.ink, fontStyle: FontStyle.italic);

  static TextStyle editorialTitle({double fontSize = 22, Color? color}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color ?? AppColors.ink, fontWeight: FontWeight.w600);
}

ThemeData buildAppTheme(Brightness brightness) {
  // Les rôles sémantiques ci-dessous lisent la palette active : on la fixe
  // d'abord sur celle du thème construit.
  AppColors.use(brightness);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
      },
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      // Toujours un texte/icône sombre sur l'or (jamais `AppColors.ink`,
      // qui vaut ivoire dans ce thème sombre — y mettre de l'ivoire sur
      // de l'or donnerait un contraste très faible).
      onPrimary: AppColors.noirProfond,
      secondary: AppColors.brunTerre,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.ink,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.backgroundSoft,
      surfaceContainer: AppColors.surfaceSolid,
      surfaceContainerHigh: AppColors.surfaceSolid,
      surfaceContainerHighest: AppColors.surfaceSolid,
      brightness: brightness,
    ),
    disabledColor: AppColors.ink,
    hintColor: AppColors.ink,
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.ink,
      textColor: AppColors.ink,
      subtitleTextStyle: TextStyle(color: AppColors.ink, fontSize: 13.5),
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0, space: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.noirProfond,
        elevation: 0,
        disabledBackgroundColor: AppColors.accentSoft,
        disabledForegroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.backgroundSoft,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    // Champs de formulaire remplis et arrondis partout dans l'app, plutôt
    // que le soulignement Material par défaut — c'est ce changement,
    // appliqué une fois ici, qui évite que chaque écran de saisie ait
    // l'air "nu" (inscription, profil, création d'annonce...).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: AppColors.ink),
      hintStyle: TextStyle(color: AppColors.ink),
      helperStyle: TextStyle(color: AppColors.ink),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide(color: AppColors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      centerTitle: false,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    // Navigation inférieure volontairement sombre (surface dédiée, pas
    // juste un fond clair de plus) : c'est le contraste noir/ivoire
    // maîtrisé demandé, appliqué à l'élément le plus visible et le plus
    // constant de l'app (présent sur les 5 onglets principaux).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBackground,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.navUnselected,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.navUnselected,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundSoft,
      selectedColor: AppColors.accentSoft,
      labelStyle: TextStyle(color: AppColors.ink),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.accentSoft,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      // Pouce foncé sur piste dorée (activé), pouce doré sur piste teintée
      // (désactivé) : lisible dans les deux thèmes, sans gris.
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.noirProfond : AppColors.accent,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.accentSoft,
      ),
      checkColor: WidgetStateProperty.all(AppColors.noirProfond),
      side: BorderSide.none,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(AppColors.accent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.accentSoft,
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.12),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.accentSoft,
      circularTrackColor: AppColors.accentSoft,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      titleTextStyle: GoogleFonts.tinos(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w600),
      contentTextStyle: TextStyle(color: AppColors.ink, fontSize: 14.5),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    // Cartes « verre » : translucides sur le dégradé, sans ombre (une ombre
    // se verrait à travers la carte) ni teinte Material.
    cardTheme: CardThemeData(
      color: AppColors.backgroundSoft,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceSolid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceSolid,
      contentTextStyle: TextStyle(color: AppColors.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
  );
}
