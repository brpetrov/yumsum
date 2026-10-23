import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lean_streak/screens/dashboard/helpers/meal_camera_page.dart';

/// What the bar's camera brought back: a packet's barcode or a photo.
typedef MealCapture = ({String? barcode, XFile? photo});

/// Opens the bar's camera, passing over a barcode the food database just
/// didn't know; overridable in tests.
final mealCameraProvider =
    Provider<
      Future<MealCapture?> Function(BuildContext context, String? skipBarcode)
    >((ref) => openMealCamera);

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Phones get the live camera, which reads a barcode by itself or takes a
/// photo of the plate; elsewhere a file picker chooses a photo, resized so
/// the upload stays small (and the AI bill tiny).
Future<MealCapture?> openMealCamera(
  BuildContext context,
  String? skipBarcode,
) async {
  if (_isMobile) {
    return Navigator.of(context).push<MealCapture>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MealCameraPage(skipBarcode: skipBarcode),
      ),
    );
  }
  final photo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );
  return photo == null ? null : (barcode: null, photo: photo);
}
