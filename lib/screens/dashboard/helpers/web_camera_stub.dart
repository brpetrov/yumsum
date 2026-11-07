import 'package:camera/camera.dart';

// The app finds its cameras and reads barcodes on the phone; only the web
// does it this way (web_camera_web.dart).

Future<CameraDescription> webBackCamera() =>
    throw UnsupportedError('Only the web asks for its back camera.');

Future<String?> readWebBarcode() async => null;
