import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';

/// The bar's camera on phones: a live picture that picks up a packet's
/// barcode by itself, and a shutter for a photo of the plate. Resolves to
/// whichever came first, or null when closed. [skipBarcode] is one the
/// food database just didn't know, so the packet can be photographed.
///
/// With [photoSteps] it reads no barcodes: it asks for one photo per
/// step ("The front of the pack", ...) and resolves to all of them.
class MealCameraPage extends StatefulWidget {
  const MealCameraPage({super.key, this.skipBarcode, this.photoSteps});

  final String? skipBarcode;
  final List<String>? photoSteps;

  @override
  State<MealCameraPage> createState() => _MealCameraPageState();
}

class _MealCameraPageState extends State<MealCameraPage>
    with WidgetsBindingObserver {
  static const _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final _scanner = BarcodeScanner(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
    ],
  );
  CameraController? _camera;
  bool _reading = false;
  bool _done = false;
  String? _problem;
  final _photos = <XFile>[];

  bool get _scanning => widget.photoSteps == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A sideways phone would squash the portrait preview box.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const []);
    _release();
    _scanner.close();
    super.dispose();
  }

  /// Stops reading and lets the camera go as soon as the page starts to
  /// close rather than after its exit animation: the camera plugin keeps
  /// one camera for the whole app, so a late release could switch off one
  /// reopened in the meantime.
  void _release() {
    _done = true;
    final camera = _camera;
    _camera = null;
    _letGo(camera);
  }

  /// A controller whose start failed throws from dispose too; that is
  /// nothing to report.
  static void _letGo(CameraController? camera) =>
      camera?.dispose().catchError((Object _) {});

  /// Hands [capture] back, unless Close or Back already started taking
  /// the page away, when a second pop would take Today with it.
  void _leave(MealCapture capture) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.of(context).pop(capture);
  }

  void _retry() {
    setState(() => _problem = null);
    _start();
  }

  /// The camera is let go while the app is in the background and picked up
  /// again on return, as Android requires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      // Not yet initialised means the permission prompt is up; leave it be.
      if (camera == null || !camera.value.isInitialized) return;
      _camera = null;
      _letGo(camera);
      setState(() {});
    } else if (state == AppLifecycleState.resumed &&
        camera == null &&
        !_done &&
        _problem == null) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || _done) return;
      if (cameras.isEmpty) {
        if (mounted) setState(() => _problem = 'No camera here.');
        return;
      }
      final camera = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        // 720p: sharp enough for barcodes and for the AI, small to upload.
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _camera = camera;
      await camera.initialize();
      if (!mounted || _camera != camera) {
        _letGo(camera);
        return;
      }
      if (_scanning) await camera.startImageStream(_onFrame);
      setState(() {});
    } on CameraException catch (error) {
      final failed = _camera;
      _camera = null;
      _letGo(failed);
      if (!mounted) return;
      setState(
        () => _problem = error.code.startsWith('CameraAccess')
            ? 'Allow camera access to take photos and scan barcodes. If '
                  'you said no before, allow it in the phone\'s Settings, '
                  'then try again.'
            : 'The camera could not start.',
      );
    }
  }

  /// One frame at a time goes to the barcode reader; frames that arrive
  /// meanwhile are skipped.
  Future<void> _onFrame(CameraImage frame) async {
    if (_reading || _done || !mounted) return;
    final image = _inputImage(frame);
    if (image == null) return;
    _reading = true;
    try {
      final barcodes = await _scanner.processImage(image);
      final code = barcodes
          .map((barcode) => barcode.rawValue)
          .nonNulls
          .where((code) => code != widget.skipBarcode);
      if (code.isNotEmpty && !_done) {
        _done = true;
        HapticFeedback.mediumImpact();
        _leave((barcode: code.first, photos: const []));
      }
    } catch (_) {
      // An unreadable frame; the next one will do.
    } finally {
      _reading = false;
    }
  }

  /// The frame as ML Kit wants it: NV21 on Android, BGRA on iOS, turned
  /// the way the phone is held.
  InputImage? _inputImage(CameraImage frame) {
    final camera = _camera;
    if (camera == null || frame.planes.length != 1) return null;
    final sensor = camera.description.sensorOrientation;
    final degrees = Platform.isAndroid
        ? (sensor -
                  (_orientationDegrees[camera.value.deviceOrientation] ?? 0) +
                  360) %
              360
        : sensor;
    final rotation = InputImageRotationValue.fromRawValue(degrees);
    final format = InputImageFormatValue.fromRawValue(frame.format.raw);
    if (rotation == null || format == null) return null;
    final plane = frame.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture ||
        _done) {
      return;
    }
    _done = true; // no barcode may win the race from here on
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      final photo = await camera.takePicture();
      _photos.add(photo);
      if (_photos.length < (widget.photoSteps?.length ?? 1)) {
        // On to the next step.
        HapticFeedback.lightImpact();
        if (mounted) setState(() => _done = false);
        return;
      }
      _leave((barcode: null, photos: List.of(_photos)));
    } on CameraException {
      // Closed meanwhile: nothing to go back to.
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
      _done = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not take the photo. Try again.')),
      );
      if (identical(_camera, camera)) {
        if (_scanning && !camera.value.isStreamingImages) {
          await camera.startImageStream(_onFrame);
        }
      } else if (_camera == null &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        // The app went to the background mid-photo and is back already.
        _start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final camera = _camera;
    final ready = camera != null && camera.value.isInitialized;
    final steps = widget.photoSteps;
    final hint = steps == null
        ? 'Point at a barcode, or photograph your meal'
        : '${_photos.length + 1} of ${steps.length} · '
              '${steps[_photos.length.clamp(0, steps.length - 1)]}';

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) setState(_release);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              // The preview size is landscape; fill the portrait screen.
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: camera.value.previewSize!.height,
                  height: camera.value.previewSize!.width,
                  child: CameraPreview(camera),
                ),
              )
            else
              Center(
                child: _problem == null
                    ? const CircularProgressIndicator(color: white)
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _problem!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _retry,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: white,
                                side: const BorderSide(color: white),
                              ),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
              ),
            if (ready && _scanning)
              Center(
                child: Container(
                  width: 260,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            if (ready)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hint,
                          style: TextStyle(
                            color: white.withValues(alpha: 0.9),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          button: true,
                          label: 'Take photo',
                          child: GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              width: 76,
                              height: 76,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: white, width: 4),
                              ),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
