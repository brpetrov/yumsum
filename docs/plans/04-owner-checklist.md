# Plan 4: Owner checklist

*Started 29 October 2026. Things only you can do (consoles, accounts, the phone), plus the next jobs Claude can pick up. Tick each one off as it's done; add a note under it if something went wrong.*

## Now

- [x] **Deploy the database rules and the website together** (done 29 October 2026)
  Run `firebase deploy --only firestore:rules,hosting` (the website is already built in `build/hosting`).
  Deploy both at once: the new rules need the new app code, or Reset all data and Delete account fail.
  Then run the app on the phone again so it has the new code too.

- [x] **Get the AI working on the phone** (done 29 October 2026: debug token added, AI works)
  Typed: "Could not estimate calories. Try again." Voice: "Could not understand the recording." Both are Firebase rejecting the phone, because it has no debug token yet.
  - [x] Run YumSum from VS Code. In the **Debug Console**, filter for `debug secret` and copy the code after the colon (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
  - [x] Firebase → App Check → Apps → **YumSum Android** row → **⋮** at the far right (shows on hover) → Manage debug tokens → Add debug token → name it "Boyan's phone", paste the code, Save.
  - [x] Wait a minute and try an AI estimate.

  Only debug builds need this, once per install: a reinstall or cleared app data makes a new code, which needs adding again. Play installs use Play Integrity and website visitors use reCAPTCHA, with nothing for them to do.

- [x] **Check the website** at https://yumsum.web.app/app/ (done 29 October 2026)
  - [x] Sign in with Google
  - [x] Log a meal with an AI estimate
  - [x] Logo: the website now draws it, so it stays sharp (goes live with the deploy below)

- [x] **Lock down the Firebase API keys** (most important security item)
  The keys in the app are public. If one may call the **Generative Language API** (Gemini itself), anyone can copy it and use Gemini directly, skipping App Check and the 10-a-day limit, on your credit. The app doesn't need it: its AI goes through the **Firebase AI Logic API**.

  Open https://console.cloud.google.com/apis/credentials?project=lean-streak-project. Under API Keys, click each key's name, scroll to **API restrictions**, and:
  - If it says **Restrict key**: open the APIs dropdown, untick **Generative Language API** if it's ticked, keep **Firebase AI Logic API** (formerly "Vertex AI in Firebase API") ticked, OK, Save.
  - If it says **Don't restrict key**: choose Restrict key and tick, using the filter box, whichever of these the list shows: Cloud Firestore API, Identity Toolkit API, Token Service API, Firebase App Check API, Firebase AI Logic API, Firebase Installations API, Firebase Crashlytics API. OK, Save.
  - Leave Application restrictions as they are.

  - [x] Browser key (auto created by Firebase), ends `u9to` (checked 29 October 2026)
  - [x] Android key (auto created by Firebase), ends `8ymM`
  - [x] iOS key (auto created by Firebase), ends `RX34`
  - [x] Delete the old AI Studio Gemini key, ends `sZZA` (deleted 29 October 2026 in aistudio.google.com/apikey): the app no longer uses it, but older website builds contained it, and it showed Gemini and Maps calls the app never made
  - [x] Wait 5 minutes, then on the phone and on the website: sign in, and log a meal with an AI estimate. If anything fails, note the message here; choosing Don't restrict key again undoes it.

  Don't change **Gemini Developer API key (auto created by Firebase)** if it's listed: that's Firebase's own server-side key, never in the app, and it needs the Generative Language API.

## Feedback emails

The app sends feedback to a Formspree form (formspree.io, signed up with help.yumsum@gmail.com), which emails it to help.yumsum with the user's address to reply to. No Gmail password, no Firebase extension. Free up to 50 messages a month.

- [x] Create the Gmail account **help.yumsum@gmail.com**
- [x] Create the Formspree form (`mqppllqo`); Claude switched the app to it and sent one test message (29 October 2026)
- [x] Check the test email from Claude arrived in help.yumsum (look in Spam too)
- [x] Deploy the website and the rules (the old `mail` rule is gone): `firebase deploy --only hosting:app,firestore:rules`
- [x] Run the app on the phone again, send feedback from Account Settings → Send feedback, and check it arrives
- [x] Delete the unused "YumSum feedback" app password from your personal Gmail (myaccount.google.com/apppasswords)

## Tidy up

- [x] Firebase → Project settings → Your apps: delete `lean_streak (android)`, `LeanStreak Android` and `lean_streak (ios)`
- [x] Push the commits to GitHub (say "push" to Claude, or use the Sync button)

## Google Play

- [x] **Release signing**: Play only accepts builds signed with your own upload key. Claude wired it in (the build reads `android/key.properties`, which Git ignores) and fixed release builds, which had been failing since Crashlytics was added. (Done 29 October 2026.)
  - [x] Create the key: in the VS Code terminal run `mkdir $HOME\keys`, then `keytool -genkeypair -v -keystore $HOME\keys\yumsum-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Choose a new password (6+ characters) and answer the questions (your name is enough; Enter skips the rest), then `yes`.
  - [x] In `android/key.properties`, replace both `CHANGE_ME` with that password, and save.
  - [x] Back up `C:\Users\brpet\keys\yumsum-upload.jks` and the password together somewhere safe (a password manager, or the file in Google Drive and the password in your head). If it's lost, Play support can swap in a new one, but it takes days.
  - [x] Claude built the app bundle: signed by `CN=Boyan Petrov`, upload key SHA-1 `A9:1D:7C:AF:C3:2E:51:1B:E8:31:5D:44:03:0F:76:B9:96:95:6D:4F`, SHA-256 `CA:F6:11:56:58:AD:A4:AA:D8:28:7C:16:6A:73:95:85:82:11:75:CC:76:F5:C6:8E:90:A9:D2:15:E6:EC:54:1F` (Play shows the same under App integrity → Upload key).
  - The bundle to upload: `flutter build appbundle --dart-define-from-file=config/off_account.json` (the Open Food Facts account goes in, so contributing works), file `build\app\outputs\bundle\release\app-release.aab`. Raise the `+1` in `version: 0.1.0+1` (pubspec.yaml) for every upload after the first.
- [x] **Play developer account**: personal, developer name YumSum, set up 29 October 2026.
  - [ ] Google checks your ID (a few days, they email you), then verify the contact phone number from the Play Console home page.

### While Google checks your ID

- [ ] **Find 12 testers.** A new personal account can only go to production after a closed test with at least 12 testers who stay opted in for 14 days in a row. Collect 12 Gmail addresses (friends, family, colleagues with Android phones) now; this is the longest wait of all.
- [ ] **Store listing** (Claude can make these): app name, short description (80 characters), full description, the 1024×500 feature graphic, 2–8 phone screenshots; the icon is `assets/android/play_store_512.png`.
- [ ] **Account deletion page** (Claude can make it): Play asks for a web link that explains how to delete your account and data, e.g. https://yumsum.web.app/delete-account.
- [ ] **Open Food Facts account**: `config/off_account.json` is still empty, so contributing has been off in every build so far. Either create a dedicated account at world.openfoodfacts.org (a password used nowhere else, as it's built into the app) and fill in the file, or launch without contributing.
- [ ] Authentication → Settings: check email enumeration protection is on. (The app asks for 6+ character passwords, Firebase's default; leave the length unless the app changes too.)

### Once Google has approved you

- [ ] **Create the app**: Play Console → Create app → YumSum, App, Free.
- [ ] **App content** forms (Claude can draft the answers): privacy policy https://yumsum.web.app/privacy, ads (none), app access (sign-in needed, so give Google a test email account with a password), content rating, target audience (18+), data safety, health apps, account deletion link.
- [ ] **First closed test**: Claude builds the bundle; upload it under Test and release → Testing → Closed testing, accept Play App Signing, add the 12 testers, and send them the opt-in link.
- [ ] Add the Play signing SHA-1 and SHA-256 (Test and release → App integrity → App signing) to **YumSum Android** in Firebase → Project settings (Google sign-in and App Check need them)
- [ ] App Check → change **YumSum Android**'s provider from Fraud Defense (the website's reCAPTCHA key, registered by mistake) to **Play Integrity**, and link the Cloud project `lean-streak-project` under App integrity → Play Integrity API in Play Console. Without this, AI fails in Play installs.
- [ ] After 14 days with 12 testers: Play Console → Dashboard → **Apply for production**.
- [ ] Once App Check metrics show nearly all requests verified: enforce App Check for **Cloud Firestore** and **Authentication**, not just AI Logic

## Known and accepted for now

- Email verification is only checked inside the app; an unverified account could still use the database through Google's API directly. Low risk.
- The daily AI allowance is counted by the app, so a modified app could skip it. App Check, the 10-a-minute per-user limit and the £3 spend cap are the real protection.
