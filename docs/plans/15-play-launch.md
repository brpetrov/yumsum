# Plan 15: From draft to closed test in Play Console

*Written 9 November 2026 for you to follow, step by step. Where you are now: identity verified, the app YumSum (`com.bpetrov.yumsum`) created as a draft, nothing uploaded. The words to paste are in plan 14, the pictures in `tools/e2e/store/`. Play Console's menus move about; if a name here doesn't match, the app's dashboard has a "Set up your app" list with the same tasks.*

## The order, and why

1. Internal testing first, with just you: no review wait, and it gives you Play's signing keys, which Firebase needs before Google sign-in and AI work in Play installs.
2. Then the store listing and the forms, which a closed test needs.
3. Then the closed test with your testers. The 14 days start once 12 of them have opted in.
4. YumSum Star's subscription can follow (plan 07); testers get it free by hand meanwhile.

## A. Before you upload (about 20 minutes)

- [ ] **Open Food Facts password**: change it on openfoodfacts.org (old test builds carried it), then in the VS Code terminal `firebase functions:secrets:set OFF_PASSWORD` (type it when asked) and `firebase deploy --only functions:contributeProduct`. Plan 04 has the background.
- [ ] **Payments profile**: Play Console → Settings (the cog) → Payments profile → create it. Needed for the subscription later; it shows your address on the listing, so decide on the address first (plan 07 step 1).
- [ ] **Your own phone's Gmail** is the first tester: note which Gmail your phone's Play Store uses.

## B. Internal test, just you (about 30 minutes, then a few hours' wait)

- [ ] **Bundle**: Claude has built `build\app\outputs\bundle\release\app-release.aab` (version 0.1.0+1). If it's older than the latest change, ask for a new one.
- [ ] Play Console → YumSum → **Test and release → Testing → Internal testing** → Create new release.
  - [ ] "Play App Signing": accept (Google keeps the signing key; your upload key stays in `C:\Users\brpet\keys`).
  - [ ] Upload the `.aab`. Release name: leave Play's (0.1.0). Release notes: `First test build.`
  - [ ] Next → Save → Go to overview → Send for review / Start rollout (internal tests usually go live within minutes to hours).
- [ ] **Testers** tab → Create email list "Me" → add your phone's Gmail → Save → tick it. Copy the **join on the web** link.
- [ ] **Signing keys into Firebase**: Test and release → **App integrity** → App signing → copy the **App signing key** SHA-1 and SHA-256. Firebase console → Project settings → Your apps → **YumSum Android** → Add fingerprint → paste each. (Without them, Google sign-in fails in Play installs.)
- [ ] **Play Integrity**: App integrity → Play Integrity API → **Link a Cloud project** → `lean-streak-project`. Then Firebase → App Check → Apps → YumSum Android → Play Integrity → add the same **App signing** SHA-256. (Without this, AI fails in Play installs.)
- [ ] **Try it**: on your phone open the join link → Become a tester → Download it on Google Play. Uninstall the VS Code build first if Play says it can't install (different signatures). Then: sign in with Google and with email, log a meal with an AI estimate, scan a barcode, use the mic, open every menu page. Anything odd → tell Claude.
- [ ] **Crash reports**: on that install, Settings → Debug tools (your owner account) → **Send a test crash report**, close the app fully, open it again; within a few minutes it shows in Firebase → Crashlytics → Non-fatals.

## C. Store listing and forms (about 1 hour; plan 14 has every answer)

- [ ] **Grow users → Store presence → Main store listing**: app name, short and full description from plan 14 section 1.
  - [ ] App icon: `assets/android/play_store_512.png`.
  - [ ] Feature graphic: `tools/e2e/store/feature-graphic.png` (1024 × 500).
  - [ ] Phone screenshots, in this order: `tools/e2e/store/en-1-home.png`, `en-2-quick-log.png`, `en-3-targets.png`, `en-4-recipes.png`, `en-5-progress.png`, `en-6-history.png`. Add one of the YumSum Star page and one of an AI estimate taken on your phone later if you like.
  - [ ] Translations → Add → Bulgarian: the Bulgarian texts from plan 14 (screenshots can stay English).
  - [ ] Save.
- [ ] **Store settings**: category **Health & Fitness**, contact email `help.yumsum@gmail.com`, website `https://yumsum.web.app`.
- [ ] **Policy and programs → App content**, each form from plan 14 section 2:
  - [ ] Privacy policy: `https://yumsum.web.app/privacy`
  - [ ] Ads: no
  - [ ] App access: restricted → add the instructions from plan 14 section 2.1, with the test account's email and password in the credential boxes. Give that account a YumSum Star manual grant first (plan 07, Manual grants), or delete step 3 of the instructions. The browser tests reset its meals, never its profile, so it stays ready.
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
- [ ] When Google approves the release, send the message below. As each tester joins, give them a YumSum Star manual grant in Firestore (`entitlements/{their uid}`, see plan 07) so they can try everything; their uid shows in Debug tools for you, or ask Claude to look it up by email.

Message for testers:

> Hi, I've made a calorie tracking app called YumSum and need Android testers for Google Play. Here's the link: [join link]. Tap "Become a tester", then "Download it on Google Play" and install it. Please keep it installed and stay in the test for 14 days. Use it now and then, log a meal or two, and tell me anything that's broken or confusing (there's a Send feedback button in Settings). Thank you!

## E. The 14 days

- [ ] Play Console → Closed testing shows how many testers have opted in. The clock needs **12 or more every day for 14 days in a row**: aim for 14–15.
- [ ] Send a short nudge around day 5 and day 10 asking people to open the app and log something.
- [ ] Watch Firebase → Crashlytics and help.yumsum's inbox; Claude fixes, builds 0.1.0+2, and you upload it to the closed track (it keeps the clock running).
- [ ] Optional during the test: YumSum Star's subscription (plan 07, steps 5–13), tried by you and two or three testers.

## F. Production

- [ ] After 14 days: Play Console → Dashboard → **Apply for production**. Google asks how you tested, what testers said and what changed; Claude can draft the answers from the feedback and the fixes.
- [ ] Once approved: Production → Create release → Add from library → the latest build → staged rollout 20%, then 100% after a few quiet days.
- [ ] Once App Check shows nearly all requests verified: enforce it for Firestore and Authentication (plan 04).
