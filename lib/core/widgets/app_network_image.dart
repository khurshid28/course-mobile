import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../extensions/image_url_extension.dart';

/// Custom CachedNetworkImage that automatically fixes image URLs
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final Map<String, String>? httpHeaders;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final fixedUrl = imageUrl.asImageUrl;

    return CachedNetworkImage(
      imageUrl: fixedUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      httpHeaders: httpHeaders,
    );
  }
}

/// NetworkImage wrapper that automatically fixes image URLs
class AppNetworkImageProvider extends ImageProvider<AppNetworkImageProvider> {
  final String imageUrl;
  final Map<String, String>? headers;
  final double scale;

  const AppNetworkImageProvider(
    this.imageUrl, {
    this.headers,
    this.scale = 1.0,
  });

  @override
  Future<AppNetworkImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AppNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AppNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final fixedUrl = imageUrl.asImageUrl;
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, fixedUrl, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: fixedUrl,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AppNetworkImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AppNetworkImageProvider key,
    ImageDecoderCallback decode,
    String url,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      final Uri resolved = Uri.base.resolve(url);
      final http.Response response = await http.get(resolved, headers: headers);

      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: resolved,
        );
      }

      final Uint8List bytes = response.bodyBytes;
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNetworkImageProvider &&
        other.imageUrl == imageUrl &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(imageUrl, scale);
}
