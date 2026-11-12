import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:lean_streak/screens/auth/auth_screen.dart';
import 'package:lean_streak/screens/dashboard/dashboard_screen.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_camera_page.dart';
import 'package:lean_streak/screens/dashboard/helpers/meal_photo.dart';
import 'package:lean_streak/screens/debug/debug_screen.dart';
import 'package:lean_streak/screens/language/language_screen.dart';
import 'package:lean_streak/screens/onboarding/onboarding_screen.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/screens/profile/profile_load_error_screen.dart';
import 'package:lean_streak/screens/profile/profile_screen.dart';
import 'package:lean_streak/screens/progress/progress_screen.dart';
import 'package:lean_streak/screens/recipes/recipe_screen.dart';
import 'package:lean_streak/screens/recipes/recipes_screen.dart';
import 'package:lean_streak/screens/coach/coach_screen.dart';
import 'package:lean_streak/screens/review/review_screen.dart';
import 'package:lean_streak/widgets/splash_screen.dart';

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const language = '/language';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const profileLoadError = '/profile-load-error';
  static const dashboard = '/dashboard';
  static const review = '/review';
  static const coach = '/coach';
  static const profile = '/profile';
  static const planSettings = '/plan-settings';
  static const progress = '/progress';
  static const recipes = '/recipes';
  static const recipe = '/recipes/:id';
  static String recipePath(String id) => '/recipes/$id';
  static const plus = '/plus';
  static const debug = '/debug';
  static const camera = '/camera';
}

/// The bar's camera page, pushed by openMealCamera and takeProductPhotos
/// with the photo steps as `extra`, none for a barcode. A route of its own,
/// so a browser's Back closes it as it does the other pages (pushed with
/// the Navigator, it added no history entry and Back left it open). A
/// reload, which has no steps, goes Home.
final cameraRoute = GoRoute(
  path: AppRoutes.camera,
  redirect: (context, state) =>
      state.extra is List<PhotoStep> ? null : AppRoutes.dashboard,
  pageBuilder: (context, state) {
    final steps = state.extra! as List<PhotoStep>;
    return MaterialPage(
      key: state.pageKey,
      fullscreenDialog: true,
      child: steps.isEmpty
          ? const MealCameraPage.barcode()
          : MealCameraPage.photos(photoSteps: steps),
    );
  },
);

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

    // The first-launch language question answered.
    ref.listen<bool>(languagePromptProvider, (_, _) => notifyListeners());

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
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
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
        path: AppRoutes.coach,
        builder: (context, state) =>
            CoachScreen(week: state.uri.queryParameters['week']),
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
        path: AppRoutes.recipes,
        builder: (context, state) => const RecipesScreen(),
      ),
      GoRoute(
        path: AppRoutes.recipe,
        builder: (context, state) => RecipeScreen(
          recipeId: state.pathParameters['id']!,
          recipe: state.extra is Recipe ? state.extra! as Recipe : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.plus,
        builder: (context, state) => const PlusScreen(),
      ),
      GoRoute(
        path: AppRoutes.debug,
        // Only where the menu offers it: debug builds and dev accounts.
        redirect: (context, state) =>
            ref.read(debugToolsProvider) ? null : AppRoutes.dashboard,
        builder: (context, state) => const DebugScreen(),
      ),
      cameraRoute,
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

  // 0. First launch in Bulgaria or Malta, or in Bulgarian: ask the language
  // before anything else. Once chosen, the steps below move on from it.
  if (ref.read(languagePromptProvider)) {
    return location == AppRoutes.language ? null : AppRoutes.language;
  }

  // 1. Firebase still initialising — hold on splash.
  if (authValue.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // A password account counts as signed in only once its email is verified,
  // as in signIn. Sign-up is signed in while it sends the link, which
  // showed onboarding for a moment (12 November 2026). Google sign-in has
  // no such check, so Google accounts aren't held here either.
  final user = authValue.valueOrNull;
  final isAuthenticated =
      user != null && (user.emailVerified || !hasPasswordLogin(user));

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

  // Debug tools' preview of onboarding, for a finished account, from its
  // language question.
  if ((location == AppRoutes.onboarding || location == AppRoutes.language) &&
      ref.read(onboardingPreviewProvider)) {
    return null;
  }

  // 4. Fully set up — bounce off auth / splash / onboarding.
  if (location == AppRoutes.splash ||
      location == AppRoutes.language ||
      location == AppRoutes.auth ||
      location == AppRoutes.profileLoadError ||
      location == AppRoutes.onboarding) {
    return AppRoutes.dashboard;
  }

  return null;
}
