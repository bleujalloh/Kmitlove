import 'package:flutter/material.dart';

/// Défilement horizontal entre images avec zoom au pincement : l'unique
/// mécanisme de visionneuse de l'app (règlement permanent, section 19 : pas
/// de doublon). Utilisé par [ImageViewerScreen] (images déjà en ligne) et
/// par l'écran de MES photos (profil/.../photo_viewer_screen.dart), qui y
/// ajoute le statut de modération et la suppression.
class ZoomPager extends StatelessWidget {
  const ZoomPager({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: itemCount,
      onPageChanged: onPageChanged,
      itemBuilder: (context, i) => InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(child: itemBuilder(context, i)),
      ),
    );
  }
}

/// Visionneuse plein écran générique pour des images déjà en ligne
/// (photos d'un autre membre, photo de conversation, affiche d'événement).
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.urls, this.initialIndex = 0});

  final List<String> urls;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.urls.length > 1
            ? Text('${_index + 1} / ${widget.urls.length}', style: const TextStyle(fontSize: 14))
            : null,
      ),
      body: ZoomPager(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => Image.network(widget.urls[i], fit: BoxFit.contain),
      ),
    );
  }
}

void openImageViewer(BuildContext context, List<String> urls, {int index = 0}) {
  if (urls.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ImageViewerScreen(urls: urls, initialIndex: index)),
  );
}
