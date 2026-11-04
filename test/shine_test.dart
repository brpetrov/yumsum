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

  testWidgets('none when the phone asks for less motion', (tester) async {
    await tester.pumpWidget(shining(lessMotion: true));
    expect(find.byType(ShaderMask), findsNothing);
  });
}
