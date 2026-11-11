import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';

void main() {
  Future<bool> asksForMacros({
    required bool shown,
    required Entitlement? real,
  }) async {
    final container = ProviderContainer(
      overrides: [
        plusProvider.overrideWith((ref) => shown),
        realEntitlementProvider.overrideWith((ref) => Stream.value(real)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(aiMacrosProvider, (_, _) {});
    await container.read(realEntitlementProvider.future);
    return container.read(aiMacrosProvider);
  }

  const owner = Entitlement(
    active: true,
    source: EntitlementSource.manual,
    admin: true,
  );

  test(
    'pretending to have YumSum Star never asks the server for macros',
    () async {
      expect(await asksForMacros(shown: true, real: null), isFalse);
    },
  );

  test('YumSum Star shown and on the real record asks for macros', () async {
    expect(await asksForMacros(shown: true, real: owner), isTrue);
  });

  test('pretending to be free leaves macros out', () async {
    expect(await asksForMacros(shown: false, real: owner), isFalse);
  });

  test('10 AI estimates a day free, 30 with YumSum Star, none for the '
      'owner', () {
    int? limit({required bool plus, bool admin = false}) {
      final container = ProviderContainer(
        overrides: [
          plusProvider.overrideWithValue(plus),
          adminProvider.overrideWithValue(admin),
        ],
      );
      addTearDown(container.dispose);
      return container.read(aiDailyLimitProvider);
    }

    expect(limit(plus: false), 10);
    expect(limit(plus: true), 30);
    expect(limit(plus: true, admin: true), isNull);
  });
}
