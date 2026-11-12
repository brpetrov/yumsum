# Plan 15: From draft to closed test in Play Console

*Written 9 November 2026 for you to follow, step by step. Where you are now: identity verified, the app YumSum (`com.bpetrov.yumsum`) created as a draft, nothing uploaded. The words to paste are in plan 14, the pictures in `tools/e2e/store/`. Play Console's menus move about; if a name here doesn't match, the app's dashboard has a "Set up your app" list with the same tasks.*

## The order, and why

1. Internal testing first, with just you: no review wait, and it gives you Play's signing keys, which Firebase needs before Google sign-in and AI work in Play installs.
2. Then the store listing and the forms, which a closed test needs.
3. Then the closed test with your testers. The 14 days start once 12 of them have opted in.
4. YumSum Star's subscription can follow (plan 07); testers get it free by hand meanwhile.

## A. Before you upload (about 20 minutes)

- [x] **Open Food Facts password** (skipped 9 November 2026: only the owner's old builds carried it): change it on openfoodfacts.org (old test builds carried it), then in the VS Code terminal `firebase functions:secrets:set OFF_PASSWORD` (type it when asked) and `firebase deploy --only functions:contributeProduct`. Plan 04 has the background.
- [ ] **Payments profile** (moved to E, around day 2–5 of the test): Play Console → Settings (the cog) → Payments profile → create it. Needed for the subscription later; it shows your address on the listing, so decide on the address first (plan 07 step 1).
- [x] **Your own phone's Gmail** (`broovenn@gmail.com`) is the first tester: note which Gmail your phone's Play Store uses.

## B. Internal test, just you (about 30 minutes, then a few hours' wait)

- [x] **Bundle**: Claude has built `build\app\outputs\bundle\release\app-release.aab` (version 0.1.0+1). If it's older than the latest change, ask for a new one.
- [x] Play Console → YumSum → **Test and release → Testing → Internal testing** → Create new release.
  - [x] "Play App Signing": accept (Google keeps the signing key; your upload key stays in `C:\Users\brpet\keys`).
  - [x] Upload the `.aab`. Release name: leave Play's (0.1.0). Release notes: `First test build.`
  - [x] Next → Save → Go to overview → Send for review / Start rollout (internal tests usually go live within minutes to hours).
- [x] **Testers** tab → Create email list "Me" → add your phone's Gmail → Save → tick it. Copy the **join on the web** link (https://play.google.com/apps/internaltest/4701065037597490716).
- [x] **Signing keys into Firebase** (added by Claude 10 November 2026; SHA-1 36:F8:32:6E…, SHA-256 68:27:1B:D7…): Protected with Play → Play Store protection → App signing → copy the **App signing key** SHA-1 and SHA-256. Firebase console → Project settings → Your apps → **YumSum Android** → Add fingerprint → paste each. (Without them, Google sign-in fails in Play installs.)
- [x] **Play Integrity** (linked to project 296684319013, App Check already registered, 10 November 2026): Protected with Play → Play Integrity API → **Link a Cloud project** → `lean-streak-project`. Then Firebase → App Check → Apps → YumSum Android → Play Integrity → add the same **App signing** SHA-256. (Without this, AI fails in Play installs.)
- [ ] **Store listing first** (since 11 November 2026): do C's Main store listing and Store settings before trying it, so the icon, feature graphic and posters show in Play when you install.
- [ ] **Try it**: on your phone open the join link → Become a tester → Download it on Google Play. Uninstall the VS Code build first if Play says it can't install (different signatures). Then: sign in with Google and with email, log a meal with an AI estimate, scan a barcode, use the mic, open every menu page. Anything odd → tell Claude.
- [ ] **Crash reports**: on that install, Settings → Debug tools (your owner account) → **Send a test crash report**, close the app fully, open it again; within a few minutes it shows in Firebase → Crashlytics → Non-fatals.

## C. Store listing and forms (about 1 hour; plan 14 has every answer)

- [x] **Grow users → Store presence → Main store listing**: app name, short and full description from plan 14 section 1.
  - [x] App icon: `assets/android/play_store_512.png`.
  - [x] Feature graphic: `tools/e2e/store/feature-graphic.png` (1024 × 500).
  - [x] Phone screenshots, in this order: `tools/e2e/store/play-1.png` to `play-8.png`, the poster-style set (`tools/e2e/store/PLAY.md`). The plain screens `en-1-home.png` to `en-6-history.png` are the fallback.
  - [ ] Translations → Add → Bulgarian: the Bulgarian texts from plan 14 (screenshots can stay English).
  - [x] Save.
- [ ] **Store settings**: category **Health & Fitness**, contact email `help.yumsum@gmail.com`, website `https://yumsum.web.app`.
- [ ] **Policy and programs → App content**, each form from plan 14 section 2:
  - [ ] Privacy policy: `https://yumsum.web.app/privacy`
  - [ ] Ads: no
  - [ ] App access: restricted → add the instructions from plan 14 section 2.1, with the test account's email and password in the credential boxes. That account has a YumSum Star manual grant (Claude wrote it on 10 November 2026). The browser tests reset its meals, never its profile, so it stays ready.
  - [ ] Content rating: the questionnaire in 2.2
  - [ ] Target audience: 18 and over
  - [ ] News app: no; Government app: no; Financial features: none
  - [ ] Health apps: nutrition and weight management, not medical
  - [ ] Data safety: the table in 2.3. Go through the "Check:" lines as you fill it in
  - [ ] **Account deletion**: `https://yumsum.web.app/delete-account`
- [ ] **Trader status** (Play Console home): can wait until February 2027, but must be done before YumSum Star is sold.

## D. Closed test with your testers

- [ ] Test and release → Testing → **Closed testing** → the track Play made ("Closed testing - Alpha") → Create new release → **Add from library** → the internal build → Next → Save → Send for review. The first closed release is reviewed by Google: allow a few days.
- [ ] **Countries**: Closed testing → Countries/regions → add the United Kingdom, Bulgaria and wherever your testers are.
- [ ] **Testers** tab → Create email list "Testers" → paste every Gmail (comma-separated) → Save → tick it → copy the join link.
- [ ] **Licence testers too**: Play Console → Settings → License testing → add the same Gmails (so they never pay real money if they try YumSum Star).
- [ ] When Google approves the release, send the message below. As each tester joins, give them a YumSum Star manual grant in Firestore (`entitlements/{their uid}`, see plan 07) so they can try everything: `active` true, `source` `manual` and `expiresAt` a timestamp 3 weeks ahead, so it ends by itself after the test (never `admin` or `dev`). Their uid shows in Debug tools for you, or ask Claude to look it up by email and write the grant.

Message for testers:

> Hi, I've made a calorie tracking app called YumSum and need Android testers for Google Play. Here's the link: [join link]. Tap "Become a tester", then "Download it on Google Play" and install it. Please keep it installed and stay in the test for 14 days. Use it now and then, log a meal or two, and tell me anything that's broken or confusing (there's a Send feedback button in Settings). Thank you!

## E. The 14 days

- [ ] Play Console → Closed testing shows how many testers have opted in. The clock needs **12 or more every day for 14 days in a row**: aim for 14–15.
- [ ] Send a short nudge around day 5 and day 10 asking people to open the app and log something.
- [ ] Watch Firebase → Crashlytics and help.yumsum's inbox; Claude fixes, builds 0.1.0+2, and you upload it to the closed track (it keeps the clock running).
- [ ] **YumSum Star's subscription, around day 2–5**: decide about the public address, create the payments profile (A), then the subscription with Claude (plan 07, steps 5–13). By day 10, two or three licence testers try buying it with test cards.

## G. Found in the first install (10 November 2026), to come back to

**Where we stopped, 10 November 2026 evening:** 0.1.0+2 is built (`build/app/outputs/bundle/release/app-release.aab`, signed with the upload key) with today's fixes and an up-to-date `google-services.json` (Firebase has a Google sign-in client for Play's key). Next: upload it to Internal testing, uninstall the debug build, install from Play, and try Continue with Google with the phone plugged in so Claude can read the error if it fails. The Gemini spend cap is £10 a month (AI Studio → Spend; it was £5 and paused the AI on 10 November); about £2–3 is left until 1 December.

**11 November 2026:** crash reports now also catch failed AI calls, Google sign-in set-up faults, purchase failures and the errors the app used to swallow (docs/features.md, Crash reporting); a fresh 0.1.0+2 bundle is needed to carry them, built when you ask. After installing it from Play, do the crash report check in B, then try Continue with Google: if it fails, Firebase → Crashlytics → Non-fatals shows it as "Google sign-in" within a few minutes, with the exact error. The help pages no longer link to the app or name you, and are dated 11 November 2026.

**12 November 2026:** 0.1.0+2 rebuilt at 17:12 with everything up to today (meal groups and times, the mic fixes, onboarding's new pictures, the time wheels); the 11 November +3 bundle was never uploaded and is gone. Uploaded to Internal testing the same evening (version code 2, live to internal testers) and the main store listing filled in. Until the App content forms are done and the app is reviewed, Play shows testers the temporary name `com.bpetrov.yumsum (unreviewed)`. Next: B's Try it and crash report check, then C's Store settings and App content forms.

Where the internal test got to: the release is live, you're a tester, the signing keys are in Firebase, Play Integrity is linked. Open:

- [ ] **Google sign-in failed in the Play build.** Found 12 November 2026: release resource shrinking dropped `default_web_client_id` (google-services.json's web client ID, which google_sign_in reads by name), so the plugin gave up before asking Google; debug builds don't shrink, so they worked. Fixed by keeping it in `android/app/src/main/res/raw/keep.xml`; 0.1.0+3 built at 18:32 with the fix (checked: the ID is in the bundle); upload it to Internal testing, update the app from Play, then try again. Before that: Play's signing SHA-1 (36:F8:32:6E…) went into Firebase at about 12:45 on 10 November; a try before that fails, and Google can take a few minutes after. Try again; if it still fails, note the exact message for Claude. Next check: Google Cloud console → APIs & Services → Credentials → an Android OAuth client with package `com.bpetrov.yumsum` and that SHA-1 (Firebase makes it when the fingerprint is added).
- [ ] **About 15 AI requests in 15 seconds** at 13:43 in the function logs, from the debug build while its App Check token was unregistered. Find out whether that was repeated taps or the app retrying by itself; if the app, fix it (one call per tap, see `quick_log_bar.dart`'s `_runAi`).
- [ ] **A debug build gets a new App Check debug token every time it's uninstalled** (it was, to install the Play version). The symptom is "Could not estimate calories" and "Decoding App Check token failed" in the logs. Fix: the token from `adb logcat` ("Failed to exchange debug token (…)") goes into Firebase → App Check → YumSum Android → ⋮ → Manage debug tokens. Registered 10 November: `25997abf-…`.
- [ ] **Debug tools' pretend Star shows the badge but the server still gives no macros**, by design (`aiMacrosProvider` asks only when the real record has Star). For screenshots or testing macros, give the account a real manual grant (plan 07). The phone has two accounts: Boyan Petrov (brooventest, admin) and John Doe (Google sign-in as `broovenn@gmail.com`, created 6 November, no Star).

### Screenshots and selling the app

- [ ] The poster-style set is specified in `tools/e2e/store/BRIEF.md`: 8 slides, who each is aimed at, the headline and line for each, the look, Play's rules. Competitor references are in `tools/e2e/store/reference/` (not in git). The raw screens (`en-*.png`) were retaken with the test account on YumSum Star and recipe portions logged, so the rings are filled.
- [ ] **Four screens from your phone**, on an account with a real Star grant, saved into `tools/e2e/store/` as `phone-ai-estimate.png` (a typed meal's AI result), `phone-choice.png` (the breakdown's choice chips; type something vague like "sarmi"), `phone-scan.png` (the barcode portion sheet with its serving chips), `phone-progress.png` (Weight & Progress with real history). Take them on a 9:16 phone with the status bar hidden or cropped.
- [ ] Then tell Codex: "Read `tools/e2e/store/BRIEF.md` and make the screenshots it describes, using the raw screens and references in that folder." Check the result against the brief's rules before uploading.
- [ ] **The selling point to lead with: 10 free AI estimates a day, typed or spoken, no ads.** Research on 10 November (ten rival apps, third-party sources) found almost all of them lock AI logging behind a subscription, one gives about 3 a day, and several free tiers show ads. Say it as our own fact in the listing and the screenshots, never as a comparison with named apps.
- [ ] The full description's first paragraph in plan 14 was rewritten to sell the benefit (only the first lines show before "Read more").

### Later, after the closed test

- [ ] **Built-in Kotlin:** `flutter build` warns that `android/app/build.gradle.kts` applies the Kotlin Gradle Plugin, and so do cloud_functions, firebase_app_check, firebase_auth, firebase_core, firebase_crashlytics and home_widget; a future Flutter will refuse to build. Migrate the app file with https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers together with a plugin upgrade, once those plugins support it. Not before the closed test: it changes the Android build for no gain today (noted 10 November 2026).

## F. Production

- [ ] After 14 days: Play Console → Dashboard → **Apply for production**. Google asks how you tested, what testers said and what changed; Claude can draft the answers from the feedback and the fixes.
- [ ] Once approved: Production → Create release → Add from library → the latest build → staged rollout 20%, then 100% after a few quiet days.
- [ ] Once App Check shows nearly all requests verified: enforce it for Firestore and Authentication (plan 04).
