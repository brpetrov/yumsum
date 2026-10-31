import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/widgets/pack_photo.dart';

void main() {
  Future<void> pumpPhoto(WidgetTester tester, String? url) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: PackPhoto(url))),
    ),
  );

  testWidgets('a spinner while the photo is on its way, a box without one', (
    tester,
  ) async {
    await pumpPhoto(tester, 'https://images.openfoodfacts.org/w.200.jpg');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpPhoto(tester, null);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
