import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/meal_row.dart';
import 'package:lean_streak/widgets/meal_slots.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// The app's fonts, Cyrillic stand-in included, so a line's length on a
/// 360dp phone is the real one.
Future<void> _loadFonts() async {
  for (final (family, files) in [
    ('Nunito', ['Nunito-Regular', 'Nunito-SemiBold', 'Nunito-Bold']),
    ('Fredoka', ['Fredoka-SemiBold']),
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

DateTime _at(int hour, int minute) => DateTime(2026, 11, 12, hour, minute);

Meal _meal(String name, int hour, int minute, double kcal, {double? protein}) {
  return Meal(
    id: name,
    date: '2026-11-12',
    timestamp: _at(hour, minute),
    name: name,
    calories: kcal,
    proteinGrams: protein,
    createdAt: _at(hour, minute),
    updatedAt: _at(hour, minute),
  );
}

final _morning = [
  _meal('Porridge', 8, 10, 380, protein: 12),
  _meal('Banana', 10, 30, 105.4),
  _meal('Coffee', 11, 59, 40, protein: 1),
];
final _afternoon = [
  _meal('Soup', 12, 0, 320, protein: 15),
  _meal('Sandwich', 16, 59, 410, protein: 20),
];
final _evening = [
  _meal('Chicken curry', 19, 40, 550, protein: 30),
  _meal('Tea with milk', 20, 15, 30, protein: 1),
];

void main() {
  setUpAll(_loadFonts);

  group('mealSlotOf', () {
    test('splits the day at 12:00 and 17:00', () {
      expect(mealSlotOf(_at(0, 30)), MealSlot.morning);
      expect(mealSlotOf(_at(11, 59)), MealSlot.morning);
      expect(mealSlotOf(_at(12, 0)), MealSlot.afternoon);
      expect(mealSlotOf(_at(16, 59)), MealSlot.afternoon);
      expect(mealSlotOf(_at(17, 0)), MealSlot.evening);
      expect(mealSlotOf(_at(23, 59)), MealSlot.evening);
    });
  });

  group('mealsBySlot', () {
    test('groups by slot, each by time, leaving out empty slots', () {
      final bySlot = mealsBySlot([..._evening.reversed, ..._morning.reversed]);

      expect(bySlot.keys, [MealSlot.morning, MealSlot.evening]);
      expect(bySlot[MealSlot.morning], _morning);
      expect(bySlot[MealSlot.evening], _evening);
    });
  });

  group('mealTotals', () {
    test('adds each meal\'s calories as its row rounds them', () {
      final totals = mealTotals([
        _meal('A', 8, 0, 100.4),
        _meal('B', 9, 0, 100.4),
      ]);
      expect(totals.kcal, 200);
    });

    test('adds the protein that is known', () {
      expect(mealTotals(_morning), (kcal: 525, protein: 13));
    });

    test('has no protein when no meal has any', () {
      expect(mealTotals([_meal('Banana', 10, 30, 105)]).protein, isNull);
    });
  });

  group('MealSlots', () {
    /// The slots as Home's meals card holds them, on a 360dp phone.
    Future<void> pumpSlots(
      WidgetTester tester, {
      required List<Meal> meals,
      DateTime? now,
      bool showProtein = true,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: ResponsivePage(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(22, 20, 8, 10),
                child: MealSlots(
                  meals: meals,
                  now: now,
                  showProtein: showProtein,
                  mealRow: (meal) => MealRow(
                    meal: meal,
                    showProtein: showProtein,
                    onEdit: () {},
                    onDelete: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final allDay = [..._morning, ..._afternoon, ..._evening];

    testWidgets('on Home in the evening, the earlier slots are folded and '
        'the evening is open', (tester) async {
      await pumpSlots(tester, meals: allDay, now: _at(19, 50));

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('525 kcal · 13 g'), findsOneWidget);
      expect(find.text('Porridge'), findsNothing);

      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('730 kcal · 35 g'), findsOneWidget);
      expect(find.text('Soup'), findsNothing);

      // Open, so its count goes; the one "2 items" is the afternoon's.
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('580 kcal · 31 g'), findsOneWidget);
      expect(find.text('Chicken curry'), findsOneWidget);
      expect(find.text('Tea with milk'), findsOneWidget);
      expect(find.text('19:40'), findsOneWidget);
      expect(find.byType(MealRow), findsNWidgets(2));
    });

    testWidgets('a tap on a header opens or folds its slot', (tester) async {
      await pumpSlots(tester, meals: allDay, now: _at(19, 50));

      await tester.tap(find.text('Morning'));
      await tester.pump();
      expect(find.text('Porridge'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('3 items'), findsNothing);

      await tester.tap(find.text('Evening'));
      await tester.pump();
      expect(find.text('Chicken curry'), findsNothing);
      expect(find.text('2 items'), findsNWidgets(2));
    });

    testWidgets('a slot with no meals does not show', (tester) async {
      await pumpSlots(
        tester,
        meals: [..._morning, ..._evening],
        now: _at(19, 50),
      );

      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsNothing);
      expect(find.text('Evening'), findsOneWidget);
    });

    testWidgets('a quiet evening opens the latest slot with meals', (
      tester,
    ) async {
      await pumpSlots(
        tester,
        meals: [..._morning, ..._afternoon],
        now: _at(21, 0),
      );

      expect(find.text('Porridge'), findsNothing);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('Soup'), findsOneWidget);
      expect(find.text('Sandwich'), findsOneWidget);
    });

    testWidgets('protein is left out of the totals when it is off', (
      tester,
    ) async {
      await pumpSlots(
        tester,
        meals: allDay,
        now: _at(19, 50),
        showProtein: false,
      );

      expect(find.text('525 kcal'), findsOneWidget);
      expect(find.text('730 kcal'), findsOneWidget);
      expect(find.text('580 kcal'), findsOneWidget);
      expect(find.textContaining('protein'), findsNothing);
    });

    testWidgets('without a time, every slot is open', (tester) async {
      await pumpSlots(tester, meals: allDay);

      expect(find.byType(MealRow), findsNWidgets(allDay.length));
      expect(find.textContaining('items'), findsNothing);
    });

    testWidgets('a big afternoon fits a phone in Bulgarian', (tester) async {
      await pumpSlots(
        tester,
        locale: const Locale('bg'),
        meals: [
          ..._morning,
          _meal('Мусака', 13, 5, 1500, protein: 90),
          _meal('Баница', 15, 0, 650, protein: 38),
          ..._evening,
        ],
        now: _at(19, 50),
      );

      expect(find.text('3 записа'), findsOneWidget);
      expect(find.text('2 записа'), findsOneWidget);
      expect(find.text('2150 ккал · 128 г'), findsOneWidget);
      for (final name in ['Сутрин', 'Следобед', 'Вечер']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
        // One line: the name is never broken inside the word.
        expect(
          paragraph.size.height,
          lessThan(
            paragraph.getFullHeightForCaret(const TextPosition(offset: 0)) *
                1.5,
          ),
          reason: name,
        );
      }
    });
  });
}
