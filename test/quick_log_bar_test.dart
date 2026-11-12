import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_contribution_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'recipe_fixtures.dart';
import 'time_picker_fixtures.dart';

class _FakeLogMealController extends LogMealController {
  final saved = <({String? name, double calories, double? protein})>[];
  final savedMacros = <Nutrients?>[];
  final savedTimes = <TimeOfDay?>[];

  @override
  Future<void> submit({
    Meal? existingMeal,
    String? date,
    String? name,
    required double calories,
    double? proteinGrams,
    Nutrients? macros,
    TimeOfDay? time,
  }) async {
    saved.add((name: name, calories: calories, protein: proteinGrams));
    savedMacros.add(macros);
    savedTimes.add(time);
  }
}

class _FakeEstimateService implements CalorieEstimateService {
  int estimateCalls = 0;
  List<EstimateItem> items = const [
    EstimateItem(name: 'Chicken wrap', grams: 200, kcal: 400, protein: 30),
    EstimateItem(name: 'Mayo', grams: 15, kcal: 120, protein: 2),
  ];

  String? described;

  /// Thrown by [estimate] when set.
  Object? error;

  @override
  Future<CalorieEstimate> estimate(String uid, String description) async {
    estimateCalls++;
    described = description;
    if (error case final error?) throw error;
    final total = totalOf(items);
    return (
      kcal: total.kcal,
      protein: total.protein,
      macros: const Nutrients(fat: 26, saturates: 6, carbs: 48, salt: 2.6),
      items: items,
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
      macros: null,
      items: const <EstimateItem>[],
    );
  }

  @override
  Future<({int? protein, Nutrients? macros})> estimateNutrients(
    String name,
    int kcal,
  ) async => (protein: 30, macros: null);

  int photoCalls = 0;

  @override
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) async {
    photoCalls++;
    return (
      name: 'Musaka',
      kcal: 640,
      protein: 28,
      macros: null,
      items: const <EstimateItem>[],
    );
  }

  // Whether the last label reading had the front of the pack.
  bool? readFront;

  @override
  Future<LabelReading> readLabel(
    String uid,
    Uint8List? front,
    Uint8List label,
  ) async {
    readFront = front != null;
    return (
      name: 'Лютеница',
      lang: 'bg',
      brand: 'Първа преса',
      quantity: '260 g',
      servingSize: null,
      per100g: const {'energy-kcal': 95.0, 'proteins': 2.0},
    );
  }
}

class _FakeContributor extends Fake implements FoodContributionService {
  final sent = <ProductContribution>[];
  final nutrition = <NutritionContribution>[];

  @override
  bool get isConfigured => true;

  @override
  Future<void> contribute(ProductContribution product) async {
    sent.add(product);
  }

  @override
  Future<void> addNutrition(NutritionContribution added) async {
    nutrition.add(added);
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
    macrosPer100g: const Nutrients(fat: 8, carbs: 24, salt: 0.9),
    servingGrams: 220,
    servingLabel: '1 wrap (220 g)',
    packGrams: 220,
    imageUrl: null,
  );
  String? lastBarcode;
  String? lastQuery;
  // Whether Open Food Facts knows the product when [food] is null, and
  // what it has when it's the nutrition that's missing.
  bool listed = false;
  ListedProduct? needsNutrition;
  // Keeps the lookup waiting until completed.
  Completer<void>? hold;

  @override
  Future<BarcodeLookup> byBarcode(String barcode) async {
    lastBarcode = barcode;
    await hold?.future;
    return (
      listed: food != null || listed || needsNutrition != null,
      food: food,
      needsNutrition: needsNutrition,
    );
  }

  @override
  Future<List<PackagedFood>> search(String query, {String? country}) async {
    lastQuery = query;
    return [?food];
  }
}

/// A microphone that plays back whatever the test feeds it.
class _FakeRecorder extends Fake implements AudioRecorder {
  var audio = StreamController<Uint8List>();
  bool stopped = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    if (audio.isClosed) audio = StreamController<Uint8List>();
    return audio.stream;
  }

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

/// A speech recogniser the test speaks through; one that doesn't [work]
/// can't start, as where the device has none.
class _FakeSpeech extends Fake implements SpeechToText {
  _FakeSpeech({this.works = true});

  final bool works;
  int starts = 0;
  SpeechResultListener? _onResult;
  SpeechSoundLevelChange? onSoundLevel;
  SpeechListenOptions? options;
  bool stopped = false;
  bool cancelled = false;

  @override
  SpeechErrorListener? errorListener;

  @override
  SpeechStatusListener? statusListener;

  bool _initWorked = false;

  /// As the plugin's: until a call works, each takes its own arguments as
  /// the listeners, replacing any set before it; after that, calls change
  /// nothing.
  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    starts++;
    if (_initWorked) return true;
    errorListener = onError;
    statusListener = onStatus;
    return _initWorked = works;
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    _onResult = onResult;
    onSoundLevel = onSoundLevelChange;
    options = listenOptions;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
  }

  /// The words heard so far; [last] once the recogniser has finished.
  void say(String words, {bool last = false}) => _onResult!(
    SpeechRecognitionResult([
      SpeechRecognitionWords(words, null, 1),
    ], (last ? ResultType.finalResult : ResultType.partial).value),
  );
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
Meal _recent(
  String name,
  double kcal,
  double? protein, {
  int daysAgo = 1,
  Nutrients? macros,
}) {
  final at = DateTime.now().subtract(Duration(days: daysAgo));
  return Meal(
    id: '$name $daysAgo',
    date: DateFormat('yyyy-MM-dd').format(at),
    timestamp: at,
    name: name,
    calories: kcal,
    proteinGrams: protein,
    macros: macros,
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
  // The photos the contribution camera last asked for.
  List<PhotoStep>? photoSteps;

  Future<void> pumpCard(
    WidgetTester tester, {
    List<Meal> recents = const [],
    List<Recipe> recipes = const [],
    LaunchAction? launchAction,
    bool takesPhoto = true,
    String? barcode,
    int aiUsed = 0,
    bool trackProtein = true,
    bool plus = true,
    _FakeSpeech? speech,
    String language = 'en',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    contributor = _FakeContributor();
    controller = _FakeLogMealController();
    estimateService = _FakeEstimateService();
    recorder = _FakeRecorder();
    foodLookup = _FakeFoodLookup();
    cameraModes = [];
    photoSteps = null;
    container = ProviderContainer(
      overrides: [
        logMealControllerProvider.overrideWith(() => controller),
        calorieEstimateServiceProvider.overrideWithValue(estimateService),
        currentUidProvider.overrideWithValue('user-1'),
        aiUsageTodayProvider.overrideWith((ref) => Stream.value(aiUsed)),
        recentMealsProvider.overrideWith((ref) => Stream.value(recents)),
        recipesProvider.overrideWith((ref) async => recipes),
        audioRecorderProvider.overrideWithValue(recorder),
        speechProvider.overrideWith((ref) => speech),
        languageCodeProvider.overrideWithValue(language),
        deviceLanguageProvider.overrideWithValue('en'),
        deviceRegionProvider.overrideWithValue('GB'),
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
        productPhotosProvider.overrideWithValue((_, steps) async {
          photoSteps = steps;
          return [
            for (final (i, _) in steps.indexed)
              XFile.fromData(_pixel, path: 'photo$i.png'),
          ];
        }),
        sharedPreferencesProvider.overrideWithValue(prefs),
        plusProvider.overrideWithValue(plus),
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

  /// The quick-log chip for the meal or recipe called [name].
  Finder chipNamed(String name) => find.widgetWithText(ActionChip, name);

  /// The round button with [tooltip].
  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  testWidgets('saves typed name and calories without calling the AI', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pump();
    await tester.enterText(kcalBox, '450');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save'));
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
    final handle = find.byKey(const ValueKey('quick-log-handle'));
    expect(handle, findsNothing);
    await tester.tap(nameBox);
    await tester.pump();
    expect(kcalBox, findsOneWidget);
    expect(proteinBox, findsOneWidget);
    expect(handle, findsOneWidget);

    // Back hides the keyboard but keeps focus: an empty bar folds away.
    tester.view.resetViewInsets();
    await tester.pump();
    expect(kcalBox, findsNothing);
    expect(handle, findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    await tester.pump();
    expect(kcalBox, findsOneWidget);

    // So does swiping the bar down, which lets go of the box.
    await tester.timedDrag(
      find.byType(QuickLogBar),
      const Offset(0, 80),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(nameBox).focusNode!.hasFocus, isFalse);
    expect(kcalBox, findsNothing);
    await tester.tap(nameBox);
    await tester.pumpAndSettle();

    await tester.enterText(kcalBox, '45x0 kcal');
    await tester.enterText(proteinBox, '21g');
    await tester.pump();
    expect(boxes(tester), ['', '450', '21']);
    expect(find.text('g'), findsOneWidget);
  });

  testWidgets('the keyboard sliding in or out rebuilds the bar once', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.tap(nameBox);
    await tester.pumpAndSettle();
    addTearDown(tester.view.resetViewInsets);

    var builds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is QuickLogBar) builds++;
    };
    try {
      // Each frame of the slide changes the insets.
      for (final inset in [100.0, 400.0, 800.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();
      }
      expect(builds, 1);
      expect(kcalBox, findsOneWidget);

      for (final inset in [400.0, 100.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();
      }
      expect(builds, 2);
      expect(kcalBox, findsNothing);
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
  });

  testWidgets('estimates calories when none are typed, then waits for Save', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Estimate'));
    await tester.pump();
    await tester.pump();

    expect(boxes(tester), ['chicken wrap', '520', '32']);
    expect(find.byTooltip('Save'), findsOneWidget);
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

    // The meal's macros scale with its calories: 520 up to 720.
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    final macros = controller.savedMacros.single!;
    expect(macros.fat, closeTo(36, 0.01));
    expect(macros.carbs, closeTo(66.46, 0.01));
    expect(macros.salt, closeTo(3.6, 0.01));
    expect(macros.fibre, isNull);
  });

  testWidgets('a failed estimate is one call; taps straight after it ask '
      'nothing, and the sparkle works again 2 seconds on', (tester) async {
    await pumpCard(tester);
    estimateService.error = const CalorieEstimateException(
      'Could not estimate calories. Try again.',
    );
    await tester.enterText(nameBox, 'healthy chicken burritos');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Estimate'));
    await tester.pump();
    expect(
      find.text('Could not estimate calories. Try again.'),
      findsOneWidget,
    );
    expect(estimateService.estimateCalls, 1);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('Estimate'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(estimateService.estimateCalls, 1);
    expect(
      find.text('Could not estimate calories. Try again.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Estimate'));
    await tester.pump();
    expect(estimateService.estimateCalls, 2);
  });

  testWidgets('where the AI had to assume the version of an item, the '
      'breakdown opens with chips and no dialog; a pick swaps the item in', (
    tester,
  ) async {
    await pumpCard(tester);
    estimateService.items = const [
      EstimateItem(
        name: 'Cappuccino with semi-skimmed milk',
        grams: 250,
        kcal: 110,
        protein: 7,
        options: [
          EstimateItem(
            name: 'Cappuccino with whole milk',
            grams: 250,
            kcal: 150,
            protein: 8,
          ),
          EstimateItem(
            name: 'Large cappuccino',
            grams: 350,
            kcal: 200,
            protein: 11,
          ),
        ],
      ),
      EstimateItem(name: 'Croissant', grams: 60, kcal: 270, protein: 5),
    ];
    await tester.enterText(nameBox, 'cappuccino and a croissant');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Estimate'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The boxes are filled with the version the AI went with, and the
    // breakdown is open with its chips: that version ticked, the others
    // beside it.
    expect(boxes(tester), ['cappuccino and a croissant', '380', '12']);
    expect(find.byType(AlertDialog), findsNothing);
    final breakdown = find.byType(EstimateBreakdown);
    for (final text in [
      '110 kcal · 7 g',
      'Whole milk',
      'Large cappuccino',
      'Croissant',
    ]) {
      expect(
        find.descendant(of: breakdown, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    // The item's row and its ticked chip.
    expect(find.text('Cappuccino with semi-skimmed milk'), findsNWidgets(2));
    expect(
      find.descendant(
        of: breakdown,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Whole milk'));
    await tester.pump();
    expect(boxes(tester), ['cappuccino and a croissant', '420', '13']);
    expect(find.text('150 kcal · 8 g'), findsOneWidget);
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

  testWidgets('a packet\'s macros are saved with it, scaled to calories '
      'typed over', (tester) async {
    await pumpCard(tester, barcode: '5000112637922');
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == '220',
      ),
      '150',
    );
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 150 g, then typed up from 323 to 646 kcal: twice the packet's figures.
    await tester.enterText(kcalBox, '646');
    await tester.pump();
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    final macros = controller.savedMacros.single!;
    expect(macros.fat, closeTo(24, 0.01));
    expect(macros.carbs, closeTo(72, 0.01));
    expect(macros.salt, closeTo(2.7, 0.01));
    expect(macros.fibre, isNull);
  });

  testWidgets('a new name drops the macros the box was filled with', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '5000112637922');
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.enterText(nameBox, 'Tuna wrap');
    await tester.pump();
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.saved.single.name, 'Tuna wrap');
    expect(controller.savedMacros.single, isNull);
  });

  testWidgets('a meal photo goes to the AI', (tester) async {
    await pumpCard(tester);
    expect(find.byType(PlusStar), findsNothing);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pumpAndSettle();
    expect(cameraModes, [CameraMode.photo]);
    expect(foodLookup.lastBarcode, isNull);
    expect(estimateService.photoCalls, 1);
    expect(boxes(tester), ['Musaka', '640', '28']);
  });

  testWidgets('without YumSum Star the photo button wears a star and sells '
      'Smart Snap instead of opening the camera', (tester) async {
    await pumpCard(tester, plus: false);
    expect(
      find.descendant(
        of: find.byTooltip('Take a photo'),
        matching: find.byType(PlusStar),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pumpAndSettle();
    expect(cameraModes, isEmpty);
    expect(find.text('Smart Snap'), findsOneWidget);
    expect(find.text('Skip the manual entry'), findsOneWidget);
    expect(find.text('Become a Star'), findsOneWidget);

    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Snap'), findsNothing);
    expect(estimateService.photoCalls, 0);
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
    await tester.enterText(find.byKey(const ValueKey('contribute-fat')), '5');
    await tester.enterText(
      find.byKey(const ValueKey('contribute-salt')),
      '1.5',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.tap(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.pumpAndSettle();

    final sent = contributor.sent.single;
    expect(photoSteps, [PhotoStep.frontOfPack, PhotoStep.nutritionTable]);
    expect(estimateService.readFront, isTrue);
    expect(sent.lang, 'bg');
    expect(sent.barcode, '3800000000017');
    expect(sent.brand, 'Първа преса');
    expect(sent.per100g, {
      'energy-kcal': 95.0,
      'proteins': 2.4,
      'fat': 5.0,
      'salt': 1.5,
    });
    expect(find.text('Thank you!'), findsOneWidget);

    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    // With no serving it starts at 100 g; the whole pack (260 g) is a chip.
    expect(find.text('Whole pack'), findsOneWidget);
    await tester.tap(find.text('Whole pack'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Лютеница', '247', '5']);
    expect(find.textContaining('isn\'t on Open Food Facts'), findsNothing);

    // Logged with the label's macros too.
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.savedMacros.single?.fat, closeTo(13, 0.1));
    expect(controller.savedMacros.single?.salt, closeTo(3.9, 0.1));
  });

  testWidgets('a listed product without calories gets only its nutrition '
      'added, then is logged', (tester) async {
    await pumpCard(tester, barcode: '3800000000024');
    foodLookup.food = null;
    foodLookup.needsNutrition = (
      name: 'Лютеница',
      brand: 'Първа преса',
      quantity: '260 g',
      servingSize: null,
      lang: 'bg',
      hasNutritionPhoto: false,
      imageUrl: null,
    );
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();

    expect(find.text('Be the first to add this'), findsNothing);
    expect(find.text('Add its nutrition'), findsOneWidget);
    await tester.tap(find.text('Contribute'));
    await tester.pumpAndSettle();

    // One photo, of the table; what the product has isn't asked for again.
    expect(photoSteps, [PhotoStep.nutritionTable]);
    expect(estimateService.readFront, isFalse);
    expect(find.text('Check the nutrition'), findsOneWidget);
    expect(find.byKey(const ValueKey('contribute-name')), findsNothing);
    expect(find.text('Brand'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.tap(find.widgetWithText(FilledButton, 'Contribute'));
    await tester.pumpAndSettle();

    final added = contributor.nutrition.single;
    expect(contributor.sent, isEmpty);
    expect(added.barcode, '3800000000024');
    expect(added.lang, 'bg');
    expect(added.name, isNull);
    expect(added.servingSize, isNull);
    expect(added.perVolume, isFalse);
    expect(added.per100g, {'energy-kcal': 95.0, 'proteins': 2.0});
    expect(added.labelPhoto, isNotNull);
    expect(
      find.textContaining('Лютеница now has its nutrition on Open Food Facts'),
      findsOneWidget,
    );

    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    // Open Food Facts' pack size (260 g) is a chip.
    await tester.tap(find.text('Whole pack'));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Лютеница', '247', '5']);
  });

  testWidgets('a spinner shows beside Working while it looks', (tester) async {
    await pumpCard(tester, barcode: '5000112637922');
    foodLookup.hold = Completer();
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pump();
    await tester.pump();

    final working = find.ancestor(
      of: find.text('Working...'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: working.first,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    foodLookup.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Working...'), findsNothing);
  });

  testWidgets('a listed product with calories but no name is not offered', (
    tester,
  ) async {
    await pumpCard(tester, barcode: '4000000000001');
    foodLookup.food = null;
    foodLookup.listed = true;
    await tester.tap(find.byTooltip('Scan a barcode'));
    await tester.pumpAndSettle();
    expect(find.text('Be the first to add this'), findsNothing);
    expect(find.text('Add its nutrition'), findsNothing);
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

  testWidgets('no search chip for a typed name while it is hidden', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'tikka wrap');
    await tester.pump();
    expect(find.text('Search foods'), findsNothing);
  }, skip: showFoodSearchChip);

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
    // Hidden for now (showFoodSearchChip); kept for when it's back.
  }, skip: !showFoodSearchChip);

  testWidgets('an idle box offers photo, barcode and mic; in use, one button', (
    tester,
  ) async {
    await pumpCard(tester);
    for (final way in ['Take a photo', 'Scan a barcode', 'Speak']) {
      expect(find.byTooltip(way), findsOneWidget);
    }
    expect(find.byTooltip('Clear'), findsNothing);
    expect(find.byTooltip('Save'), findsNothing);
    expect(find.byTooltip('Estimate'), findsNothing);

    // Tapping the box with the keyboard up makes room: the three slide
    // out for an Estimate button, which waits for a name.
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pumpAndSettle();
    for (final way in ['Take a photo', 'Scan a barcode', 'Speak']) {
      expect(find.byTooltip(way), findsNothing);
    }
    expect(button(tester, 'Estimate').onPressed, isNull);

    await tester.enterText(nameBox, 'wrap');
    await tester.pump();
    expect(find.byTooltip('Clear'), findsOneWidget);
    expect(button(tester, 'Estimate').onPressed, isNotNull);

    // With calories it saves.
    await tester.enterText(kcalBox, '450');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Estimate'), findsNothing);
    expect(find.byTooltip('Save'), findsOneWidget);

    // Cleared, once the keyboard is down, the three are back.
    await tester.tap(find.byTooltip('Clear'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(boxes(tester), ['', '', '']);
    expect(find.byTooltip('Save'), findsNothing);
    expect(find.byTooltip('Speak'), findsOneWidget);
  });

  testWidgets('a button\'s tooltip shows above it, clear of the navigation '
      'bar', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.resetPadding);
    await pumpCard(tester);
    // Where the bar lives: at the bottom of the screen.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: QuickLogBar()),
        ),
      ),
    );
    await tester.longPress(find.byTooltip('Take a photo'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Take a photo')).bottom,
      lessThan(tester.getRect(find.byTooltip('Take a photo')).top),
    );
  });

  testWidgets('with protein off there is no protein box and no protein in '
      'the breakdown', (tester) async {
    await pumpCard(tester, trackProtein: false);
    await tester.enterText(nameBox, 'chicken wrap');
    await tester.pumpAndSettle();
    expect(kcalBox, findsOneWidget);
    expect(proteinBox, findsNothing);

    await tester.tap(find.byTooltip('Estimate'));
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
    await tester.pumpAndSettle();
    expect(find.byTooltip('Estimate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers usual meals while the box is focused', (tester) async {
    await pumpCard(
      tester,
      recents: [
        _recent('Ham sandwich', 500, 20),
        _recent('Musaka', 640, 28),
        _recent('Ham sandwich', 480, 20, daysAgo: 2),
        _recent(
          'Chicken wrap',
          450,
          30,
          daysAgo: 2,
          macros: const Nutrients(fat: 15, salt: 1.8),
        ),
        _recent('Ham sandwich', 480, 20, daysAgo: 3),
      ],
    );
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);

    // Empty box: only what has been had at this time more than once.
    await tester.tap(nameBox);
    await tester.pump();
    expect(find.byType(ActionChip, skipOffstage: false), findsOneWidget);
    expect(chipNamed('Ham sandwich'), findsOneWidget);
    expect(
      find.descendant(
        of: chipNamed('Ham sandwich'),
        matching: find.text('· 500 kcal'),
      ),
      findsOneWidget,
    );

    await tester.enterText(nameBox, 'wrap');
    await tester.pump();
    expect(
      find.text('Search foods'),
      showFoodSearchChip ? findsOneWidget : findsNothing,
    );
    expect(chipNamed('Ham sandwich'), findsNothing);

    await tester.tap(chipNamed('Chicken wrap'));
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Chicken wrap', '450', '30']);
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 30.0),
    ]);
    expect(controller.savedMacros.single?.fat, 15);
    expect(controller.savedMacros.single?.salt, 1.8);
  });

  testWidgets('typing offers up to 10 chips; a long name is cut short '
      'and shown whole with its calories when held', (tester) async {
    const long =
        'Chicken, avocado and sweetcorn wrap with extra garlic mayonnaise';
    await pumpCard(
      tester,
      recents: [
        _recent(long, 620, 31),
        for (var i = 1; i <= 11; i++) _recent('Wrap $i', 400.0 + i, 20),
      ],
    );
    await tester.pump();
    await tester.tap(nameBox);
    await tester.pump();
    await tester.enterText(nameBox, 'wrap');
    await tester.pump();

    // The row builds what's on screen: scroll it to the end.
    final row = find
        .descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(chipNamed('Wrap 9'), 200, scrollable: row);
    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(chipNamed('Wrap 9'), findsOneWidget);
    expect(chipNamed('Wrap 10'), findsNothing);
    await tester.drag(row, const Offset(3000, 0));
    await tester.pumpAndSettle();

    final name = find.descendant(
      of: chipNamed(long),
      matching: find.text(long),
    );
    expect(tester.getSize(name).width, lessThanOrEqualTo(200));
    expect(
      find.descendant(of: chipNamed(long), matching: find.text('· 620 kcal')),
      findsOneWidget,
    );

    await tester.longPress(chipNamed(long));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('$long\n620 kcal · 31 g protein', findRichText: true),
      findsOneWidget,
    );
    // Holding doesn't log it.
    expect(boxes(tester).first, 'wrap');
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('a chip can be tapped as a browser taps, where pressing '
      'outside a box lets go of it', (tester) async {
    await pumpCard(
      tester,
      recents: [
        _recent('Ham sandwich', 500, 20),
        _recent('Ham sandwich', 480, 20, daysAgo: 2),
      ],
    );
    await tester.pump();
    await tester.tap(nameBox);
    await tester.pump();

    // A browser (and a mouse anywhere) lets go of a box when the pointer
    // goes down outside it; an empty bar would fold before the tap ends.
    final press = await tester.startGesture(
      tester.getCenter(chipNamed('Ham sandwich')),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await press.up();
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Ham sandwich', '500', '20']);
  });

  testWidgets('a chip can be tapped as iOS Safari taps, where touching '
      'outside a box drops it and the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await pumpCard(
      tester,
      recents: [
        _recent('Ham sandwich', 500, 20),
        _recent('Ham sandwich', 480, 20, daysAgo: 2),
      ],
    );
    await tester.pump();
    await tester.tap(nameBox);
    await tester.pump();

    // The browser lets go of the box, and the keyboard goes, as soon as the
    // finger touches the chip, before the tap ends.
    final press = await tester.startGesture(
      tester.getCenter(chipNamed('Ham sandwich')),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 100));
    await press.up();
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Ham sandwich', '500', '20']);
  });

  testWidgets('a typed recipe name offers a portion of it', (tester) async {
    await pumpCard(
      tester,
      recipes: [testRecipe('Pasta bolognese', kcal: 560, protein: 42)],
    );
    await tester.pump();
    await tester.tap(nameBox);
    await tester.pump();
    expect(find.byType(ActionChip), findsNothing);

    await tester.enterText(nameBox, 'bolo');
    await tester.pump();
    final chip = chipNamed('Pasta bolognese');
    expect(chip, findsOneWidget);
    expect(
      find.descendant(
        of: chip,
        matching: find.byIcon(Icons.menu_book_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(boxes(tester), ['Pasta bolognese', '560', '42']);
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.saved, [
      (name: 'Pasta bolognese', calories: 560.0, protein: 42.0),
    ]);
    expect(controller.savedMacros.single?.fat, 14);
  });

  testWidgets('the mic records a note and the AI fills the box from it', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(find.text(listening), findsOneWidget);

    recorder.audio.add(Uint8List(32000)); // one second of 16-bit mono
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(recorder.stopped, isTrue);
    expect(estimateService.heard!.length, 44 + 32000);
    expect(boxes(tester), ['Lunch', '400', '']);
  });

  testWidgets('the mic writes the words as they are said, and once the '
      'speaker stops they wait for the sparkle or the X', (tester) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(find.text(listening), findsOneWidget);
    // The bar opens as the mic starts, so nothing appears mid-sentence.
    expect(kcalBox, findsOneWidget);
    expect(speech.options!.localeId, 'en-GB');
    expect(speech.options!.pauseFor, const Duration(milliseconds: 2500));
    // The mic bubble, swelling with the voice; the box wraps a long meal.
    final bubble = find.byKey(const ValueKey('quick-log-listening'));
    expect(bubble, findsOneWidget);
    speech.onSoundLevel!(8);
    await tester.pumpAndSettle();
    final halo = tester.widget<Transform>(
      find.descendant(of: bubble, matching: find.byType(Transform)).first,
    );
    expect(halo.transform.getMaxScaleOnAxis(), closeTo(1.2 + 0.8 * 0.7, 1e-6));
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('quick-log-name')))
          .maxLines,
      3,
    );

    speech.say('two eggs');
    await tester.pump();
    expect(boxes(tester).first, 'two eggs');
    expect(estimateService.estimateCalls, 0);

    speech.say('two eggs on toast', last: true);
    await tester.pumpAndSettle();
    expect(find.text(listening), findsNothing);
    expect(bubble, findsNothing);
    // Nothing sent: the words sit in the box to be checked first.
    expect(estimateService.estimateCalls, 0);
    expect(boxes(tester), ['two eggs on toast', '', '']);
    expect(find.byTooltip('Clear'), findsOneWidget);

    await tester.tap(find.byTooltip('Estimate'));
    await tester.pumpAndSettle();
    expect(estimateService.described, 'two eggs on toast');
    expect(boxes(tester).take(2), ['two eggs on toast', '520']);
    expect(estimateService.heard, isNull);
  });

  testWidgets('misheard words are one tap from gone', (tester) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    speech.say('two legs on toast', last: true);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(boxes(tester).first, '');
    expect(estimateService.estimateCalls, 0);
  });

  testWidgets('in Bulgarian the recogniser listens for Bulgarian', (
    tester,
  ) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech, language: 'bg');
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(speech.options!.localeId, 'bg-BG');
  });

  testWidgets('stop keeps the words heard so far', (tester) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    speech.say('a banana');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();
    expect(speech.stopped, isTrue);
    expect(boxes(tester).first, 'a banana');
    expect(estimateService.estimateCalls, 0);
    expect(find.byTooltip('Estimate'), findsOneWidget);
  });

  testWidgets('silence from the recogniser is not sent to the AI', (
    tester,
  ) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech);
    for (final silence in [
      () => speech.statusListener!(SpeechToText.doneStatus),
      () => speech.errorListener!(SpeechRecognitionError('no-speech', true)),
    ]) {
      await tester.tap(find.byTooltip('Speak'));
      await tester.pump();
      silence();
      await tester.pumpAndSettle();
      expect(estimateService.estimateCalls, 0);
      expect(
        find.text('Didn\'t catch that. Tap the mic and try again.'),
        findsOneWidget,
      );
    }
    expect(recorder.stopped, isFalse);
  });

  testWidgets('without a recogniser the mic records a note for the AI, '
      'and keeps to that', (tester) async {
    final speech = _FakeSpeech(works: false);
    await pumpCard(tester, speech: speech);
    for (var note = 0; note < 2; note++) {
      estimateService.heard = null;
      await tester.tap(find.byTooltip('Speak'));
      await tester.pump();
      expect(find.text(listening), findsOneWidget);
      recorder.audio.add(Uint8List(32000));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Stop'));
      await tester.pumpAndSettle();
      expect(estimateService.heard, isNotNull);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
    }
    expect(speech.starts, 1);
  });

  testWidgets('a recogniser that can\'t listen in the language hands the '
      'note to the recorder', (tester) async {
    final speech = _FakeSpeech();
    await pumpCard(tester, speech: speech);
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    speech.errorListener!(
      SpeechRecognitionError('error_language_not_supported', true),
    );
    await tester.pumpAndSettle();

    expect(speech.cancelled, isTrue);
    expect(find.text(listening), findsOneWidget);
    recorder.audio.add(Uint8List(32000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();
    expect(estimateService.heard, isNotNull);
    expect(boxes(tester).take(2), ['Lunch', '400']);
  });

  testWidgets('the mic says so before recording once the AI is used up', (
    tester,
  ) async {
    await pumpCard(tester, aiUsed: 10, plus: false);
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

  testWidgets('YumSum Star has 30 AI estimates a day', (tester) async {
    await pumpCard(tester, aiUsed: 27);
    await tester.pump();
    await tester.enterText(nameBox, 'Wrap');
    await tester.pump();
    expect(find.text('3 AI estimates left today'), findsOneWidget);
  });

  testWidgets('what is left of the AI shows once half is used', (tester) async {
    await pumpCard(tester, aiUsed: 7, plus: false);
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
    await pumpCard(tester, aiUsed: 4, plus: false);
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
    await tester.pumpAndSettle();
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

      await tester.pumpAndSettle();
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

    await tester.pumpAndSettle();
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

    expect(chipNamed('Chicken wrap'), findsOneWidget);
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
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();

    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 35.0),
    ]);
  });

  final clock = find.byTooltip('Time eaten');

  /// The time the clock reads, null while it shows Now (the clock icon).
  String? clockLabel(WidgetTester tester) {
    final time = find.descendant(
      of: find.byKey(const ValueKey('quick-log-time')),
      matching: find.byType(Text),
    );
    if (time.evaluate().isEmpty) {
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      return null;
    }
    return tester.widget<Text>(time).data;
  }

  /// Opens the bar with the keyboard up, then the time picker over it,
  /// which takes the focus so the keyboard goes.
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(clock);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
  }

  testWidgets('the clock shows Now, coming with the number boxes', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(clock, findsNothing);

    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pump();
    // In the same frame as the boxes, at the end of their row.
    expect(kcalBox, findsOneWidget);
    expect(clock, findsOneWidget);
    expect(clockLabel(tester), isNull);
    expect(tester.getCenter(clock).dy, tester.getCenter(kcalBox).dy);
    // Once the buttons have swapped, under the one beside the name box,
    // with the boxes ending where the name box does.
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(clock).dx,
      tester.getCenter(find.byTooltip('Estimate')).dx,
    );
    expect(tester.getTopRight(proteinBox).dx, tester.getTopRight(nameBox).dx);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(kcalBox, findsNothing);
    expect(clock, findsNothing);
  });

  testWidgets('a picked time is the one the meal is saved at; the next is '
      'Now again', (tester) async {
    await pumpCard(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pump();
    await tester.enterText(nameBox, 'porridge');
    await tester.enterText(kcalBox, '350');
    await tester.pump();

    await openPicker(tester);
    await pickTime(tester, 8, 5);
    expect(clockLabel(tester), '08:05');

    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.saved, [
      (name: 'Porridge', calories: 350.0, protein: null),
    ]);
    expect(controller.savedTimes, [const TimeOfDay(hour: 8, minute: 5)]);

    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    await tester.tap(nameBox);
    await tester.pump();
    expect(clockLabel(tester), isNull);
  });

  testWidgets('a meal saved without a picked time is saved at Now', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(nameBox, 'porridge');
    await tester.pump();
    await tester.enterText(kcalBox, '350');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(controller.savedTimes, [null]);
  });

  testWidgets('Clear takes the time back to Now', (tester) async {
    await pumpCard(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pump();
    await tester.enterText(nameBox, 'porridge');
    await tester.pump();
    await openPicker(tester);
    await pickTime(tester, 8, 0);
    expect(clockLabel(tester), '08:00');

    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(boxes(tester), ['', '', '']);
    expect(clockLabel(tester), isNull);
  });

  testWidgets('the bar stays as it was while the picker is up, and a picked '
      'time keeps it open until cleared', (tester) async {
    await pumpCard(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(nameBox);
    await tester.pump();

    // The empty bar doesn't fold under the picker as the keyboard goes.
    await openPicker(tester);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(kcalBox, findsOneWidget);
    expect(find.byTooltip('Estimate'), findsOneWidget);
    await pickTime(tester, 12, 30);

    // Let go of the box: still open with the time, and the X clears it.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(clockLabel(tester), '12:30');
    expect(kcalBox, findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(kcalBox, findsNothing);
    expect(find.byTooltip('Speak'), findsOneWidget);
  });

  testWidgets('the clock is greyed while the mic listens', (tester) async {
    await pumpCard(tester, speech: _FakeSpeech());
    await tester.tap(find.byTooltip('Speak'));
    await tester.pump();
    expect(find.text(listening), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.byKey(const ValueKey('quick-log-time')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('in Bulgarian on a 360dp phone the clock fits beside the '
      'number boxes, and a three-digit protein with its unit in its box', (
    tester,
  ) async {
    // The app's own font, so the widths are the real ones. Loaded last in
    // this file, as it changes every later test's text widths.
    final nunito = FontLoader('Nunito');
    for (final file in ['Nunito-Regular', 'Nunito-SemiBold', 'Nunito-Bold']) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      nunito.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await nunito.load();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCard(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('bg'),
          home: const Scaffold(body: QuickLogBar()),
        ),
      ),
    );
    await tester.enterText(nameBox, 'мусака');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Кога хапна'), findsOneWidget);
    expect(clockLabel(tester), isNull);
    // The bar's 18 px sides, the 12 px gap, and the clock and its gap.
    expect(tester.getSize(proteinBox).width, (360 - 36 - 12 - 10 - 44) / 2);

    await tester.enterText(proteinBox, '120');
    await tester.pumpAndSettle();
    expect(find.text('г'), findsOneWidget);
    final input = tester
        .state<EditableTextState>(
          find.descendant(of: proteinBox, matching: find.byType(EditableText)),
        )
        .renderEditable;
    expect(
      input.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(input.size.width),
    );
    expect(tester.takeException(), isNull);
  });
}
