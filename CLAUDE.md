# CLAUDE.md

Guidance for Claude Code in this repository. The rules and the map are here; how each feature works in detail is in `docs/features.md` (read the section for what you're changing), and why things are the way they are is in `docs/plans/`. Trust the code over any notes, and update `docs/features.md` when you change a feature.

## Commands

```bash
flutter run -d edge            # Web, the primary target (-d chrome where Chrome is installed)
flutter run -d android         # Android phone or emulator
flutter test                   # All tests
flutter test test/health_calculator_test.dart   # One file
flutter test test/recipes_asset_test.dart       # The recipe library and its photos
flutter analyze                # Lint (flutter_lints)
flutter build apk --release --dart-define=APP_CHECK_DEBUG=true   # A release build for the phone from the PC (Play Integrity passes only Play installs)
tools/build_hosting.ps1        # Build the website into build/hosting, before a hosting deploy
firebase deploy --only hosting:app      # The website
firebase deploy --only firestore:rules  # Firestore rules
firebase deploy --only functions        # The Cloud Functions (functions/; their tests: npm test there)
npm run eval                   # In functions/: the typed-estimate test set, before and after a prompt change
node run.js webkit "iPhone 13" # In tools/e2e/: the website in a browser, signed in as the test account (its README)
```

Run the deploys a change needs yourself, straight after it: rules, then the website. The VS Code configs in `.vscode/launch.json` add `--web-port 5000` for Edge, and a contribute dry run (`OFF_DRY_RUN`) for Android.

## Names

- The app is **YumSum**. The Dart package (`lean_streak`), class names (`LeanStreakApp`), `leanstreak://` launch URIs, log tags and the Firebase project `lean-streak-project` keep the old LeanStreak name. Only what users or Open Food Facts see says YumSum.
- **Home** in the app is `DashboardScreen`, called Today in the code.
- **YumSum Star**, the paid tier, is `plus` in the code (`plusProvider`, `PlusScreen`, `/plus`).
- The Android application ID and iOS bundle ID are `com.bpetrov.yumsum`.

## Architecture

- **State:** Riverpod 2. StreamProviders for live Firestore data, FutureProviders for one-off reads, `AsyncNotifier` controllers in `lib/providers/` for changes (`LogMealController`, `WeightLogController`, …), `Notifier`s for device settings.
- **Routing:** GoRouter (`goRouterProvider`, paths in `AppRoutes`, `lib/app/router.dart`), with auth and profile redirects: Splash → Auth → Onboarding → Home. Home is the root; the menu's pages swap one level above it, so Back always returns Home.
- **Data:** a repository per Firestore collection (`lib/repositories/`), services that combine them (`lib/services/`), providers that expose them. Open Food Facts lookups are reached over `http`; the Cloud Functions (billing, AI, Open Food Facts contributions, feedback through Formspree, the sign-up confirmation email through Gmail, account deletion) through `cloud_functions`.
- **Firestore:** the profile is `users/{uid}`; everything else is in its subcollections (`meals`, `daily_summaries`, `weight_entries`, `ai_usage`, `day_edits`, `days_off`, `weekly_reviews`, and the functions' own `contribution_usage`, `feedback_usage` and `coach_replies`). YumSum Star's record is the top-level `entitlements/{uid}`, which the app can only read; the billing functions write it and keep `playPurchases`, which the app can't see.
- **Device settings:** SharedPreferences through `sharedPreferencesProvider`, overridden in `main()`; unoverridden it throws.
- **Styling:** `AppColors` (`lib/core/constants/app_colors.dart`) switches between the light and dark palettes at run time, so expressions using it can't be `const`. Use `AppCard` for cards, Nunito for text and Fredoka (`AppTheme.display`) for headings and big numbers. Orange (`primary`) is for actions, green (`veryGood`) for on track and progress.

## Rules that break things when missed

- **New stored field:** add it to the model's `fromFirestore`/`toFirestore` and to `firestore.rules`, whose `hasOnly` lists reject unknown fields. Deploy the rules before a build that writes it, or saving fails.
- **Formula change:** bump `planCalculationVersion` or `activityScaleVersion` in `lib/models/user_profile.dart`, so stored plans are recalculated at startup.
- **Tests never touch Firebase, the network or device hardware.** Pump screens in a `ProviderScope` inside `MaterialApp(theme: AppTheme.light, …)` and override what reads Firestore or the device: `currentUidProvider`, `userProfileProvider`, `entitlementProvider`, the data providers, `weeklyReviewProvider`, `sharedPreferencesProvider` (after `SharedPreferences.setMockInitialValues`), `billingServiceProvider` and `realEntitlementProvider` where the YumSum Star page or `LeanStreakApp` is pumped (`test/billing_fixtures.dart`), and the AI, Open Food Facts, recorder, speech and camera providers. `test/quick_log_bar_test.dart` has the full set. Fake controllers by subclassing and services with `Fake implements …`; `FakeFunctions` (`test/fake_functions.dart`) stands in for `FirebaseFunctions`.
- **Formatting:** run `dart format` on the files you changed only; `dart format lib` reformats untouched files.
- **AI:** every Gemini call goes through the `aiEstimate` and `aiWeeklyReview` Cloud Functions (`functions/src/ai.ts`), which count the allowance in `ai_usage` before asking, check YumSum Star, and hold the prompts and the model (`functions/src/prompts.ts`). The app sends only what the user gave, never prompt text, and can only read `ai_usage`. A change to AI Coach's instruction also needs `weeklyReviewPromptVersion` raised; it labels new notes only, as a week's notes are written once and never again (the function keeps its reply in `coach_replies`). Every call needs an App Check token: a debug build prints a debug token that must be registered in the Firebase console, and the web needs the fixed port 5000. On the web App Check starts on demand, so any new Cloud Functions call must `await ensureAppCheck()` first.
- **YumSum Star gates:**
  - Use `plusProvider` for features and `adminProvider` for limits.
  - Owner grants are typed into `entitlements/{uid}` in the console: `active`, `source` `manual`, and `admin` or `dev` for the owner.
  - Macros are YumSum Star only for good, whatever they cost; the AI functions refuse them otherwise.
- **The Adaptive formula changes targets only on Mondays,** never on a weigh-in.
- **Recipe photos are served from the website,** so deploy hosting before an app release that lists new recipes, and run `test/recipes_asset_test.dart` after adding any.
- **Secrets:** never print or commit them. The Open Food Facts account is held only by the functions, as the secrets `OFF_USER_ID` and `OFF_PASSWORD`, the Gemini key as `GEMINI_API_KEY` and help.yumsum's Gmail app password as `GMAIL_APP_PASSWORD`, never in the app; the release signing details are in the gitignored `android/key.properties`.

## Copy

Short and plain, in British English, saying "you":
- Sentence case for buttons and messages; page names like Plan Settings stay as titled.
- No "Please", and no exclamation marks except the contribution's "Thank you!" and onboarding's "Your plan is ready!".
- Errors say what failed and what to do next: "Could not X. Try again.", or "Could not load X." for a page.
- Plain words over jargon: "adjusts", not "recalculates".
- Keep lines and button labels short enough for a 360dp phone.

## Text and translation

The app is in English and Bulgarian (`docs/translation.md` has the how-to and what is still to move):
- Every user-facing string goes in both `lib/l10n/app_en.arb` (with an `@key` description) and `app_bg.arb`, never as a literal in Dart. Widgets read it with `context.l10n.key`; code without a context (controllers, services, notifications) with `ref.read(l10nProvider)`. Run `flutter gen-l10n` after editing the ARBs and commit the generated `app_localizations*.dart`.
- Keys are lowerCamelCase, `<area><Thing>`: the screen or feature first (`auth`, `home`, `quickLog`, `coach`, `progress`, …, `common` for shared words like Cancel), then what it is (`homeTitle`, `progressErrorLoad`).
- Values in text are ICU placeholders (`{name}`), never glued strings; counts use ICU plurals, and Bulgarian needs only `one` and `other` (plus `=0` where the text differs).
- Dates and decimals go through the `AppFormats` helpers in `lib/l10n/l10n.dart` (`l10n.dayMonth(date)`, `l10n.decimal(kg)`), not `DateFormat` or `toStringAsFixed` in shown text. Date keys (`yyyy-MM-dd`) and what the AI is sent stay as they are.
- The language sent to the Cloud Functions comes from `languageCodeProvider` only.
- Owner-only Debug tools (`lib/screens/debug/`, `debug_provider.dart`) stay English. So do the AI's facts and prompts, log lines and exceptions nobody sees.
- Bulgarian copy says "ти", never "Вие" ("Запиши", "планът ти"), keeps the rules above (sentence case, no exclamation marks, "Не успяхме да … Опитай отново."), and must fit a 360dp phone: Bulgarian runs about a fifth longer.

## Where things live

| Feature | Code | Plan |
|---|---|---|
| Plan maths, protein and macro targets | `lib/helpers/health_calculator.dart` | |
| Weight trend | `lib/helpers/weight_trend.dart` | 08 |
| Adaptive formula | `lib/helpers/adaptive_formula.dart`, `lib/providers/adaptive_formula_provider.dart` | 08 |
| Quick-log bar | `lib/screens/dashboard/helpers/quick_log_bar.dart` | |
| AI estimates and the allowance | `lib/services/calorie_estimate_service.dart`, `lib/repositories/ai_usage_repository.dart`, `functions/src/ai.ts`, `functions/src/prompts.ts`, `lib/widgets/estimate_choice_dialog.dart` | 03, 12 |
| AI Coach (the weekly review) | `lib/helpers/week_facts.dart`, `lib/services/weekly_review_service.dart`, `lib/providers/weekly_review_provider.dart`, `lib/screens/coach/coach_screen.dart`, `lib/screens/review/weekly_notes.dart` | 09 |
| Macros | `lib/models/nutrients.dart`, `lib/widgets/macro_rings.dart`, `macro_totals.dart`, `macro_guide.dart` | 10 |
| Daily summaries, statuses, day off | `lib/services/daily_summary_service.dart`, `lib/widgets/day_status.dart` | |
| Packaged foods and contributing | `lib/services/food_lookup_service.dart`, `food_contribution_service.dart`, `functions/src/off.ts`, `lib/screens/dashboard/helpers/portion_sheet.dart` | 01, 13 |
| Recipes | `assets/recipes/recipes.json`, `lib/models/recipe.dart`, `lib/screens/recipes/` | 05 |
| YumSum Star, Debug tools | `lib/providers/plus_provider.dart`, `lib/screens/plus/`, `lib/widgets/plus_mark.dart`, `lib/screens/debug/` | 06, 07 |
| Billing | `lib/services/billing_service.dart`, `lib/providers/plus_purchase_controller.dart`, `lib/repositories/billing_repository.dart`, `functions/` | 07 |
| Reminders, widget, shortcuts | `lib/services/notification_service.dart`, `lib/app/launch_actions.dart` | |
| Language, texts, dates and numbers | `lib/l10n/`, `lib/providers/language_provider.dart`, `lib/screens/language/` | |
| Legal pages, website | `tools/hosting/`, `tools/build_hosting.ps1` | 02 |

`docs/plans/` holds the owner's plans with their set-up steps and checklists:
- 01 contributing
- 02 name, email and website
- 03 AI costs and earning
- 04 owner checklist
- 05 recipes
- 06 YumSum Star
- 07 billing
- 08 Adaptive formula
- 09 AI weekly review (AI Coach)
- 10 full macros
- 11 pricing YumSum Star
- 12 estimate choices: the amount and the kind
- 13 servings on the scan sheet
- 14 Play store listing and forms
- 15 from draft to closed test in Play Console
