import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/plan_choices.dart';

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
  bool _trackProtein = true;

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
          trackProtein: _trackProtein,
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
                    const SectionLabel('ABOUT YOU'),
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
                        GenderButton(
                          label: 'Male',
                          selected: _gender == Gender.male,
                          onTap: () => setState(() => _gender = Gender.male),
                        ),
                        SizedBox(width: 8),
                        GenderButton(
                          label: 'Female',
                          selected: _gender == Gender.female,
                          onTap: () => setState(() => _gender = Gender.female),
                        ),
                        SizedBox(width: 8),
                        GenderButton(
                          label: 'Other',
                          selected: _gender == Gender.other,
                          onTap: () => setState(() => _gender = Gender.other),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),

                    // ── Your body ──────────────────────────────────────────
                    const SectionLabel('YOUR BODY'),
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
                    const SectionLabel('YOUR GOAL'),
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
                        child: PaceCard(
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
                    const SectionLabel('YOUR DAILY MOVEMENT'),
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
                        child: ActivityCard(
                          level: level,
                          selected: _activityLevel == level,
                          onTap: () => setState(() => _activityLevel = level),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    const SectionLabel('HOW OFTEN DO YOU TRAIN?'),
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
                        child: TrainingCard(
                          frequency: frequency,
                          selected: _trainingFrequency == frequency,
                          onTap: () =>
                              setState(() => _trainingFrequency = frequency),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    const SectionLabel('TRACK PROTEIN TOO?'),
                    Text(
                      'Protein helps keep muscle while you lose weight. You can change this in Plan Settings.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    PillToggle<bool>(
                      options: const [(true, 'Yes'), (false, 'No')],
                      selected: _trackProtein,
                      onChanged: (value) =>
                          setState(() => _trackProtein = value),
                    ),
                    SizedBox(height: 28),

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
