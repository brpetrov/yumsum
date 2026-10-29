import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/responsive_page.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/plan_choices.dart';

class PlanSettingsScreen extends ConsumerStatefulWidget {
  const PlanSettingsScreen({super.key});

  @override
  ConsumerState<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _foodCtrl = TextEditingController();

  String? _loadedProfileUid;
  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  TrainingFrequency _trainingFrequency = TrainingFrequency.none;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;

  double? get _currentBmi {
    final currentWeight = double.tryParse(_currentWeightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    if (currentWeight == null || height == null) return null;
    if (currentWeight <= 0 || height <= 0) return null;
    return HealthCalculator.bmi(currentWeight, height);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _countryCtrl.dispose();
    _foodCtrl.dispose();
    super.dispose();
  }

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

  void _seedForm(UserProfile profile) {
    if (_loadedProfileUid == profile.uid) return;

    _loadedProfileUid = profile.uid;
    _ageCtrl.text = profile.age.toString();
    _heightCtrl.text = _formatDouble(profile.heightCm);
    _currentWeightCtrl.text = _formatDouble(profile.currentWeightKg);
    _targetWeightCtrl.text = _formatDouble(profile.targetWeightKg);
    _countryCtrl.text = profile.country;
    _foodCtrl.text = profile.usualFood;
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _trainingFrequency = profile.trainingFrequency;
    _weightLossPace = profile.weightLossPace;
  }

  Future<void> _submit(UserProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showSnack('Select your gender.');
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(
          currentProfile: profile,
          name: profile.name,
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

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Plan saved.')));
      return;
    }

    _showSnack('Could not save your plan. Try again.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final isSaving = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text('Plan Settings')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Could not load your profile.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          _seedForm(profile);
          final preview = _preview;
          final currentBmi = _currentBmi;

          return SafeArea(
            child: SingleChildScrollView(
              child: ResponsivePage(
                maxWidth: 560,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Update your health plan',
                        style: AppTheme.display.copyWith(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Change anything below and your plan adjusts to match.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 28),
                      const SectionLabel('PERSONAL DETAILS'),
                      TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        validator: (value) {
                          final age = int.tryParse(value ?? '');
                          if (age == null) return 'Enter your age.';
                          if (age < 18 || age > 120) {
                            return 'Valid age: 18–120.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
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
                      SizedBox(height: 18),
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 10),
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
                            onTap: () =>
                                setState(() => _gender = Gender.female),
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
                      const SectionLabel('YOUR BODY'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                              validator: (value) {
                                final height = double.tryParse(value ?? '');
                                if (height == null) return 'Required';
                                if (height < 100 || height > 250) {
                                  return '100-250 cm';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _currentWeightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                              validator: (value) {
                                final weight = double.tryParse(value ?? '');
                                if (weight == null) return 'Required';
                                if (weight < 30 || weight > 300) {
                                  return '30-300 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28),
                      if (currentBmi != null) ...[
                        const SectionLabel('YOUR BMI'),
                        _BmiCard(bmi: currentBmi),
                        SizedBox(height: 28),
                      ],
                      const SectionLabel('YOUR GOAL'),
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
                          validator: (value) {
                            final target = double.tryParse(value ?? '');
                            if (target == null) return 'Required';
                            if (target < 30 || target > 300) {
                              return '30-300 kg';
                            }
                            final current = double.tryParse(
                              _currentWeightCtrl.text,
                            );
                            if (current != null && target >= current) {
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
                            'Your target weight stays at your current weight.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 28),
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
                      const SectionLabel(
                        'HOW FAST DO YOU WANT TO LOSE WEIGHT?',
                      ),
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
                      SizedBox(height: 20),
                      if (preview != null) ...[
                        HealthPlanPreviewCard(
                          preview: preview,
                          title: 'Updated plan',
                        ),
                        SizedBox(height: 20),
                      ],
                      const MedicalNote(),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () => _submit(profile),
                          child: isSaving
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Save plan',
                                  style: TextStyle(
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
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            'Could not load your profile.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double bmi;

  static const double _minBmi = 12;
  static const double _maxBmi = 40;

  _BmiCategory get _category {
    if (bmi < 18.5) {
      return _BmiCategory(label: 'Underweight', color: AppColors.info);
    }
    if (bmi < 25) {
      return _BmiCategory(label: 'Healthy range', color: AppColors.veryGood);
    }
    if (bmi < 30) {
      return _BmiCategory(label: 'Overweight', color: AppColors.bad);
    }
    return _BmiCategory(label: 'Obese range', color: AppColors.veryBad);
  }

  double get _markerPosition {
    return ((bmi.clamp(_minBmi, _maxBmi) - _minBmi) / (_maxBmi - _minBmi))
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your BMI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: AppTheme.display.copyWith(
                        fontSize: 36,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _BmiBadge(category: category),
            ],
          ),
          SizedBox(height: 18),
          _BmiGradientLine(markerPosition: _markerPosition),
          SizedBox(height: 10),
          const _BmiScaleLabels(),
        ],
      ),
    );
  }
}

class _BmiGradientLine extends StatelessWidget {
  const _BmiGradientLine({required this.markerPosition});

  final double markerPosition;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerLeft = (constraints.maxWidth - 14) * markerPosition;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 11,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info,
                        AppColors.veryGood,
                        AppColors.bad,
                        AppColors.veryBad,
                      ],
                      stops: [0, 0.32, 0.58, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                top: 0,
                child: Container(
                  width: 14,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BmiBadge extends StatelessWidget {
  const _BmiBadge({required this.category});

  final _BmiCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: AppColors.isDark ? 0.2 : 0.17),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: AppTheme.display.copyWith(
          fontSize: 14,
          color: tintedTextColor(category.color),
        ),
      ),
    );
  }
}

class _BmiTickLabel extends StatelessWidget {
  const _BmiTickLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _BmiScaleLabels extends StatelessWidget {
  const _BmiScaleLabels();

  double _positionFor(double value) {
    return ((value - _BmiCard._minBmi) / (_BmiCard._maxBmi - _BmiCard._minBmi))
        .clamp(0, 1)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const labelWidth = 34.0;

          double leftFor(double value) {
            final position = _positionFor(value);
            return (constraints.maxWidth - labelWidth) * position;
          }

          return Stack(
            children: [
              Positioned(
                left: leftFor(18.5),
                width: labelWidth,
                child: const _BmiTickLabel('18.5'),
              ),
              Positioned(
                left: leftFor(25),
                width: labelWidth,
                child: const _BmiTickLabel('25'),
              ),
              Positioned(
                left: leftFor(30),
                width: labelWidth,
                child: const _BmiTickLabel('30'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BmiCategory {
  const _BmiCategory({required this.label, required this.color});

  final String label;
  final Color color;
}

String _formatDouble(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
