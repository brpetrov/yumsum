import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/health_calculator.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/profile_controller.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/day_status.dart';
import 'package:lean_streak/widgets/health_plan_preview_card.dart';
import 'package:lean_streak/widgets/responsive_page.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/measure_field.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/plan_choices.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

class PlanSettingsScreen extends ConsumerStatefulWidget {
  const PlanSettingsScreen({super.key});

  @override
  ConsumerState<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _height = HeightInput(HeightUnit.cm);
  final _currentWeight = WeightInput(WeightUnit.kg);
  final _targetWeight = WeightInput(WeightUnit.kg);
  WeightUnit _weightUnit = WeightUnit.kg;
  HeightUnit _heightUnit = HeightUnit.cm;

  String? _loadedProfileUid;
  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  TrainingFrequency _trainingFrequency = TrainingFrequency.none;
  WeightLossPace _weightLossPace = WeightLossPace.moderate;
  bool _trackProtein = true;

  double? get _currentBmi {
    final currentWeight = _currentWeight.value;
    final height = _height.value;
    if (currentWeight == null || height == null) return null;
    if (currentWeight <= 0 || height <= 0) return null;
    return HealthCalculator.bmi(currentWeight, height);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _height.dispose();
    _currentWeight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  /// Whether the form changes what the Adaptive formula learnt from, so
  /// saving starts it again.
  bool _detailsChanged(UserProfile profile) =>
      int.tryParse(_ageCtrl.text) != profile.age ||
      _height.value != profile.heightCm ||
      _gender != profile.gender ||
      _activityLevel != profile.activityLevel ||
      _trainingFrequency != profile.trainingFrequency;

  HealthPlanCalculation? _preview(UserProfile profile) {
    final currentWeight = _currentWeight.value;
    final height = _height.value;
    final age = int.tryParse(_ageCtrl.text);

    if (currentWeight == null ||
        height == null ||
        age == null ||
        _gender == null) {
      return null;
    }

    final isMaintaining = _weightLossPace == WeightLossPace.maintain;
    final targetWeight = isMaintaining ? null : _targetWeight.value;
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
      adaptiveKcal: _detailsChanged(profile)
          ? 0
          : profile.adaptiveKcal.toDouble(),
    );
  }

  void _seedForm(UserProfile profile) {
    if (_loadedProfileUid == profile.uid) return;

    _loadedProfileUid = profile.uid;
    _ageCtrl.text = profile.age.toString();
    _weightUnit = ref.read(weightUnitProvider);
    _heightUnit = ref.read(heightUnitProvider);
    _height
      ..unit = _heightUnit
      ..show(profile.heightCm);
    _currentWeight
      ..unit = _weightUnit
      ..show(profile.currentWeightKg);
    _targetWeight
      ..unit = _weightUnit
      ..show(profile.targetWeightKg);
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _trainingFrequency = profile.trainingFrequency;
    _weightLossPace = profile.weightLossPace;
    _trackProtein = profile.trackProtein;
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
          heightCm: _height.value!,
          currentWeightKg: _currentWeight.value!,
          targetWeightKg: _weightLossPace == WeightLossPace.maintain
              ? null
              : _targetWeight.value!,
          activityLevel: _activityLevel,
          trainingFrequency: _trainingFrequency,
          weightLossPace: _weightLossPace,
          trackProtein: _trackProtein,
          weightUnit: _weightUnit,
          heightUnit: _heightUnit,
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

  String? _weightError(WeightInput input) {
    final kg = input.value;
    if (kg == null) return 'Required';
    if (kg < 30 || kg > 300) return weightRange(30, 300, _weightUnit);
    return null;
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
          final preview = _preview(profile);
          final currentBmi = _currentBmi;
          final heightField = MeasureField(
            input: _height,
            label: 'Height',
            validator: () {
              final cm = _height.value;
              if (cm == null) return 'Required';
              if (cm < 100 || cm > 250) {
                return heightRange(100, 250, _heightUnit);
              }
              return null;
            },
          );
          final weightField = MeasureField(
            input: _currentWeight,
            label: 'Current weight',
            validator: () => _weightError(_currentWeight),
          );
          final unitLabel = TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          );

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
                      const SectionLabel('UNITS'),
                      Text('Weight', style: unitLabel),
                      SizedBox(height: 10),
                      WeightUnitToggle(
                        unit: _weightUnit,
                        onChanged: (unit) => setState(() {
                          _weightUnit = unit;
                          _currentWeight.switchTo(unit);
                          _targetWeight.switchTo(unit);
                        }),
                      ),
                      SizedBox(height: 18),
                      Text('Height', style: unitLabel),
                      SizedBox(height: 10),
                      HeightUnitToggle(
                        unit: _heightUnit,
                        onChanged: (unit) => setState(() {
                          _heightUnit = unit;
                          _height.switchTo(unit);
                        }),
                      ),
                      SizedBox(height: 28),
                      const SectionLabel('YOUR BODY'),
                      // Side by side when each is one box; stones or feet
                      // need the width.
                      if (!_height.twoBoxes && !_currentWeight.twoBoxes)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: heightField),
                            SizedBox(width: 12),
                            Expanded(child: weightField),
                          ],
                        )
                      else ...[
                        heightField,
                        SizedBox(height: 18),
                        weightField,
                      ],
                      SizedBox(height: 28),
                      if (currentBmi != null) ...[
                        const SectionLabel('YOUR BMI'),
                        _BmiCard(bmi: currentBmi),
                        SizedBox(height: 28),
                      ],
                      const SectionLabel('YOUR GOAL'),
                      if (_weightLossPace != WeightLossPace.maintain) ...[
                        MeasureField(
                          input: _targetWeight,
                          label: 'Target weight',
                          prefixIcon: Icon(Icons.flag_outlined),
                          textInputAction: TextInputAction.done,
                          validator: () {
                            final error = _weightError(_targetWeight);
                            if (error != null) return error;
                            final current = _currentWeight.value;
                            if (current != null &&
                                _targetWeight.value! >= current) {
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
                      const SectionLabel('TRACK PROTEIN TOO?'),
                      Text(
                        'Protein helps keep muscle while you lose weight. Off hides it everywhere.',
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
                            weightUnit: _weightUnit,
                            selected: _weightLossPace == pace,
                            onTap: () => setState(() => _weightLossPace = pace),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      const SectionLabel('PERSONAL ADJUSTMENT'),
                      _AdaptiveSection(
                        preview: preview,
                        restarts: _detailsChanged(profile),
                      ),
                      SizedBox(height: 20),
                      if (preview != null) ...[
                        HealthPlanPreviewCard(
                          preview: preview,
                          title: 'Updated plan',
                          weightUnit: _weightUnit,
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

/// The Adaptive formula, always on with YumSum Star: the sum it makes and
/// how well it knows them so far. Free users see the star, and a tap opens
/// the YumSum Star page.
class _AdaptiveSection extends ConsumerWidget {
  const _AdaptiveSection({required this.preview, required this.restarts});

  final HealthPlanCalculation? preview;
  final bool restarts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusProvider);
    final muted = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    );
    final preview = this.preview;
    final progress = plus
        ? ref.watch(adaptiveProgressProvider).valueOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Flexible(child: Text('Adaptive formula')),
              if (!plus) ...[
                const SizedBox(width: 6),
                const PlusStar(size: 20),
              ],
            ],
          ),
          subtitle: const Text(
            'Learns from your weigh-ins and adjusts your target each Monday.',
          ),
          onTap: plus ? null : () => showPlusPaywall(context),
        ),
        if (plus) ...[
          if (preview != null) Text(adaptiveSumLine(preview), style: muted),
          if (progress != null)
            if (adaptivePausedLine(progress) case final paused?) ...[
              const SizedBox(height: 4),
              Text(paused, style: muted),
            ],
          if (restarts) ...[
            const SizedBox(height: 4),
            Text('Saving starts it again from your new plan.', style: muted),
          ],
          TextButton(
            onPressed: () => showAdaptiveIntro(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('How it works'),
          ),
        ],
      ],
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
