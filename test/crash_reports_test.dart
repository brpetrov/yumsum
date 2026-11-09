import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/config/crash_reports.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';

class _Saver extends AsyncNotifier<int> {
  @override
  Future<int> build() async => 0;

  Future<void> fail(Object error) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => throw error);
  }
}

final _saverProvider = AsyncNotifierProvider<_Saver, int>(_Saver.new);

void main() {
  test('a provider turning to an error is reported once per error', () async {
    final reports = <String>[];
    final container = ProviderContainer(
      observers: [
        CrashReportObserver(
          report: (error, _, reason) => reports.add('$reason: $error'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(_saverProvider.future);
    final saver = container.read(_saverProvider.notifier);

    await saver.fail(StateError('disk full'));
    expect(reports, hasLength(1));
    expect(reports.single, contains('disk full'));
    await saver.fail(StateError('again'));
    expect(reports, hasLength(2));
  });

  test("the user's and the network's errors aren't the app's", () {
    expect(expectedError(const EditLimitExceededException()), isTrue);
    expect(
      expectedError(
        FirebaseFunctionsException(message: 'x', code: 'unavailable'),
      ),
      isTrue,
    );
    expect(
      expectedError(FirebaseFunctionsException(message: 'x', code: 'internal')),
      isFalse,
    );
    expect(expectedError(StateError('bug')), isFalse);
  });
}
