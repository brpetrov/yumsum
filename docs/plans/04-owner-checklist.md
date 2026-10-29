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

- [ ] **Lock down the Firebase API keys** (most important security item)
  The keys in the app are public. If one may call the **Generative Language API** (Gemini itself), anyone can copy it and use Gemini directly, skipping App Check and the 10-a-day limit, on your credit. The app doesn't need it: its AI goes through the **Firebase AI Logic API**.

  Open https://console.cloud.google.com/apis/credentials?project=lean-streak-project. Under API Keys, click each key's name, scroll to **API restrictions**, and:
  - If it says **Restrict key**: open the APIs dropdown, untick **Generative Language API** if it's ticked, keep **Firebase AI Logic API** (formerly "Vertex AI in Firebase API") ticked, OK, Save.
  - If it says **Don't restrict key**: choose Restrict key and tick, using the filter box, whichever of these the list shows: Cloud Firestore API, Identity Toolkit API, Token Service API, Firebase App Check API, Firebase AI Logic API, Firebase Installations API, Firebase Crashlytics API. OK, Save.
  - Leave Application restrictions as they are.

  - [x] Browser key (auto created by Firebase), ends `u9to` (checked 29 October 2026)
  - [x] Android key (auto created by Firebase), ends `8ymM`
  - [x] iOS key (auto created by Firebase), ends `RX34`
  - [x] Delete the old AI Studio Gemini key, ends `sZZA` (deleted 29 October 2026 in aistudio.google.com/apikey): the app no longer uses it, but older website builds contained it, and it showed Gemini and Maps calls the app never made
  - [ ] Wait 5 minutes, then on the phone and on the website: sign in, and log a meal with an AI estimate. If anything fails, note the message here; choosing Don't restrict key again undoes it.

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

## Before Play closed testing (Claude can do these, just ask)

- [x] **Release signing**: Play only accepts builds signed with your own upload key. Claude wired it in (the build reads `android/key.properties`, which Git ignores) and fixed release builds, which had been failing since Crashlytics was added. (Done 29 October 2026.)
  - [x] Create the key: in the VS Code terminal run `mkdir $HOME\keys`, then `keytool -genkeypair -v -keystore $HOME\keys\yumsum-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`. Choose a new password (6+ characters) and answer the questions (your name is enough; Enter skips the rest), then `yes`.
  - [x] In `android/key.properties`, replace both `CHANGE_ME` with that password, and save.
  - [ ] Back up `C:\Users\brpet\keys\yumsum-upload.jks` and the password together somewhere safe (a password manager, or the file in Google Drive and the password in your head). If it's lost, Play support can swap in a new one, but it takes days.
  - [x] Claude built the app bundle: signed by `CN=Boyan Petrov`, upload key SHA-1 `A9:1D:7C:AF:C3:2E:51:1B:E8:31:5D:44:03:0F:76:B9:96:95:6D:4F`, SHA-256 `CA:F6:11:56:58:AD:A4:AA:D8:28:7C:16:6A:73:95:85:82:11:75:CC:76:F5:C6:8E:90:A9:D2:15:E6:EC:54:1F` (Play shows the same under App integrity → Upload key).
  - The bundle to upload: `flutter build appbundle --dart-define-from-file=config/off_account.json` (the Open Food Facts account goes in, so contributing works), file `build\app\outputs\bundle\release\app-release.aab`. Raise the `+1` in `version: 0.1.0+1` (pubspec.yaml) for every upload after the first.
- [ ] Add the Play signing SHA-1 and SHA-256 to **YumSum Android** in Firebase once Play App Signing is set up (Google sign-in and App Check need them)
- [ ] App Check → change **YumSum Android**'s provider from Fraud Defense (the website's reCAPTCHA key, registered by mistake) to **Play Integrity**. It only matters for release builds, which use Play Integrity.
- [ ] Once App Check metrics show nearly all requests verified: enforce App Check for **Cloud Firestore** and **Authentication**, not just AI Logic
- [ ] Authentication → Settings: check email enumeration protection is on, and set a minimum password length
- [ ] Open Food Facts: use a dedicated account with a password used nowhere else (it's built into the Android app)
- [ ] Play developer account, store listing (icon `assets/android/play_store_512.png`, a 1024×500 feature graphic, screenshots, privacy policy https://yumsum.web.app/privacy, account deletion URL) and 12 testers for 14 days

## Known and accepted for now

- Email verification is only checked inside the app; an unverified account could still use the database through Google's API directly. Low risk.
- The daily AI allowance is counted by the app, so a modified app could skip it. App Check, the 10-a-minute per-user limit and the £3 spend cap are the real protection.
