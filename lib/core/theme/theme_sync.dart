import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fixe la palette `AppColors` sur le thème réellement affiché et, quand il
/// change (choix du membre ou thème du système), force la reconstruction de
/// tout l'arbre : les écrans lisent `AppColors` directement, et un widget
/// déjà construit ne se redessinerait pas tout seul. L'état et la
/// navigation sont conservés (aucun widget n'est recréé).
class ThemeSync extends StatefulWidget {
  const ThemeSync({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeSync> createState() => _ThemeSyncState();
}

class _ThemeSyncState extends State<ThemeSync> {
  Brightness? _applied;

  void _rebuildAll(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_rebuildAll);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    AppColors.use(brightness);
    if (_applied != null && _applied != brightness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(_rebuildAll);
      });
    }
    _applied = brightness;
    return ColoredBox(color: AppColors.background, child: widget.child);
  }
}
