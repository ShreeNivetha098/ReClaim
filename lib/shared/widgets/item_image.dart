import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_store_service.dart';

/// Shows an item photo from either a Firestore reference or a web URL.
class ItemImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final WidgetBuilder placeholder;
  final WidgetBuilder error;

  const ItemImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    required this.error,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!ImageStoreService.isStoredRef(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, _) => placeholder(context),
        errorWidget: (context, _, _) => error(context),
      );
    }

    final cached = ImageStoreService.cached(imageUrl);
    if (cached != null) return _memoryImage(context, cached);

    return FutureBuilder<Uint8List?>(
      future: ImageStoreService.load(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder(context);
        }
        final bytes = snapshot.data;
        if (bytes == null) return error(context);
        return _memoryImage(context, bytes);
      },
    );
  }

  Widget _memoryImage(BuildContext context, Uint8List bytes) {
    return Image.memory(
      bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) => error(context),
    );
  }
}
