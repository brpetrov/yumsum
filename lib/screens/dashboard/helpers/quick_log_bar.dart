import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/wav.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/food_search_sheet.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/portion_sheet.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';

/// The microphone behind the bar's mic button; overridable in tests.
final audioRecorderProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

typedef _Entry = ({String? name, int? kcal, int? protein});

/// The log composer pinned to the bottom of Today, under the thumb: a name
/// box, with calorie and protein boxes under it once the bar is in use. A
/// meal with calories saves straight away; one without can be estimated
/// by the AI, or a photo taken (of the plate, or of a packet's
/// barcode). With the box empty the main
/// button is the mic: it records a short note that the AI listens to
/// itself, in English, Bulgarian or a mix. While the box is focused, meals
/// are offered as chips for one-tap re-logging: the usual ones for this
/// time of day, then recent ones matching what is typed, along with a
/// search of packaged foods.
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

  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _focusNode = FocusNode();
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
  bool _working = false;
  List<EstimateItem> _aiItems = const [];
  String? _error;

  _Entry get _entry {
    final name = _name.text.trim();
    final kcal = int.tryParse(_kcal.text);
    return (
      name: name.isEmpty ? null : name[0].toUpperCase() + name.substring(1),
      kcal: kcal != null && kcal > 0 ? kcal : null,
      protein: int.tryParse(_protein.text),
    );
  }

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
    if (_listening) ref.read(audioRecorderProvider).cancel();
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
    if (_focusNode.hasFocus || _kcalFocus.hasFocus || _proteinFocus.hasFocus) {
      setState(() {});
    }
  }

  /// Puts a meal in the boxes, as an AI result, a chip or a barcode does.
  void _fill(String name, int? kcal, int? protein) {
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
        );
    if (!mounted) return;

    setState(() => _working = false);
    if (ref.read(logMealControllerProvider).hasError) {
      setState(() => _error = 'Could not save meal. Try again.');
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
      _fill(text, result.kcal, result.protein);
      _aiItems = result.items;
    });
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
      _error =
          'Daily AI limit reached. Add the calories yourself, e.g. "wrap 450".';
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Could not reach the AI right now.';
    }

    if (mounted) setState(() => _working = false);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _finishListening();
      return;
    }

    final recorder = ref.read(audioRecorderProvider);
    if (!await recorder.hasPermission()) {
      if (mounted) {
        setState(() => _error = 'Allow microphone access to log by voice.');
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
        _error = 'Could not start recording. Try again.';
      });
      return;
    }
    _levelSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen(_onLevel);
    _stopTimer = Timer(_maxRecording, _finishListening);
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
    if (!mounted || !_listening) return;
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
      setState(() => _error = 'Didn\'t catch that. Tap the mic and try again.');
      return;
    }

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .parseVoiceAudio(wavFromPcm16(pcm, sampleRate: _sampleRate));
      if (!mounted) return;
      _fill(result.name, result.kcal, result.protein);
      _aiItems = result.items;
    });
  }

  /// One camera for everything: a photo with a packet's barcode in it is
  /// looked up in Open Food Facts (label figures, no AI use); any other
  /// photo, or a barcode the database can't answer for, goes to the AI,
  /// which can read the packet itself.
  Future<void> _takePhoto() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final photo = await ref.read(mealPhotoPickerProvider)();
    if (photo == null || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final barcode = await ref.read(photoBarcodeReaderProvider)(photo);
    PackagedFood? food;
    if (barcode != null) {
      try {
        food = await ref.read(foodLookupServiceProvider).byBarcode(barcode);
      } on FoodLookupException {
        // Left to the AI below.
      }
    }
    if (!mounted) return;
    if (food != null) {
      setState(() => _working = false);
      await _usePackagedFood(food);
      return;
    }
    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimateFromPhoto(uid, bytes);
      if (!mounted) return;
      _fill(result.name, result.kcal, result.protein);
      _aiItems = result.items;
    });
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
    final portion = await showPortionSheet(context, food);
    if (portion == null || !mounted) return;
    _fill(portion.name, portion.kcal, portion.protein);
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
        _focusNode.hasFocus || _kcalFocus.hasFocus || _proteinFocus.hasFocus;
    // The number boxes join the name box once the bar is in use, so while
    // idle it is one box, the camera and the mic. On phones focus outlives
    // the keyboard (Back only hides it), so an empty bar folds away with
    // it. The view's insets are read because Scaffold hides them from its
    // body, where the bar lives.
    final keyboardUp = View.of(context).viewInsets.bottom > 0;
    final open = hasText || (focused && (keyboardUp || _isDesktop));
    final showStatus =
        _listening || _working || _error != null || _aiItems.isNotEmpty;
    // Watched whether or not the box is focused, so the chips are ready the
    // moment it is and the list isn't refetched on every focus. Once there
    // are calories the meal is complete and suggestions would only repeat it.
    final allRecents =
        ref.watch(recentMealsProvider).valueOrNull ?? const <Meal>[];
    final offering = focused && !_listening && !_working && entry.kcal == null;
    final recents = offering
        ? _matchingRecents(allRecents, _name.text)
        : const <Meal>[];
    // A name without calories can be searched for; the web can't reach
    // the search service.
    final query = _name.text.trim();
    final search = !kIsWeb && offering && query.length >= 3 ? query : null;

    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (recents.isNotEmpty || search != null) ...[
                      _buildChips(recents, search),
                      const SizedBox(height: 8),
                    ],
                    if (showStatus) ...[
                      _buildStatus(),
                      const SizedBox(height: 8),
                    ],
                    // Keyed so the status line and chips appearing above
                    // it never make Flutter rebuild this row as one of
                    // them, which would recreate the field and drop the
                    // keyboard on the first keystroke. The name box stays
                    // first in its column for the same reason when the
                    // number boxes appear under it.
                    Row(
                      key: const ValueKey('quick-log-field'),
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                key: const ValueKey('quick-log-name'),
                                controller: _name,
                                focusNode: _focusNode,
                                autofocus: _isDesktop,
                                readOnly: _working || _listening,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => _edited(),
                                onSubmitted: (_) => _submit(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _boxDecoration(
                                  hint: 'What did you eat?',
                                  // Camera while empty; a clear button once
                                  // there is text, so a wrong voice or AI
                                  // result is one tap from gone.
                                  suffixIcon: _working || _listening
                                      ? null
                                      : hasText
                                      ? IconButton(
                                          tooltip: 'Clear',
                                          onPressed: _reset,
                                          color: AppColors.textSecondary,
                                          icon: const Icon(Icons.close_rounded),
                                        )
                                      : IconButton(
                                          tooltip: 'Photo or barcode',
                                          onPressed: _takePhoto,
                                          color: AppColors.textSecondary,
                                          icon: const Icon(
                                            Icons.photo_camera_outlined,
                                          ),
                                        ),
                                ),
                              ),
                              if (open) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _numberBox(
                                        'quick-log-kcal',
                                        _kcal,
                                        _kcalFocus,
                                        hint: 'kcal',
                                        unit: 'kcal',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _numberBox(
                                        'quick-log-protein',
                                        _protein,
                                        _proteinFocus,
                                        hint: 'protein (g)',
                                        unit: 'g protein',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildAction(entry, hasText),
                      ],
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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

  /// While the box is empty, the meals usually had around now; once
  /// typing, up to three recent meals whose name contains the text.
  List<Meal> _matchingRecents(List<Meal> all, String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return usualMealsAt(all, DateTime.now());
    return distinctRecentMeals(all)
        .where((meal) => meal.name!.toLowerCase().contains(query))
        .take(3)
        .toList();
  }

  /// One scrolling row of chips: a search for [search] when given, then
  /// meals, which fill the boxes ready to save when tapped.
  Widget _buildChips(List<Meal> recents, String? search) {
    ActionChip chip(String label, VoidCallback onPressed, {Widget? avatar}) =>
        ActionChip(
          avatar: avatar,
          label: Text(label),
          labelStyle: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          backgroundColor: AppColors.surfaceVariant,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: onPressed,
        );
    final chips = [
      if (search != null)
        chip(
          'Search foods',
          () => _search(search),
          avatar: Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      for (final meal in recents)
        chip('${meal.name} · ${meal.calories.round()} kcal', () {
          _fill(meal.name!, meal.calories.round(), meal.proteinGrams?.round());
          _focusNode.requestFocus();
          setState(() {
            _aiItems = const [];
            _error = null;
          });
        }),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: chips[index]),
      ),
    );
  }

  /// One thumb-sized button that changes with the boxes: mic when empty,
  /// save once there are calories, estimate for a name without, stop while
  /// listening.
  Widget _buildAction(_Entry entry, bool hasText) {
    final (IconData icon, String tooltip, VoidCallback? onPressed) = _listening
        ? (Icons.stop_rounded, 'Stop', _toggleListening)
        : _working
        ? (Icons.more_horiz_rounded, 'Working', null)
        : !hasText
        ? (Icons.mic_rounded, 'Speak', _toggleListening)
        : entry.kcal != null
        ? (Icons.check_rounded, 'Save', _submit)
        : entry.name != null
        ? (Icons.auto_awesome_rounded, 'Estimate with AI', _submit)
        : (Icons.check_rounded, 'Save', null);

    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 26,
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        backgroundColor: _listening ? AppColors.veryBad : AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      icon: Icon(icon),
    );
  }

  /// Listening, working or what went wrong, and an AI result's breakdown.
  Widget _buildStatus() {
    final (String? message, Color color) = _listening
        ? ('Listening... tap stop when you\'re done.', AppColors.textSecondary)
        : _working
        ? ('Working...', AppColors.textSecondary)
        : (_error, AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Text(message, style: TextStyle(fontSize: 14, color: color)),
          if (_aiItems.isNotEmpty && !_working && !_listening)
            EstimateBreakdown(items: _aiItems),
        ],
      ),
    );
  }
}
