import 'package:flutter/material.dart';

/// Pastille "G" simple et fiable, en attendant d'ajouter l'asset officiel
/// multicolore de Google — l'icône de police précédente (Icons.g_mobiledata)
/// s'affichait de façon cassée/illisible sur certains appareils.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.62,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
