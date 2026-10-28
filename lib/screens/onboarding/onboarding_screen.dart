import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/clickable.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _foodCtrl = TextEditingController();

  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  TrainingFrequency _trainingFrequency = TrainingFrequency.none;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _countryCtrl.dispose();
    _foodCtrl.dispose();
    super.dispose();
  }

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

    final isMaintaining = _weightLossPace == WeightLossPace.maintain;
    final targetWeight = isMaintaining
        ? null
        : double.tryParse(_targetWeightCtrl.text);
    if (!isMaintaining &&
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

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showSnack('Select your gender.');
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
          targetWeightKg: _weightLossPace == WeightLossPace.maintain
              ? null
              : double.parse(_targetWeightCtrl.text),
          activityLevel: _activityLevel,
          trainingFrequency: _trainingFrequency,
          weightLossPace: _weightLossPace,
          country: _countryCtrl.text,
          usualFood: _foodCtrl.text,
        );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(onboardingControllerProvider, (_, next) {
      if (next.hasError) {
        _showSnack('Something went wrong. Try again.');
      }
    });

    final isLoading = ref.watch(onboardingControllerProvider).isLoading;
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final preview = _preview;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isLoading || isSigningOut
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(
                          isSigningOut ? 'Signing out...' : 'Back to sign in',
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Let\'s get started',
                      style: AppTheme.display.copyWith(
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tell us about yourself to get your plan.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 32),

                    // ── About you ──────────────────────────────────────────
                    const _SectionLabel('ABOUT YOU'),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name.'
                          : null,
                    ),
                    SizedBox(height: 14),
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null) return 'Enter your age.';
                        if (n < 18 || n > 120) return 'Valid age: 18–120.';
                        return null;
                      },
                    ),
                    SizedBox(height: 14),
                    TextFormField(
                      controller: _countryCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Country you live in',
                        prefixIcon: Icon(Icons.public_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your country.'
                          : null,
                    ),
                    SizedBox(height: 14),
                    TextFormField(
                      controller: _foodCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Food you usually eat (optional)',
                        hintText: 'e.g. Bulgarian home cooking, vegetarian',
                        helperText:
                            'Helps the AI read dish names and portions the way you mean them.',
                        helperMaxLines: 2,
                        prefixIcon: Icon(Icons.restaurant_outlined),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _GenderButton(
                          label: 'Male',
                          selected: _gender == Gender.male,
                          onTap: () => setState(() => _gender = Gender.male),
                        ),
                        SizedBox(width: 8),
                        _GenderButton(
                          label: 'Female',
                          selected: _gender == Gender.female,
                          onTap: () => setState(() => _gender = Gender.female),
                        ),
                        SizedBox(width: 8),
                        _GenderButton(
                          label: 'Other',
                          selected: _gender == Gender.other,
                          onTap: () => setState(() => _gender = Gender.other),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),

                    // ── Your body ──────────────────────────────────────────
                    const _SectionLabel('YOUR BODY'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}\.?\d{0,1}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Height',
                              suffixText: 'cm',
                            ),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null) return 'Required';
                              if (n < 100 || n > 250) return '100–250 cm';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _currentWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}\.?\d{0,1}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Current weight',
                              suffixText: 'kg',
                            ),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null) return 'Required';
                              if (n < 30 || n > 300) return '30–300 kg';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),

                    // ── Your goal ──────────────────────────────────────────
                    const _SectionLabel('YOUR GOAL'),
                    Text(
                      'Pace sets the calorie target. Target weight sets how long the plan takes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...WeightLossPace.values.map(
                      (pace) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PaceCard(
                          pace: pace,
                          selected: _weightLossPace == pace,
                          onTap: () => setState(() => _weightLossPace = pace),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_weightLossPace != WeightLossPace.maintain) ...[
                      TextFormField(
                        controller: _targetWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}\.?\d{0,1}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Target weight',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (v) {
                          if (_weightLossPace == WeightLossPace.maintain) {
                            return null;
                          }
                          final n = double.tryParse(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 30 || n > 300) return '30-300 kg';
                          final current = double.tryParse(
                            _currentWeightCtrl.text,
                          );
                          if (current != null && n >= current) {
                            return 'Must be less than your current weight';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppTheme.inputRadius,
                          ),
                        ),
                        child: Text(
                          'Your daily target will be close to your maintenance calories.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 28),

                    // ── Activity level ─────────────────────────────────────
                    const _SectionLabel('YOUR DAILY MOVEMENT'),
                    Text(
                      'Your normal day outside workouts.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...ActivityLevel.values.map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActivityCard(
                          level: level,
                          selected: _activityLevel == level,
                          onTap: () => setState(() => _activityLevel = level),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    const _SectionLabel('HOW OFTEN DO YOU TRAIN?'),
                    Text(
                      'Structured workouts on top of your normal day.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...TrainingFrequency.values.map(
                      (frequency) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TrainingCard(
                          frequency: frequency,
                          selected: _trainingFrequency == frequency,
                          onTap: () =>
                              setState(() => _trainingFrequency = frequency),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    if (preview != null) ...[
                      HealthPlanPreviewCard(
                        preview: preview,
                        title: 'Your plan',
                      ),
                      SizedBox(height: 20),
                    ],
                    const MedicalNote(),
                    SizedBox(height: 16),

                    // ── Submit ─────────────────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
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
                                'Get my plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 32),
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Text(
        text,
        style: AppTheme.display.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Clickable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.display.copyWith(
              fontSize: 15.5,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Activity level card ────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });
  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  static String _title(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary => 'Mostly sitting',
    ActivityLevel.lightlyActive => 'Light daily movement',
    ActivityLevel.moderatelyActive => 'On feet often',
    ActivityLevel.veryActive => 'Physical job or high movement',
  };

  static String _description(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary => 'Desk day, low steps, little standing.',
    ActivityLevel.lightlyActive => 'Some walking, errands, or light chores.',
    ActivityLevel.moderatelyActive =>
      'Standing or walking for much of the day.',
    ActivityLevel.veryActive => 'Manual work, high steps, or very active days.',
  };

  static IconData _icon(ActivityLevel l) => switch (l) {
    ActivityLevel.sedentary => Icons.weekend_outlined,
    ActivityLevel.lightlyActive => Icons.directions_walk_outlined,
    ActivityLevel.moderatelyActive => Icons.directions_run_outlined,
    ActivityLevel.veryActive => Icons.fitness_center_outlined,
  };

  @override
  Widget build(BuildContext context) => _SelectionCard(
    title: _title(level),
    description: _description(level),
    icon: _icon(level),
    selected: selected,
    onTap: onTap,
  );
}

// ── Training frequency card ────────────────────────────────────────────────

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    required this.frequency,
    required this.selected,
    required this.onTap,
  });

  final TrainingFrequency frequency;
  final bool selected;
  final VoidCallback onTap;

  static String _title(TrainingFrequency frequency) => switch (frequency) {
    TrainingFrequency.none => 'No regular training',
    TrainingFrequency.oneToTwo => '1 to 2 sessions/week',
    TrainingFrequency.threeToFour => '3 to 4 sessions/week',
    TrainingFrequency.fivePlus => '5+ sessions/week',
  };

  static String _description(TrainingFrequency frequency) =>
      switch (frequency) {
        TrainingFrequency.none => 'No planned workouts most weeks.',
        TrainingFrequency.oneToTwo =>
          'A couple of lifting, cardio, or sport days.',
        TrainingFrequency.threeToFour => 'Regular training most weeks.',
        TrainingFrequency.fivePlus => 'Frequent structured workouts.',
      };

  static IconData _icon(TrainingFrequency frequency) => switch (frequency) {
    TrainingFrequency.none => Icons.block_rounded,
    TrainingFrequency.oneToTwo => Icons.fitness_center_outlined,
    TrainingFrequency.threeToFour => Icons.directions_run_outlined,
    TrainingFrequency.fivePlus => Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) => _SelectionCard(
    title: _title(frequency),
    description: _description(frequency),
    icon: _icon(frequency),
    selected: selected,
    onTap: onTap,
  );
}

// ── Weight loss pace card ──────────────────────────────────────────────────

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pace,
    required this.selected,
    required this.onTap,
  });
  final WeightLossPace pace;
  final bool selected;
  final VoidCallback onTap;

  static String _title(WeightLossPace p) => switch (p) {
    WeightLossPace.slow => 'Slow - 0.25 kg/week',
    WeightLossPace.moderate => 'Moderate - 0.5 kg/week',
    WeightLossPace.fast => 'Fast - 0.75 kg/week',
    WeightLossPace.maintain => 'Maintain weight',
  };

  static String _description(WeightLossPace p) => switch (p) {
    WeightLossPace.slow =>
      'Gentle and easier to maintain over a longer period.',
    WeightLossPace.moderate =>
      'Steady progress with a moderate calorie deficit.',
    WeightLossPace.fast =>
      'Faster results, but more restrictive for most people.',
    WeightLossPace.maintain =>
      'Keeps your calories around maintenance instead of creating a deficit.',
  };

  static IconData _icon(WeightLossPace p) => switch (p) {
    WeightLossPace.slow => Icons.hourglass_bottom_rounded,
    WeightLossPace.moderate => Icons.trending_down_rounded,
    WeightLossPace.fast => Icons.bolt_rounded,
    WeightLossPace.maintain => Icons.horizontal_rule_rounded,
  };

  @override
  Widget build(BuildContext context) => _SelectionCard(
    title: _title(pace),
    description: _description(pace),
    icon: _icon(pace),
    selected: selected,
    onTap: onTap,
  );
}

// ── Shared selection card ──────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconBubble(
              icon,
              size: 40,
              background: selected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
