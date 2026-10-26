import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Normalize orientation, remove source metadata and bound local storage usage.
Uint8List optimizeProductPhoto(Uint8List bytes) {
  if (bytes.length > 10000000) {
    throw ArgumentError('Photo trop volumineuse : 10 Mo maximum.');
  }
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null || info.width * info.height > 24000000) {
    throw ArgumentError(
      'Image illisible ou trop grande (24 mégapixels maximum).',
    );
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) throw ArgumentError('Image illisible.');
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1200 || oriented.height > 1200
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1200 : null,
          height: oriented.height > oriented.width ? 1200 : null,
        )
      : oriented;
  resized.exif.clear();
  for (final quality in [85, 70, 55, 40]) {
    final result = img.encodeJpg(resized, quality: quality);
    if (result.length <= 350000) return result.asUnmodifiableView();
  }
  throw ArgumentError('Impossible de réduire cette photo à 350 Ko.');
}
