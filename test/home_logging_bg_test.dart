import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/repositories/daily_summary_repository.dart';
import 'package:lean_streak/repositories/day_off_repository.dart';
import 'package:lean_streak/repositories/meal_repository.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';
import 'package:lean_streak/screens/dashboard/dashboard_screen.dart';
import 'package:lean_streak/screens/dashboard/helpers/adaptive_dialogs.dart';
import 'package:lean_streak/screens/dashboard/helpers/contribute_sheet.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_camera_page.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/portion_sheet.dart';
import 'package:lean_streak/screens/meals/log_meal_sheet.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/daily_summary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_fixtures.dart';

class _FakeMeals extends Fake implements MealRepository {}

class _FakeProfiles extends Fake implements UserProfileRepository {}

class _FakeSummaries extends Fake implements DailySummaryRepository {}

class _FakeDaysOff extends Fake implements DayOffRepository {}

class _FakeEstimates extends Fake implements CalorieEstimateService {}

const _star = Entitlement(active: true, source: EntitlementSource.manual);

/// The app's fonts, Cyrillic stand-in included, so a line's length on a
/// 360dp phone is the real one.
Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      'Nunito',
      [
        'Nunito-Regular',
        'Nunito-Medium',
        'Nunito-SemiBold',
        'Nunito-Bold',
        'Nunito-ExtraBold',
      ],
    ),
    ('Fredoka', ['Fredoka-Medium', 'Fredoka-SemiBold']),
    ('NunitoDisplay', ['Nunito-ExtraBold']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

Meal _meal(String name, double kcal, {double? protein, Nutrients? macros}) {
  final now = DateTime.now();
  return Meal(
    id: name,
    date: DateFormat('yyyy-MM-dd').format(now),
    timestamp: DateTime(now.year, now.month, now.day, 13, 5),
    name: name,
    calories: kcal,
    proteinGrams: protein,
    macros: macros,
    createdAt: now,
    updatedAt: now,
  );
}

final _meals = [
  _meal(
    'Мусака',
    640,
    protein: 28,
    macros: const Nutrients(
      fat: 34,
      saturates: 12,
      carbs: 48,
      sugars: 9,
      fibre: 6,
      salt: 2.4,
    ),
  ),
  _meal('Баница', 450),
];

/// English words that would mean a text was left untranslated.
final _english = RegExp(
  r'\b(kcal|meals?|Today|Weight|History|Log|logged|left|over|protein|'
  r'Carbs|Fat|Fibre|Sugars|Salt|Unlock|Target)\b',
);

void main() {
  setUpAll(_loadFonts);

  /// A 360 x 760 phone.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget bulgarian(Widget home) => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('bg'),
    home: home,
  );

  final bg = lookupAppLocalizations(const Locale('bg'));

  /// A macro line, whose figures are held together by non-breaking spaces.
  Finder macroLine(String line) => find.byWidgetPredicate(
    (widget) => widget is Text && widget.data?.replaceAll(' ', ' ') == line,
  );

  /// Every text on screen, laid out or not.
  List<String> shownTexts(WidgetTester tester) => [
    for (final text in tester.widgetList<RichText>(
      find.byType(RichText, skipOffstage: false),
    ))
      text.text.toPlainText(),
  ];

  Future<void> pumpHome(
    WidgetTester tester, {
    required Entitlement? entitlement,
    required DateTime lastWeighIn,
    int aiUsed = 0,
  }) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({adaptiveIntroShownKey: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(planProfile()),
          ),
          entitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          latestWeightEntryProvider.overrideWith(
            (ref) => Stream<WeightEntry?>.value(weighIn(lastWeighIn, 80.5)),
          ),
          mealsForDateProvider.overrideWith(
            (ref, date) => Stream.value(_meals),
          ),
          dailySummaryForDateProvider.overrideWith(
            (ref, date) => Stream<DailySummary?>.value(null),
          ),
          dayOffProvider.overrideWith((ref, date) => Stream.value(false)),
          reviewSummariesProvider.overrideWith(
            (ref, range) => Stream.value(const {}),
          ),
          dailySummaryServiceProvider.overrideWithValue(
            DailySummaryService(
              mealRepository: _FakeMeals(),
              userProfileRepository: _FakeProfiles(),
              dailySummaryRepository: _FakeSummaries(),
              dayOffRepository: _FakeDaysOff(),
            ),
          ),
          aiUsageTodayProvider.overrideWith((ref) => Stream.value(aiUsed)),
          recentMealsProvider.overrideWith((ref) => Stream.value(const [])),
          recipesProvider.overrideWith((ref) async => const []),
        ],
        child: bulgarian(const DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Home for a free account is in Bulgarian and fits a phone', (
    tester,
  ) async {
    final now = DateTime.now();
    await pumpHome(
      tester,
      entitlement: null,
      lastWeighIn: now.subtract(const Duration(days: 10)),
    );

    expect(find.text(capitalised(bg.weekdayDayMonth(now))), findsOneWidget);
    expect(find.textContaining('ккал остават', findRichText: true), findsOne);
    expect(find.textContaining('Приети 1090 от'), findsOneWidget);
    expect(find.text('Днешни хранения'), findsOneWidget);
    expect(find.text('2 записани'), findsOneWidget);
    expect(find.text('Отключи макроси'), findsOneWidget);
    expect(
      find.text('1 хранене не е отчетено (няма данни за протеин)'),
      findsOne,
    );
    expect(find.text('640 ккал'), findsOneWidget);
    expect(find.text('28 г протеин'), findsOneWidget);
    expect(find.text('13:05'), findsNWidgets(2));

    // The rest of the page, scrolled into view.
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text(capitalised(bg.month(now))), findsOneWidget);
    expect(find.text('Този месец още няма записани дни.'), findsOneWidget);
    expect(find.textContaining('адаптивна формула, AI треньор'), findsOne);
    expect(find.text('Последно: 80,5 кг · преди 10 дни'), findsOneWidget);
    expect(find.text('Запиши'), findsOneWidget);

    expect(shownTexts(tester).where(_english.hasMatch), isEmpty);
  });

  testWidgets('Home with YumSum Star: every ring and label fits', (
    tester,
  ) async {
    await pumpHome(
      tester,
      entitlement: _star,
      lastWeighIn: DateTime.now().subtract(const Duration(days: 2)),
    );

    final rings = find.byType(SingleChildScrollView).first;
    for (final label in ['Протеин', 'Въглехидр.', 'Мазнини', 'Наситени']) {
      final text = find.descendant(of: rings, matching: find.text(label));
      await tester.ensureVisible(text);
      final paragraph = tester.renderObject<RenderParagraph>(text);
      // One line: the label is never broken inside a word.
      expect(
        paragraph.size.height,
        lessThan(
          paragraph.getFullHeightForCaret(const TextPosition(offset: 0)) * 1.5,
        ),
        reason: label,
      );
    }
    expect(find.textContaining('макс.', skipOffstage: false), findsWidgets);
    expect(find.byTooltip('Стойности'), findsOneWidget);

    await tester.tap(find.byTooltip('Стойности'));
    await tester.pumpAndSettle();
    expect(
      macroLine(
        'Мазнини 34 г · наситени мазнини 12 г · въглехидрати 48 г · '
        'захари 9 г · фибри 6 г · протеин 28 г · сол 2,4 г',
      ),
      findsOneWidget,
    );
    expect(shownTexts(tester).where(_english.hasMatch), isEmpty);
  });

  testWidgets('the targets guide, the day off and delete dialogs fit', (
    tester,
  ) async {
    await pumpHome(tester, entitlement: null, lastWeighIn: DateTime.now());

    await tester.tap(find.byTooltip('За целите ти'));
    await tester.pumpAndSettle();
    expect(find.text('Твоите цели'), findsOneWidget);
    expect(find.text('НЕ НАДВИШАВАЙ', skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('Добре'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Вземи почивен ден'));
    await tester.pumpAndSettle();
    expect(find.text('Почивен ден днес?'), findsOneWidget);
    expect(
      find.text('Денят не влияе на резултатите в „История“.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Отказ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Опции за храненето').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изтрий'));
    await tester.pumpAndSettle();
    expect(find.text('Да изтрием ли храненето?'), findsOneWidget);
    await tester.tap(find.text('Отказ'));
    await tester.pumpAndSettle();
  });

  testWidgets('the quick-log bar in use, with the AI allowance running low', (
    tester,
  ) async {
    await pumpHome(
      tester,
      entitlement: null,
      lastWeighIn: DateTime.now(),
      aiUsed: 5,
    );
    expect(find.byTooltip('Снимай'), findsOneWidget);
    expect(find.byTooltip('Говори'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byKey(const ValueKey('quick-log-name')));
    await tester.pumpAndSettle();
    expect(find.text('Опиши храната'), findsOneWidget);
    expect(find.text('ккал'), findsOneWidget);
    expect(find.text('протеин (г)'), findsOneWidget);
    expect(find.text('За днес остават 5 AI оценки'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('quick-log-name')),
      'мусака',
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Изчисли'), findsOneWidget);
  });

  testWidgets('the meal form in Bulgarian', (tester) async {
    phone(tester);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logMealControllerProvider.overrideWith(LogMealController.new),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(planProfile()),
          ),
          currentUidProvider.overrideWithValue('user-1'),
          calorieEstimateServiceProvider.overrideWithValue(_FakeEstimates()),
        ],
        child: bulgarian(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLogMealSheet(
                  context,
                  date: DateFormat('yyyy-MM-dd').format(yesterday),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Добави хранене'), findsOneWidget);
    expect(find.text(capitalised(bg.weekdayDayMonth(yesterday))), findsOne);
    expect(find.text('Калории'), findsOneWidget);
    expect(find.text('Изчисли по описанието'), findsOneWidget);
    expect(find.text('Запази храненето'), findsOneWidget);

    await tester.tap(find.text('Запази храненето'));
    await tester.pump();
    expect(find.text('Въведи калориите или ги изчисли.'), findsOneWidget);
  });

  testWidgets('the camera card, the portion sheet and the invitation fit', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      bulgarian(
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const PhotoStepCard(
                  step: PhotoStep.nutritionTable,
                  number: 2,
                  total: 2,
                ),
                TextButton(
                  onPressed: () => showPortionSheet(context, (
                    name: 'Лютеница',
                    brand: 'Първа преса',
                    kcalPer100g: 95,
                    proteinPer100g: 2,
                    macrosPer100g: const Nutrients(
                      fat: 4,
                      carbs: 12,
                      salt: 1.2,
                    ),
                    servingGrams: 260,
                    servingLabel: null,
                    packGrams: 260,
                    imageUrl: null,
                  ), showMacros: true),
                  child: const Text('portion'),
                ),
                TextButton(
                  onPressed: () => inviteToContribute(context),
                  child: const Text('invite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Стъпка 2 от 2'), findsOneWidget);
    expect(find.text('Снимай таблицата с хранителните стойности'), findsOne);

    await tester.tap(find.text('portion'));
    await tester.pumpAndSettle();
    expect(
      find.text('95 ккал · 2 г протеин на 100 г · Open Food Facts'),
      findsOne,
    );
    expect(find.text('Количество'), findsOneWidget);
    expect(find.text('247 ккал · 5 г протеин'), findsOneWidget);
    expect(macroLine('Мазнини 10 г · въглехидрати 31 г · сол 3,1 г'), findsOne);
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('invite'));
    await tester.pumpAndSettle();
    expect(find.text('Добави продукта в базата'), findsOneWidget);
    expect(find.text('Не сега'), findsOneWidget);
  });

  testWidgets('the Adaptive formula dialog fits a phone', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: bulgarian(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAdaptiveIntro(context, plus: false),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Калории по твоя мярка'), findsOneWidget);
    expect(find.text('По-късно'), findsOneWidget);
    expect(find.text('Отключи YumSum Star'), findsOneWidget);
  });
}
