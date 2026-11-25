import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// Gambar universal aplikasi.
///
/// Mendukung tiga sumber:
/// - URL http/https (Firebase Storage, gambar contoh, dsb.)
/// - path file lokal (hasil `image_picker`, belum diunggah)
/// - string kosong → placeholder
class AppCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final bool allowLocal;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.allowLocal = false,
  });

  static bool isNetworkSource(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  late Future<Uint8List>? _localBytes = _readLocal();

  Future<Uint8List>? _readLocal() {
    final url = widget.imageUrl;
    if (!widget.allowLocal || url.isEmpty || AppCachedImage.isNetworkSource(url)) {
      return null;
    }
    final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
    return XFile(path).readAsBytes();
  }

  @override
  void didUpdateWidget(covariant AppCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl || widget.allowLocal != oldWidget.allowLocal) {
      _localBytes = _readLocal();
    }
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
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
      width: widget.width,
      height: widget.height,
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
    final AppCachedImage(:imageUrl, :width, :height, :fit, :isCircle, :borderRadius) = widget;
    final Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = _placeholder();
    } else if (AppCachedImage.isNetworkSource(imageUrl)) {
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
    } else if (_localBytes case final future?) {
      imageWidget = FutureBuilder<Uint8List>(
        key: ValueKey(imageUrl),
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _placeholder();
          final bytes = snapshot.data;
          if (bytes == null) return _loadingPlaceholder();
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
        },
      );
    } else {
      imageWidget = _placeholder();
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
