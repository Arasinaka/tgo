import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../theme/tgo_theme.dart';

/// Image message bubble
class ImageBubble extends StatelessWidget {
  final String url;
  final int width;
  final int height;

  const ImageBubble({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    // Calculate display size
    final maxWidth = MediaQuery.of(context).size.width * 0.65;
    final maxHeight = 300.0;

    double displayWidth = width.toDouble();
    double displayHeight = height.toDouble();

    if (displayWidth > maxWidth) {
      displayHeight = displayHeight * (maxWidth / displayWidth);
      displayWidth = maxWidth;
    }
    if (displayHeight > maxHeight) {
      displayWidth = displayWidth * (maxHeight / displayHeight);
      displayHeight = maxHeight;
    }

    // Minimum size
    displayWidth = displayWidth.clamp(100, maxWidth);
    displayHeight = displayHeight.clamp(60, maxHeight);

    return GestureDetector(
      onTap: () => _showImagePreview(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: displayWidth,
          height: displayHeight,
          color: theme.bgTertiary,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: theme.textMuted,
                  size: 32,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

