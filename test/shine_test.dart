import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/widgets/shine.dart';

void main() {
  Widget shining({bool lessMotion = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: lessMotion),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: Shine(child: SizedBox(width: 40, height: 20)),
    ),
  );

  testWidgets('sweeps three times, then rests', (tester) async {
    await tester.pumpWidget(shining());
    expect(find.byType(ShaderMask), findsOneWidget);
    // Still going after two sweeps.
    await tester.pump(const Duration(milliseconds: 3600));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Done after the third.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('shines again when a page on top goes, not after a dialog', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Shine(child: SizedBox(width: 40, height: 20)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // A dialog over it and closed: it settles as soon as the dialog has
    // gone, a few frames.
    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const SizedBox(),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    expect(await tester.pumpAndSettle(), lessThan(10));

    // A page over it and back: three sweeps again, over 5 seconds of
    // 100 ms frames.
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    expect(await tester.pumpAndSettle(), greaterThan(50));
  });

  testWidgets('none when the phone asks for less motion', (tester) async {
    await tester.pumpWidget(shining(lessMotion: true));
    expect(find.byType(ShaderMask), findsNothing);
  });
}
