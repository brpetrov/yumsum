import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/weekly_review_repository.dart';
import 'package:lean_streak/services/weekly_review_service.dart';

final weeklyReviewServiceProvider = Provider<WeeklyReviewService>((ref) {
  return WeeklyReviewService();
});

final weeklyReviewRepositoryProvider = Provider<WeeklyReviewRepository>((ref) {
  return WeeklyReviewRepository(FirebaseFirestore.instance);
});

final _dateKey = DateFormat('yyyy-MM-dd');

/// The notes the AI is writing, by user, week and basis, so runs that
/// overlap (the page rebuilt while the AI is still at it) share one call.
final _writingProvider = Provider<Map<String, Future<List<ReviewPoint>>>>(
  (ref) => {},
);

/// The AI Coach's notes on the week starting [monday], for YumSum Star
/// (plan 09). The facts are worked out afresh each time; the saved notes
/// are shown while they still match, and the AI writes new ones only when
/// they don't. None for a week still going or with fewer than 4 judged
/// days.
final weeklyReviewProvider = FutureProvider.autoDispose
    .family<List<ReviewPoint>, DateTime>((ref, monday) async {
      final uid = ref.watch(currentUidProvider);
      final now = DateTime.now();
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      final today = DateTime(now.year, now.month, now.day);
      if (uid == null || !sunday.isBefore(today)) return const [];

      final summaryRepository = ref.watch(dailySummaryRepositoryProvider);
      final mealRepository = ref.watch(mealRepositoryProvider);
      final weightRepository = ref.watch(weightEntryRepositoryProvider);
      final repository = ref.watch(weeklyReviewRepositoryProvider);
      final service = ref.watch(weeklyReviewServiceProvider);
      final writing = ref.watch(_writingProvider);
      final (user, recipes) = await (
        ref.watch(userProfileProvider.future),
        ref.watch(recipesProvider.future),
      ).wait;
      if (user == null) return const [];
      final week = _dateKey.format(monday);
      final end = _dateKey.format(sunday);
      final facts = buildWeekFacts(
        monday: monday,
        // Four weeks, for the usual big day.
        summaries: await summaryRepository.fetchSummariesInRange(
          uid,
          startDate: _dateKey.format(
            DateTime(monday.year, monday.month, monday.day - 21),
          ),
          endDate: end,
        ),
        meals: await mealRepository.fetchMealsInRange(
          uid,
          startDate: week,
          endDate: end,
        ),
        weighIns: await weightRepository.countEntriesInRange(
          uid,
          startDate: week,
          endDate: end,
        ),
        profile: user,
        recipes: recipes,
      );
      if (facts.judgedDays < 4) return const [];

      final basis = 'Prompt version $weeklyReviewPromptVersion\n${facts.text}';
      final saved = await repository.fetch(uid, week);
      if (saved != null && saved.basis == basis) return saved.points;

      final key = '$uid $week $basis';
      final call = writing[key] ??= () async {
        final points = await service.write(facts.text);
        try {
          await repository.save(
            uid,
            week,
            WeeklyReview(
              points: points,
              basis: basis,
              createdAt: DateTime.now(),
            ),
          );
        } catch (error) {
          // The notes are written and worth showing; the next look asks again.
          debugPrint('Could not save the weekly review: $error');
        }
        return points;
      }();
      try {
        return await call;
      } finally {
        // Done, so a later run reads the saved notes or, after a failure,
        // asks again.
        if (identical(writing[key], call)) writing.remove(key);
      }
    });
