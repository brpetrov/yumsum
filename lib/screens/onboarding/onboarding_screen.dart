import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/legal_links.dart';
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

/// First run: one question per card, then the plan. The country comes from
/// the phone's region, usual food is left blank and the pace is moderate;
/// Plan Settings changes any of them.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  // Read once, as the screen opens.
  final _country = countryNameFor(
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );

  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  TrainingFrequency _trainingFrequency = TrainingFrequency.none;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;
  bool _trackProtein = true;
  int _index = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  bool get _maintaining => _weightLossPace == WeightLossPace.maintain;

  List<_Step> get _steps => [
    for (final step in _Step.values)
      if (step != _Step.target || !_maintaining) step,
  ];

  // ── Checks, as Plan Settings makes them ─────────────────────────────────

  String? _ageError(String text) {
    final n = int.tryParse(text);
    if (n == null) return 'Enter your age.';
    if (n < 18 || n > 120) return 'Valid age: 18–120.';
    return null;
  }

  String? _heightError(String text) {
    final n = double.tryParse(text);
    if (n == null) return 'Enter your height.';
    if (n < 100 || n > 250) return '100–250 cm';
    return null;
  }

  String? _weightError(String text) {
    final n = double.tryParse(text);
    if (n == null) return 'Enter your weight.';
    if (n < 30 || n > 300) return '30–300 kg';
    return null;
  }

  String? _targetError(String text) {
    final error = _weightError(text);
    if (error != null) return error;
    final current = double.tryParse(_currentWeightCtrl.text);
    if (current != null && double.parse(text) >= current) {
      return 'Must be less than your current weight';
    }
    return null;
  }

  bool _answered(_Step step) => switch (step) {
    _Step.name => _nameCtrl.text.trim().isNotEmpty,
    _Step.gender => _gender != null,
    _Step.age => _ageError(_ageCtrl.text) == null,
    _Step.height => _heightError(_heightCtrl.text) == null,
    _Step.weight => _weightError(_currentWeightCtrl.text) == null,
    _Step.target => _targetError(_targetWeightCtrl.text) == null,
    _Step.goal || _Step.activity || _Step.training || _Step.protein => true,
    _Step.plan => _preview != null,
  };

  // ── Live preview ─────────────────────────────────────────────────────────

  HealthPlanCalculation? get _preview {
    final currentWeight = double.tryParse(_currentWeightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);

    if (currentWeight == null ||
        height == null ||
        age == null ||
        _gender == null) {
      return null;
    }

    final targetWeight = _maintaining
        ? null
        : double.tryParse(_targetWeightCtrl.text);
    if (!_maintaining &&
        (targetWeight == null || targetWeight >= currentWeight)) {
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
    setState(() => _index++);
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
          heightCm: double.parse(_heightCtrl.text),
          currentWeightKg: double.parse(_currentWeightCtrl.text),
          targetWeightKg: _maintaining
              ? null
              : double.parse(_targetWeightCtrl.text),
          activityLevel: _activityLevel,
          trainingFrequency: _trainingFrequency,
          weightLossPace: _weightLossPace,
          country: _country,
          usualFood: '',
          trackProtein: _trackProtein,
        );
  }

  // ── Cards ────────────────────────────────────────────────────────────────

  /// A text answer: focused on arrival, the keyboard's Next moves on, and
  /// what's wrong shows once something is typed.
  Widget _field(
    TextEditingController controller, {
    required String label,
    String? suffix,
    String? Function(String)? error,
    TextInputType keyboard = const TextInputType.numberWithOptions(
      decimal: true,
    ),
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      textInputAction: TextInputAction.next,
      inputFormatters:
          formatters ??
          [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: controller.text.isEmpty
            ? null
            : error?.call(controller.text),
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _next(),
    );
  }

  /// The heading, the line under it (if any) and the answer for [step].
  (String, String?, Widget) _card(_Step step) => switch (step) {
    _Step.name => (
      'What\'s your name?',
      null,
      _field(
        _nameCtrl,
        label: 'Name',
        keyboard: TextInputType.name,
        formatters: const [],
        capitalization: TextCapitalization.words,
      ),
    ),
    _Step.gender => (
      'Are you…',
      null,
      Row(
        children: [
          for (final (i, (gender, label)) in [
            (Gender.male, 'Male'),
            (Gender.female, 'Female'),
            (Gender.other, 'Other'),
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
      'How old are you?',
      null,
      _field(
        _ageCtrl,
        label: 'Age',
        keyboard: TextInputType.number,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        error: _ageError,
      ),
    ),
    _Step.height => (
      'How tall are you?',
      null,
      _field(_heightCtrl, label: 'Height', suffix: 'cm', error: _heightError),
    ),
    _Step.weight => (
      'What do you weigh now?',
      null,
      _field(
        _currentWeightCtrl,
        label: 'Current weight',
        suffix: 'kg',
        error: _weightError,
      ),
    ),
    _Step.goal => (
      'What\'s your goal?',
      'A calorie is the energy in food. Eat a little less than your body '
          'burns and you lose weight, steadily and safely.',
      PillToggle<WeightLossPace>(
        options: const [
          (WeightLossPace.moderate, 'Lose weight'),
          (WeightLossPace.maintain, 'Keep my weight'),
        ],
        selected: _weightLossPace,
        onChanged: (pace) => setState(() => _weightLossPace = pace),
      ),
    ),
    _Step.target => (
      'What weight are you aiming for?',
      null,
      _field(
        _targetWeightCtrl,
        label: 'Target weight',
        suffix: 'kg',
        error: _targetError,
      ),
    ),
    _Step.activity => (
      'How active is your normal day?',
      'Outside workouts.',
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
      'Do you train on top of that?',
      'Structured workouts, if any.',
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
      'Track protein too?',
      'Protein keeps you full and looks after your muscle. YumSum works it '
          'out for each meal you log.',
      PillToggle<bool>(
        options: const [(true, 'Yes'), (false, 'No')],
        selected: _trackProtein,
        onChanged: (track) => setState(() => _trackProtein = track),
      ),
    ),
    _Step.plan => (
      'Your plan is ready!',
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
                title: 'Your plan',
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'You can go over all of this again, and get into more detail, '
            'in Plan Settings.',
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
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    });

    final isLoading = ref.watch(onboardingControllerProvider).isLoading;
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final inPreview = ref.watch(onboardingPreviewProvider);
    final steps = _steps;
    final step = steps[_index];
    final last = _index == steps.length - 1;
    final (heading, helper, answer) = _card(step);

    return Scaffold(
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
                      onPressed: isLoading || isSigningOut ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(
                        _index > 0 || inPreview
                            ? 'Back'
                            : isSigningOut
                            ? 'Signing out...'
                            : 'Back to sign in',
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
                      child: SingleChildScrollView(
                        key: ValueKey(step),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading || !_answered(step) ? null : _next,
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
                              last ? 'Start' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }
}
