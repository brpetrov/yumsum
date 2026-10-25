import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/providers/account_provider.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/daily_summary_provider.dart';
import 'package:lean_streak/providers/meal_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';

/// Whether [user] can sign in with a password; an account made with Google
/// only can't, so it has no password to change or confirm with.
bool hasPasswordLogin(User user) =>
    user.providerData.any((info) => info.providerId == 'password');

class AccountActionException implements Exception {
  const AccountActionException(this.message);

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
        throw const AccountActionException('You are not signed in.');
      }
      if (trimmedName.isEmpty) {
        throw const AccountActionException('Enter your name.');
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
        throw const AccountActionException(
          'This account does not have an email address.',
        );
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
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
        throw const AccountActionException('Enter a new email address.');
      }

      final user = await _reauthenticate(password);
      final currentEmail = user.email;
      if (currentEmail != null &&
          currentEmail.toLowerCase() == trimmedEmail.toLowerCase()) {
        throw const AccountActionException('That\'s already your email.');
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
      ref.invalidate(dailySummaryRepositoryProvider);
      ref.invalidate(recentMealsProvider);
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
      await ref.read(accountRepositoryProvider).deleteAccountData(user.uid);
      await user.delete();
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
      throw const AccountActionException('You are not signed in.');
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
              ? 'Choose the Google account you signed in with.'
              : _mapAuthError(error),
        );
      }
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AccountActionException(
        'This account cannot confirm with a password.',
      );
    }

    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) {
      throw const AccountActionException('Enter your password.');
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

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Could not connect. Check your internet and try again.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already uses that email address.';
      case 'requires-recent-login':
        return 'Confirm your password and try again.';
      default:
        return 'Could not verify your password.';
    }
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);
