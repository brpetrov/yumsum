import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/adaptive_formula.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/models/weight_entry.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/onboarding_controller.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_entry_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:lean_streak/screens/profile/profile_screen.dart';
import 'package:lean_streak/screens/progress/helpers/log_weight_dialog.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';
import 'package:lean_streak/services/weight_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_fixtures.dart';

// Onboarding, Plan Settings, Weight & Progress and the weigh-in in
// Bulgarian on a 360 dp phone with the app's fonts: the words are there,
// nothing overflows and no label is cut short.

class _FakeOnboardingController extends OnboardingController {
  @override
  Future<void> submit({
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
    required double? targetWeightKg,
    required ActivityLevel activityLevel,
    required TrainingFrequency trainingFrequency,
    required WeightLossPace weightLossPace,
    required String country,
    required bool trackProtein,
    required WeightUnit weightUnit,
    required HeightUnit heightUnit,
  }) async {}
}

class _FakeAuthController extends AuthController {
  @override
  Future<void> signOut() async {}
}

class _FakeWeightLogController extends WeightLogController {
  @override
  Future<WeightLogResult?> logWeight({
    required double weightKg,
    WeightSource source = WeightSource.manual,
  }) async => null;
}

const _star = Entitlement(active: true, source: EntitlementSource.manual);

final bg = lookupAppLocalizations(const Locale('bg'));

/// English words that would mean a text was left untranslated.
final _english = RegExp(
  r'\b(kg|cm|kcal|Weight|Height|Target|Next|Back|Start|Yes|No|Male|Female|'
  r'Pounds|Inches|plan|weigh-in|Adaptive|History|Change|Current|Trend)\b',
);

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

void main() {
  setUpAll(_loadFonts);

  /// [home] in Bulgarian on a 360 × 780 phone.
  Future<void> pumpBg(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'language': 'bg'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('bg'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Every text laid out so far, as shown.
  List<String> shownTexts(WidgetTester tester) => [
    for (final text in tester.widgetList<RichText>(
      find.byType(RichText, skipOffstage: false),
    ))
      text.text.toPlainText(),
  ];

  /// Nothing overflows, no text is cut short with an ellipsis, and no
  /// English is left.
  void fits(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '"${paragraph.text.toPlainText()}" is cut short',
      );
    }
    for (final text in shownTexts(tester)) {
      expect(_english.hasMatch(text), isFalse, reason: '"$text" is English');
    }
  }

  group('onboarding', () {
    Future<void> pump(WidgetTester tester, {String region = 'BG'}) => pumpBg(
      tester,
      const OnboardingScreen(),
      overrides: [
        deviceRegionProvider.overrideWithValue(region),
        onboardingControllerProvider.overrideWith(
          _FakeOnboardingController.new,
        ),
        authControllerProvider.overrideWith(_FakeAuthController.new),
      ],
    );

    Future<void> next(WidgetTester tester) async {
      await tester.tap(find.text('Продължи'));
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String label, String text) async {
      await tester.enterText(find.widgetWithText(TextField, label), text);
      await tester.pumpAndSettle();
    }

    testWidgets('every card, in kg and cm', (tester) async {
      await pump(tester);
      expect(find.text('Как се казваш?'), findsOneWidget);
      expect(find.text('Обратно към входа'), findsOneWidget);
      fits(tester);
      await type(tester, 'Име', 'Мария');
      await next(tester);

      expect(find.text('Ти си…'), findsOneWidget);
      expect(find.text('Мъж'), findsOneWidget);
      expect(find.text('Друго'), findsOneWidget);
      expect(find.text('Назад'), findsOneWidget);
      fits(tester);
      await tester.tap(find.text('Жена'));
      await tester.pump();
      await next(tester);

      expect(find.text('На колко години си?'), findsOneWidget);
      await type(tester, 'Възраст', '15');
      expect(find.text('Въведи възраст от 18 до 120.'), findsOneWidget);
      fits(tester);
      await type(tester, 'Възраст', '34');
      await next(tester);

      expect(find.text('Какъв е ръстът ти?'), findsOneWidget);
      expect(find.text('ft и in'), findsOneWidget);
      expect(find.text('см'), findsWidgets);
      await type(tester, 'Ръст', '90');
      expect(find.text('100–250 см'), findsOneWidget);
      fits(tester);
      await type(tester, 'Ръст', '168');
      await next(tester);

      expect(find.text('Колко тежиш сега?'), findsOneWidget);
      expect(find.text('st и lb'), findsOneWidget);
      await type(tester, 'Сегашно тегло', '20');
      expect(find.text('30–300 кг'), findsOneWidget);
      fits(tester);
      await type(tester, 'Сегашно тегло', '72,5');
      await next(tester);

      expect(find.text('Каква е целта ти?'), findsOneWidget);
      expect(find.text('Да отслабна'), findsOneWidget);
      expect(find.text('Да запазя теглото'), findsOneWidget);
      expect(find.textContaining('Калориите са енергията'), findsOneWidget);
      fits(tester);
      await next(tester);

      expect(find.text('Към какво тегло се стремиш?'), findsOneWidget);
      await type(tester, 'Желано тегло', '80');
      expect(find.text('Трябва да е под сегашното ти тегло'), findsOneWidget);
      fits(tester);
      await type(tester, 'Желано тегло', '64');
      await next(tester);

      expect(find.text('Колко се движиш в обикновен ден?'), findsOneWidget);
      expect(find.text('Предимно седене'), findsOneWidget);
      fits(tester);
      await next(tester);

      expect(find.text('Тренираш ли освен това?'), findsOneWidget);
      expect(find.text('Без редовни тренировки'), findsOneWidget);
      fits(tester);
      await next(tester);

      expect(find.text('Да следим ли и протеина?'), findsOneWidget);
      expect(find.text('Да'), findsOneWidget);
      expect(find.text('Не'), findsOneWidget);
      fits(tester);
      await next(tester);

      expect(find.text('Планът ти е готов!'), findsOneWidget);
      expect(find.text('Твоят план'), findsOneWidget);
      expect(find.text('Дневна цел'), findsOneWidget);
      expect(find.text('Темпо'), findsOneWidget);
      expect(find.text('Цел до'), findsOneWidget);
      expect(find.text('0,5 кг/седм.'), findsOneWidget);
      expect(find.text('Устойчиво темпо'), findsOneWidget);
      expect(find.text('Да започваме'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('„Настройки на плана“'));
      await tester.pumpAndSettle();
      fits(tester);

      await tester.tap(find.byTooltip('Как се изчислява'));
      await tester.pumpAndSettle();
      expect(find.text('Как изчисляваме калориите'), findsOneWidget);
      expect(find.text('В покой'), findsOneWidget);
      expect(find.text('Обща активност'), findsOneWidget);
      expect(find.textContaining('ккал/ден'), findsWidgets);
      expect(find.text('Разбрах'), findsOneWidget);
      fits(tester);
    });

    testWidgets('stones and feet, from the UK', (tester) async {
      await pump(tester, region: 'GB');
      await type(tester, 'Име', 'Иван');
      await next(tester);
      await tester.tap(find.text('Мъж'));
      await tester.pump();
      await next(tester);
      await type(tester, 'Възраст', '40');
      await next(tester);

      expect(find.text('Инчове'), findsOneWidget);
      await type(tester, 'Ръст', '9');
      expect(find.text('3 ft 4 in–8 ft 2 in'), findsOneWidget);
      fits(tester);
      await type(tester, 'Ръст', '5');
      await type(tester, 'Инчове', '10');
      await next(tester);

      expect(find.text('Фунтове'), findsOneWidget);
      await type(tester, 'Сегашно тегло', '13');
      await type(tester, 'Фунтове', '4,5');
      fits(tester);
      // The same weight in kg, with a decimal comma.
      await tester.tap(find.text('кг'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Фунтове'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '84,6',
      );
      fits(tester);
    });
  });

  group('Plan Settings', () {
    Future<void> pump(WidgetTester tester, UserProfile profile) => pumpBg(
      tester,
      const PlanSettingsScreen(),
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        entitlementProvider.overrideWith(
          (ref) => Stream<Entitlement?>.value(_star),
        ),
        adaptiveProgressProvider.overrideWith(
          (ref) async => const AdaptiveMeasure(
            hold: AdaptiveNote.learning,
            days: 3,
            weighIns: 1,
            daysLogged: 3,
          ),
        ),
      ],
    );

    /// Scrolls down the page, checking each screenful.
    Future<void> scrollThrough(WidgetTester tester) async {
      fits(tester);
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        fits(tester);
      }
    }

    testWidgets('in kg and cm', (tester) async {
      await pump(tester, planProfile(adaptiveKcal: -80));
      expect(find.text('Настройки на плана'), findsOneWidget);
      expect(find.text('Обнови плана си'), findsOneWidget);
      expect(find.text('ЛИЧНИ ДАННИ'), findsOneWidget);
      expect(find.text('МЕРНИ ЕДИНИЦИ'), findsOneWidget);
      expect(find.widgetWithText(TextField, '79,8'), findsOneWidget);
      expect(find.text('ТВОЯТ ИТМ', skipOffstage: false), findsOneWidget);
      expect(find.text('27,6', skipOffstage: false), findsOneWidget);
      expect(find.text('Наднормено тегло', skipOffstage: false), findsOne);
      expect(find.text('18,5', skipOffstage: false), findsOneWidget);
      expect(
        find.text('КОЛКО БЪРЗО ИСКАШ ДА ОТСЛАБНЕШ?', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Бързо – 0,75 кг седмично', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Адаптивна формула', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining(' по план − 80 адаптивно = ', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Обновен план', skipOffstage: false), findsOneWidget);
      expect(find.text('Запази плана', skipOffstage: false), findsOneWidget);
      await scrollThrough(tester);
    });

    testWidgets('in stones and feet', (tester) async {
      await pump(
        tester,
        planProfile().copyWith(
          weightUnit: WeightUnit.st,
          heightUnit: HeightUnit.ftin,
        ),
      );
      expect(find.text('st и lb'), findsOneWidget);
      expect(find.text('ft и in'), findsOneWidget);
      expect(find.text('Фунтове', skipOffstage: false), findsNWidgets(2));
      expect(find.text('Инчове', skipOffstage: false), findsOneWidget);
      final boxes = [
        for (final box in tester.widgetList<TextField>(
          find.byType(TextField, skipOffstage: false),
        ))
          box.controller!.text,
      ];
      expect(boxes, ['29', '5', '6,9', '12', '7,9', '11', '6,9']);
      expect(
        find.text('Бързо – 1,65 lb седмично', skipOffstage: false),
        findsOneWidget,
      );
      await scrollThrough(tester);
    });

    testWidgets('what is wrong, in Bulgarian', (tester) async {
      await pump(tester, planProfile());
      await tester.enterText(
        find.widgetWithText(TextField, 'Сегашно тегло'),
        '500',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Възраст'), '');
      // Unfocused, so the box doesn't scroll itself back into view.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.text('Запази плана');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('30–300 кг', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Въведи възрастта си.', skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Weight & Progress', () {
    WeightEntry entry(String day, double kg) => WeightEntry(
      dateKey: day,
      weightKg: kg,
      loggedAt: DateTime.parse(day),
      source: WeightSource.manual,
    );

    Future<void> pump(WidgetTester tester, UserProfile profile) => pumpBg(
      tester,
      const ProgressScreen(),
      overrides: [
        deviceRegionProvider.overrideWithValue('BG'),
        weightEntriesProvider.overrideWith(
          (ref) => Stream.value([
            entry('2026-10-01', 86.0),
            entry('2026-10-08', 85.2),
          ]),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(profile),
        ),
        entitlementProvider.overrideWith((ref) => Stream.value(_star)),
        adaptiveProgressProvider.overrideWith((ref) async => null),
        adaptiveTodayLineProvider.overrideWithValue(bg.adaptiveFewWeighIns),
        weightLogControllerProvider.overrideWith(_FakeWeightLogController.new),
      ],
    );

    testWidgets('in kg, with the Adaptive formula on', (tester) async {
      await pump(tester, planProfile(adaptiveKcal: -80));
      expect(find.text('Тегло и напредък'), findsOneWidget);
      expect(find.text('Запиши тегло'), findsOneWidget);
      expect(find.text('Сега'), findsOneWidget);
      expect(find.text('85,2 кг'), findsWidgets);
      expect(find.text('-0,8 кг'), findsOneWidget);
      expect(find.text('73,0 кг'), findsOneWidget);
      expect(find.text('Включена'), findsOneWidget);
      expect(
        find.text('Гориш 2410 ккал на ден', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Целта ти е 1590 ккал на ден', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('За да сваляш по 0,75 кг седмично.'), findsOneWidget);
      expect(find.text(bg.adaptiveFewWeighIns), findsOneWidget);
      fits(tester);

      await tester.scrollUntilVisible(find.text('Нулирай напредъка'), 200);
      await tester.pumpAndSettle();
      expect(find.text('История'), findsOneWidget);
      expect(find.text('чт, 8 окт 2026'), findsOneWidget);
      fits(tester);

      await tester.tap(find.byTooltip('Изтрий претеглянето').first);
      await tester.pumpAndSettle();
      expect(find.text('Да изтрием ли претеглянето?'), findsOneWidget);
      expect(
        find.text(
          'Да премахнем ли 85,2 кг от чт, 8 окт? Планът ти ще се върне към '
          '86,0 кг.',
        ),
        findsOneWidget,
      );
      fits(tester);
      await tester.tap(find.text('Отказ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Нулирай напредъка'));
      await tester.pumpAndSettle();
      expect(find.text('Да нулираме ли напредъка?'), findsOneWidget);
      fits(tester);
    });

    testWidgets('in stones, the axis in stones', (tester) async {
      await pump(tester, planProfile().copyWith(weightUnit: WeightUnit.st));
      expect(find.text('13 st 6 lb'), findsWidgets);
      expect(find.text('-1,8 lb'), findsOneWidget);
      expect(find.text('За да сваляш по 1,65 lb седмично.'), findsOneWidget);
      fits(tester);
    });

    testWidgets('without YumSum Star, the invitation fits', (tester) async {
      await pumpBg(
        tester,
        const ProgressScreen(),
        overrides: [
          weightEntriesProvider.overrideWith(
            (ref) => Stream.value([entry('2026-10-01', 86.0)]),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(planProfile()),
          ),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          adaptiveProgressProvider.overrideWith((ref) async => null),
          adaptiveTodayLineProvider.overrideWithValue(null),
        ],
      );
      expect(find.text('Адаптивна формула'), findsOneWidget);
      expect(find.textContaining('специално за теб'), findsOneWidget);
      fits(tester);
    });

    testWidgets('with nothing logged', (tester) async {
      await pumpBg(
        tester,
        const ProgressScreen(),
        overrides: [
          weightEntriesProvider.overrideWith((ref) => Stream.value([])),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(planProfile()),
          ),
        ],
      );
      expect(find.text('Още няма записано тегло'), findsOneWidget);
      expect(find.text('Запиши тегло'), findsOneWidget);
      fits(tester);
    });
  });

  testWidgets('the weigh-in dialog', (tester) async {
    await pumpBg(
      tester,
      Consumer(
        builder: (context, ref, _) {
          ref.watch(userProfileProvider);
          return Scaffold(
            body: TextButton(
              onPressed: () => showLogWeightDialog(context),
              child: const Text('open'),
            ),
          );
        },
      ),
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(planProfile())),
        weightLogControllerProvider.overrideWith(_FakeWeightLogController.new),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Запиши теглото си'), findsOneWidget);
    expect(find.widgetWithText(TextField, '79,8'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '500');
    await tester.tap(find.text('Запази'));
    await tester.pumpAndSettle();
    expect(find.text('Въведи тегло между 25 и 400 кг.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '80,5');
    await tester.tap(find.text('Запази'));
    await tester.pumpAndSettle();
    expect(
      find.text('Не успяхме да запишем теглото ти. Опитай отново.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('the Adaptive formula\'s lines on Home', () {
    final now = DateTime(2026, 11, 4);
    final week = AdaptiveFormula.dateKey(AdaptiveFormula.mondayOf(now));
    String? line(String note, {int kcal = -80}) => adaptiveTodayLine(
      planProfile(adaptiveKcal: kcal, adaptiveWeek: week, adaptiveNote: note),
      bg,
      lastWeighIn: now,
      now: now,
    );

    expect(
      line(AdaptiveNote.lowered.value),
      'Настроено за теб: −80 ккал. Гориш малко по-малко, отколкото '
      'предвиждаше планът.',
    );
    expect(
      line(AdaptiveNote.steady.value, kcal: 0),
      'Без промяна тази седмица: теглото ти отговаря на това, което ядеш.',
    );
    expect(
      adaptiveTodayLine(
        planProfile(),
        bg,
        lastWeighIn: now.subtract(const Duration(days: 10)),
        now: now,
      ),
      bg.adaptivePaused,
    );
  });
}
