import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/measure_field.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/plan_choices.dart';
import 'package:lean_streak/widgets/shine.dart';

/// The questions, one card each, in order. [target] is skipped when keeping
/// weight.
enum _Step {
  name,
  gender,
  age,
  height,
  weight,
  goal,
  target,
  activity,
  training,
  protein,
  plan,
}

/// First run: one question per card, then the plan. Losing is at the
/// moderate pace until Plan Settings changes it, and gaining at its one
/// pace; the country is stored from the phone's region, as
/// `countryProvider`'s fallback. Height and weight are typed in kg and cm
/// until a card's units toggle changes them, and the units are stored too.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  HeightUnit _heightUnit = HeightUnit.cm;
  WeightUnit _weightUnit = WeightUnit.kg;
  late final HeightInput _height;
  late final WeightInput _currentWeight;
  late final WeightInput _targetWeight;

  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  TrainingFrequency _trainingFrequency = TrainingFrequency.none;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;
  bool _trackProtein = true;
  int _index = 0;
  // The few seconds between the last question and the plan (_PlanBuilding).
  bool _building = false;

  @override
  void initState() {
    super.initState();
    _height = HeightInput(_heightUnit);
    _currentWeight = WeightInput(_weightUnit);
    _targetWeight = WeightInput(_weightUnit);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _height.dispose();
    _currentWeight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  bool get _maintaining => _weightLossPace == WeightLossPace.maintain;
  bool get _gaining => _weightLossPace == WeightLossPace.gain;

  /// A target the goal can't reach: not under the current weight when
  /// losing, not over it when gaining.
  bool _wrongSide(double target, double current) =>
      _gaining ? target <= current : target >= current;

  List<_Step> get _steps => [
    for (final step in _Step.values)
      if (step != _Step.target || !_maintaining) step,
  ];

  // ── Checks, as Plan Settings makes them ─────────────────────────────────

  String? _ageError(String text) {
    final n = int.tryParse(text);
    if (n == null) return context.l10n.commonEnterAge;
    if (n < 18 || n > 120) return context.l10n.commonAgeRange;
    return null;
  }

  String? _heightError() {
    final cm = _height.value;
    if (cm == null) return context.l10n.onboardingEnterHeight;
    if (cm < 100 || cm > 250) {
      return heightRange(100, 250, _heightUnit, context.l10n);
    }
    return null;
  }

  String? _weightError(WeightInput input) {
    final kg = input.value;
    if (kg == null) return context.l10n.onboardingEnterWeight;
    if (kg < 30 || kg > 300) {
      return weightRange(30, 300, _weightUnit, context.l10n);
    }
    return null;
  }

  String? _targetError() {
    final error = _weightError(_targetWeight);
    if (error != null) return error;
    final current = _currentWeight.value;
    if (current != null && _wrongSide(_targetWeight.value!, current)) {
      return _gaining
          ? context.l10n.commonTargetAboveCurrent
          : context.l10n.commonTargetBelowCurrent;
    }
    return null;
  }

  bool _answered(_Step step) => switch (step) {
    _Step.name => _nameCtrl.text.trim().isNotEmpty,
    _Step.gender => _gender != null,
    _Step.age => _ageError(_ageCtrl.text) == null,
    _Step.height => _heightError() == null,
    _Step.weight => _weightError(_currentWeight) == null,
    _Step.target => _targetError() == null,
    _Step.goal || _Step.activity || _Step.training || _Step.protein => true,
    _Step.plan => _preview != null,
  };

  // ── Live preview ─────────────────────────────────────────────────────────

  HealthPlanCalculation? get _preview {
    final currentWeight = _currentWeight.value;
    final height = _height.value;
    final age = int.tryParse(_ageCtrl.text);

    if (currentWeight == null ||
        height == null ||
        age == null ||
        _gender == null) {
      return null;
    }

    final targetWeight = _maintaining ? null : _targetWeight.value;
    if (!_maintaining &&
        (targetWeight == null || _wrongSide(targetWeight, currentWeight))) {
      return null;
    }
    return HealthCalculator.calculatePlan(
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      heightCm: height,
      age: age,
      gender: _gender!,
      activityLevel: _activityLevel,
      trainingFrequency: _trainingFrequency,
      weightLossPace: _weightLossPace,
    );
  }

  // ── Moving ───────────────────────────────────────────────────────────────

  void _next() {
    final steps = _steps;
    if (!_answered(steps[_index])) return;
    if (_index == steps.length - 1) {
      _submit();
      return;
    }
    FocusScope.of(context).unfocus();
    if (steps[_index + 1] == _Step.plan) {
      setState(() => _building = true);
      return;
    }
    setState(() => _index++);
  }

  void _built() {
    if (!mounted) return;
    setState(() {
      _building = false;
      _index++;
    });
  }

  void _back() {
    if (_index == 0) {
      if (_inPreview) {
        _leavePreview();
      } else {
        ref.read(authControllerProvider.notifier).signOut();
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _index--);
  }

  /// Debug tools' preview: nothing is saved, and Start or Back on the
  /// first card goes back to Debug tools.
  bool get _inPreview => ref.read(onboardingPreviewProvider);

  void _leavePreview() {
    ref.read(onboardingPreviewProvider.notifier).state = false;
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (_inPreview) {
      _leavePreview();
      return;
    }
    await ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          name: _nameCtrl.text,
          age: int.parse(_ageCtrl.text),
          gender: _gender!,
          heightCm: _height.value!,
          currentWeightKg: _currentWeight.value!,
          targetWeightKg: _maintaining ? null : _targetWeight.value!,
          activityLevel: _activityLevel,
          trainingFrequency: _trainingFrequency,
          weightLossPace: _weightLossPace,
          country: countryNameFor(ref.read(deviceRegionProvider)),
          trackProtein: _trackProtein,
          weightUnit: _weightUnit,
          heightUnit: _heightUnit,
        );
  }

  // ── Cards ────────────────────────────────────────────────────────────────

  /// A text answer: focused on arrival, the keyboard's Next moves on, and
  /// what's wrong shows once something is typed.
  Widget _field(
    TextEditingController controller, {
    required String label,
    String? Function(String)? error,
    required TextInputType keyboard,
    required List<TextInputFormatter> formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      textInputAction: TextInputAction.next,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        errorText: controller.text.isEmpty
            ? null
            : error?.call(controller.text),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _next(),
    );
  }

  /// A height or weight: the units toggle, then the boxes, as [_field].
  Widget _measure(
    MeasureInput input, {
    required String label,
    required String? Function() error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerRight, child: _unitsToggle),
        const SizedBox(height: 16),
        MeasureField(
          input: input,
          label: label,
          autofocus: true,
          error: input.isEmpty ? null : error(),
          onChanged: () => setState(() {}),
          onSubmitted: _next,
        ),
      ],
    );
  }

  Widget get _unitsToggle => SizedBox(
    width: 240,
    child: UnitsToggle(
      weightUnit: _weightUnit,
      onChanged: (weight, height) => setState(() {
        _weightUnit = weight;
        _heightUnit = height;
        _height.switchTo(height, context.l10n);
        _currentWeight.switchTo(weight, context.l10n);
        _targetWeight.switchTo(weight, context.l10n);
      }),
    ),
  );

  /// The heading, the line under it (if any) and the answer for [step].
  AppLocalizations get _l10n => context.l10n;

  (String, String?, Widget) _card(_Step step) => switch (step) {
    _Step.name => (
      _l10n.onboardingNameTitle,
      null,
      _field(
        _nameCtrl,
        label: _l10n.onboardingName,
        keyboard: TextInputType.name,
        formatters: const [],
        capitalization: TextCapitalization.words,
      ),
    ),
    _Step.gender => (
      _l10n.onboardingGenderTitle,
      null,
      Row(
        children: [
          for (final (i, (gender, label)) in [
            (Gender.male, _l10n.commonMale),
            (Gender.female, _l10n.commonFemale),
            (Gender.other, _l10n.commonOther),
          ].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            GenderButton(
              label: label,
              selected: _gender == gender,
              onTap: () => setState(() => _gender = gender),
            ),
          ],
        ],
      ),
    ),
    _Step.age => (
      _l10n.onboardingAgeTitle,
      null,
      _field(
        _ageCtrl,
        label: _l10n.commonAge,
        keyboard: TextInputType.number,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        error: _ageError,
      ),
    ),
    _Step.height => (
      _l10n.onboardingHeightTitle,
      null,
      _measure(_height, label: _l10n.commonHeight, error: _heightError),
    ),
    _Step.weight => (
      _l10n.onboardingWeightTitle,
      null,
      _measure(
        _currentWeight,
        label: _l10n.commonCurrentWeight,
        error: () => _weightError(_currentWeight),
      ),
    ),
    _Step.goal => (
      _l10n.onboardingGoalTitle,
      _l10n.onboardingGoalBody,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, goal) in const [
            WeightLossPace.moderate,
            WeightLossPace.maintain,
            WeightLossPace.gain,
          ].indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            GoalCard(
              goal: goal,
              selected: _weightLossPace == goal,
              onTap: () => setState(() => _weightLossPace = goal),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _l10n.onboardingGoalNote,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
    _Step.target => (
      _l10n.onboardingTargetTitle,
      null,
      _measure(
        _targetWeight,
        label: _l10n.commonTargetWeight,
        error: _targetError,
      ),
    ),
    _Step.activity => (
      _l10n.onboardingActivityTitle,
      _l10n.onboardingActivityBody,
      Column(
        children: [
          for (final level in ActivityLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActivityCard(
                level: level,
                selected: _activityLevel == level,
                onTap: () => setState(() => _activityLevel = level),
              ),
            ),
        ],
      ),
    ),
    _Step.training => (
      _l10n.onboardingTrainingTitle,
      _l10n.onboardingTrainingBody,
      Column(
        children: [
          for (final frequency in TrainingFrequency.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TrainingCard(
                frequency: frequency,
                selected: _trainingFrequency == frequency,
                onTap: () => setState(() => _trainingFrequency = frequency),
              ),
            ),
        ],
      ),
    ),
    _Step.protein => (
      _l10n.onboardingProteinTitle,
      _l10n.onboardingProteinBody,
      PillToggle<bool>(
        options: [(true, _l10n.commonYes), (false, _l10n.commonNo)],
        selected: _trackProtein,
        onChanged: (track) => setState(() => _trackProtein = track),
      ),
    ),
    _Step.plan => (
      _l10n.onboardingPlanTitle,
      null,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The celebration illustration goes here once it's drawn.
          const Center(child: AppLogoMark(size: 96)),
          const SizedBox(height: 20),
          if (_preview case final preview?)
            Shine(
              child: HealthPlanPreviewCard(
                preview: preview,
                title: _l10n.onboardingPlanCardTitle,
                weightUnit: _weightUnit,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _l10n.onboardingPlanNote,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const MedicalNote(),
        ],
      ),
    ),
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(onboardingControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.onboardingErrorSave)),
        );
      }
    });

    final isLoading = ref.watch(onboardingControllerProvider).isLoading;
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final inPreview = ref.watch(onboardingPreviewProvider);
    final steps = _steps;
    final step = steps[_index];
    final last = _index == steps.length - 1;
    final l10n = context.l10n;
    final (heading, helper, answer) = _card(step);

    // While the plan is built, the phone's back gesture waits too.
    return PopScope(
      canPop: !_building,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / steps.length,
                        minHeight: 6,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isLoading || isSigningOut || _building
                            ? null
                            : _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(
                          _index > 0 || inPreview
                              ? l10n.onboardingBack
                              : isSigningOut
                              ? l10n.commonSigningOut
                              : l10n.profileBackToSignIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _building
                            ? SingleChildScrollView(
                                key: const ValueKey('building'),
                                child: _PlanBuilding(
                                  gaining: _gaining,
                                  onDone: _built,
                                ),
                              )
                            : SingleChildScrollView(
                                key: ValueKey(step),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      heading,
                                      style: AppTheme.display.copyWith(
                                        fontSize: 26,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (helper != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        helper,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    answer,
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Kept in place while the plan is built, so nothing jumps.
                    Visibility(
                      visible: !_building,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading || !_answered(step)
                              ? null
                              : _next,
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(
                                  last
                                      ? l10n.onboardingStart
                                      : l10n.onboardingNext,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

/// Between the last question and the plan: ten seconds of the plan being
/// put together, a bar filling with what it's working on, and three cards in
/// turn: a fact for the goal (the WHO's on obesity, or for someone
/// [gaining] one on muscle), one on calories for everyone, and a line to
/// start on, so the plan arrives as the result of the answers (12 November
/// 2026). The plan itself is worked out at once; this is only the moment.
/// [onDone] when the bar is full.
class _PlanBuilding extends StatefulWidget {
  const _PlanBuilding({required this.gaining, required this.onDone});

  final bool gaining;
  final VoidCallback onDone;

  @override
  State<_PlanBuilding> createState() => _PlanBuildingState();
}

class _PlanBuildingState extends State<_PlanBuilding>
    with SingleTickerProviderStateMixin {
  // Long enough to read each of the three cards.
  static const _duration = Duration(seconds: 10);

  late final _controller = AnimationController(vsync: this, duration: _duration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = [
      l10n.onboardingBuildingBurn,
      l10n.onboardingBuildingTarget,
      l10n.onboardingBuildingPlan,
    ];
    // (icon, text, source)
    final cards = [
      widget.gaining
          ? (
              Icons.fitness_center_rounded,
              l10n.onboardingBuildingGainFact,
              null,
            )
          : (
              Icons.public_rounded,
              l10n.onboardingBuildingFact,
              l10n.onboardingBuildingFactSource,
            ),
      (
        Icons.local_fire_department_rounded,
        l10n.onboardingBuildingCalorieFact,
        null,
      ),
      (Icons.flag_rounded, l10n.onboardingBuildingStart, null),
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final progress = Curves.easeInOut.transform(t);
        final line = (t * status.length).floor().clamp(0, status.length - 1);
        final card = (t * cards.length).floor().clamp(0, cards.length - 1);
        final (icon, text, source) = cards[card];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Center(child: AppLogoMark(size: 80)),
            const SizedBox(height: 24),
            Text(
              l10n.onboardingBuildingTitle,
              textAlign: TextAlign.center,
              style: AppTheme.display.copyWith(
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                status[line],
                key: ValueKey(line),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: AppColors.veryGood,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingBuildingPercent((progress * 100).round()),
              textAlign: TextAlign.center,
              style: AppTheme.display.copyWith(
                fontSize: 18,
                color: AppColors.veryGood,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: AppCard(
                key: ValueKey(card),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (source != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              source,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
