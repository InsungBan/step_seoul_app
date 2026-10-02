import 'package:flutter/material.dart';

/// Uses the Firebase Storage download URL saved with each shoe.  The fallback
/// preserves the existing visual while an image has not been uploaded yet.
class ShoeImage extends StatelessWidget {
  const ShoeImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.iconColor = Colors.white,
  });
  final String? imageUrl;
  final BoxFit fit;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(Icons.directions_walk_rounded, color: iconColor, size: 50),
      );
    }
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => Center(
        child: Icon(Icons.directions_walk_rounded, color: iconColor, size: 50),
      ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
