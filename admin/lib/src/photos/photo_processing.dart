import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Upload limits from the Phase 1 targets (low-end phones, mobile data).
abstract final class PhotoLimits {
  static const maxSide = 1280;
  static const maxBytes = 200 * 1024;
}

class PreparedPhoto {
  const PreparedPhoto(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

class PhotoTooLarge implements Exception {
  const PhotoTooLarge();
}

/// Shrinks a picked image to at most [PhotoLimits.maxSide] pixels and
/// [PhotoLimits.maxBytes], re-encoded as JPEG.
///
/// Re-encoding drops all metadata, including the GPS position phones
/// record in photos. Throws [FormatException] for files that are not
/// images, and [PhotoTooLarge] if even the lowest quality is too big.
PreparedPhoto preparePhoto(Uint8List original) {
  final decoded = img.decodeImage(original);
  if (decoded == null) throw const FormatException('Not an image');
  // Respect the camera's rotation before the metadata is dropped.
  var image = img.bakeOrientation(decoded);
  if (image.width > PhotoLimits.maxSide || image.height > PhotoLimits.maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: PhotoLimits.maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: PhotoLimits.maxSide,
            interpolation: img.Interpolation.average,
          );
  }
  image.exif = img.ExifData();

  for (final quality in [85, 75, 65, 55, 45, 35]) {
    final bytes = img.encodeJpg(image, quality: quality);
    if (bytes.length <= PhotoLimits.maxBytes) {
      return PreparedPhoto(bytes, image.width, image.height);
    }
  }
  throw const PhotoTooLarge();
}
