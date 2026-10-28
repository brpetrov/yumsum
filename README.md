# YumSum

YumSum is a calorie and protein logger built with Flutter and Firebase. A short
onboarding sets your daily calorie and protein targets, and logging a meal takes
a line of text, a few spoken words or a photo, with Gemini estimating the
numbers. Days are marked green, amber or red against your target, though today
isn't judged mid-day.

## Features

- **Quick log:** type a meal, say it or photograph the plate, and an AI estimate
  fills in the calories and protein, with a per-item breakdown you can correct.
  Ten AI estimates per user a day.
- **Packaged food:** scan a barcode or search by name to fill in the label
  figures from Open Food Facts, and add products it doesn't know yet.
- **Targets:** a daily calorie target (Mifflin-St Jeor BMR and TDEE) and a
  protein target from your goal weight and training. Logging a weight adjusts
  the plan.
- **History:** a week or month calendar with a review of finished days. Past
  days can be changed 10 times a month.
- **Weight & Progress:** log weigh-ins and follow them on a chart.
- **Day off:** take today off so it isn't judged; reviews count it separately.
- **Reminders:** a daily meal reminder, a weekly weigh-in and an optional
  creatine reminder.
- **Android home-screen widget:** type or speak a meal from the home screen.
- **Light and dark mode:** follows the system, or set it in the menu.

Sign-in is by email and password or Google.

## Platforms

The web is the primary target; the same code runs on Android and iOS. The web
build leaves out barcode scanning, food search, contributing to Open Food Facts,
reminders and crash reporting, and its camera button picks a photo instead.
ML Kit needs iOS 15.5 or later, so raise the iOS deployment target (still 13.0)
before an iOS build.

## Stack

- Flutter (Dart `^3.11.4`), Riverpod 2 and go_router
- Firebase: Auth, Cloud Firestore, Hosting, AI Logic (Gemini 3.5 Flash-Lite),
  App Check and Crashlytics
- Open Food Facts for barcode lookup, search and contributions
- Also: `fl_chart`, `record` (voice), `camera` with ML Kit barcode scanning,
  `flutter_local_notifications` and `home_widget`

## Getting started

### Prerequisites

- Flutter SDK with Dart `^3.11.4`
- Firebase CLI, for deploys
- PowerShell, for the web build script
- Python 3 with Pillow, only to regenerate the app icons

### Firebase

The repo is wired to the Firebase project `lean-streak-project` (`.firebaserc`,
`lib/firebase_options.dart`, `android/app/google-services.json`). It needs:

- **Authentication** with the Email/Password and Google providers. On Android,
  Google sign-in needs the web client ID in `google-services.json`, which is
  only there once the Google provider is on.
- **Cloud Firestore**, with the rules in `firestore.rules`.
- **AI Logic** switched on (console → Build → AI Logic). There's no API key in
  the app. The project is on the Blaze plan, and UK and EU users need the
  Gemini API's paid tier; see `docs/plans/03-ai-costs-and-earning.md`.
- **App Check**. Debug builds print a debug token in the log at startup;
  register it under App Check → Apps → Manage debug tokens. For the web, run on
  a fixed port (5000, as below) so the token stays the same, and register it
  under the web app. Release builds use Play Integrity on Android and
  DeviceCheck on iOS; the web uses reCAPTCHA Enterprise (site key in
  `lib/core/config/app_check.dart`).

### Open Food Facts contributions (optional)

Contributing new products needs an Open Food Facts account, given at build
time. Copy `config/off_account.example.json` to `config/off_account.json`
(gitignored) and fill in `OFF_USER_ID`, `OFF_PASSWORD` and `OFF_HOST`
(`world.openfoodfacts.net` is their test server). Without it, the app just says
a barcode is unknown. Set-up steps are in `docs/plans/01-contribute.md`.

### Run, test and analyse

```bash
flutter pub get
flutter run -d edge --web-port 5000   # web (-d chrome where Chrome is installed)
flutter run -d android                # Android device or emulator
# add --dart-define-from-file=config/off_account.json for contributions
flutter test                                    # all tests
flutter test test/health_calculator_test.dart   # one file
flutter analyze                                 # lint (flutter_lints)
```

`.vscode/launch.json` has matching configs. Tests never touch Firebase, the
network or device hardware.

## Deploying the web app

```powershell
./tools/build_hosting.ps1
firebase deploy --only hosting
```

The script builds two web bundles into `build/hosting`: `/app` for most
browsers and `/webkit` for Safari and iOS, behind a small redirect page. It
also copies the legal pages, served at `/privacy` and `/terms`. The deploy goes
to the Hosting site set by `firebase.json` and `.firebaserc`.

Firestore rules deploy separately:

```bash
firebase deploy --only firestore:rules
```

## App icons

Icons for Android, iOS and the web are generated from the artwork in `design/`:

```bash
python -I tools/make_icons.py
```

## Project layout

```
lib/
├── app/           # app root, router, launch actions (widget, shortcut, reminders)
├── core/          # theme, colours, App Check config, legal links
├── helpers/       # pure logic: health calculator, WAV wrapper, weigh-in timing
├── models/        # UserProfile, Meal, DailySummary, WeightEntry, PeriodReview
├── providers/     # Riverpod providers and controllers
├── repositories/  # Firestore reads and writes, one per collection
├── screens/       # auth, onboarding, Today, History, progress, settings, ...
├── services/      # AI estimates, daily summaries, reviews, Open Food Facts,
│                  #   notifications, weight logging
└── widgets/       # shared UI
```

## More

- `CLAUDE.md` covers the architecture, domain rules and conventions in detail.
- `docs/plans/` holds the launch plans: contributing, name/email/website, and
  AI costs.

## A note on naming

The app was called LeanStreak until October 2026. Only what users and Open Food
Facts see uses the new name. The Dart package is still `lean_streak`, and so
are class names such as `LeanStreakApp`, the `leanstreak://` launch URIs, the
Firebase project ID and a few build flags. `leanstreak_agent_build_spec.md` is
an old build spec and out of date.
