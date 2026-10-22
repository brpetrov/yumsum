import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/day_off_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';

class DailySummaryService {
  DailySummaryService({
    required MealRepository mealRepository,
    required UserProfileRepository userProfileRepository,
    required DailySummaryRepository dailySummaryRepository,
    required DayOffRepository dayOffRepository,
  }) : _mealRepository = mealRepository,
       _userProfileRepository = userProfileRepository,
       _dailySummaryRepository = dailySummaryRepository,
       _dayOffRepository = dayOffRepository;

  final MealRepository _mealRepository;
  final UserProfileRepository _userProfileRepository;
  final DailySummaryRepository _dailySummaryRepository;
  final DayOffRepository _dayOffRepository;

  /// Takes [date] off, or puts it back on plan, and refreshes its summary.
  Future<void> setDayOff(String uid, String date, bool off) async {
    await _dayOffRepository.setDayOff(uid, date, off);
    await recomputeForDate(uid, date);
  }

  Future<void> recomputeForDate(String uid, String date) async {
    final profile = await _userProfileRepository.fetchProfile(uid);
    if (profile == null) {
      throw Exception('User profile not found');
    }

    final meals = await _mealRepository.fetchMealsForDate(uid, date);
    if (meals.isEmpty) {
      await _dailySummaryRepository.deleteSummary(uid, date);
      return;
    }

    final summary = buildSummary(
      date: date,
      meals: meals,
      dailyCalorieTarget: profile.dailyCalorieTarget,
      dayOff: await _dayOffRepository.isDayOff(uid, date),
    );

    await _dailySummaryRepository.saveSummary(uid, summary);
  }

  DailySummary buildSummary({
    required String date,
    required List<Meal> meals,
    required double dailyCalorieTarget,
    bool dayOff = false,
  }) {
    final targetCalories = dailyCalorieTarget.round();

    final totalCalories = meals.fold<int>(0, (sum, meal) {
      return sum + meal.calories.round();
    });
    final calorieDelta = totalCalories - targetCalories;
    final proteinMeals = meals.where((meal) => meal.proteinGrams != null);
    final proteinGrams = proteinMeals.isEmpty
        ? null
        : proteinMeals
              .fold<double>(0, (sum, meal) => sum + meal.proteinGrams!)
              .round();

    return DailySummary(
      date: date,
      totalCalories: totalCalories,
      targetCalories: targetCalories,
      calorieDelta: calorieDelta,
      mealCount: meals.length,
      proteinGrams: proteinGrams,
      status: _statusForCalories(
        totalCalories: totalCalories,
        targetCalories: targetCalories,
      ),
      dayOff: dayOff,
      updatedAt: DateTime.now(),
    );
  }

  DailyStatus _statusForCalories({
    required int totalCalories,
    required int targetCalories,
  }) {
    if (targetCalories <= 0) return DailyStatus.red;

    final ratio = (totalCalories - targetCalories).abs() / targetCalories;
    if (ratio <= 0.10) return DailyStatus.green;
    if (ratio <= 0.20) return DailyStatus.yellow;
    return DailyStatus.red;
  }
}
