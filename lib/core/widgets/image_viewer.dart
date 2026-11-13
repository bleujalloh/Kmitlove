import 'package:flutter/material.dart';

/// Visionneuse plein écran générique pour des images déjà en ligne
/// (photos d'un autre membre, photo de conversation, affiche
/// d'événement) : balayage entre les images, zoom au pincement. Les photos
/// du membre lui-même, avec statut de modération et suppression, ont leur
/// propre écran (profil/presentation/screens/photo_viewer_screen.dart).
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
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(child: Image.network(widget.urls[i], fit: BoxFit.contain)),
        ),
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
