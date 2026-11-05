# YumSum

A calorie and protein logger built with Flutter and Firebase. You log a meal by
typing it, saying it or photographing it, and Gemini estimates the numbers.
YumSum Star, the paid tier, adds more estimates, the Adaptive formula, AI Coach
and full macros.

The web is the main target; the same code runs on Android and iOS.

## Docs

- `CLAUDE.md`: the rules, a map of the code and the commands.
- `docs/features.md`: how each feature works.
- `docs/plans/`: the plans, with their set-up steps and checklists.

## Commands

```bash
flutter run -d edge --web-port 5000   # The web (App Check needs the fixed port)
flutter test
flutter analyze
tools/build_hosting.ps1               # Build the website into build/hosting
firebase deploy --only functions,firestore:rules,hosting:app
```

The Cloud Functions are in `functions/`; run their tests with `npm test` there.
The Gemini key and the Open Food Facts account are Functions secrets, never in
the app.
