import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lean_streak/screens/dashboard/helpers/meal_camera_page.dart';

/// What the camera brought back: a packet's barcode, or the photos taken
/// (one for a meal, one per step for a product).
typedef MealCapture = ({String? barcode, List<XFile> photos});

/// The bar's two camera buttons.
enum CameraMode { photo, barcode }

/// One photo the camera asks for: what to take, and a tip for taking it.
typedef PhotoStep = ({String title, String? tip});

/// The photos a product contribution needs: both for a new product, only
/// the table for one that's listed without its nutrition.
const PhotoStep frontOfPackStep = (
  title: 'Take a photo of the front of the pack',
  tip: 'Get the whole front in, name and all.',
);
const PhotoStep nutritionTableStep = (
  title: 'Take a photo of the nutrition table',
  tip:
      'Fill the frame with the table, flat and sharp, so every number can '
      'be read.',
);

/// Opens the bar's camera in [CameraMode]; overridable in tests.
final mealCameraProvider =
    Provider<
      Future<MealCapture?> Function(BuildContext context, CameraMode mode)
    >((ref) => openMealCamera);

/// Only phones read barcodes: the scanner runs on the device, and the
/// browser can't run it.
bool get hasBarcodeScanner =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Phones get the live camera; elsewhere a file picker chooses a photo,
/// resized so the upload stays small (and the AI bill tiny).
Future<MealCapture?> openMealCamera(
  BuildContext context,
  CameraMode mode,
) async {
  if (hasBarcodeScanner) {
    return Navigator.of(context).push<MealCapture>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => switch (mode) {
          CameraMode.barcode => const MealCameraPage.barcode(),
          CameraMode.photo => const MealCameraPage.photos(
            photoSteps: [
              (
                title: 'Take a photo of your meal',
                tip: 'From above, with the whole plate in.',
              ),
            ],
          ),
        },
      ),
    );
  }
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
  final capture = await Navigator.of(context).push<MealCapture>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MealCameraPage.photos(photoSteps: steps),
    ),
  );
  return capture?.photos;
}
