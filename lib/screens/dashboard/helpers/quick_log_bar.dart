import 'dart:async';
import 'dart:math';

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
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';
import 'package:lean_streak/screens/dashboard/helpers/contribute_sheet.dart';
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
/// box, with calorie and protein boxes under it once the bar is in use.
/// Beside the idle box sit the other ways in, one round button each: a
/// photo of the plate for the AI, a packet's barcode (phones only) and the
/// mic, which records a short note that the AI listens to itself, in
/// English, Bulgarian or a mix. Once the bar is in use (text, or the
/// keyboard up for it) they slide away for one round button, so the box
/// has the room: a sparkle to estimate a named meal, a tick to save one
/// with calories. While the box is focused, meals are offered as chips for
/// one-tap re-logging: the usual ones for this time of day, then recent
/// ones matching what is typed, along with a search of packaged foods.
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
  static const _switchDuration = Duration(milliseconds: 220);
  static const _limitMessage =
      'Today\'s ${AiUsageRepository.dailyLimit} AI estimates are used up. '
      'Type the calories yourself.';

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

  /// AI estimates left today, or null until the count has loaded.
  int? get _aiLeft => switch (ref.read(aiUsageTodayProvider).valueOrNull) {
    final used? => max(0, AiUsageRepository.dailyLimit - used),
    null => null,
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

  /// A weight corrected in the breakdown: the boxes follow the items.
  void _itemsChanged(List<EstimateItem> items) {
    final total = totalOf(items);
    _fill(_name.text, total.kcal, total.protein);
    setState(() => _aiItems = items);
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
      _error = _limitMessage;
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Could not reach the AI. Try again.';
    }

    if (mounted) setState(() => _working = false);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _finishListening();
      return;
    }
    // Said before recording, not after the user has spoken the whole meal.
    if (_aiLeft == 0) {
      setState(() => _error = _limitMessage);
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
      setState(() => _error = 'Didn\'t catch that. Tap the mic and try again.');
      return;
    }

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .parseVoiceAudio(uid, wavFromPcm16(pcm, sampleRate: _sampleRate));
      if (!mounted) return;
      _fill(result.name, result.kcal, result.protein);
      _aiItems = result.items;
    });
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

  /// A photo of the plate goes to the AI.
  Future<void> _takePhoto() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
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
      _fill(result.name, result.kcal, result.protein);
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
              ? 'Open Food Facts has no calories for this product yet. '
                    'Take a photo of the packet instead.'
              : 'This product isn\'t on Open Food Facts. Take a photo of '
                    'the packet instead.');
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
        ? const ['Front of the pack', 'Nutrition table']
        : const ['Nutrition table'];
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
    );
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
    final trackProtein = ref.watch(trackProteinProvider);
    final offering = focused && !_listening && !_working && entry.kcal == null;
    final recents = offering
        ? _matchingRecents(allRecents, _name.text)
        : const <Meal>[];
    // A name without calories can be searched for; the web can't reach
    // the search service.
    final query = _name.text.trim();
    final search = !kIsWeb && offering && query.length >= 3 ? query : null;
    // Once half of today's AI estimates are used, a quiet count of what's
    // left, while the bar could still use one.
    ref.watch(aiUsageTodayProvider);
    final left = _aiLeft;
    final aiHint =
        open &&
            !showStatus &&
            entry.kcal == null &&
            left != null &&
            left <= AiUsageRepository.dailyLimit ~/ 2
        ? switch (left) {
            0 => 'No AI estimates left today',
            1 => '1 AI estimate left today',
            _ => '$left AI estimates left today',
          }
        : null;

    // A soft panel with a rounded top, floating on a warm shadow. Swiping
    // it down lets go of the box, as tapping the page or Back does, so the
    // keyboard goes and an empty bar folds away.
    return GestureDetector(
      onVerticalDragEnd: (drag) {
        if ((drag.primaryVelocity ?? 0) >= 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _edited(),
                              onSubmitted: (_) => _submit(),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                              decoration: _boxDecoration(
                                hint: 'Type a meal',
                                // A clear button once there is text, so a
                                // wrong voice or AI result is one tap from
                                // gone.
                                suffixIcon: hasText && !_working && !_listening
                                    ? IconButton(
                                        tooltip: 'Clear',
                                        onPressed: _reset,
                                        color: AppColors.textSecondary,
                                        icon: const Icon(Icons.close_rounded),
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
                                hint: 'kcal',
                                unit: 'kcal',
                              ),
                            ),
                            if (trackProtein) ...[
                              const SizedBox(width: 12),
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
          labelStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimaryContainer,
          ),
          backgroundColor: AppColors.primaryContainer,
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
            color: AppColors.onPrimaryContainer,
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
    final (String kind, Widget buttons) = _listening
        ? (
            'stop',
            _circle(
              const Icon(Icons.stop_rounded),
              'Stop',
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
                  const Icon(Icons.photo_camera_rounded),
                  'Take a photo',
                  _working ? null : _takePhoto,
                ),
                if (hasBarcodeScanner) ...[
                  const SizedBox(width: 6),
                  _circle(
                    const Icon(Icons.qr_code_scanner_rounded),
                    'Scan a barcode',
                    _working ? null : _scanBarcode,
                  ),
                ],
                const SizedBox(width: 6),
                _circle(
                  const Icon(Icons.mic_rounded),
                  'Speak',
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
              'Save',
              _working ? null : _submit,
            ),
          )
        : (
            'estimate',
            _circle(
              const Icon(Icons.auto_awesome_rounded),
              'Estimate',
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
  }) {
    // The bar sits at the bottom of the screen, so the tooltips show above
    // the buttons, clear of the phone's navigation bar.
    return TooltipTheme(
      data: TooltipTheme.of(context).copyWith(preferBelow: false),
      child: _glossy(
        enabled: onPressed != null,
        shape: const CircleBorder(),
        glow: stop ? AppColors.veryBad : AppColors.primary,
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
  /// when disabled.
  Widget _glossy({
    required bool enabled,
    required ShapeBorder shape,
    required Widget child,
    Color? glow,
  }) {
    final color = glow ?? AppColors.primary;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: enabled ? null : AppColors.surfaceVariant,
        gradient: !enabled
            ? null
            : glow == null
            ? AppColors.primaryGradient
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.15)!, color],
              ),
        shadows: !enabled
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: AppColors.isDark ? 0.3 : 0.4),
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
        ? ('Listening... tap stop when you\'re done.', AppColors.textSecondary)
        : _working
        ? ('Working...', AppColors.textSecondary)
        : (_error, AppColors.error);

    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Text(message, style: TextStyle(fontSize: 14, color: color)),
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
