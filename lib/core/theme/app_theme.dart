import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
class AppColors {
  // Palette imposée.
  static const noirProfond = Color(0xFF11110F);
  static const ivoire = Color(0xFFF6F0E5);
  static const orAntique = Color(0xFFD7B66E);
  static const orDoux = Color(0xFFE0BD76);
  static const brunProfond = Color(0xFF29251D);
  static const brunTerre = Color(0xFF49351E);

  // Rôles sémantiques — utilisés partout dans l'app. Thème sombre par
  // défaut (pas clair avec quelques bandeaux sombres) : corrigé le
  // 11/11/2026 d'après la référence visuelle validée par le propriétaire
  // (capture d'écran Communauté — fond noir profond, texte ivoire,
  // accents or, exactement l'inverse de la première version de ce
  // fichier qui gardait un fond clair par défaut).
  static const background = noirProfond;
  static const backgroundSoft = brunProfond;
  static const ink = ivoire;
  static const muted = Color(0xFFB3A581);
  static const border = brunTerre;
  static const accent = orAntique;
  // Fond de puce/badge sélectionné quand il ne doit PAS être plein or
  // (ex. case cochée dans un formulaire) — plein or + texte sombre est
  // réservé à la sélection "principale" (onglets, voir chaque écran de
  // pilules de filtre).
  static const accentSoft = Color(0xFF3A301A);
  static const placeholder = Color(0xFF362F22);
  static const placeholderIcon = Color(0xFF8A7C5E);

  // Surfaces "plein noir" encore plus sombres que le fond standard —
  // bandeaux de marque, tuile Premium — pour une hiérarchie à trois
  // paliers (fond > carte > bandeau de marque) plutôt que deux.
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
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
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
  static TextStyle brand({double fontSize = 28, Color color = AppColors.accent, FontWeight weight = FontWeight.bold}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color, fontWeight: weight);

  /// Baseline officielle de marque, toujours accolée au nom "MERUT" là où
  /// il apparaît en vitrine (onboarding, à propos...) — demandée par le
  /// propriétaire le 11/11/2026 en même temps que la référence visuelle.
  static TextStyle tagline({double fontSize = 14, Color color = AppColors.ink}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color, fontStyle: FontStyle.italic);

  static TextStyle editorialTitle({double fontSize = 22, Color color = AppColors.ink}) =>
      GoogleFonts.tinos(fontSize: fontSize, color: color, fontWeight: FontWeight.w600);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
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
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.ink),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.noirProfond,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
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
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.tinos(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    // Navigation inférieure volontairement sombre (surface dédiée, pas
    // juste un fond clair de plus) : c'est le contraste noir/ivoire
    // maîtrisé demandé, appliqué à l'élément le plus visible et le plus
    // constant de l'app (présent sur les 5 onglets principaux).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.accent.withValues(alpha: 0.22),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.onSurfaceDark.withValues(alpha: 0.7),
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.onSurfaceDark.withValues(alpha: 0.7),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundSoft,
      selectedColor: AppColors.accentSoft,
      labelStyle: const TextStyle(color: AppColors.ink),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.border,
      ),
      // Pouce foncé sur piste dorée (activé) plutôt qu'ivoire sur doré —
      // trouvé par revue de code : les deux étant clairs, le pouce se
      // distinguait mal de la piste une fois activé.
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.noirProfond : AppColors.ivoire,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      titleTextStyle: GoogleFonts.tinos(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: AppColors.ink, fontSize: 14.5),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.backgroundSoft,
      contentTextStyle: const TextStyle(color: AppColors.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
  );
}
