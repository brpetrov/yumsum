import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';
import 'package:lean_streak/screens/dashboard/dashboard_screen.dart';
import 'package:lean_streak/screens/notifications/notifications_screen.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:lean_streak/screens/profile/profile_load_error_screen.dart';
import 'package:lean_streak/screens/profile/profile_screen.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/widgets/splash_screen.dart';

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const profileLoadError = '/profile-load-error';
  static const dashboard = '/dashboard';
  static const review = '/review';
  static const profile = '/profile';
  static const planSettings = '/plan-settings';
  static const progress = '/progress';
  static const notifications = '/notifications';
}

// ---------------------------------------------------------------------------
// Notifier — re-triggers GoRouter whenever auth or onboarding state changes.
// ---------------------------------------------------------------------------
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // Auth state changes.
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });

    // Onboarding completion changes.
    ref.listen(userProfileProvider, (previous, next) {
      final prevDone = previous?.valueOrNull?.onboardingCompleted;
      final nextDone = next.valueOrNull?.onboardingCompleted;
      if (prevDone != nextDone ||
          previous?.isLoading != next.isLoading ||
          previous?.hasError != next.hasError) {
        notifyListeners();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// GoRouter provider
// ---------------------------------------------------------------------------
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileLoadError,
        builder: (context, state) => const ProfileLoadErrorScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.planSettings,
        builder: (context, state) => const PlanSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

// ---------------------------------------------------------------------------
// Redirect logic
// ---------------------------------------------------------------------------
String? _redirect(Ref ref, GoRouterState state) {
  final authValue = ref.read(authStateProvider);
  final location = state.matchedLocation;

  // 1. Firebase still initialising — hold on splash.
  if (authValue.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final isAuthenticated = authValue.valueOrNull != null;

  // 2. Not signed in — send to auth.
  if (!isAuthenticated) {
    return location == AppRoutes.auth ? null : AppRoutes.auth;
  }

  // 3. Signed in — check onboarding.
  final profileValue = ref.read(userProfileProvider);

  // Profile stream still loading — hold on splash.
  if (profileValue.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (profileValue.hasError) {
    return location == AppRoutes.profileLoadError
        ? null
        : AppRoutes.profileLoadError;
  }

  final profile = profileValue.valueOrNull;
  final onboardingDone = profile?.onboardingCompleted ?? false;

  // No profile or onboarding incomplete — send to onboarding.
  if (!onboardingDone) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  // 4. Fully set up — bounce off auth / splash / onboarding.
  if (location == AppRoutes.splash ||
      location == AppRoutes.auth ||
      location == AppRoutes.profileLoadError ||
      location == AppRoutes.onboarding) {
    return AppRoutes.dashboard;
  }

  return null;
}
