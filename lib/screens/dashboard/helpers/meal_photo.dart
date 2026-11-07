import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/l10n/l10n.dart';

/// What the camera brought back: a packet's barcode, or the photos taken
/// (one for a meal, one per step for a product).
typedef MealCapture = ({String? barcode, List<XFile> photos});

/// The bar's two camera buttons.
enum CameraMode { photo, barcode }

/// What the camera asks for: a photo of the meal; for a product
/// contribution, the front of the pack and the nutrition table (both for a
/// new product, only the table for one that's listed without its
/// nutrition); or, while scanning, the barcode, which takes no photo.
enum PhotoStep {
  meal,
  frontOfPack,
  nutritionTable,
  barcode;

  /// What to take.
  String title(AppLocalizations l10n) => switch (this) {
    meal => l10n.cameraMealTitle,
    frontOfPack => l10n.cameraFrontTitle,
    nutritionTable => l10n.cameraTableTitle,
    barcode => l10n.cameraBarcodeTitle,
  };

  /// A tip for taking it.
  String tip(AppLocalizations l10n) => switch (this) {
    meal => l10n.cameraMealTip,
    frontOfPack => l10n.cameraFrontTip,
    nutritionTable => l10n.cameraTableTip,
    barcode => l10n.cameraBarcodeTip,
  };
}

/// Opens the bar's camera in [CameraMode]; overridable in tests.
final mealCameraProvider =
    Provider<
      Future<MealCapture?> Function(BuildContext context, CameraMode mode)
    >((ref) => openMealCamera);

/// The live camera page, which also reads barcodes: phones, in the app or a
/// browser, and every browser, a desktop's webcam included (its page offers
/// a photo file as well). The desktop app picks a photo file.
bool get hasLiveCamera =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// The live camera; elsewhere [pickMealPhoto].
Future<MealCapture?> openMealCamera(
  BuildContext context,
  CameraMode mode,
) async {
  if (hasLiveCamera) {
    return context.push<MealCapture>(
      AppRoutes.camera,
      extra: switch (mode) {
        CameraMode.barcode => const <PhotoStep>[],
        CameraMode.photo => const [PhotoStep.meal],
      },
    );
  }
  return pickMealPhoto();
}

/// A photo chosen from the device's files, resized so the upload stays
/// small (and the AI bill tiny).
Future<MealCapture?> pickMealPhoto() async {
  final photo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );
  return photo == null ? null : (barcode: null, photos: [photo]);
}

/// Takes the photos a product contribution needs, one per step (the front
/// and the nutrition table, or just the table); overridable in tests.
final productPhotosProvider =
    Provider<
      Future<List<XFile>?> Function(BuildContext context, List<PhotoStep> steps)
    >((ref) => takeProductPhotos);

Future<List<XFile>?> takeProductPhotos(
  BuildContext context,
  List<PhotoStep> steps,
) async {
  final capture = await context.push<MealCapture>(
    AppRoutes.camera,
    extra: steps,
  );
  return capture?.photos;
}
