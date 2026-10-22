# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run -d edge            # Run web (primary target; -d chrome where Chrome is installed)
flutter run -d android          # Run on Android device/emulator
flutter test                    # Run all tests
flutter test test/health_calculator_test.dart   # Run a single test file
flutter analyze                 # Lint (uses flutter_lints)
firebase deploy --only hosting  # Deploy web build to Firebase Hosting
firebase deploy --only firestore:rules  # Deploy Firestore security rules
```

`tools/build_hosting.ps1` builds the web app into `build/hosting` (an `/app` build plus a `/webkit` build for Safari/iOS, behind a small redirect page). Firebase Hosting serves it with SPA rewrites.

## Architecture

**State management:** Riverpod. StreamProviders for real-time Firestore data, StateNotifier-style controllers for mutations.

**Routing:** GoRouter with reactive auth-based redirects. The router listens to both `authStateProvider` and `userProfileProvider` and enforces: Splash → Auth → Onboarding → Dashboard. Route names live in `AppRoutes` in `lib/app/router.dart`.

**Screens:** Today (`DashboardScreen`) is home: calories/protein, the day's meals, a month graph and weight, with the quick-log bar pinned at the bottom (type `chicken wrap 450` or `мусака 450 ккал`, tap the mic, tap the camera icon in the box to photograph the plate, or tap the barcode icon to scan a packet; while the box is focused, meals are offered as chips: with the box empty, up to five usually logged around this time of day (`usualMealsAt`: at least twice within 90 minutes of now, not already logged today); once typing, up to three of the last 50 distinct meal names that match). There are no bottom tabs; the top-left menu (`AppDrawer` in `lib/widgets/app_frame.dart`, on every page) lists Today, History, Weight & Progress, Plan Settings and Account Settings. Today is the root and the other pages sit one level above it: picking a page from inside another swaps it (`pushReplacement`), so Back always returns to Today. History (`ReviewScreen`, route `review`) combines a week/month calendar with the period review; tapping a day opens its meals for adding, editing or deleting.

**Styling:** Warm light and dark palettes (`AppPalette.light` / `AppPalette.dark` in `lib/core/constants/app_colors.dart`). `AppColors` is a set of static getters switched by `AppColors.isDark`, which `LeanStreakApp` sets from the stored ThemeMode (System/Light/Dark in the menu, `themeControllerProvider`) and the platform brightness, so expressions using `AppColors` cannot be `const`. `AppTheme.light`/`dark` are built from the palettes; use `AppCard` (`lib/widgets/app_card.dart`) for cards rather than hand-built containers. On wide browser windows `appShellBuilder` (`lib/app/app.dart`) shows the app as one centred column.

**Data flow:** Repository pattern. Each Firestore collection has a repository (`lib/repositories/`) that handles reads/writes. Services (`lib/services/`) compose repositories for business logic. Providers (`lib/providers/`) expose state to the UI and wire up controllers.

**Device settings:** Theme and reminder switches live in SharedPreferences through `sharedPreferencesProvider` (`lib/providers/preferences_provider.dart`), overridden in `main()` so readers never wait on it.

**Firestore structure:** All user data lives under `/users/{uid}/` with subcollections for meals, daily summaries, weight entries, AI usage and past-day edits (period reviews are computed, not stored; old `check_ins` documents are only deleted along with the account). Reset progress on Weight & Progress clears `weight_entries` only.. Security rules enforce owner-only access.

## Key Domain Logic

- **Health calculations** (`lib/helpers/health_calculator.dart`): Pure functions for BMI, BMR (Mifflin-St Jeor), TDEE, and daily calorie targets. Has safety floors. Extensively tested.
- **Daily summaries** (`lib/services/daily_summary_service.dart`): Recomputed from meals whenever a meal is logged/edited. Includes calorie totals, meal count, and a green/yellow/red status based on adherence to target (±10% green, ±20% yellow, else red).
- **AI calorie estimation** (`lib/services/calorie_estimate_service.dart`): Uses Gemini 3.5 Flash-Lite; every prompt opens with `nutritionContext`, built from the profile's `country` and `usualFood` (asked in onboarding, editable in Plan Settings; profiles from before these fields default to the UK and Bulgarian home cooking); returns calories, protein and a per-item breakdown (shown as one muted line that expands on tap). `estimateFromPhoto` sends a resized JPEG with the same itemised prompt. Prompts keep the meal and item names in the language the user wrote (English or Bulgarian). Typed and photo estimates share a daily limit (`AiUsageRepository.dailyLimit`, 20/user/day) tracked in Firestore.
- **Period reviews** (`lib/services/period_review_service.dart`): Aggregates daily summaries into weekly/monthly review data, shown under the History calendar for finished days.
- **Past-day changes** (`lib/providers/log_meal_controller.dart`): adding, editing or deleting a meal on an earlier day uses one of 10 changes per calendar month (`DayEditRepository.monthlyLimit`).
- **Today isn't judged mid-day:** a day only shows its green/yellow/red status once it is finished, on track, or over target (`hasSettledStatus` in `lib/widgets/day_status.dart`).

## Models

All models use manual Firestore serialization (no codegen). Each model has `fromFirestore` / `toFirestore` methods. Enums use `fromString` factory constructors with legacy value handling (e.g., `ActivityLevel` accepts both old and new string formats).

Key models: `UserProfile` (with enums for Gender, ActivityLevel, TrainingFrequency, WeightGoal, DeficitLevel), `Meal` (name, calories, optional protein), `DailySummary` (with optional protein), `WeightEntry`, `PeriodReview`.

## Conventions

- Dart SDK `^3.11.4`, uses modern Dart 3 features (switch expressions, pattern matching, records).
- Voice logging records a short clip with `record` (16 kHz mono PCM, wrapped as WAV by `lib/helpers/wav.dart`) and sends the audio to Gemini (`parseVoiceAudio`), which understands English, Bulgarian or a mix with no language setting. Recording ends on the Stop button, after a pause once something was said, or at 30 s. `quick_log_parser.dart` reads English and Bulgarian units (ккал/кал/калории, г/гр протеин/белтък).
- AI calls go through Firebase AI Logic (`firebase_ai`, Gemini Developer API backend, `FirebaseAI.googleAI()`), so there is no API key in the app; the Firebase project must have AI Logic enabled (console → Build → AI Logic). On the Spark plan this is the Gemini API's no-cost tier; `QuotaExceeded` and `ServiceApiNotEnabled` are mapped to plain messages in `CalorieEstimateService`. Every call carries a Firebase App Check token (`lib/core/config/app_check.dart`): debug builds use the debug provider, whose token (printed in the log at startup) must be registered under App Check → Apps → Manage debug tokens; release builds use Play Integrity, and the web uses reCAPTCHA Enterprise (Fraud Defense in Google Cloud; classic v3 can no longer be registered) with the public site key in `recaptchaSiteKey` (`web/index.html` turns on the debug token on localhost; run the web app on a fixed port, as the VS Code "LeanStreak (Edge)" config does with `--web-port 5000`, because the token is stored per origin in the browser profile Flutter keeps under `.dart_tool/chrome-device`, and register it under the `lean_streak (web)` app's debug tokens). Firebase makes App Check enforcement mandatory for AI Logic from 2 November 2026.
- Barcode scanning: `mobile_scanner` (`BarcodeScanPage`, retail formats only) reads the code, `FoodLookupService` fetches the product from Open Food Facts (`/api/v2/product/{code}.json`, only the barcode is sent, `app_name`/User-Agent identify the app), and `showPortionSheet` asks for the grams (prefilled from `serving_size` or `quantity`) before filling the box with label figures; no AI call, no daily-limit use. The scanner and lookup are providers (`barcodeScannerProvider`, `foodLookupServiceProvider`) so tests stand in for the camera and the network. On the web it relies on the browser's BarcodeDetector API, so desktop browsers mostly show the "no camera" message.
- Crash reporting: `firebase_crashlytics` on Android/iOS only (it has no web build); the handlers are set in `main()` after Firebase is initialised. Account Settings has a Send feedback tile that opens a mailto link (`LegalLinks.feedback`, `openFeedbackEmail`). Onboarding and Plan Settings accept ages 18–120, matching the legal pages.
- Sign-in is email/password (with email verification) or Google: Firebase's popup on the web, `google_sign_in` 7 on phones, which needs the web client ID that the google-services plugin reads from `google-services.json` (present once the Google provider is enabled in Firebase Auth). Backing out of the Google flow is not shown as an error.
- Legal pages live in `tools/hosting/privacy.html` and `terms.html`; `build_hosting.ps1` copies them to the hosting root and `firebase.json` has `cleanUrls`, so they're served at `/privacy` and `/terms`. `LegalLinks` holds the URLs; `LegalFooter` (sign-in; on the web it also carries the reCAPTCHA attribution line Google requires when the badge is hidden) and the Help & Legal section in Account Settings open them, and `MedicalNote` is the health disclaimer shown under the plan preview in onboarding and Plan Settings.
- Android home-screen widget: `LogWidgetProvider.kt` draws `res/layout/log_widget.xml` (a 2×1 mini log bar declared in `res/xml/log_widget_info.xml`, colours in `values(-night)/colors.xml`); taps open the app with `leanstreak://log/text` or `leanstreak://log/voice`, which `launchActionForUri` maps to `LaunchAction.typeLog`/`voiceLog`. Flutter deep linking is off in the manifest so go_router never sees those URIs, and `MainActivity` blanks the intent on a relaunch from Recents. The app-icon shortcut (`quick_actions`, id `log_voice`) uses the same path.
- `NotificationService` (`flutter_local_notifications`) schedules a daily meal reminder (20:30) and a weekly weigh-in reminder (Saturday 20:00 by default; day and time are set under the switch); both switches are in Account Settings and `reminderSyncProvider` keeps the schedules in step. A notification tap becomes a `LaunchAction` (`lib/app/launch_actions.dart`, set before the widget tree exists) that Today consumes; the app-icon shortcut and home-screen widget use the same path.
- The app targets web primarily but also supports Android and iOS. The Android application ID and iOS bundle ID are `com.bpetrov.leanstreak` (Kotlin lives under `com/bpetrov/leanstreak`); `android/app/google-services.json` belongs to that Firebase Android app.
