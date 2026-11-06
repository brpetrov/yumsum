import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';

void main() {
  test('phones get the live camera, desktops the file picker', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final (platform, live) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.windows, false),
      (TargetPlatform.macOS, false),
      (TargetPlatform.linux, false),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(hasLiveCamera, live, reason: '$platform');
      // In the app (tests never run on the web) a phone reads barcodes too.
      expect(hasBarcodeScanner, live, reason: '$platform');
    }
  });
}
