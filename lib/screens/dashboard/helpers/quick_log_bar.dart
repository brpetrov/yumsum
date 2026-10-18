import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/helpers/quick_log_parser.dart';
import 'package:lean_streak/helpers/wav.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';

/// The microphone behind the bar's mic button; overridable in tests.
final audioRecorderProvider = Provider<AudioRecorder>((ref) {
  final recorder = AudioRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// The log composer pinned to the bottom of Today, under the thumb.
/// "chicken wrap 450" saves straight away; a meal without calories can be
/// estimated by the AI, or a photo taken. With the box empty the main
/// button is the mic: it records a short note that the AI listens to
/// itself, in English, Bulgarian or a mix. While the box is focused, recent
/// meals are offered as chips for one-tap re-logging.
class QuickLogBar extends ConsumerStatefulWidget {
  const QuickLogBar({super.key});

  @override
  ConsumerState<QuickLogBar> createState() => _QuickLogBarState();
}

class _QuickLogBarState extends ConsumerState<QuickLogBar> {
  static const _sampleRate = 16000;
  static const _maxRecording = Duration(seconds: 30);
  // Auto-stop: once something has been said, this much near-silence ends
  // the recording, like a speech recogniser's pause timeout.
  static const _silenceAfterSpeech = Duration(milliseconds: 2500);
  static const _speechDbfs = -30.0;
  static const _silenceDbfs = -45.0;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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

  QuickLogEntry get _entry => parseQuickLog(_controller.text);

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
    _focusNode.addListener(() => setState(() {}));
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
    _resumeListener?.dispose();
    _stopTimer?.cancel();
    _levelSub?.cancel();
    _audioSub?.cancel();
    if (_listening) ref.read(audioRecorderProvider).cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _reset() {
    _controller.clear();
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
    final text = _controller.text.trim();
    final uid = ref.read(currentUidProvider);
    if (text.isEmpty || uid == null) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimate(uid, text);
      if (!mounted) return;
      _setText('$text ${_amounts(result.kcal, result.protein)}');
      _aiItems = result.items;
    });
  }

  String _amounts(int kcal, int? protein) =>
      protein == null ? '$kcal kcal' : '$kcal kcal ${protein}g protein';

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
    _setText('');
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
      _setText('${result.name} ${_amounts(result.kcal, result.protein)}');
      _aiItems = result.items;
    });
  }

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Camera on phones, a file picker elsewhere. The picker resizes the photo
  /// so the upload stays small (and the AI bill tiny).
  Future<void> _pickPhoto() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final file = await ImagePicker().pickImage(
      source: _isMobile ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    await _runAi(() async {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimateFromPhoto(uid, bytes);
      if (!mounted) return;
      _setText('${result.name} ${_amounts(result.kcal, result.protein)}');
      _aiItems = result.items;
    });
  }

  Future<void> _openDetails() async {
    final entry = _entry;
    final saved = await showLogMealSheet(
      context,
      initialName: entry.name,
      initialCalories: entry.kcal,
      initialProtein: entry.protein,
    );
    if (saved == true && mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final hasText = _controller.text.trim().isNotEmpty;
    final showStatus = hasText || _listening || _working || _error != null;
    // Watched whether or not the box is focused, so the chips are ready the
    // moment it is and the list isn't refetched on every focus.
    final allRecents =
        ref.watch(recentMealsProvider).valueOrNull ?? const <Meal>[];
    final recents = _focusNode.hasFocus && !_listening && !_working
        ? _matchingRecents(allRecents, _controller.text)
        : const <Meal>[];

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
                    if (recents.isNotEmpty) ...[
                      _buildRecents(recents),
                      const SizedBox(height: 8),
                    ],
                    if (showStatus) ...[
                      _buildStatus(entry, hasText),
                      const SizedBox(height: 8),
                    ],
                    // Keyed so the status line and chips appearing above
                    // it never make Flutter rebuild this row as one of
                    // them, which would recreate the field and drop the
                    // keyboard on the first keystroke.
                    Row(
                      key: const ValueKey('quick-log-field'),
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: _isDesktop,
                            readOnly: _working || _listening,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {
                              _aiItems = const [];
                              _error = null;
                            }),
                            onSubmitted: (_) => _submit(),
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'What did you eat? e.g. wrap 450',
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
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 20,
                              ),
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
                                      tooltip: 'Photo',
                                      onPressed: _pickPhoto,
                                      color: AppColors.textSecondary,
                                      icon: const Icon(
                                        Icons.photo_camera_outlined,
                                      ),
                                    ),
                            ),
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

  /// Up to three recent meals: the latest ones while the box is empty,
  /// otherwise those whose name contains what has been typed.
  List<Meal> _matchingRecents(List<Meal> all, String text) {
    final query = text.trim().toLowerCase();
    return all
        .where(
          (meal) => query.isEmpty || meal.name!.toLowerCase().contains(query),
        )
        .take(3)
        .toList();
  }

  /// One scrolling row of chips; tapping one fills the box ready to save.
  Widget _buildRecents(List<Meal> recents) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recents.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final meal = recents[index];
          final kcal = meal.calories.round();
          return Center(
            child: ActionChip(
              label: Text('${meal.name} · $kcal kcal'),
              labelStyle: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              backgroundColor: AppColors.surfaceVariant,
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                _setText(
                  '${meal.name} '
                  '${_amounts(kcal, meal.proteinGrams?.round())}',
                );
                _focusNode.requestFocus();
                setState(() {
                  _aiItems = const [];
                  _error = null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// One thumb-sized button that changes with the box: mic when empty,
  /// save or estimate once there is text, stop while listening.
  Widget _buildAction(QuickLogEntry entry, bool hasText) {
    final (IconData icon, String tooltip, VoidCallback? onPressed) = _listening
        ? (Icons.stop_rounded, 'Stop', _toggleListening)
        : _working
        ? (Icons.more_horiz_rounded, 'Working', null)
        : !hasText
        ? (Icons.mic_rounded, 'Speak', _toggleListening)
        : entry.kcal != null
        ? (Icons.check_rounded, 'Save', _submit)
        : (Icons.auto_awesome_rounded, 'Estimate with AI', _submit);

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

  Widget _buildStatus(QuickLogEntry entry, bool hasText) {
    final (message, color, emphasise) = switch (entry) {
      _ when _listening => (
        'Listening... tap stop when you\'re done.',
        AppColors.textSecondary,
        false,
      ),
      _ when _working => ('Working...', AppColors.textSecondary, false),
      _ when _error != null => (_error!, AppColors.error, false),
      (name: final name, kcal: null, protein: _) => (
        '${name ?? 'Meal'} · no calories yet. Add a number or estimate with AI.',
        AppColors.textSecondary,
        false,
      ),
      (name: final name, kcal: final kcal, protein: final protein) => (
        [
          ?name,
          '$kcal kcal',
          if (protein != null) '$protein g protein',
        ].join(' · '),
        AppColors.textPrimary,
        true,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (_aiItems.isNotEmpty && !_working) ...[
                  const SizedBox(height: 2),
                  EstimateBreakdown(items: _aiItems),
                ],
              ],
            ),
          ),
        ),
        if (hasText && !_working && !_listening)
          TextButton(
            onPressed: _openDetails,
            child: const Text('More details'),
          ),
      ],
    );
  }
}
