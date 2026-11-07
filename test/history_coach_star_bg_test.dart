import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/coach/coach_screen.dart';
import 'package:lean_streak/screens/notifications/notifications_screen.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/recipes/recipe_screen.dart';
import 'package:lean_streak/screens/recipes/recipes_screen.dart';
import 'package:lean_streak/screens/review/day_meals_sheet.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_fixtures.dart';
import 'recipe_fixtures.dart';

/// History, AI Coach, Recipes, Notifications and YumSum Star in Bulgarian,
/// on a 360-wide phone: the Bulgarian shows, and nothing overflows (an
/// overflow is reported as an exception).

const _plus = Entitlement(active: true, source: EntitlementSource.manual);

final _key = DateFormat('yyyy-MM-dd');

DateTime _day(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day + days);

/// A summary for [day], every third one close, every fifth one a day off.
DailySummary _summary(DateTime day) => DailySummary(
  date: _key.format(day),
  totalCalories: 1850,
  targetCalories: 1900,
  calorieDelta: -50,
  mealCount: 3,
  proteinGrams: 95,
  status: day.day % 3 == 0 ? DailyStatus.yellow : DailyStatus.green,
  dayOff: day.day % 5 == 0,
  updatedAt: day,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _bulgarian(List<Override> overrides, Widget home) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('bg'),
    home: home,
  ),
);

void main() {
  final today = DateTime.now();

  testWidgets('History, month and week, in Bulgarian', (tester) async {
    _phone(tester);
    final prefs = await _prefs();
    await tester.pumpWidget(
      _bulgarian([
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('test'),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        entitlementProvider.overrideWith((ref) => Stream.value(_plus)),
        firstLoggedDayProvider.overrideWith((ref) async => _day(today, -60)),
        reviewSummariesProvider.overrideWith(
          (ref, range) => Stream.value({
            for (
              var day = range.startDate;
              !day.isAfter(range.endDate) && day.isBefore(today);
              day = _day(day, 1)
            )
              _key.format(day): _summary(day),
          }),
        ),
      ], const ReviewScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('История'), findsOneWidget);
    expect(find.text('Месец'), findsOneWidget);
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('Без записи'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Last week, all of it finished.
    await tester.tap(find.text('Седмица'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Средно'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Днес'), findsOneWidget);
    expect(find.text('Записани 7 от 7 дни'), findsOneWidget);
    expect(find.text('Средно 1850 ккал на ден'), findsOneWidget);
    expect(find.text('от записаните дни са в целта'), findsOneWidget);
    expect(find.textContaining('в целта'), findsWidgets);
    expect(find.textContaining(' – '), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a day's meals in Bulgarian", (tester) async {
    _phone(tester);
    final day = DateTime(2020, 3, 11);
    await tester.pumpWidget(
      _bulgarian([
        plusProvider.overrideWithValue(false),
        mealsForDateProvider.overrideWith(
          (ref, date) => Stream.value(<Meal>[]),
        ),
        dailySummaryForDateProvider.overrideWith(
          (ref, date) => Stream.value(_summary(DateTime(2020, 3, 11))),
        ),
        dayEditsThisMonthProvider.overrideWith((ref) => Stream.value(9)),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
      ], Scaffold(body: DayMealsSheet(date: day))),
    );
    await tester.pump();

    expect(find.text('Сряда, 11 март'), findsOneWidget);
    expect(find.text('1850 от 1900 ккал'), findsOneWidget);
    expect(find.text('В целта'), findsOneWidget);
    expect(
      find.text('Остава 1 от 10 промени по минали дни този месец'),
      findsOneWidget,
    );
    expect(find.text('Няма записани хранения за този ден.'), findsOneWidget);
    expect(find.text('Добави хранене'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('AI Coach in Bulgarian', () {
    Future<void> pump(WidgetTester tester, Entitlement? entitlement) async {
      _phone(tester);
      final prefs = await _prefs();
      final latest = latestFinishedWeek(today);
      await tester.pumpWidget(
        _bulgarian([
          sharedPreferencesProvider.overrideWithValue(prefs),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          recipesProvider.overrideWith((ref) async => const []),
          hasWeeklyReviewsProvider.overrideWith((ref) async => false),
          firstLoggedDayProvider.overrideWith((ref) async => _day(latest, -12)),
          weeklyReviewProvider.overrideWith(
            (ref, monday) async => const [
              ReviewPoint(
                title: 'Солта е над препоръката',
                text: 'Средно 7,4 г сол на ден при препоръка 6 г.',
                good: false,
                why: 'Много сол вдига кръвното с времето.',
                tips: ['Замени чипса с ядки без сол.'],
              ),
              ReviewPoint(
                title: 'Фибрите са в норма',
                text: 'Цяла седмица.',
                good: true,
                tips: ['Продължавай с бобовите.'],
              ),
            ],
          ),
          reviewSummariesProvider.overrideWith(
            (ref, range) => Stream.value({
              for (var i = 0; i < 6; i++)
                _key.format(_day(range.startDate, i)): _summary(
                  DateTime(2026, 11, 1),
                ),
            }),
          ),
        ], CoachScreen(week: _key.format(latest))),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    testWidgets('a member reads the notes', (tester) async {
      await pump(tester, _plus);

      expect(find.text('AI треньор'), findsOneWidget);
      expect(find.text('Миналата седмица'), findsOneWidget);
      expect(find.text('Опитай това'), findsOneWidget);
      expect(find.text('Продължавай така'), findsOneWidget);
      expect(find.byTooltip('Предишна седмица'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without YumSum Star, what it does', (tester) async {
      await pump(tester, null);

      expect(find.text('Твоят AI треньор'), findsOneWidget);
      expect(find.text('Виж какво те спъва'), findsOneWidget);
      expect(find.text('Отключи Star'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Recipes in Bulgarian', () {
    final soup = testRecipe('Lentil soup', prepMinutes: 30, minutes: 30);

    Future<void> pump(WidgetTester tester, Widget home) async {
      _phone(tester);
      final prefs = await _prefs();
      await tester.pumpWidget(
        _bulgarian([
          recipesProvider.overrideWith(
            (ref) async => [
              testRecipe('Overnight oats', category: RecipeCategory.breakfast),
              testRecipe('Hummus plate', category: RecipeCategory.snack),
              soup,
            ],
          ),
          recipeImageProvider.overrideWithValue(pixelImage),
          recentMealsProvider.overrideWith((ref) => Stream.value(<Meal>[])),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          plusProvider.overrideWithValue(false),
        ], home),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the library', (tester) async {
      await pump(tester, const RecipesScreen());

      expect(find.text('Рецепти'), findsOneWidget);
      expect(find.text('Търси рецепти или съставки'), findsOneWidget);
      expect(find.text('Всички'), findsOneWidget);
      expect(find.text('Закуска'), findsWidgets);
      expect(find.text('500 ккал · 40 г протеин'), findsWidgets);
      expect(find.text('30 мин'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a recipe, and its portions sheet', (tester) async {
      await pump(tester, RecipeScreen(recipeId: soup.id));

      expect(find.text('Рецепта'), findsOneWidget);
      expect(find.text('500 ккал · 40 г протеин на порция'), findsOneWidget);
      expect(find.text('Подготовка'), findsOneWidget);
      expect(find.text('Няма'), findsOneWidget);
      expect(find.text('За 4 порции'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Запиши порция'));
      await tester.pumpAndSettle();
      expect(find.text('Колко порции?'), findsOneWidget);
      await tester.tap(find.byTooltip('Повече'));
      await tester.pumpAndSettle();
      expect(find.text('1,5'), findsOneWidget);
      expect(find.text('750 ккал · 60 г протеин'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Notifications in Bulgarian', (tester) async {
    _phone(tester);
    final prefs = await _prefs();
    await tester.pumpWidget(
      _bulgarian([
        sharedPreferencesProvider.overrideWithValue(prefs),
      ], const NotificationsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Известия'), findsOneWidget);
    expect(find.text('Всяка вечер в 20:30'), findsOneWidget);
    expect(find.text('Всяка събота в 20:00'), findsOneWidget);
    expect(find.text('Събота'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('YumSum Star in Bulgarian', () {
    Future<void> pump(WidgetTester tester, Entitlement? entitlement) async {
      _phone(tester);
      await tester.pumpWidget(
        _bulgarian([
          currentUidProvider.overrideWithValue('u1'),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          billingRepositoryProvider.overrideWithValue(FakeBillingRepository()),
          realEntitlementProvider.overrideWith(
            (ref) => Stream.value(entitlement),
          ),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
        ], const PlusScreen()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the offer', (tester) async {
      await pump(tester, null);

      expect(find.text('Отключи още умни функции.'), findsOneWidget);
      expect(find.text('Годишен'), findsOneWidget);
      expect(find.text('Спести 50%'), findsOneWidget);
      expect(find.text('Опитай 7 дни безплатно'), findsOneWidget);
      expect(find.textContaining('7 дни безплатно, след това'), findsOneWidget);
      expect(find.text('Възстанови покупка'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('for a member', (tester) async {
      await pump(tester, _plus);

      expect(find.text('Вече имаш YumSum Star'), findsOneWidget);
      expect(find.text('Всичко това е твое.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
