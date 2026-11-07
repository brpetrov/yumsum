import 'dart:js_interop';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_web/camera_web.dart';
// camera_web keeps a camera's id in a type it doesn't export; pinned to
// 0.3.5+6 in pubspec.yaml for that reason.
// ignore: implementation_imports
import 'package:camera_web/src/types/camera_metadata.dart';

@JS('yumsumBackCamera')
external JSPromise<_Found> _backCamera();

@JS('yumsumReadBarcode')
external JSPromise<JSString?> _readBarcode();

extension type _Found(JSObject _) implements JSObject {
  external String? get error;
  external String get deviceId;
  external String? get facingMode;
  external String get label;
}

/// The back camera (a desktop's only one), from one request for it in
/// web/camera.js, made known to camera_web so a CameraController can open
/// it. camera_web's own availableCameras opens every camera in turn, and
/// Firefox on Android left the front one running, so the back one couldn't
/// open (Galaxy S24+, 7 November 2026). Throws a CameraException with
/// camera_web's code for the browser's error.
Future<CameraDescription> webBackCamera() async {
  final found = await _backCamera().toDart;
  if (found.error case final name?) {
    throw CameraException(switch (name) {
      'NotAllowedError' ||
      'PermissionDeniedError' ||
      'SecurityError' => 'CameraAccessDenied',
      'NotFoundError' ||
      'DevicesNotFoundError' ||
      'OverconstrainedError' => 'cameraNotFound',
      'NotReadableError' ||
      'TrackStartError' ||
      'AbortError' => 'cameraNotReadable',
      _ => 'cameraUnknown',
    }, name);
  }
  final facing = found.facingMode;
  final description = CameraDescription(
    name: found.label,
    lensDirection: switch (facing) {
      'user' => CameraLensDirection.front,
      'environment' => CameraLensDirection.back,
      _ => CameraLensDirection.external,
    },
    sensorOrientation: 0,
  );
  // Public, but marked for camera_web's tests; it's where availableCameras
  // puts what it finds.
  // ignore: invalid_use_of_visible_for_testing_member
  (CameraPlatform.instance as CameraPlugin).camerasMetadata[description] =
      CameraMetadata(deviceId: found.deviceId, facingMode: facing);
  return description;
}

/// The barcode in the camera page's preview, or null, from web/camera.js.
/// Throws when no barcode reader could be loaded.
Future<String?> readWebBarcode() async => (await _readBarcode().toDart)?.toDart;
