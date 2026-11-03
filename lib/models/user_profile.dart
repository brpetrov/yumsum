import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum Gender {
  male('male'),
  female('female'),
  other('other');

  const Gender(this.value);
  final String value;

  static Gender fromString(String s) =>
      Gender.values.firstWhere((e) => e.value == s);
}

/// How physically active the user is — used for TDEE calculation.
enum ActivityLevel {
  sedentary('sedentary'),
  lightlyActive('lightly_active'),
  moderatelyActive('moderately_active'),
  veryActive('very_active');

  const ActivityLevel(this.value);
  final String value;

  static ActivityLevel fromString(String s) {
    return switch (s) {
      'sedentary' || 'light' => ActivityLevel.sedentary,
      'lightly_active' ||
      'lightlyActive' ||
      'medium' => ActivityLevel.lightlyActive,
      'moderately_active' ||
      'moderatelyActive' ||
      'hard' => ActivityLevel.moderatelyActive,
      'very_active' || 'veryActive' => ActivityLevel.veryActive,
      _ => throw ArgumentError.value(s, 's', 'Unknown activity level'),
    };
  }
}

enum TrainingFrequency {
  none('none'),
  oneToTwo('one_to_two'),
  threeToFour('three_to_four'),
  fivePlus('five_plus');

  const TrainingFrequency(this.value);
  final String value;

  static TrainingFrequency fromString(String s) {
    return switch (s) {
      'none' => TrainingFrequency.none,
      'one_to_two' || 'oneToTwo' => TrainingFrequency.oneToTwo,
      'three_to_four' || 'threeToFour' => TrainingFrequency.threeToFour,
      'five_plus' || 'fivePlus' => TrainingFrequency.fivePlus,
      _ => throw ArgumentError.value(s, 's', 'Unknown training frequency'),
    };
  }

  static TrainingFrequency legacyDefaultFor(ActivityLevel activityLevel) {
    return switch (activityLevel) {
      ActivityLevel.sedentary => TrainingFrequency.none,
      ActivityLevel.lightlyActive => TrainingFrequency.oneToTwo,
      ActivityLevel.moderatelyActive => TrainingFrequency.threeToFour,
      ActivityLevel.veryActive => TrainingFrequency.fivePlus,
    };
  }
}

const currentActivityScaleVersion = 3;
const currentPlanCalculationVersion = 2;

/// How quickly the user wants to lose weight — determines target date & deficit.
enum WeightLossPace {
  slow('slow'),
  moderate('moderate'),
  fast('fast'),
  maintain('maintain');

  const WeightLossPace(this.value);
  final String value;

  static WeightLossPace fromString(String s) =>
      WeightLossPace.values.firstWhere((e) => e.value == s);
}

enum GoalPaceLevel {
  safe('safe'),
  caution('caution'),
  warning('warning');

  const GoalPaceLevel(this.value);
  final String value;

  static GoalPaceLevel fromString(String s) =>
      GoalPaceLevel.values.firstWhere((e) => e.value == s);
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Profiles from before the country/food fields existed get the values the
/// prompts used to hard-code.
const defaultCountry = 'United Kingdom';
const legacyUsualFood = 'Bulgarian home cooking';

/// One change the Adaptive formula made: the Monday (yyyy-MM-dd) and the
/// target before and after.
typedef AdaptiveChange = ({String week, int from, int to});

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.country = defaultCountry,
    this.usualFood = '',
    this.trackProtein = true,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.trainingFrequency,
    required this.activityScaleVersion,
    required this.planCalculationVersion,
    required this.weightLossPace,
    required this.targetDate,
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.dailyCalorieTarget,
    required this.goalPaceKgPerWeek,
    required this.goalPaceLevel,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.adaptiveOn = true,
    this.adaptiveKcal = 0,
    this.adaptiveWeek,
    this.adaptiveNote,
    this.adaptiveFrom,
    this.adaptiveChanges = const [],
  });

  final String uid;
  final String email;
  final String name;

  /// Where the user lives and what they usually eat; both open every AI
  /// prompt so dish names and portions are read the way they mean them.
  final String country;
  final String usualFood;

  /// Off hides protein everywhere (Today, the bar, meals, History) and
  /// skips the automatic protein estimate; calories alone are tracked.
  final bool trackProtein;

  final int age;
  final Gender gender;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;

  /// Physical activity level — used to compute TDEE.
  final ActivityLevel activityLevel;
  final TrainingFrequency trainingFrequency;
  final int activityScaleVersion;
  final int planCalculationVersion;

  /// Desired weight loss pace — used to compute target date and daily deficit.
  final WeightLossPace weightLossPace;

  final DateTime targetDate;

  // Calculated fields — derived during onboarding, stored for quick reads.
  final double bmi;
  final double bmr;
  final double tdee;
  final double dailyCalorieTarget;
  final double goalPaceKgPerWeek;
  final GoalPaceLevel goalPaceLevel;

  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // The Adaptive formula (docs/plans/08-adaptive-formula.md), a YumSum Star
  // feature: a personal adjustment on top of the plan, changed on Mondays.

  /// The user's switch; it only acts with YumSum Star.
  final bool adaptiveOn;

  /// The adjustment to the formula's burn, in kcal a day.
  final int adaptiveKcal;

  /// The Monday last processed (yyyy-MM-dd).
  final String? adaptiveWeek;

  /// That Monday's result, an `AdaptiveNote` value.
  final String? adaptiveNote;

  /// Learn nothing from before this day (yyyy-MM-dd).
  final String? adaptiveFrom;

  /// The last changes, newest last, at most 6.
  final List<AdaptiveChange> adaptiveChanges;

  // ── Serialisation ──────────────────────────────────────────────────────

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => UserProfile.fromMap(doc.data()!);

  factory UserProfile.fromMap(Map<String, dynamic> d) {
    final activityLevel = ActivityLevel.fromString(
      d['activityLevel'] as String,
    );
    final trainingFrequencyValue = d['trainingFrequency'] as String?;
    return UserProfile(
      uid: d['uid'] as String,
      email: d['email'] as String,
      name: d['name'] as String,
      country: d['country'] as String? ?? defaultCountry,
      usualFood: d['usualFood'] as String? ?? legacyUsualFood,
      trackProtein: d['trackProtein'] as bool? ?? true,
      age: d['age'] as int,
      gender: Gender.fromString(d['gender'] as String),
      heightCm: (d['heightCm'] as num).toDouble(),
      currentWeightKg: (d['currentWeightKg'] as num).toDouble(),
      targetWeightKg: (d['targetWeightKg'] as num).toDouble(),
      activityLevel: activityLevel,
      trainingFrequency: trainingFrequencyValue == null
          ? TrainingFrequency.legacyDefaultFor(activityLevel)
          : TrainingFrequency.fromString(trainingFrequencyValue),
      activityScaleVersion: (d['activityScaleVersion'] as num?)?.round() ?? 1,
      planCalculationVersion:
          (d['planCalculationVersion'] as num?)?.round() ?? 1,
      weightLossPace: WeightLossPace.fromString(d['weightLossPace'] as String),
      targetDate: (d['targetDate'] as Timestamp).toDate(),
      bmi: (d['bmi'] as num).toDouble(),
      bmr: (d['bmr'] as num).toDouble(),
      tdee: (d['tdee'] as num).toDouble(),
      dailyCalorieTarget: (d['dailyCalorieTarget'] as num).toDouble(),
      goalPaceKgPerWeek: (d['goalPaceKgPerWeek'] as num).toDouble(),
      goalPaceLevel: GoalPaceLevel.fromString(d['goalPaceLevel'] as String),
      onboardingCompleted: d['onboardingCompleted'] as bool,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
      adaptiveOn: d['adaptiveOn'] as bool? ?? true,
      adaptiveKcal: (d['adaptiveKcal'] as num?)?.round() ?? 0,
      adaptiveWeek: d['adaptiveWeek'] as String?,
      adaptiveNote: d['adaptiveNote'] as String?,
      adaptiveFrom: d['adaptiveFrom'] as String?,
      adaptiveChanges: [
        for (final change in d['adaptiveChanges'] as List? ?? const [])
          (
            week: change['week'] as String,
            from: (change['from'] as num).round(),
            to: (change['to'] as num).round(),
          ),
      ],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'name': name,
    'country': country,
    'usualFood': usualFood,
    'trackProtein': trackProtein,
    'age': age,
    'gender': gender.value,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'activityLevel': activityLevel.value,
    'trainingFrequency': trainingFrequency.value,
    'activityScaleVersion': activityScaleVersion,
    'planCalculationVersion': planCalculationVersion,
    'weightLossPace': weightLossPace.value,
    'targetDate': Timestamp.fromDate(targetDate),
    'bmi': bmi,
    'bmr': bmr,
    'tdee': tdee,
    'dailyCalorieTarget': dailyCalorieTarget,
    'goalPaceKgPerWeek': goalPaceKgPerWeek,
    'goalPaceLevel': goalPaceLevel.value,
    'onboardingCompleted': onboardingCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'adaptiveOn': adaptiveOn,
    'adaptiveKcal': adaptiveKcal,
    if (adaptiveWeek != null) 'adaptiveWeek': adaptiveWeek,
    if (adaptiveNote != null) 'adaptiveNote': adaptiveNote,
    if (adaptiveFrom != null) 'adaptiveFrom': adaptiveFrom,
    'adaptiveChanges': [
      for (final change in adaptiveChanges)
        {'week': change.week, 'from': change.from, 'to': change.to},
    ],
  };

  // ── copyWith ───────────────────────────────────────────────────────────

  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? country,
    String? usualFood,
    bool? trackProtein,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    TrainingFrequency? trainingFrequency,
    int? activityScaleVersion,
    int? planCalculationVersion,
    WeightLossPace? weightLossPace,
    DateTime? targetDate,
    double? bmi,
    double? bmr,
    double? tdee,
    double? dailyCalorieTarget,
    double? goalPaceKgPerWeek,
    GoalPaceLevel? goalPaceLevel,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? adaptiveOn,
    int? adaptiveKcal,
    String? adaptiveWeek,
    String? adaptiveNote,
    String? adaptiveFrom,
    List<AdaptiveChange>? adaptiveChanges,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      country: country ?? this.country,
      usualFood: usualFood ?? this.usualFood,
      trackProtein: trackProtein ?? this.trackProtein,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      activityScaleVersion: activityScaleVersion ?? this.activityScaleVersion,
      planCalculationVersion:
          planCalculationVersion ?? this.planCalculationVersion,
      weightLossPace: weightLossPace ?? this.weightLossPace,
      targetDate: targetDate ?? this.targetDate,
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      goalPaceKgPerWeek: goalPaceKgPerWeek ?? this.goalPaceKgPerWeek,
      goalPaceLevel: goalPaceLevel ?? this.goalPaceLevel,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adaptiveOn: adaptiveOn ?? this.adaptiveOn,
      adaptiveKcal: adaptiveKcal ?? this.adaptiveKcal,
      adaptiveWeek: adaptiveWeek ?? this.adaptiveWeek,
      adaptiveNote: adaptiveNote ?? this.adaptiveNote,
      adaptiveFrom: adaptiveFrom ?? this.adaptiveFrom,
      adaptiveChanges: adaptiveChanges ?? this.adaptiveChanges,
    );
  }
}
