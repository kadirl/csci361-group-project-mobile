import 'package:flutter/material.dart';

// Full-screen, swipeable and zoomable image gallery for product pictures.
class ProductImageGalleryView extends StatefulWidget {
  const ProductImageGalleryView({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  // List of image URLs to preview.
  final List<String> imageUrls;

  // Which image to show first.
  final int initialIndex;

  @override
  State<ProductImageGalleryView> createState() => _ProductImageGalleryViewState();
}

class _ProductImageGalleryViewState extends State<ProductImageGalleryView> {
  // Controller to keep track of the current page.
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);

  // Current index, used for the title counter.
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    // Dispose page controller to free resources.
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (int newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        itemBuilder: (BuildContext context, int index) {
          final String url = widget.imageUrls[index];

          // InteractiveViewer enables pinch-to-zoom on images.
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.white70,
                  size: 64,
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}



