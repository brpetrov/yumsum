import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/account_provider.dart';
import 'package:lean_streak/providers/adaptive_formula_provider.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// Whether [user] can sign in with a password; an account made with Google
/// only can't, so it has no password to change or confirm with.
bool hasPasswordLogin(User user) =>
    user.providerData.any((info) => info.providerId == 'password');

class AccountActionException implements Exception {
  const AccountActionException(this.message);

  /// Shown as it is, so in the app's language.
  final String message;

  @override
  String toString() => message;
}

class AccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> syncAuthEmailToProfile() async {
    final uid = ref.read(currentUidProvider);
    final authEmail = FirebaseAuth.instance.currentUser?.email;
    final profile = ref.read(userProfileProvider).valueOrNull;

    if (uid == null ||
        authEmail == null ||
        authEmail.isEmpty ||
        profile == null ||
        profile.email == authEmail) {
      return;
    }

    await ref.read(userProfileRepositoryProvider).updateProfile(uid, {
      'email': authEmail,
    });
  }

  Future<void> updateAccountName({required String name}) async {
    state = const AsyncLoading();

    try {
      final uid = ref.read(currentUidProvider);
      final trimmedName = name.trim();
      if (uid == null) {
        throw AccountActionException(_l10n.accountErrorSignedOut);
      }
      if (trimmedName.isEmpty) {
        throw AccountActionException(_l10n.accountEnterName);
      }

      await ref.read(userProfileRepositoryProvider).updateProfile(uid, {
        'name': trimmedName,
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(trimmedName);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail() async {
    state = const AsyncLoading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw AccountActionException(_l10n.accountErrorNoEmail);
      }

      await sendResetEmail(ref, email);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      throw AccountActionException(_mapAuthError(error));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendEmailChangeVerification({
    required String newEmail,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final trimmedEmail = newEmail.trim();
      if (trimmedEmail.isEmpty) {
        throw AccountActionException(_l10n.accountErrorEnterNewEmail);
      }

      final user = await _reauthenticate(password);
      final currentEmail = user.email;
      if (currentEmail != null &&
          currentEmail.toLowerCase() == trimmedEmail.toLowerCase()) {
        throw AccountActionException(_l10n.accountErrorSameEmail);
      }

      await user.verifyBeforeUpdateEmail(trimmedEmail);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      throw AccountActionException(_mapAuthError(error));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resetAllData({required String password}) async {
    state = const AsyncLoading();

    try {
      final user = await _reauthenticate(password);
      await ref.read(accountRepositoryProvider).resetAllData(user.uid);
      await resetAdaptive(ref, user.uid);
      refreshHistory(ref);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    state = const AsyncLoading();

    try {
      final user = await _reauthenticate(password);
      // The YumSum Star record is the server's, so only the server can
      // delete it. Only an account that ever had YumSum Star has one.
      if (await ref.read(realEntitlementProvider.future) != null) {
        await ref.read(billingRepositoryProvider).deleteBillingData();
      }
      final accounts = ref.read(accountRepositoryProvider);
      await accounts.deleteAccountData(user.uid);
      // The server deletes the login too, with the counters, so they can't
      // be reset without the account going.
      await accounts.deleteAccount();
      await FirebaseAuth.instance.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<User> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = ref.read(currentUidProvider);

    if (user == null || uid == null) {
      throw AccountActionException(_l10n.accountErrorSignedOut);
    }

    // A Google account has no password, so it confirms with Google and
    // [password] is ignored. Closing the picker is rethrown as it is
    // ([backedOutOfGoogle]), for the screen to treat as a cancel.
    if (!hasPasswordLogin(user)) {
      try {
        if (kIsWeb) {
          await user.reauthenticateWithPopup(GoogleAuthProvider());
        } else {
          final account = await (await googleSignIn()).authenticate();
          await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(
              idToken: account.authentication.idToken,
            ),
          );
        }
        return user;
      } on FirebaseAuthException catch (error) {
        if (backedOutOfGoogle(error)) rethrow;
        throw AccountActionException(
          error.code == 'user-mismatch'
              ? _l10n.accountErrorWrongGoogle
              : _mapAuthError(error),
        );
      }
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw AccountActionException(_l10n.accountErrorNoPassword);
    }

    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) {
      throw AccountActionException(_l10n.commonEnterPassword);
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: trimmedPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return user;
    } on FirebaseAuthException catch (error) {
      throw AccountActionException(_mapAuthError(error));
    }
  }

  AppLocalizations get _l10n => ref.read(l10nProvider);

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
        return _l10n.accountErrorWrongPassword;
      case 'too-many-requests':
        return _l10n.commonErrorTooManyAttempts;
      case 'network-request-failed':
        return _l10n.accountErrorNoConnection;
      case 'invalid-email':
        return _l10n.commonEnterValidEmailAddress;
      case 'email-already-in-use':
        return _l10n.accountErrorEmailInUse;
      case 'requires-recent-login':
        return _l10n.accountErrorConfirmPassword;
      default:
        return _l10n.accountErrorVerifyPassword;
    }
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);
