import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/weekly_review_repository.dart';
import 'package:lean_streak/repositories/weight_entry_repository.dart';
import 'package:lean_streak/services/weekly_review_service.dart';

import 'adaptive_fixtures.dart';

String _key(DateTime day) =>
    '${day.year}-${'${day.month}'.padLeft(2, '0')}-'
    '${'${day.day}'.padLeft(2, '0')}';

/// Every day of the week starting [monday] logged at target.
class _FakeSummaries extends Fake implements DailySummaryRepository {
  _FakeSummaries(this.monday);

  final DateTime monday;

  @override
  Future<List<DailySummary>> fetchSummariesInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async => [
    for (var i = 0; i < 7; i++)
      DailySummary(
        date: _key(DateTime(monday.year, monday.month, monday.day + i)),
        totalCalories: 1900,
        targetCalories: 1900,
        calorieDelta: 0,
        mealCount: 3,
        status: DailyStatus.green,
        updatedAt: monday,
      ),
  ];
}

class _FakeMeals extends Fake implements MealRepository {
  final ranges = <(String, String)>[];

  @override
  Future<List<Meal>> fetchMealsInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async {
    ranges.add((startDate, endDate));
    return const [];
  }
}

class _FakeWeighIns extends Fake implements WeightEntryRepository {
  final ranges = <(String, String)>[];

  @override
  Future<int> countEntriesInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async {
    ranges.add((startDate, endDate));
    return 2;
  }
}

class _FakeReviews extends Fake implements WeeklyReviewRepository {
  final saved = <String, WeeklyReview>{};

  @override
  Future<WeeklyReview?> fetch(String uid, String week) async => saved[week];

  @override
  Future<void> save(String uid, String week, WeeklyReview review) async =>
      saved[week] = review;
}

/// Each call waits on its own [Completer] in [calls].
class _FakeCoach extends Fake implements WeeklyReviewService {
  final calls = <Completer<List<ReviewPoint>>>[];
  String? facts;

  @override
  Future<List<ReviewPoint>> write(String facts) {
    this.facts = facts;
    calls.add(Completer());
    return calls.last.future;
  }
}

const _points = <ReviewPoint>[
  ReviewPoint(title: 'Steady', text: 'Steady all week.', good: true),
];

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _oldNotes = WeeklyReview(
  points: _points,
  basis: 'Prompt version 1\nOld facts.',
  createdAt: DateTime(2026, 10, 5),
);

void main() {
  final now = DateTime.now();
  // Last week, so it's over.
  final monday = DateTime(now.year, now.month, now.day - now.weekday - 6);
  final week = _key(monday);
  final sunday = _key(DateTime(monday.year, monday.month, monday.day + 6));
  late _FakeMeals meals;
  late _FakeWeighIns weighIns;
  late _FakeReviews reviews;
  late _FakeCoach coach;

  /// Listening to the notes on [week] (last week unless given), with
  /// [saved] already written, for an account with [entitlement], in
  /// [language].
  ProviderContainer container({
    Entitlement? entitlement = _plus,
    DateTime? week,
    Map<String, WeeklyReview> saved = const {},
    String region = 'GB',
    String language = 'en',
  }) {
    meals = _FakeMeals();
    weighIns = _FakeWeighIns();
    reviews = _FakeReviews()..saved.addAll(saved);
    coach = _FakeCoach();
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue('user-1'),
        deviceRegionProvider.overrideWithValue(region),
        languageCodeProvider.overrideWithValue(language),
        entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        userProfileProvider.overrideWith((ref) => Stream.value(planProfile())),
        recipesProvider.overrideWith((ref) async => const []),
        dailySummaryRepositoryProvider.overrideWithValue(
          _FakeSummaries(monday),
        ),
        mealRepositoryProvider.overrideWithValue(meals),
        weightEntryRepositoryProvider.overrideWithValue(weighIns),
        weeklyReviewRepositoryProvider.overrideWithValue(reviews),
        weeklyReviewServiceProvider.overrideWithValue(coach),
      ],
    );
    addTearDown(container.dispose);
    container.listen(weeklyReviewProvider(week ?? monday), (_, _) {});
    return container;
  }

  /// What the notes on [week] (last week unless given) come to.
  Future<List<ReviewPoint>?> notesOn(
    ProviderContainer notes, [
    DateTime? week,
  ]) => notes.read(weeklyReviewProvider(week ?? monday).future);

  test('counts the weigh-ins from a read of that week only', () async {
    container();
    await pumpEventQueue();
    expect(weighIns.ranges, [(week, sunday)]);
    expect(coach.facts, contains('Weigh-ins this week: 2.'));
  });

  test('the country is the device\'s region, not the stored one', () async {
    container(region: 'BG');
    await pumpEventQueue();
    expect(coach.facts, startsWith('The user lives in Bulgaria.\n'));
  });

  test('reads 4 weeks of meals, for the nutrients over the weeks', () async {
    container();
    await pumpEventQueue();
    final fourWeeksAgo = _key(
      DateTime(monday.year, monday.month, monday.day - 21),
    );
    expect(meals.ranges, [(fourWeeksAgo, sunday)]);
  });

  test('the saved notes are shown while they match the facts', () async {
    container();
    await pumpEventQueue();
    coach.calls.single.complete(_points);
    await pumpEventQueue();
    final basis = reviews.saved[week]!.basis;

    final again = container(saved: {week: reviews.saved[week]!});
    expect(await notesOn(again), _points);
    expect(coach.calls, isEmpty);
    expect(basis, startsWith('Prompt version $weeklyReviewPromptVersion\n'));
  });

  test('notes saved in one language are written again in the other', () async {
    container();
    await pumpEventQueue();
    coach.calls.single.complete(_points);
    await pumpEventQueue();
    final english = reviews.saved[week]!;
    // English keeps the basis it always had.
    expect(
      english.basis,
      'Prompt version $weeklyReviewPromptVersion\n${coach.facts}',
    );

    container(language: 'bg', saved: {week: english});
    await pumpEventQueue();
    expect(coach.calls, hasLength(1));
    coach.calls.single.complete(_points);
    await pumpEventQueue();
    final bulgarian = reviews.saved[week]!;
    expect(
      bulgarian.basis,
      'Prompt version $weeklyReviewPromptVersion\nLanguage bg\n${coach.facts}',
    );

    final again = container(language: 'bg', saved: {week: bulgarian});
    expect(await notesOn(again), _points);
    expect(coach.calls, isEmpty);

    container(saved: {week: bulgarian});
    await pumpEventQueue();
    expect(coach.calls, hasLength(1));
  });

  test(
    'an earlier week only shows what was saved: no facts, no call',
    () async {
      final earlier = DateTime(monday.year, monday.month, monday.day - 7);
      final earlierWeek = _key(earlier);
      final notes = container(week: earlier, saved: {earlierWeek: _oldNotes});
      expect(await notesOn(notes, earlier), _points);
      expect(coach.calls, isEmpty);
      expect(meals.ranges, isEmpty);

      final none = container(week: earlier);
      expect(await notesOn(none, earlier), isNull);
      expect(coach.calls, isEmpty);
    },
  );

  test('without YumSum Star, the saved notes only', () async {
    final notes = container(entitlement: null, saved: {week: _oldNotes});
    expect(await notesOn(notes), _points);
    expect(coach.calls, isEmpty);
    expect(meals.ranges, isEmpty);

    final none = container(entitlement: null);
    expect(await notesOn(none), isNull);
  });

  test('YumSum Star that began after the week: nothing yet', () async {
    final notes = container(
      entitlement: Entitlement(
        active: true,
        source: EntitlementSource.play,
        startedAt: DateTime.now(),
      ),
    );
    expect(await notesOn(notes), isNull);
    expect(coach.calls, isEmpty);
  });

  test('YumSum Star that began during the week counts it', () async {
    container(
      entitlement: Entitlement(
        active: true,
        source: EntitlementSource.play,
        startedAt: DateTime(monday.year, monday.month, monday.day + 6, 20),
      ),
    );
    await pumpEventQueue();
    expect(coach.calls, hasLength(1));
  });

  test('a run that overlaps one still writing shares its call', () async {
    final notes = container();
    await pumpEventQueue();
    expect(coach.calls, hasLength(1));

    // A rebuild while the AI is still writing.
    notes.invalidate(weeklyReviewProvider(monday));
    final again = notes.read(weeklyReviewProvider(monday).future);
    await pumpEventQueue();
    coach.calls.single.complete(_points);
    expect(await again, _points);
    expect(coach.calls, hasLength(1));
    expect(reviews.saved[week]!.points, _points);
  });

  test('after a failure, the next run asks again', () async {
    final notes = container();
    await pumpEventQueue();
    coach.calls.single.completeError(const WeeklyReviewException());
    await expectLater(
      notes.read(weeklyReviewProvider(monday).future),
      throwsA(isA<WeeklyReviewException>()),
    );

    notes.invalidate(weeklyReviewProvider(monday));
    final again = notes.read(weeklyReviewProvider(monday).future);
    await pumpEventQueue();
    expect(coach.calls, hasLength(2));
    coach.calls.last.complete(_points);
    expect(await again, _points);
  });
}
