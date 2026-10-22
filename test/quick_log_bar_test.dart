import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lean_streak/app/launch_actions.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/barcode_scan_page.dart';
import 'package:lean_streak/screens/dashboard/helpers/quick_log_bar.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';
import 'package:record/record.dart';

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
      note: 'Typical wrap.',
      items: const [
        (name: 'Chicken wrap', kcal: 400, protein: 30),
        (name: 'Mayo', kcal: 120, protein: 2),
      ],
    );
  }

  Uint8List? heard;

  @override
  Future<VoiceMealParsed> parseVoiceAudio(Uint8List wav) async {
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

  @override
  Future<VoiceMealParsed> estimateFromPhoto(String uid, Uint8List jpeg) =>
      throw UnimplementedError();
}

/// A microphone that plays back whatever the test feeds it.
class _FakeFoodLookup implements FoodLookupService {
  PackagedFood? food = (
    name: 'Chicken Tikka Wrap',
    brand: 'Tesco',
    kcalPer100g: 215,
    proteinPer100g: 9,
    servingGrams: 220,
  );
  String? lastBarcode;

  @override
  Future<PackagedFood?> byBarcode(String barcode) async {
    lastBarcode = barcode;
    return food;
  }
}

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

  Future<void> pumpCard(
    WidgetTester tester, {
    List<Meal> recents = const [],
    LaunchAction? launchAction,
    String? scanned,
  }) async {
    controller = _FakeLogMealController();
    estimateService = _FakeEstimateService();
    recorder = _FakeRecorder();
    foodLookup = _FakeFoodLookup();
    container = ProviderContainer(
      overrides: [
        logMealControllerProvider.overrideWith(() => controller),
        calorieEstimateServiceProvider.overrideWithValue(estimateService),
        currentUidProvider.overrideWithValue('user-1'),
        recentMealsProvider.overrideWith((ref) async => recents),
        audioRecorderProvider.overrideWithValue(recorder),
        barcodeScannerProvider.overrideWithValue((_) async => scanned),
        foodLookupServiceProvider.overrideWithValue(foodLookup),
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

  String boxText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('saves typed name and calories without calling the AI', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), 'chicken wrap 450');
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal'), findsOneWidget);
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();

    // Protein for typed meals is filled in by the controller, not the box.
    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: null),
    ]);
    expect(estimateService.estimateCalls, 0);
    expect(boxText(tester), isEmpty);
  });

  testWidgets('estimates calories when none are typed, then waits for Save', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), 'chicken wrap');
    await tester.pump();

    await tester.tap(find.byTooltip('Estimate with AI'));
    await tester.pump();
    await tester.pump();

    expect(boxText(tester), 'chicken wrap 520 kcal 32g protein');
    expect(find.text('Chicken wrap · 520 kcal · 32 g protein'), findsOneWidget);
    expect(find.byTooltip('Save'), findsOneWidget);
    expect(controller.saved, isEmpty);

    // The breakdown is one muted line until tapped.
    expect(find.text('Chicken wrap 400 · Mayo 120'), findsOneWidget);
    expect(find.text('120 kcal · 2 g'), findsNothing);
    await tester.tap(find.text('Chicken wrap 400 · Mayo 120'));
    await tester.pump();
    expect(find.text('120 kcal · 2 g'), findsOneWidget);
    expect(find.text('400 kcal · 30 g'), findsOneWidget);
  });

  testWidgets('a scanned barcode is looked up and the portion fills the box', (
    tester,
  ) async {
    await pumpCard(tester, scanned: '5000112637922');
    await tester.tap(find.byTooltip('Scan barcode'));
    await tester.pumpAndSettle();

    expect(foodLookup.lastBarcode, '5000112637922');
    expect(find.text('Chicken Tikka Wrap'), findsOneWidget);
    final grams = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '220',
    );
    expect(grams, findsOneWidget);

    await tester.enterText(grams, '150');
    await tester.pump();
    await tester.tap(find.text('Use'));
    await tester.pumpAndSettle();

    expect(boxText(tester), 'Chicken Tikka Wrap 323 kcal 14g protein');
    expect(estimateService.estimateCalls, 0);
  });

  testWidgets('an unknown barcode says so', (tester) async {
    await pumpCard(tester, scanned: '4000000000000');
    foodLookup.food = null;
    await tester.tap(find.byTooltip('Scan barcode'));
    await tester.pumpAndSettle();
    expect(find.textContaining('isn\'t in the food database'), findsOneWidget);
    expect(boxText(tester), isEmpty);
  });

  testWidgets('backing out of the scanner changes nothing', (tester) async {
    await pumpCard(tester, scanned: null);
    await tester.tap(find.byTooltip('Scan barcode'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(boxText(tester), isEmpty);
  });

  testWidgets('the box offers the camera when empty and clear when not', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(find.byTooltip('Scan barcode'), findsOneWidget);
    expect(find.byTooltip('Photo'), findsOneWidget);
    expect(find.byTooltip('Clear'), findsNothing);

    await tester.enterText(find.byType(TextField), 'wrap');
    await tester.pump();
    expect(find.byTooltip('Photo'), findsNothing);
    expect(find.byTooltip('Clear'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(boxText(tester), isEmpty);
    expect(find.byTooltip('Photo'), findsOneWidget);
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
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.byType(ActionChip, skipOffstage: false), findsOneWidget);
    expect(find.text('Ham sandwich · 500 kcal'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wrap');
    await tester.pump();
    expect(find.byType(ActionChip), findsOneWidget);

    await tester.tap(find.text('Chicken wrap · 450 kcal'));
    await tester.pump();
    expect(boxText(tester), 'Chicken wrap 450 kcal 30g protein');
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.byTooltip('Save'));
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
    expect(
      find.text('Listening... tap stop when you\'re done.'),
      findsOneWidget,
    );

    recorder.audio.add(Uint8List(32000)); // one second of 16-bit mono
    await tester.pump();
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(recorder.stopped, isTrue);
    expect(estimateService.heard!.length, 44 + 32000);
    expect(boxText(tester), 'Lunch 400 kcal');
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

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(container.read(launchActionProvider), isNull);
    await tester.pump(const Duration(milliseconds: 500)); // the keyboard retry
  });

  testWidgets('the first keystroke keeps the same field and its focus', (
    tester,
  ) async {
    // No chips: the status line is the first thing to appear above the field.
    await pumpCard(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final before = tester.state<EditableTextState>(find.byType(EditableText));

    // The status line appears above the field on the first character; the
    // field must not be rebuilt as a new widget (which drops the keyboard).
    await tester.enterText(find.byType(TextField), 'c');
    await tester.pump();

    final after = tester.state<EditableTextState>(find.byType(EditableText));
    expect(after, same(before));
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
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
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final before = tester.state<EditableTextState>(find.byType(EditableText));

    await tester.enterText(find.byType(TextField), 'c');
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal'), findsOneWidget);
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(before),
    );
  });

  testWidgets('keyboard done saves when calories are present', (tester) async {
    await pumpCard(tester);
    await tester.enterText(find.byType(TextField), '450 kcal porridge');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.saved, [
      (name: 'Porridge', calories: 450.0, protein: null),
    ]);
  });

  testWidgets('saves protein typed into the box', (tester) async {
    await pumpCard(tester);
    await tester.enterText(
      find.byType(TextField),
      'chicken wrap 450 35g protein',
    );
    await tester.pump();

    expect(find.text('Chicken wrap · 450 kcal · 35 g protein'), findsOneWidget);
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();

    expect(controller.saved, [
      (name: 'Chicken wrap', calories: 450.0, protein: 35.0),
    ]);
  });
}
