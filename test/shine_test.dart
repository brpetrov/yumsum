import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('rests with no glint when the last frame comes late', (
    tester,
  ) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: boundary,
            child: const Shine(
              child: ColoredBox(
                color: Colors.black,
                child: SizedBox(width: 40, height: 20),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // A slow frame, such as a dialog opening, lands 540 ms after the third
    // sweep ends: a third of the way into a fourth, glint mid-box.
    await tester.pump(const Duration(milliseconds: 1800 * 3 + 540));
    expect(tester.binding.hasScheduledFrame, isFalse);

    final middle = await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = (await image.toByteData())!;
      return bytes.getUint8((10 * image.width + 20) * 4);
    });
    expect(middle, 0);
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
