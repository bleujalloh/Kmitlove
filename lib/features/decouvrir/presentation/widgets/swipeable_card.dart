import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Carte swipable de Découvrir : glisser à droite = like, à gauche = passe.
///
/// Corrections du 14/11/2026 (« quand on swipe à droite ou à gauche, ça ne
/// marche pas selon le contexte, ça plante ») :
/// - le geste se valide aussi sur la **vitesse** (un coup de doigt rapide
///   suffit, plus besoin de tirer la carte sur 110 px) ;
/// - la carte **sort de l'écran** avant l'appel, puis **revient au centre**
///   si l'action est refusée ou échoue (appel déjà en cours, erreur
///   réseau…) au lieu de rester bloquée de travers ;
/// - toute erreur de l'action est absorbée ici : un échec ne peut plus
///   faire planter l'écran ;
/// - plus aucun `setState` après le retrait de la carte (`mounted`).
///
/// `onSwipeLike` / `onSwipePass` renvoient `true` quand l'action a été prise
/// en compte (la carte sera remplacée par la suivante) et `false` quand elle
/// est ignorée ou refusée (la carte revient au centre).
class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.onSwipeLike,
    required this.onSwipePass,
    required this.likeLabel,
    required this.passLabel,
    required this.child,
  });

  final Future<bool> Function() onSwipeLike;
  final Future<bool> Function() onSwipePass;
  final String likeLabel;
  final String passLabel;
  final Widget child;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> with SingleTickerProviderStateMixin {
  static const _distanceThreshold = 90.0;
  static const _velocityThreshold = 700.0;

  late final AnimationController _controller;
  Offset _offset = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        if (!mounted) return;
        setState(() => _offset = Offset.lerp(_from, _to, Curves.easeOut.transform(_controller.value))!);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Un seul écouteur et une seule animation à la fois : relancer
  /// l'animation repart simplement de la position courante.
  void _animateTo(Offset target, Duration duration) {
    _from = _offset;
    _to = target;
    _controller
      ..stop()
      ..duration = duration
      ..forward(from: 0);
  }

  void _onDragStart(DragStartDetails details) {
    if (_busy) return;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_busy) return;
    setState(() => _offset += Offset(details.delta.dx, details.delta.dy * 0.2));
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_busy) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final like = _offset.dx > _distanceThreshold || (vx > _velocityThreshold && _offset.dx > 12);
    final pass = _offset.dx < -_distanceThreshold || (vx < -_velocityThreshold && _offset.dx < -12);
    if (!like && !pass) {
      _animateTo(Offset.zero, const Duration(milliseconds: 220));
      return;
    }
    _busy = true;
    final width = MediaQuery.sizeOf(context).width;
    final off = Offset(like ? width * 1.3 : -width * 1.3, _offset.dy);
    _animateTo(off, const Duration(milliseconds: 160));
    var accepted = false;
    try {
      accepted = await (like ? widget.onSwipeLike() : widget.onSwipePass());
    } catch (_) {
      accepted = false;
    }
    if (!mounted) return;
    if (accepted) return; // la carte va être remplacée par la suivante
    _busy = false;
    _animateTo(Offset.zero, const Duration(milliseconds: 240));
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_offset.dx / 1200).clamp(-0.25, 0.25);
    final likeOpacity = (_offset.dx / _distanceThreshold).clamp(0.0, 1.0);
    final passOpacity = (-_offset.dx / _distanceThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: angle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.lg)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  widget.child,
                  Positioned(
                    top: 24,
                    left: 20,
                    child: Opacity(opacity: likeOpacity, child: _SwipeStamp(label: widget.likeLabel, color: AppColors.accent)),
                  ),
                  Positioned(
                    top: 24,
                    right: 20,
                    child: Opacity(opacity: passOpacity, child: _SwipeStamp(label: widget.passLabel, color: AppColors.ink)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mention « LIKE » / « PASSE » qui apparaît pendant le glissement — du
/// texte seul, sans cadre.
class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          color: AppColors.noirProfond.withValues(alpha: 0.55),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
