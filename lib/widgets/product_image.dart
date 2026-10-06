import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.backgroundColor = const Color(0xFFE4EAF3),
    this.iconColor = const Color(0xFF14284B),
    this.fit = BoxFit.cover,
  });
  final String imageUrl;
  final double width, height, borderRadius;
  final Color backgroundColor, iconColor;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final image = imageUrl.trim();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isEmpty
          ? _fallback()
          : Image.network(
              image,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => _fallback(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes == null
                          ? null
                          : progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _fallback() => Center(
    child: Icon(Icons.directions_run, color: iconColor, size: height * .55),
  );
}
