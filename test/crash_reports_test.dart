import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  test("sign-in errors are the user's only when the user caused them", () {
    for (final code in [
      'wrong-password',
      'invalid-credential',
      'too-many-requests',
    ]) {
      expect(
        expectedError(FirebaseAuthException(code: code)),
        isTrue,
        reason: code,
      );
    }
    // Set-up faults: reported.
    for (final code in [
      'internal-error',
      'operation-not-allowed',
      'app-not-authorized',
    ]) {
      expect(
        expectedError(FirebaseAuthException(code: code)),
        isFalse,
        reason: code,
      );
    }
    // Backing out of Google's picker is the user's; a broken picker isn't.
    expect(
      expectedError(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      isTrue,
    );
    expect(
      expectedError(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
      isFalse,
    );
  });

  test('reporting before Firebase is up (or in a test) does nothing', () {
    expect(() => reportError(StateError('bug'), null, 'test'), returnsNormally);
    expect(() => reportFault(StateError('bug'), null, 'test'), returnsNormally);
  });
}
