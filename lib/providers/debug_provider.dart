import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/preferences_provider.dart';

/// Who Debug tools pretend the account is, to try each YumSum Star state
/// without touching Firestore.
enum DebugAccount {
  real('Your real account'),
  free('Free'),
  plus('YumSum Star'),
  trialEnding('YumSum Star trial, ending in 2 days'),
  ended('YumSum Star ended 3 days ago'),
  admin('Admin');

  const DebugAccount(this.label);

  final String label;

  /// The record the app sees instead of the real one.
  Entitlement? entitlementAt(DateTime now) => switch (this) {
    real || free => null,
    plus => Entitlement(
      active: true,
      source: EntitlementSource.play,
      state: 'active',
      expiresAt: now.add(const Duration(days: 30)),
    ),
    trialEnding => Entitlement(
      active: true,
      source: EntitlementSource.play,
      state: 'active',
      inTrial: true,
      expiresAt: now.add(const Duration(days: 2)),
    ),
    ended => Entitlement(
      active: false,
      source: EntitlementSource.play,
      state: 'expired',
      expiresAt: now.subtract(const Duration(days: 3)),
    ),
    admin => const Entitlement(
      active: true,
      source: EntitlementSource.manual,
      admin: true,
    ),
  };
}

/// The debug tools' "Pretend to be", kept on the device. It only counts
/// where Debug tools are on offer (`debugToolsProvider`).
class DebugAccountNotifier extends Notifier<DebugAccount> {
  static const _key = 'debug.account';

  @override
  DebugAccount build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return DebugAccount.values.firstWhere(
      (account) => account.name == saved,
      orElse: () => DebugAccount.real,
    );
  }

  Future<void> set(DebugAccount account) async {
    state = account;
    await ref.read(sharedPreferencesProvider).setString(_key, account.name);
  }
}

final debugAccountProvider =
    NotifierProvider<DebugAccountNotifier, DebugAccount>(
      DebugAccountNotifier.new,
    );

/// Debug tools "Go through onboarding again": while on, the router lets a
/// finished account open onboarding, and Start or Back on its first card
/// goes back to Debug tools without saving anything.
final onboardingPreviewProvider = StateProvider<bool>((ref) => false);
