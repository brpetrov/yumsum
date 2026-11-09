import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/config/crash_reports.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/meal_suggestions.dart';
import 'package:lean_streak/helpers/wav.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';
import 'package:lean_streak/screens/dashboard/helpers/contribute_sheet.dart';
import 'package:lean_streak/screens/dashboard/helpers/food_search_sheet.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/portion_sheet.dart';
import 'package:lean_streak/screens/dashboard/helpers/smart_snap_dialog.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';
import 'package:lean_streak/widgets/estimate_choice_dialog.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Whether a typed name offers "Search foods" (Open Food Facts' search).
/// Hidden for now; the barcode scan still looks packets up there.
const showFoodSearchChip = false;

/// The microphone behind the bar's mic button; overridable in tests.
final audioRecorderProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// The phone's or browser's speech recogniser behind the mic, which shows
/// the words as they're said and stops by itself after a pause; overridable
/// in tests. Null once it has failed this session (none there, no such
/// language, as on iPhones in Bulgarian, or no permission), so the mic
/// records a note for the AI to listen to instead.
final speechProvider = StateProvider<SpeechToText?>((ref) => SpeechToText());

typedef _Entry = ({String? name, int? kcal, int? protein});

/// The log composer pinned to the bottom of Today, under the thumb: a name
/// box, with calorie and protein boxes under it once the bar is in use.
/// Beside the idle box sit the other ways in, one round button each: a
/// photo of the plate for the AI, a packet's barcode (phones only) and the
/// mic, which writes the words into the box as they're said, in the app's
/// language, and estimates them as if typed; where the device can't, it
/// records a short note that the AI listens to itself. Once the bar is in
/// use (text, or the keyboard up for it) they slide away for one round
/// button, so the box has the room: a sparkle to estimate a named meal, a
/// tick to save one with calories. While the box is focused, meals are
/// offered as chips for one-tap re-logging: the usual ones for this time of
/// day, then recent ones matching what is typed, along with a search of
/// packaged foods while [showFoodSearchChip] is on.
enum _Offer { declined, abandoned, contributed }

class QuickLogBar extends ConsumerStatefulWidget {
  const QuickLogBar({super.key});

  @override
  ConsumerState<QuickLogBar> createState() => _QuickLogBarState();
}

class _QuickLogBarState extends ConsumerState<QuickLogBar>
    with WidgetsBindingObserver {
  static const _sampleRate = 16000;
  static const _maxRecording = Duration(seconds: 30);
  // Auto-stop: once something has been said, this much near-silence ends
  // the recording, like a speech recogniser's pause timeout.
  static const _silenceAfterSpeech = Duration(milliseconds: 2500);
  static const _speechDbfs = -30.0;
  static const _silenceDbfs = -45.0;
  // The recogniser stops after this long without new words.
  static const _speechPause = Duration(seconds: 3);
  // Errors that mean nothing was said, rather than that it can't listen.
  static const _nothingSaid = {
    'error_no_match',
    'error_speech_timeout',
    'no-speech',
  };
  static const _switchDuration = Duration(milliseconds: 220);
  // A chip's name is cut short past this, so a long one doesn't fill the
  // row: about half a 360 px phone.
  static const _chipNameWidth = 200.0;

  String get _limitMessage =>
      context.l10n.quickLogLimit(AiUsageRepository.dailyLimit);

  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _focusNode = FocusNode();

  /// Whether the keyboard was up when a finger went down on the panel while
  /// a box had focus, until it lifts; null otherwise. iOS Safari lets go of
  /// the box, and hides the keyboard, as soon as a finger touches outside
  /// it, which folded the chips before their tap could end; the panel stays
  /// as it was until the finger lifts.
  bool? _heldKeyboardUp;
  final _kcalFocus = FocusNode();
  final _proteinFocus = FocusNode();

  final _chunks = <Uint8List>[];
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<Amplitude>? _levelSub;
  Timer? _stopTimer;
  bool _heardSpeech = false;
  DateTime? _quietSince;
  AppLifecycleListener? _resumeListener;

  bool _listening = false;
  // The recogniser while it, rather than the recorder, is listening.
  SpeechToText? _speech;
  bool _working = false;
  // As of the last metrics change, so only the keyboard coming or going
  // rebuilds, not each frame of its slide.
  bool _keyboardUp = false;
  List<EstimateItem> _aiItems = const [];
  String? _error;

  // The bar has no boxes for macros: they are kept with the calories they
  // came with, and scaled to the calories saved.
  Nutrients? _macros;
  int? _macrosKcal;

  _Entry get _entry {
    final name = _name.text.trim();
    final kcal = int.tryParse(_kcal.text);
    return (
      name: name.isEmpty ? null : name[0].toUpperCase() + name.substring(1),
      kcal: kcal != null && kcal > 0 ? kcal : null,
      protein: int.tryParse(_protein.text),
    );
  }

  /// AI estimates left today; null until the count has loaded, and for
  /// the owner's account, which has no limit.
  int? get _aiLeft => switch ((
    ref.read(aiUsageTodayProvider).valueOrNull,
    ref.read(aiDailyLimitProvider),
  )) {
    (final used?, final limit?) => max(0, limit - used),
    _ => null,
  };

  // Touch devices choose between typing and the mic, so only desktop
  // (including desktop browsers, which have no on-screen keyboard) focuses
  // the box on open.
  bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final focus in [_focusNode, _kcalFocus, _proteinFocus]) {
      focus.addListener(() => setState(() {}));
    }
    ref.listenManual(
      launchActionProvider,
      (_, action) => _onLaunchAction(action),
      fireImmediately: true,
    );
  }

  /// A tap on the app-icon shortcut or the home-screen widget: start the
  /// mic, or focus the box with the keyboard up, as soon as there is a frame
  /// to do it on (on a cold start this runs inside initState).
  void _onLaunchAction(LaunchAction? action) {
    if (action != LaunchAction.voiceLog && action != LaunchAction.typeLog) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(launchActionProvider.notifier).clear();
      if (_listening || _working) return;
      if (action == LaunchAction.voiceLog) {
        _toggleListening();
      } else {
        _whenResumed(_focusForTyping);
      }
    });
  }

  /// Runs [action] once the window has focus. Android drops a keyboard
  /// request made before then, which is the case right after a widget tap
  /// brings the app forward: the box ended up focused with the keyboard down.
  void _whenResumed(VoidCallback action) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      action();
      return;
    }
    _resumeListener?.dispose();
    _resumeListener = AppLifecycleListener(
      onResume: () {
        _resumeListener?.dispose();
        _resumeListener = null;
        if (mounted) action();
      },
    );
  }

  /// Focus raises the keyboard by itself in the normal case; after a launch
  /// Android sometimes drops that first request, so ask once more shortly
  /// after.
  void _focusForTyping() {
    _focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeListener?.dispose();
    _stopTimer?.cancel();
    _levelSub?.cancel();
    _audioSub?.cancel();
    _speech?.cancel();
    if (_listening && _speech == null) {
      ref.read(audioRecorderProvider).cancel();
    }
    for (final focus in [_focusNode, _kcalFocus, _proteinFocus]) {
      focus.dispose();
    }
    for (final box in [_name, _kcal, _protein]) {
      box.dispose();
    }
    super.dispose();
  }

  /// The keyboard coming or going decides whether empty number boxes show.
  @override
  void didChangeMetrics() {
    final keyboardUp = View.of(context).viewInsets.bottom > 0;
    if (keyboardUp == _keyboardUp) return;
    _keyboardUp = keyboardUp;
    if (_focusNode.hasFocus || _kcalFocus.hasFocus || _proteinFocus.hasFocus) {
      setState(() {});
    }
  }

  /// The finger that held the panel open lifted: it follows the boxes'
  /// focus and the keyboard again. The chip's tap lands first, as the
  /// rebuild waits for the next frame.
  void _letGo() {
    if (_heldKeyboardUp != null) setState(() => _heldKeyboardUp = null);
  }

  /// A weight corrected in the breakdown: the boxes follow the items, and
  /// the macros scale with the calories.
  void _itemsChanged(List<EstimateItem> items) {
    final total = totalOf(items);
    _fill(
      _name.text,
      total.kcal,
      total.protein,
      macros: _macrosFor(total.kcal),
    );
    setState(() => _aiItems = items);
  }

  /// The macros the boxes were filled with, scaled to [kcal]. Rough: more
  /// rice should mean more carbs, not more fat.
  Nutrients? _macrosFor(int kcal) => switch ((_macros, _macrosKcal)) {
    (final macros?, final from?) when from > 0 => macros.scaled(kcal / from),
    _ => null,
  };

  /// Puts a meal in the boxes, as an AI result, a chip or a barcode does,
  /// with the [macros] that go with [kcal].
  void _fill(String name, int? kcal, int? protein, {Nutrients? macros}) {
    _macros = macros;
    _macrosKcal = kcal;
    for (final (box, text) in [
      (_name, name),
      (_kcal, kcal?.toString() ?? ''),
      (_protein, protein?.toString() ?? ''),
    ]) {
      box.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _reset() {
    for (final box in [_name, _kcal, _protein]) {
      box.clear();
    }
    _macros = null;
    setState(() {
      _aiItems = const [];
      _error = null;
    });
  }

  void _submit() {
    if (_working || _listening) return;
    if (_entry.kcal != null) {
      _save();
    } else {
      _estimate();
    }
  }

  Future<void> _save() async {
    final entry = _entry;
    setState(() => _working = true);

    await ref
        .read(logMealControllerProvider.notifier)
        .submit(
          name: entry.name,
          calories: entry.kcal!.toDouble(),
          proteinGrams: entry.protein?.toDouble(),
          macros: _macrosFor(entry.kcal!),
        );
    if (!mounted) return;

    setState(() => _working = false);
    if (ref.read(logMealControllerProvider).hasError) {
      setState(() => _error = context.l10n.quickLogErrorSave);
      return;
    }
    _reset();
  }

  Future<void> _estimate() async {
    final text = _name.text.trim();
    final uid = ref.read(currentUidProvider);
    if (text.isEmpty || uid == null) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimate(uid, text);
      if (!mounted) return;
      _fill(text, result.kcal, result.protein, macros: result.macros);
      _aiItems = result.items;
    });
    await _offerChoices();
  }

  /// Where the AI had to assume which version of an item the user had, it
  /// asks (`offerEstimateChoices`); a pick swaps the item in and the boxes
  /// follow, as for a corrected weight.
  Future<void> _offerChoices() async {
    final items = await offerEstimateChoices(context, _aiItems);
    if (items != null && mounted) _itemsChanged(items);
  }

  /// Shared busy and error handling for the estimate and voice AI calls.
  Future<void> _runAi(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _error = null;
    });

    try {
      await action();
    } on DailyLimitExceededException {
      if (mounted) _error = _limitMessage;
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      reportError(error, stack, 'AI estimate');
      if (mounted) _error = context.l10n.mealErrorAi;
    }

    if (mounted) setState(() => _working = false);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await (_speech != null ? _stopSpeech() : _finishListening());
      return;
    }
    // Said before recording, not after the user has spoken the whole meal.
    if (_aiLeft == 0) {
      setState(() => _error = _limitMessage);
      return;
    }
    // The words as they're said where the device can; a note for the AI
    // otherwise.
    final speech = ref.read(speechProvider);
    if (speech != null && await _startSpeech(speech)) return;
    if (!mounted) return;

    final recorder = ref.read(audioRecorderProvider);
    if (!await recorder.hasPermission()) {
      if (mounted) {
        setState(() => _error = context.l10n.quickLogAllowMic);
      }
      return;
    }
    if (!mounted) return;

    _chunks.clear();
    _heardSpeech = false;
    _quietSince = null;
    _fill('', null, null);
    setState(() {
      _listening = true;
      _aiItems = const [];
      _error = null;
    });

    try {
      final audio = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      _audioSub = audio.listen(_chunks.add);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = context.l10n.quickLogErrorRecord;
      });
      return;
    }
    _levelSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen(_onLevel);
    _stopTimer = Timer(_maxRecording, _finishListening);
  }

  /// The language the recogniser listens for: the app's, with the device's
  /// region when the device speaks it too (en-US), else en-GB or bg-BG.
  String get _speechLocale {
    final language = ref.read(languageCodeProvider);
    final region = ref.read(deviceRegionProvider);
    if (ref.read(deviceLanguageProvider) == language &&
        region != null &&
        region.isNotEmpty) {
      return '$language-$region';
    }
    return language == 'bg' ? 'bg-BG' : 'en-GB';
  }

  /// Listens with the device's recogniser, the words filling the box as
  /// they're said, until a pause, the stop button or the time cap. False
  /// when it can't start, and then it isn't tried again this session.
  Future<bool> _startSpeech(SpeechToText speech) async {
    try {
      // Set each time: initialize() takes its listeners only once.
      speech
        ..errorListener = _onSpeechError
        ..statusListener = _onSpeechStatus;
      if (await speech.initialize()) {
        if (!mounted) return true;
        _fill('', null, null);
        setState(() {
          _listening = true;
          _speech = speech;
          _aiItems = const [];
          _error = null;
        });
        await speech.listen(
          onResult: _onWords,
          listenOptions: SpeechListenOptions(
            localeId: _speechLocale,
            listenFor: _maxRecording,
            pauseFor: _speechPause,
            listenMode: ListenMode.dictation,
            cancelOnError: true,
          ),
        );
        return true;
      }
    } catch (error) {
      debugPrint('Speech recognition failed: $error');
    }
    _speechFailed();
    return false;
  }

  /// The recogniser can't listen here: the mic records notes for the AI
  /// for the rest of the session.
  void _speechFailed() {
    if (!mounted) return;
    ref.read(speechProvider.notifier).state = null;
    if (_speech != null) {
      setState(() {
        _speech = null;
        _listening = false;
      });
    }
  }

  void _onWords(SpeechRecognitionResult result) {
    if (!mounted || _speech == null) return;
    final words = result.recognizedWords;
    setState(() {
      _name.value = TextEditingValue(
        text: words,
        selection: TextSelection.collapsed(offset: words.length),
      );
    });
    if (result.finalResult) _finishSpeech();
  }

  /// The recogniser stopped by itself, after a pause or at the time cap.
  void _onSpeechStatus(String status) {
    if (status == SpeechToText.doneStatus) _finishSpeech();
  }

  /// Words heard before an error still count, and silence says so; with
  /// nothing heard, a recogniser that can't listen (no such language, no
  /// network, no permission) hands this note over to the recorder.
  void _onSpeechError(SpeechRecognitionError error) {
    final speech = _speech;
    if (!mounted || speech == null) return;
    if (_name.text.trim().isEmpty && !_nothingSaid.contains(error.errorMsg)) {
      _speechFailed();
      speech.cancel().whenComplete(() {
        if (mounted) _toggleListening();
      });
      return;
    }
    speech.cancel();
    _finishSpeech();
  }

  Future<void> _stopSpeech() async {
    await _speech?.stop();
    await _finishSpeech();
  }

  /// Ends listening and estimates what was said, as if typed.
  Future<void> _finishSpeech() async {
    if (!mounted || _speech == null) return;
    setState(() {
      _speech = null;
      _listening = false;
    });
    if (_name.text.trim().isEmpty) {
      setState(() => _error = context.l10n.quickLogMisTap);
      return;
    }
    await _estimate();
  }

  /// Ends the recording by itself after a pause, once something was said.
  void _onLevel(Amplitude level) {
    if (level.current >= _speechDbfs) _heardSpeech = true;
    if (level.current > _silenceDbfs) {
      _quietSince = null;
      return;
    }
    if (!_heardSpeech) return;
    final since = _quietSince ??= DateTime.now();
    if (DateTime.now().difference(since) >= _silenceAfterSpeech) {
      _finishListening();
    }
  }

  /// Stops the recording (whichever of the stop button, a pause or the time
  /// cap comes first) and has the AI listen to it.
  Future<void> _finishListening() async {
    final uid = ref.read(currentUidProvider);
    if (!mounted || !_listening || uid == null) return;
    setState(() => _listening = false);
    _stopTimer?.cancel();
    _levelSub?.cancel();
    await ref.read(audioRecorderProvider).stop();
    _audioSub?.cancel();
    if (!mounted) return;

    final pcm = Uint8List(_chunks.fold(0, (n, chunk) => n + chunk.length));
    var offset = 0;
    for (final chunk in _chunks) {
      pcm.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks.clear();

    // Under half a second (16-bit mono) is a mis-tap, not a meal.
    if (pcm.length < _sampleRate) {
      setState(() => _error = context.l10n.quickLogMisTap);
      return;
    }

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .parseVoiceAudio(uid, wavFromPcm16(pcm, sampleRate: _sampleRate));
      if (!mounted) return;
      _fill(result.name, result.kcal, result.protein, macros: result.macros);
      _aiItems = result.items;
    });
    await _offerChoices();
  }

  /// A barcode the camera read is looked up in Open Food Facts (label
  /// figures, no AI use).
  Future<void> _scanBarcode() async {
    final capture = await ref.read(mealCameraProvider)(
      context,
      CameraMode.barcode,
    );
    if (capture?.barcode case final barcode? when mounted) {
      await _lookUpBarcode(barcode);
    }
  }

  /// A photo of the plate goes to the AI: Smart Snap, YumSum Star only.
  /// Without it, the dialog that sells it.
  Future<void> _takePhoto() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    if (!ref.read(plusProvider)) {
      await showSmartSnapIntro(context);
      return;
    }
    final capture = await ref.read(mealCameraProvider)(
      context,
      CameraMode.photo,
    );
    if (capture == null || capture.photos.isEmpty || !mounted) return;
    final bytes = await capture.photos.first.readAsBytes();
    if (!mounted) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimateFromPhoto(uid, bytes);
      if (!mounted) return;
      _fill(result.name, result.kcal, result.protein, macros: result.macros);
      _aiItems = result.items;
    });
  }

  Future<void> _lookUpBarcode(String barcode) async {
    setState(() {
      _working = true;
      _error = null;
    });
    BarcodeLookup? found;
    String? problem;
    try {
      found = await ref.read(foodLookupServiceProvider).byBarcode(barcode);
    } on FoodLookupException catch (error) {
      problem = error.message;
    }
    if (!mounted) return;
    setState(() => _working = false);
    if (found?.food case final food?) {
      await _usePackagedFood(food);
      return;
    }
    // A product Open Food Facts has never heard of can be added, and one
    // it lists without calories can have its nutrition added; the rest of
    // someone else's entry is left as it is.
    if (found != null &&
        (!found.listed || found.needsNutrition != null) &&
        await _offerContribution(barcode, found.needsNutrition) !=
            _Offer.declined) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _error =
          problem ??
          (found!.listed
              ? context.l10n.quickLogNoCalories
              : context.l10n.quickLogNotListed);
    });
  }

  /// A barcode Open Food Facts doesn't know, or [listed] without its
  /// nutrition: invite the user to add it and, once they have, log it
  /// straight away. Declined when they said Not now (or can't:
  /// contributing needs the app's account and a phone camera); abandoned
  /// when they started and then backed out, which needs no message.
  Future<_Offer> _offerContribution(
    String barcode,
    ListedProduct? listed,
  ) async {
    if (kIsWeb || !ref.read(foodContributionServiceProvider).isConfigured) {
      return _Offer.declined;
    }
    if (!await inviteToContribute(context, nutritionOnly: listed != null) ||
        !mounted) {
      return _Offer.declined;
    }
    final steps = listed == null
        ? const [PhotoStep.frontOfPack, PhotoStep.nutritionTable]
        : const [PhotoStep.nutritionTable];
    final photos = await ref.read(productPhotosProvider)(context, steps);
    if (photos == null || photos.length < steps.length || !mounted) {
      return _Offer.abandoned;
    }
    final result = await showContributeSheet(
      context,
      barcode: barcode,
      photos: photos,
      listed: listed,
    );
    if (!result.contributed || !mounted) return _Offer.abandoned;
    if (result.food case final food?) await _usePackagedFood(food);
    return _Offer.contributed;
  }

  /// Packaged foods matching what is typed, then the portion as for a
  /// barcode.
  Future<void> _search(String query) async {
    final food = await showFoodSearchSheet(context, query);
    if (food == null || !mounted) return;
    await _usePackagedFood(food);
  }

  /// Asks how much of [food] was eaten; the box is then filled like an AI
  /// result, but with label figures and no AI usage.
  Future<void> _usePackagedFood(PackagedFood food) async {
    final portion = await showPortionSheet(
      context,
      food,
      showProtein: ref.read(trackProteinProvider),
      showMacros: ref.read(showMacrosProvider),
    );
    if (portion == null || !mounted) return;
    _fill(portion.name, portion.kcal, portion.protein, macros: portion.macros);
    setState(() => _aiItems = const []);
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final hasText = [
      _name,
      _kcal,
      _protein,
    ].any((box) => box.text.trim().isNotEmpty);
    final focused =
        _heldKeyboardUp != null ||
        _focusNode.hasFocus ||
        _kcalFocus.hasFocus ||
        _proteinFocus.hasFocus;
    // The number boxes join the name box once the bar is in use, so while
    // idle it is one box, the camera and the mic. On phones focus outlives
    // the keyboard (Back only hides it), so an empty bar folds away with
    // it. The view's insets are read because Scaffold hides them from its
    // body, where the bar lives.
    final keyboardUp =
        _heldKeyboardUp ?? View.of(context).viewInsets.bottom > 0;
    final open = hasText || (focused && (keyboardUp || _isDesktop));
    // The other ways in make room once the bar is in use: text, or the
    // keyboard up to type it. Not for desktop's standing focus, which
    // would hide them for good.
    final typing = hasText || (focused && keyboardUp);
    final showStatus =
        _listening || _working || _error != null || _aiItems.isNotEmpty;
    // Watched whether or not the box is focused, so the chips are ready the
    // moment it is and the list isn't refetched on every focus. Once there
    // are calories the meal is complete and suggestions would only repeat it.
    final allRecents =
        ref.watch(recentMealsProvider).valueOrNull ?? const <Meal>[];
    final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
    final trackProtein = ref.watch(trackProteinProvider);
    final offering = focused && !_listening && !_working && entry.kcal == null;
    final recents = offering
        ? suggestionsFor(
            recents: allRecents,
            recipes: recipes,
            query: _name.text,
            now: DateTime.now(),
            language: context.l10n.localeName,
          )
        : const <MealSuggestion>[];
    // A name without calories can be searched for, while the chip is
    // shown; the web can't reach the search service.
    final query = _name.text.trim();
    final search =
        showFoodSearchChip && !kIsWeb && offering && query.length >= 3
        ? query
        : null;
    // Once half of today's AI estimates are used, a quiet count of what's
    // left, while the bar could still use one.
    ref.watch(aiUsageTodayProvider);
    final limit = ref.watch(aiDailyLimitProvider) ?? 0;
    final left = _aiLeft;
    final aiHint =
        open &&
            !showStatus &&
            entry.kcal == null &&
            left != null &&
            left <= limit ~/ 2
        ? context.l10n.quickLogAiLeft(left)
        : null;

    // A soft panel with a rounded top, floating on a warm shadow. Swiping
    // it down lets go of the box, as tapping the page or Back does, so the
    // keyboard goes and an empty bar folds away. The whole panel counts as
    // part of its boxes (TextFieldTapRegion): a browser, and any mouse, lets
    // go of a box as soon as the pointer goes down outside it, which folded
    // an empty bar before a chip's tap could land.
    return GestureDetector(
      onVerticalDragEnd: (drag) {
        if ((drag.primaryVelocity ?? 0) >= 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Listener(
        onPointerDown: (_) {
          if (focused) setState(() => _heldKeyboardUp = keyboardUp);
        },
        onPointerUp: (_) => _letGo(),
        onPointerCancel: (_) => _letGo(),
        child: TextFieldTapRegion(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, open ? 8 : 18, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The drag handle a sheet has, while there is
                          // something to swipe down.
                          if (open) ...[
                            Center(
                              child: Container(
                                key: const ValueKey('quick-log-handle'),
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.outline,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (recents.isNotEmpty || search != null) ...[
                            _buildChips(recents, search),
                            const SizedBox(height: 12),
                          ],
                          if (showStatus) ...[
                            _buildStatus(trackProtein),
                            const SizedBox(height: 12),
                          ] else if (aiHint != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                aiHint,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Keyed so the status line and chips appearing above
                          // it never make Flutter rebuild this row as one of
                          // them, which would recreate the field and drop the
                          // keyboard on the first keystroke. The number boxes
                          // come after it, so they never shift it either.
                          Row(
                            key: const ValueKey('quick-log-field'),
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('quick-log-name'),
                                  controller: _name,
                                  focusNode: _focusNode,
                                  autofocus: _isDesktop,
                                  readOnly: _working || _listening,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.done,
                                  // Macros belong to the food named, so a new
                                  // name drops them.
                                  onChanged: (_) {
                                    _macros = null;
                                    _edited();
                                  },
                                  onSubmitted: (_) => _submit(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _boxDecoration(
                                    hint: context.l10n.quickLogHint,
                                    // A clear button once there is text, so a
                                    // wrong voice or AI result is one tap from
                                    // gone.
                                    suffixIcon:
                                        hasText && !_working && !_listening
                                        ? IconButton(
                                            tooltip: context.l10n.quickLogClear,
                                            onPressed: _reset,
                                            color: AppColors.textSecondary,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildActions(entry, typing),
                            ],
                          ),
                          // The number boxes span the whole bar, under the name
                          // and the button.
                          if (open) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _numberBox(
                                    'quick-log-kcal',
                                    _kcal,
                                    _kcalFocus,
                                    hint: context.l10n.commonKcalUnit,
                                    unit: context.l10n.commonKcalUnit,
                                  ),
                                ),
                                if (trackProtein) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _numberBox(
                                      'quick-log-protein',
                                      _protein,
                                      _proteinFocus,
                                      hint: context.l10n.quickLogProteinHint,
                                      unit: context.l10n.quickLogProteinUnit,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Any edit makes an earlier AI breakdown or error stale.
  void _edited() => setState(() {
    _aiItems = const [];
    _error = null;
  });

  InputDecoration _boxDecoration({
    required String hint,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
    );
  }

  /// Digits only: the box says what the number is, so no unit is typed.
  Widget _numberBox(
    String key,
    TextEditingController box,
    FocusNode focus, {
    required String hint,
    required String unit,
  }) {
    return TextField(
      key: ValueKey(key),
      controller: box,
      focusNode: focus,
      readOnly: _working || _listening,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      textInputAction: TextInputAction.done,
      onChanged: (_) => _edited(),
      onSubmitted: (_) => _submit(),
      style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: _boxDecoration(
        hint: hint,
        suffixText: box.text.isEmpty ? null : unit,
      ),
    );
  }

  /// One scrolling row of chips: a search for [search] when given, then
  /// meals and recipe portions ([suggestionsFor]), which fill the boxes
  /// ready to save when tapped. A long name is cut short with its calories
  /// kept; holding the chip (or hovering, on a computer) shows it whole with
  /// its calories, and protein where it's tracked.
  Widget _buildChips(List<MealSuggestion> suggestions, String? search) {
    final l10n = context.l10n;
    final trackProtein = ref.read(trackProteinProvider);
    final labelStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.onPrimaryContainer,
    );
    ActionChip chip(Widget label, VoidCallback onPressed, {Widget? avatar}) =>
        ActionChip(
          avatar: avatar,
          label: label,
          labelStyle: labelStyle,
          backgroundColor: AppColors.primaryContainer,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: onPressed,
        );
    Widget withWholeName(MealSuggestion meal, Widget chip) => Tooltip(
      preferBelow: false,
      triggerMode: TooltipTriggerMode.longPress,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: meal.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.surface,
            ),
          ),
          TextSpan(
            text:
                '\n${trackProtein && meal.protein != null ? l10n.commonKcalProtein(meal.kcal, meal.protein!) : l10n.commonKcal(meal.kcal)}',
            style: TextStyle(fontSize: 13, color: AppColors.surface),
          ),
        ],
      ),
      child: chip,
    );
    final chips = [
      if (search != null)
        chip(
          Text(l10n.quickLogSearchFoods),
          () => _search(search),
          avatar: Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.onPrimaryContainer,
          ),
        ),
      for (final meal in suggestions)
        withWholeName(
          meal,
          chip(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _chipNameWidth),
                  child: Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(l10n.quickLogChipKcal(meal.kcal)),
              ],
            ),
            () {
              _fill(meal.name, meal.kcal, meal.protein, macros: meal.macros);
              _focusNode.requestFocus();
              setState(() {
                _aiItems = const [];
                _error = null;
              });
            },
            avatar: meal.fromRecipe
                ? Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: AppColors.onPrimaryContainer,
                  )
                : null,
          ),
        ),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: chips[index]),
      ),
    );
  }

  /// Beside the box: while the bar is idle, the other ways in as one round
  /// button each (greyed while the bar is busy); the stop button while
  /// listening; once the bar is in use, one round button, a sparkle to
  /// estimate a named meal (greyed until there is a name) or a tick to save one
  /// with calories. A change scales at the box's edge, which follows it.
  Widget _buildActions(_Entry entry, bool typing) {
    final plus = ref.watch(plusProvider);
    final l10n = context.l10n;
    final (String kind, Widget buttons) = _listening
        ? (
            'stop',
            _circle(
              const Icon(Icons.stop_rounded),
              l10n.quickLogStop,
              _toggleListening,
              stop: true,
            ),
          )
        : !typing
        ? (
            'ways',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circle(
                  plus
                      ? const Icon(Icons.photo_camera_rounded)
                      : const _Starred(Icons.photo_camera_rounded),
                  l10n.quickLogPhoto,
                  _working ? null : _takePhoto,
                  dim: !plus,
                ),
                if (hasLiveCamera) ...[
                  const SizedBox(width: 6),
                  _circle(
                    const Icon(Icons.qr_code_scanner_rounded),
                    l10n.quickLogBarcode,
                    _working ? null : _scanBarcode,
                  ),
                ],
                const SizedBox(width: 6),
                _circle(
                  const Icon(Icons.mic_rounded),
                  l10n.quickLogSpeak,
                  _working ? null : _toggleListening,
                ),
              ],
            ),
          )
        : entry.kcal != null
        ? (
            'save',
            _circle(
              const Icon(Icons.check_rounded),
              l10n.commonSave,
              _working ? null : _submit,
            ),
          )
        : (
            'estimate',
            _circle(
              const Icon(Icons.auto_awesome_rounded),
              l10n.quickLogEstimate,
              _working || entry.name == null ? null : _submit,
            ),
          );
    return AnimatedSwitcher(
      duration: _switchDuration,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: _collapse,
      // Anchored at the right, so the buttons come and go at the box's
      // edge; the row is as wide as the wider set while both show.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerRight,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(key: ValueKey(kind), child: buttons),
    );
  }

  /// Buttons on their way out shrink into the box's edge and fade, and
  /// ones on their way in grow out of it, their row following their size
  /// so the box's edge moves with them; nothing is clipped.
  static Widget _collapse(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) => Align(
          alignment: Alignment.centerRight,
          widthFactor: animation.value,
          child: Transform.scale(
            scale: animation.value,
            alignment: Alignment.centerRight,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _circle(
    Widget icon,
    String tooltip,
    VoidCallback? onPressed, {
    bool stop = false,
    bool dim = false,
  }) {
    // The bar sits at the bottom of the screen, so the tooltips show above
    // the buttons, clear of the phone's navigation bar.
    return TooltipTheme(
      data: TooltipTheme.of(context).copyWith(preferBelow: false),
      child: _glossy(
        enabled: onPressed != null,
        shape: const CircleBorder(),
        glow: stop ? AppColors.veryBad : AppColors.primary,
        dim: dim,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 24,
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.onPrimary,
            disabledForegroundColor: AppColors.textDisabled,
          ),
          icon: icon,
        ),
      ),
    );
  }

  /// A glossy bubble in the icon tile's colours, with a soft glow; grey
  /// when disabled. [dim] takes it down a shade, so a star on it shows.
  Widget _glossy({
    required bool enabled,
    required ShapeBorder shape,
    required Widget child,
    Color? glow,
    bool dim = false,
  }) {
    final color = glow ?? AppColors.primary;
    final shade = dim ? 0.15 : 0.0;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: enabled ? null : AppColors.surfaceVariant,
        gradient: !enabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  for (final c
                      in glow == null
                          ? AppColors.primaryGradient.colors
                          : [Color.lerp(color, Colors.white, 0.15)!, color])
                    Color.lerp(c, Colors.black, shade)!,
                ],
              ),
        shadows: !enabled
            ? null
            : [
                BoxShadow(
                  color: color.withValues(
                    alpha: (AppColors.isDark ? 0.3 : 0.4) * (dim ? 0.6 : 1),
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }

  /// Listening, working or what went wrong, and an AI result's breakdown.
  Widget _buildStatus(bool showProtein) {
    final (String? message, Color color) = _listening
        ? (context.l10n.quickLogListening, AppColors.textSecondary)
        : _working
        ? (context.l10n.quickLogWorking, AppColors.textSecondary)
        : (_error, AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Row(
              children: [
                if (_working && !_listening) ...[
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 14, color: color),
                  ),
                ),
              ],
            ),
          if (_aiItems.isNotEmpty && !_working && !_listening)
            EstimateBreakdown(
              items: _aiItems,
              onChanged: _itemsChanged,
              showProtein: showProtein,
            ),
        ],
      ),
    );
  }
}

/// [icon] with a small star at its corner: a YumSum Star feature, shown to
/// people without it so they know it exists.
class _Starred extends StatelessWidget {
  const _Starred(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon),
      const Positioned(right: -9, top: -9, child: PlusStar(size: 16)),
    ],
  );
}
