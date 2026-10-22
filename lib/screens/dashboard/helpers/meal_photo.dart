import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Takes the photo behind the bar's camera button; overridable in tests.
final mealPhotoPickerProvider = Provider<Future<XFile?> Function()>(
  (ref) => pickMealPhoto,
);

/// Reads a packet barcode in a photo, if there is one; overridable in tests.
final photoBarcodeReaderProvider = Provider<Future<String?> Function(XFile)>(
  (ref) => readPhotoBarcode,
);

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Camera on phones, a file picker elsewhere. The picker resizes the photo
/// so the upload stays small (and the AI bill tiny).
Future<XFile?> pickMealPhoto() => ImagePicker().pickImage(
  source: _isMobile ? ImageSource.camera : ImageSource.gallery,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 80,
);

/// The first retail barcode (EAN or UPC) in [photo], or null when there is
/// none or the platform can't read photos (the web).
Future<String?> readPhotoBarcode(XFile photo) async {
  if (!_isMobile) return null;
  final controller = MobileScannerController(autoStart: false);
  try {
    final capture = await controller.analyzeImage(
      photo.path,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
    return capture?.barcodes.firstOrNull?.rawValue;
  } catch (_) {
    // Unreadable as a barcode photo: it is treated as a meal photo.
    return null;
  } finally {
    await controller.dispose();
  }
}
