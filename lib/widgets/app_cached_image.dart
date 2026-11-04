import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gambar universal aplikasi.
///
/// Mendukung tiga sumber:
/// - URL http/https (Firebase Storage, gambar contoh, dsb.)
/// - path file lokal (hasil `image_picker`, belum diunggah)
/// - string kosong → placeholder
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
  });

  static bool isNetworkSource(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = _placeholder();
    } else if (isNetworkSource(imageUrl)) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingPlaceholder();
        },
      );
    } else {
      final path = imageUrl.startsWith('file://')
          ? Uri.parse(imageUrl).toFilePath()
          : imageUrl;
      imageWidget = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
