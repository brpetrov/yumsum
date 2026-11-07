import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/web_camera_stub.dart'
    if (dart.library.js_interop) 'package:lean_streak/screens/dashboard/helpers/web_camera_web.dart';

/// The bar's camera on phones, in the app or a browser, and in a desktop's
/// browser, in one of two modes. Resolves to what it got, or null when
/// closed.
class MealCameraPage extends StatefulWidget {
  /// A live picture that picks up a packet's barcode by itself; nothing
  /// to press.
  const MealCameraPage.barcode({super.key}) : photoSteps = const [];

  /// A shutter, asking for one photo per step (the meal, or the front of
  /// the pack then the nutrition table), each explained on a card.
  const MealCameraPage.photos({super.key, required this.photoSteps});

  final List<PhotoStep> photoSteps;

  @override
  State<MealCameraPage> createState() => _MealCameraPageState();
}

class _MealCameraPageState extends State<MealCameraPage>
    with WidgetsBindingObserver {
  /// A browser's back camera, found once a visit ([webBackCamera]).
  static CameraDescription? _webCamera;

  /// A browser's errors for a camera that's still busy: Firefox on Android
  /// lets a stopped camera go a few seconds later, and a phone opens one at
  /// a time, so a camera opened again soon after is refused at first.
  static const _busy = {'cameraNotReadable', 'cameraAbort'};

  static const _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// The app's barcode reader, ML Kit on the phone. The web's is in the
  /// browser ([readWebBarcode]), which looks at the preview a few times a
  /// second ([_webReading]).
  final BarcodeScanner? _scanner = !kIsWeb && hasLiveCamera
      ? BarcodeScanner(
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upca,
            BarcodeFormat.upce,
          ],
        )
      : null;
  CameraController? _camera;
  Timer? _webReading;
  bool _reading = false;
  bool _done = false;
  String? _problem;
  final _photos = <XFile>[];

  bool get _scanning => widget.photoSteps.isEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A sideways phone would squash the portrait preview box.
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb) SystemChrome.setPreferredOrientations(const []);
    _release();
    _scanner?.close();
    super.dispose();
  }

  /// Stops reading and lets the camera go as soon as the page starts to
  /// close rather than after its exit animation: the camera plugin keeps
  /// one camera for the whole app, so a late release could switch off one
  /// reopened in the meantime.
  void _release() {
    _done = true;
    _stopWebReading();
    final camera = _camera;
    _camera = null;
    _letGo(camera);
  }

  void _stopWebReading() {
    _webReading?.cancel();
    _webReading = null;
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

  /// In a browser: a photo from the device's files instead.
  Future<void> _pickInstead() async {
    final capture = await pickMealPhoto();
    if (capture != null) _leave(capture);
  }

  /// The camera is let go while the app is in the background and picked up
  /// again on return, as Android requires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      // Not yet initialised means the permission prompt is up; leave it be.
      if (camera == null || !camera.value.isInitialized) return;
      _stopWebReading();
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
      final CameraDescription description;
      if (kIsWeb) {
        final found = _webCamera ?? await _whileBusy(webBackCamera);
        if (found == null) return;
        description = _webCamera = found;
      } else {
        final cameras = await availableCameras();
        if (!mounted || _done) return;
        if (cameras.isEmpty) {
          if (mounted) setState(() => _problem = 'No camera found.');
          return;
        }
        description = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }
      if (!mounted || _done) return;
      final camera = await _whileBusy(() => _open(description));
      if (camera == null) return;
      if (!mounted || _camera != camera) {
        _letGo(camera);
        return;
      }
      if (_scanning && _scanner != null) {
        await camera.startImageStream(_onFrame);
      } else if (_scanning && kIsWeb) {
        _stopWebReading();
        _webReading = Timer.periodic(
          const Duration(milliseconds: 250),
          (_) => _readWebFrame(),
        );
      }
      setState(() {});
    } on CameraException catch (error) {
      // Found again next time, in case the camera changed.
      _webCamera = null;
      final failed = _camera;
      _camera = null;
      _letGo(failed);
      if (!mounted) return;
      setState(
        () => _problem = error.code == 'cameraNotFound'
            ? 'No camera found.'
            : !error.code.startsWith('CameraAccess')
            ? 'The camera could not start.'
            : kIsWeb
            ? 'Allow camera access in your browser to scan barcodes and take '
                  'photos.'
            : 'Allow camera access to scan barcodes and take photos. If '
                  'you said no before, turn it on in your phone\'s Settings.',
      );
    }
  }

  /// [description] opened, as [_camera]; let go again if it fails.
  Future<CameraController> _open(CameraDescription description) async {
    final camera = CameraController(
      description,
      // 720p: sharp enough for barcodes and for the AI, small to upload.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _camera = camera;
    try {
      await camera.initialize();
      return camera;
    } on CameraException {
      if (_camera == camera) _camera = null;
      _letGo(camera);
      rethrow;
    }
  }

  /// [attempt], tried again every second for up to 5 seconds while a
  /// browser says the camera is busy ([_busy]). Null when the page closed
  /// meanwhile.
  Future<T?> _whileBusy<T extends Object>(Future<T> Function() attempt) async {
    for (var tries = 1; ; tries++) {
      try {
        return await attempt();
      } on CameraException catch (error) {
        if (!kIsWeb || !_busy.contains(error.code) || tries == 6) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted || _done) return null;
      }
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
      final barcodes = await _scanner!.processImage(image);
      final code = barcodes.map((barcode) => barcode.rawValue).nonNulls;
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

  /// The browser looks for a barcode in the preview; a look still going
  /// skips the tick. When no reader could be loaded the camera is let go
  /// and the page says so, with Try again.
  Future<void> _readWebFrame() async {
    if (_reading || _done || !mounted) return;
    _reading = true;
    try {
      final code = await readWebBarcode();
      if (code != null && !_done) {
        _done = true;
        _leave((barcode: code, photos: const []));
      }
    } catch (_) {
      if (!_done && mounted) {
        _stopWebReading();
        final camera = _camera;
        _camera = null;
        _letGo(camera);
        setState(
          () => _problem = 'Could not start the barcode reader. Try again.',
        );
      }
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
    final degrees = defaultTargetPlatform == TargetPlatform.android
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
    _done = true;
    try {
      final photo = await camera.takePicture();
      _photos.add(photo);
      if (_photos.length < widget.photoSteps.length) {
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
      if (_camera == null &&
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
    // Still the last step while the page closes after its photo.
    final index = _scanning ? 0 : _photos.length.clamp(0, steps.length - 1);

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
              FittedBox(
                fit: BoxFit.cover,
                child: kIsWeb
                    // The browser turns the picture the way the phone is
                    // held, so its size is the picture's own.
                    ? SizedBox(
                        width: camera.value.previewSize!.width,
                        height: camera.value.previewSize!.height,
                        child: camera.buildPreview(),
                      )
                    // The preview size is landscape; fill the portrait
                    // screen.
                    : SizedBox(
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
                            if (kIsWeb && !_scanning) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _pickInstead,
                                style: TextButton.styleFrom(
                                  foregroundColor: white,
                                ),
                                child: const Text('Choose a photo instead'),
                              ),
                            ],
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
                        // Fades from one step to the next, so the change
                        // is noticed.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: PhotoStepCard(
                            key: ValueKey(index),
                            step: _scanning
                                ? const (
                                    title: 'Point at the barcode',
                                    tip:
                                        'Hold it inside the box and it\'s '
                                        'read by itself.',
                                  )
                                : steps[index],
                            number: steps.length > 1 ? index + 1 : null,
                            total: steps.length,
                          ),
                        ),
                        if (!_scanning) ...[
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
                          if (kIsWeb)
                            TextButton(
                              onPressed: _pickInstead,
                              style: TextButton.styleFrom(
                                foregroundColor: white,
                              ),
                              child: const Text('Choose a photo instead'),
                            ),
                        ],
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

/// What to photograph now, on a dark card over the camera: "Step 1 of 2"
/// when there's more than one step, then what to take and a tip.
class PhotoStepCard extends StatelessWidget {
  const PhotoStepCard({
    super.key,
    required this.step,
    this.number,
    this.total = 1,
  });

  final PhotoStep step;
  final int? number;
  final int total;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (number != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Step $number of $total',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (step.tip case final tip?) ...[
            const SizedBox(height: 6),
            Text(
              tip,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
