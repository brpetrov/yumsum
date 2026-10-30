import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_contribution_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogMealController extends LogMealController {
  final saved = <({String? name, double calories, double? protein})>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
  }) async {
    saved.add((name: name, calories: calories, protein: proteinGrams));
  }
}

class _FakeEstimateService implements CalorieEstimateService {
  int estimateCalls = 0;

  @override
  Future<CalorieEstimate> estimate(String uid, String description) async {
    estimateCalls++;
    return (
      kcal: 520,
      protein: 32,
      items: const [
        (name: 'Chicken wrap', grams: 200, kcal: 400, protein: 30),
        (name: 'Mayo', grams: 15, kcal: 120, protein: 2),
      ],
    );
  }

  Uint8List? heard;

  @override
  Future<VoiceMealParsed> parseVoiceAudio(String uid, Uint8List wav) async {
    heard = wav;
    return (
      name: 'Lunch',
      kcal: 400,
      protein: null,
      items: const <EstimateItem>[],
    );
  }

  @override
  Future<int?> estimateProtein(String name, int kcal) async => 30;

  int photoCalls = 0;

  @override
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) async {
    photoCalls++;
    return (
      name: 'Musaka',
      kcal: 640,
      protein: 28,
      items: const <EstimateItem>[],
    );
  }

  @override
  Future<LabelReading> readLabel(
    String uid,
    Uint8List front,
    Uint8List label,
  ) async => (
    name: 'Лютеница',
    lang: 'bg',
    brand: 'Първа преса',
    quantity: '260 g',
    servingSize: null,
    per100g: const {'energy-kcal': 95.0, 'proteins': 2.0},
  );
}

class _FakeContributor extends Fake implements FoodContributionService {
  final sent = <ProductContribution>[];

  @override
  bool get isConfigured => true;

  @override
  Future<void> contribute(ProductContribution product) async {
    sent.add(product);
  }
}

// A 1x1 PNG, so the photos the contribute sheet shows decode.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _FakeFoodLookup implements FoodLookupService {
  PackagedFood? food = (
    name: 'Chicken Tikka Wrap',
    brand: 'Tesco',
    kcalPer100g: 215,
    proteinPer100g: 9,
    servingGrams: 220,
    imageUrl: null,
  );
  String? lastBarcode;
  String? lastQuery;
  // Whether Open Food Facts knows the product when [food] is null.
  bool listed = false;

  @override
  Future<BarcodeLookup> byBarcode(String barcode) async {
    lastBarcode = barcode;
    return (listed: food != null || listed, food: food);
  }

  @override
  Future<List<PackagedFood>> search(String query, {String? country}) async {
    lastQuery = query;
    return [?food];
  }
}

/// A microphone that plays back whatever the test feeds it.
class _FakeRecorder extends Fake implements AudioRecorder {
  final audio = StreamController<Uint8List>();
  bool stopped = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async =>
      audio.stream;

  @override
  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      const Stream.empty();

  @override
  Future<String?> stop() async {
    stopped = true;
    await audio.close();
    return null;
  }
}

/// A profile that has switched protein off.
final _noProteinProfile = UserProfile(
  uid: 'user-1',
  email: 'a@b.com',
  name: 'Test',
  trackProtein: false,
  age: 30,
  gender: Gender.male,
  heightCm: 180,
  currentWeightKg: 86,
  targetWeightKg: 75,
  activityLevel: ActivityLevel.lightlyActive,
  trainingFrequency: TrainingFrequency.oneToTwo,
  activityScaleVersion: currentActivityScaleVersion,
  planCalculationVersion: currentPlanCalculationVersion,
  weightLossPace: WeightLossPace.moderate,
  targetDate: DateTime(2027),
  bmi: 26.5,
  bmr: 1800,
  tdee: 2400,
  dailyCalorieTarget: 1900,
  goalPaceKgPerWeek: 0.5,
  goalPaceLevel: GoalPaceLevel.values.first,
  onboardingCompleted: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// A meal logged at this time of day [daysAgo] days ago.
Meal _recent(String name, double kcal, double? protein, {int daysAgo = 1}) {
  final at = DateTime.now().subtract(Duration(days: daysAgo));
  return Meal(
    id: '$name $daysAgo',
    date: DateFormat('yyyy-MM-dd').format(at),
    timestamp: at,
    name: name,
    calories: kcal,
    proteinGrams: protein,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  late _FakeLogMealController controller;
  late _FakeEstimateService estimateService;
  late _FakeRecorder recorder;
  late _FakeFoodLookup foodLookup;
  late ProviderContainer container;
  late List<CameraMode> cameraModes;
  late _FakeContributor contributor;

  Future<void> pumpCard(
    WidgetTester tester, {
    List<Meal> recents = const [],
    LaunchAction? launchAction,
    bool takesPhoto = true,
    String? barcode,
    int aiUsed = 0,
    bool trackProtein = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    contributor = _FakeContributor();
    controller = _FakeLogMealController();
    estimateService = _FakeEstimateService();
    recorder = _FakeRecorder();
    foodLookup = _FakeFoodLookup();
    cameraModes = [];
    container = ProviderContainer(
      overrides: [
        logMealControllerProvider.overrideWith(() => controller),
        calorieEstimateServiceProvider.overrideWithValue(estimateService),
        currentUidProvider.overrideWithValue('user-1'),
        aiUsageTodayProvider.overrideWith((ref) => Stream.value(aiUsed)),
        recentMealsProvider.overrideWith((ref) async => recents),
        audioRecorderProvider.overrideWithValue(recorder),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(trackProtein ? null : _noProteinProfile),
        ),
        mealCameraProvider.overrideWithValue((_, mode) async {
          cameraModes.add(mode);
          return switch (mode) {
            CameraMode.barcode =>
              barcode == null
                  ? null
                  : (barcode: barcode, photos: const <XFile>[]),
            CameraMode.photo =>
              !takesPhoto
                  ? null
                  : (
                      barcode: null,
                      photos: [
                        XFile.fromData(
                          Uint8List.fromList([1, 2, 3]),
                          path: 'a.jpg',
                        ),
                      ],
                    ),
          };
        }),
        foodLookupServiceProvider.overrideWithValue(foodLookup),
        foodContributionServiceProvider.overrideWithValue(contributor),
        productPhotosProvider.overrideWithValue(
          (_) async => [
            XFile.fromData(_pixel, path: 'front.png'),
            XFile.fromData(_pixel, path: 'label.png'),
          ],
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    if (launchAction != null) {
      container.read(launchActionProvider.notifier).set(launchAction);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: QuickLogBar())),
      ),
    );
  }

  const listening = 'Listening... tap stop when you\'re done.';

  final nameBox = find.byKey(const ValueKey('quick-log-name'));
  final kcalBox = find.byKey(const ValueKey('quick-log-kcal'));
  final proteinBox = find.byKey(const ValueKey('quick-log-protein'));

  /// The name, calorie and protein boxes; '' for a box that isn't shown.
  List<String> boxes(WidgetTester tester) => [
    for (final box in [nameBox, kcalBox, proteinBox])
      box.evaluate().isEmpty
          ? ''
          : tester.widget<TextField>(box).controller!.text,
  ];

  EditableTextState nameField(WidgetTester tester) => tester.state(
    find.descendant(of: nameBox, matching: find.byType(EditableText)),
  );

  testWidgets('saves typed name and calories without calling the AI', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pump();
    await tester.enterText(kcalBox, '450');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    // Protein for typed meals is filled in by the controller, not the box.
    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: null),
    ]);
    expect(estimateService.estimateCalls, 0);
    expect(boxes(tester), ['', '', '']);
  });

  testWidgets('the number boxes appear once the bar is in use; digits only', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(kcalBox, findsNothing);

    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pump();
    expect(kcalBox, findsOneWidget);
    expect(proteinBox, findsOneWidget);

    // Back hides the keyboard but keeps focus: an empty bar folds away.
    tester.view.resetViewInsets();
    await tester.pump();
    expect(kcalBox, findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    await tester.pump();

    await tester.enterText(kcalBox, '45x0 kcal');
    await tester.enterText(proteinBox, '21g');
    await tester.pump();
    expect(boxes(tester), ['', '450', '21']);
    expect(find.text('g protein'), findsOneWidget);
  });

  testWidgets('estimates calories when none are typed, then waits for Save', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Estimate'));
    await tester.pump();
    await tester.pump();

    expect(boxes(tester), ['chicken wrap', '520', '32']);
    expect(find.widgetWithText(TextButton, 'Save'), findsOneWidget);
    expect(controller.saved, isEmpty);

    // The breakdown is one muted line until tapped.
    expect(find.text('Chicken wrap 400 · Mayo 120'), findsOneWidget);
    expect(find.text('120 kcal · 2 g'), findsNothing);
    await tester.tap(find.text('Chicken wrap 400 · Mayo 120'));
    await tester.pump();
    expect(find.text('120 kcal · 2 g'), findsOneWidget);
    expect(find.text('400 kcal · 30 g'), findsOneWidget);

    // A corrected weight rescales the item and the boxes, with no AI call.
    await tester.tap(find.text('200 g'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '300',
    );
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();
    expect(find.text('600 kcal · 45 g'), findsOneWidget);
    expect(boxes(tester), ['chicken wrap', '720', '47']);
    expect(estimateService.estimateCalls, 1);
  });

  testWidgets('a scanned barcode is looked up; the portion fills the box', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '5000112637922');
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();

    expect(foodLookup.lastBarcode, '5000112637922');
    expect(find.text('Chicken Tikka Wrap'), findsOneWidget);
    final grams = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '220',
    );
    expect(grams, findsOneWidget);

    await tester.enterText(grams, '150');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(boxes(tester), ['Chicken Tikka Wrap', '323', '14']);
    expect(estimateService.photoCalls, 0);
  });

  testWidgets('a meal photo goes to the AI', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pumpAndSettle();
    expect(cameraModes, [CameraMode.photo]);
    expect(foodLookup.lastBarcode, isNull);
    expect(estimateService.photoCalls, 1);
    expect(boxes(tester), ['Musaka', '640', '28']);
  });

  testWidgets('a missing product can be contributed, then logged', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '3800000000017');
    foodLookup.food = null;
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();

    expect(find.text('Be the first to add this'), findsOneWidget);
    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    // The AI's reading is in the form, for the user to check.
    String field(String key) =>
        tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;
    expect(field('contribute-name'), 'Лютеница');
    expect(field('contribute-energy-kcal'), '95');
    await tester.enterText(
      find.byKey(const ValueKey('contribute-proteins')),
      '2,4',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.tap(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.pumpAndSettle();

    final sent = contributor.sent.single;
    expect(sent.lang, 'bg');
    expect(sent.barcode, '3800000000017');
    expect(sent.brand, 'Първа преса');
    expect(sent.per100g, {'energy-kcal': 95.0, 'proteins': 2.4});
    expect(find.text('Thank you!'), findsOneWidget);

    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    // The pack size (260 g) is the starting amount.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Лютеница', '247', '5']);
    expect(find.textContaining('isn\'t on Open Food Facts'), findsNothing);
  });

  testWidgets('a listed product without calories is not offered', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '4000000000001');
    foodLookup.food = null;
    foodLookup.listed = true;
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    expect(find.text('Be the first to add this'), findsNothing);
    expect(
      find.textContaining('no calories for this product yet'),
      findsOneWidget,
    );
  });

  testWidgets('closing the thank-you still counts as contributed', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '3800000000017');
    foodLookup.food = null;
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.tap(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.pumpAndSettle();
    expect(find.text('Thank you!'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20)); // outside the sheet
    await tester.pumpAndSettle();
    expect(find.text('Thank you!'), findsNothing);
    expect(find.textContaining('isn\'t on Open Food Facts'), findsNothing);
  });

  testWidgets('a barcode the database lacks says so', (tester) async {
    await pumpCard(tester, barcode: '4000000000000');
    foodLookup.food = null;
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    // Not now: the plain message, and no contribution.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(contributor.sent, isEmpty);
    expect(foodLookup.lastBarcode, '4000000000000');
    expect(find.textContaining('isn\'t on Open Food Facts'), findsOneWidget);
    expect(estimateService.photoCalls, 0);
    expect(boxes(tester), ['', '', '']);
    expect(cameraModes, [CameraMode.barcode]);
  });

  testWidgets('backing out of the camera changes nothing', (tester) async {
    await pumpCard(tester, takesPhoto: false);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    expect(cameraModes, [CameraMode.photo, CameraMode.barcode]);
    expect(estimateService.photoCalls, 0);
    expect(foodLookup.lastBarcode, isNull);
    expect(boxes(tester), ['', '', '']);
  });

  testWidgets('a typed name can be searched for; the pick fills the box', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'tikka wrap');
    await tester.pump();
    await tester.tap(find.text('Search foods'));
    await tester.pumpAndSettle();

    expect(foodLookup.lastQuery, 'tikka wrap');
    expect(find.text('Tesco · 215 kcal per 100 g'), findsOneWidget);
    await tester.tap(find.text('Chicken Tikka Wrap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(boxes(tester), ['Chicken Tikka Wrap', '473', '20']);
    expect(find.text('Search foods'), findsNothing);
  });

  testWidgets(
    'an empty box offers photo, barcode and mic; text gets one named button',
    (tester) async {
      await pumpCard(tester);
      for (final way in ['Take a photo', 'Scan a barcode', 'Speak']) {
        expect(find.byTooltip(way), findsOneWidget);
      }
      expect(find.byTooltip('Clear'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Estimate'), findsNothing);

      // A name alone can be estimated.
      await tester.enterText(nameBox, 'wrap');
      await tester.pump();
      for (final way in ['Take a photo', 'Scan a barcode', 'Speak']) {
        expect(find.byTooltip(way), findsNothing);
      }
      expect(find.byTooltip('Clear'), findsOneWidget);
      expect(find.text('Estimate'), findsOneWidget);

      // With calories it saves.
      await tester.enterText(kcalBox, '450');
      await tester.pump();
      expect(find.text('Estimate'), findsNothing);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(boxes(tester), ['', '', '']);
      expect(find.byTooltip('Speak'), findsOneWidget);
    },
  );

  testWidgets('with protein off there is no protein box and no protein in '
      'the breakdown', (tester) async {
    await pumpCard(tester, trackProtein: false);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pump();
    expect(kcalBox, findsOneWidget);
    expect(proteinBox, findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Estimate'));
    await tester.pump();
    await tester.pump();
    expect(boxes(tester), ['chicken wrap', '520', '']);
    await tester.tap(find.text('Chicken wrap 400 · Mayo 120'));
    await tester.pump();
    expect(find.text('400 kcal'), findsOneWidget);
    expect(find.text('400 kcal · 30 g'), findsNothing);
  });

  testWidgets('fits a 360dp phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCard(tester);
    // Three buttons beside the box, no overflow.
    expect(find.byTooltip('Scan a barcode'), findsOneWidget);
    await tester.enterText(nameBox, 'A long meal name that keeps going');
    await tester.pump();
    expect(find.text('Estimate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers usual meals while the box is focused', (tester) async {
    await pumpCard(
      tester,
      recents: [
        _recent('Ham sandwich', 500, 20),
        _recent('Musaka', 640, 28),
        _recent('Ham sandwich', 480, 20, daysAgo: 2),
        _recent('Chicken wrap', 450, 30, daysAgo: 2),
        _recent('Ham sandwich', 480, 20, daysAgo: 3),
      ],
    );
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);

    // Empty box: only what has been had at this time more than once.
    await tester.tap(nameBox);
    await tester.pump();
    expect(find.byType(ActionChip, skipOffstage: false), findsOneWidget);
    expect(find.text('Ham sandwich · 500 kcal'), findsOneWidget);

    await tester.enterText(nameBox, 'wrap');
    await tester.pump();
    expect(find.text('Search foods'), findsOneWidget);
    expect(find.text('Ham sandwich · 500 kcal'), findsNothing);

    await tester.tap(find.text('Chicken wrap · 450 kcal'));
    await tester.pump();
    expect(boxes(tester), ['Chicken wrap', '450', '30']);
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();
    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 30.0),
    ]);
  });

  testWidgets('the mic records a note and the AI fills the box from it', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(find.text(listening), findsOneWidget);

    recorder.audio.add(Uint8List(32000)); // one second of 16-bit mono
    await tester.pump();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(recorder.stopped, isTrue);
    expect(estimateService.heard!.length, 44 + 32000);
    expect(boxes(tester), ['Lunch', '400', '']);
  });

  testWidgets('the mic says so before recording once the AI is used up', (
    tester,
  ) async {
    await pumpCard(tester, aiUsed: 10);
    await tester.pump();
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();

    expect(find.text(listening), findsNothing);
    expect(
      find.text(
        'Today\'s 10 AI estimates are used up. Type the calories yourself.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('what is left of the AI shows once half is used', (tester) async {
    await pumpCard(tester, aiUsed: 7);
    await tester.pump();
    expect(find.text('3 AI estimates left today'), findsNothing);

    await tester.enterText(nameBox, 'Wrap');
    await tester.pump();
    expect(find.text('3 AI estimates left today'), findsOneWidget);

    await tester.enterText(kcalBox, '450');
    await tester.pump();
    expect(find.text('3 AI estimates left today'), findsNothing);
  });

  testWidgets('nothing about the AI allowance while under half is used', (
    tester,
  ) async {
    await pumpCard(tester, aiUsed: 4);
    await tester.pump();
    await tester.enterText(nameBox, 'Wrap');
    await tester.pump();
    expect(find.textContaining('left today'), findsNothing);
  });

  testWidgets('a mis-tap on the mic is not sent to the AI', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    recorder.audio.add(Uint8List(2000));
    await tester.pump();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(estimateService.heard, isNull);
    expect(
      find.text('Didn\'t catch that. Tap the mic and try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a voice launch action waiting before Today opens starts the mic',
    (tester) async {
      await pumpCard(tester, launchAction: LaunchAction.voiceLog);
      await tester.pump(); // the post-frame callback
      await tester.pump(); // permission check, recorder start

      expect(find.text(listening), findsOneWidget);
      expect(container.read(launchActionProvider), isNull);

      await tester.tap(find.byTooltip('Stop'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a voice launch action while Today is open starts the mic', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(find.text(listening), findsNothing);

    container.read(launchActionProvider.notifier).set(LaunchAction.voiceLog);
    await tester.pump();
    await tester.pump();

    expect(find.text(listening), findsOneWidget);
    expect(container.read(launchActionProvider), isNull);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();
  });

  testWidgets('a type launch action focuses the box for the keyboard', (
    tester,
  ) async {
    await pumpCard(tester, launchAction: LaunchAction.typeLog);
    await tester.pump();

    expect(tester.widget<TextField>(nameBox).focusNode!.hasFocus, isTrue);
    expect(container.read(launchActionProvider), isNull);
    await tester.pump(const Duration(milliseconds: 500)); // the keyboard retry
  });

  testWidgets('focusing and typing keep the same name field and its focus', (
    tester,
  ) async {
    await pumpCard(tester);
    final before = nameField(tester);

    // The number boxes appear under the name box on focus; it must not be
    // rebuilt as a new widget (which drops the keyboard).
    await tester.tap(nameBox);
    await tester.pump();
    await tester.enterText(nameBox, 'c');
    await tester.pump();

    expect(nameField(tester), same(before));
    expect(tester.widget<TextField>(nameBox).focusNode!.hasFocus, isTrue);
  });

  testWidgets('the first keystroke keeps the field when chips stay', (
    tester,
  ) async {
    await pumpCard(
      tester,
      recents: [
        _recent('Chicken wrap', 450, 30),
        _recent('Chicken wrap', 450, 30, daysAgo: 2),
      ],
    );
    await tester.pump();
    await tester.tap(nameBox);
    await tester.pump();
    final before = nameField(tester);

    await tester.enterText(nameBox, 'c');
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal'), findsOneWidget);
    expect(nameField(tester), same(before));
  });

  testWidgets('keyboard done saves when calories are present', (tester) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'porridge');
    await tester.pump();
    await tester.enterText(kcalBox, '450');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.saved, [
      (name: 'Porridge', calories: 450.0, protein: null),
    ]);
  });

  testWidgets('saves protein typed into its box', (tester) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pump();
    await tester.enterText(kcalBox, '450');
    await tester.enterText(proteinBox, '35');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 35.0),
    ]);
  });
}
