import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/weekly_review_repository.dart';
import 'package:lean_streak/services/weekly_review_service.dart';

final weeklyReviewServiceProvider = Provider<WeeklyReviewService>((ref) {
  return WeeklyReviewService(null, ref.watch(languageCodeProvider));
});

final weeklyReviewRepositoryProvider = Provider<WeeklyReviewRepository>((ref) {
  return WeeklyReviewRepository(FirebaseFirestore.instance);
});

final _dateKey = DateFormat('yyyy-MM-dd');

/// The Monday of the latest finished week: a week finishes on its Sunday,
/// so last week's.
DateTime latestFinishedWeek(DateTime today) =>
    DateTime(today.year, today.month, today.day - today.weekday - 6);

/// The Monday of the first week AI Coach can have notes on: the week YumSum
/// Star began in. Null for a grant with no start, which counts from the
/// beginning.
DateTime? firstCoachWeek(Entitlement? entitlement) {
  final started = entitlement?.startedAt;
  if (started == null) return null;
  return DateTime(
    started.year,
    started.month,
    started.day - started.weekday + 1,
  );
}

/// Whether the AI writes notes on the week starting [monday] today: it's
/// the latest finished week, and YumSum Star is on and began by its Sunday.
/// Every other week only shows what was saved, so paging back never costs a
/// call, and someone who joins mid-week gets their first notes on Monday.
bool reviewWritable(
  Entitlement? entitlement, {
  required DateTime monday,
  required DateTime now,
}) {
  if (!(entitlement?.isPlusAt(now) ?? false)) return false;
  if (monday != latestFinishedWeek(DateTime(now.year, now.month, now.day))) {
    return false;
  }
  final first = firstCoachWeek(entitlement);
  return first == null || !first.isAfter(monday);
}

/// Whether any notes are saved, for someone whose YumSum Star has ended:
/// their notes stay readable.
final hasWeeklyReviewsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return false;
  return ref.watch(weeklyReviewRepositoryProvider).hasAny(uid);
});

/// The notes the AI is writing, by user, week and basis, so runs that
/// overlap (the page rebuilt while the AI is still at it) share one call.
final _writingProvider = Provider<Map<String, Future<List<ReviewPoint>>>>(
  (ref) => {},
);

/// The AI Coach's notes on the week starting [monday] (plan 09): the saved
/// ones, or null when there are none. The AI writes them only where
/// [reviewWritable], and only when the saved notes don't match the facts,
/// which are worked out afresh each time, or the app's language: notes
/// saved in English are written again in Bulgarian after a switch, and
/// back. Empty for a week still going or
/// with fewer than 4 judged days.
final weeklyReviewProvider = FutureProvider.autoDispose
    .family<List<ReviewPoint>?, DateTime>((ref, monday) async {
      final uid = ref.watch(currentUidProvider);
      final now = DateTime.now();
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      final today = DateTime(now.year, now.month, now.day);
      if (uid == null || !sunday.isBefore(today)) return const [];

      final repository = ref.watch(weeklyReviewRepositoryProvider);
      final week = _dateKey.format(monday);
      final entitlement = await ref.watch(entitlementProvider.future);
      final saved = await repository.fetch(uid, week);
      if (!reviewWritable(entitlement, monday: monday, now: now)) {
        return saved?.points;
      }

      final summaryRepository = ref.watch(dailySummaryRepositoryProvider);
      final mealRepository = ref.watch(mealRepositoryProvider);
      final weightRepository = ref.watch(weightEntryRepositoryProvider);
      final service = ref.watch(weeklyReviewServiceProvider);
      final writing = ref.watch(_writingProvider);
      final (user, recipes) = await (
        ref.watch(userProfileProvider.future),
        ref.watch(recipesProvider.future),
      ).wait;
      if (user == null) return const [];
      final end = _dateKey.format(sunday);
      // Four weeks, for the usual big day and the nutrients over the weeks.
      final fourWeeks = _dateKey.format(
        DateTime(monday.year, monday.month, monday.day - 21),
      );
      final facts = buildWeekFacts(
        monday: monday,
        summaries: await summaryRepository.fetchSummariesInRange(
          uid,
          startDate: fourWeeks,
          endDate: end,
        ),
        meals: await mealRepository.fetchMealsInRange(
          uid,
          startDate: fourWeeks,
          endDate: end,
        ),
        weighIns: await weightRepository.countEntriesInRange(
          uid,
          startDate: week,
          endDate: end,
        ),
        profile: user,
        country: ref.watch(countryProvider),
        recipes: recipes,
      );
      if (facts.judgedDays < 4) return const [];

      // English keeps the basis it always had, so its saved notes stay.
      final language = ref.watch(languageCodeProvider);
      final basis =
          'Prompt version $weeklyReviewPromptVersion\n'
          '${language == 'en' ? '' : 'Language $language\n'}${facts.text}';
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
