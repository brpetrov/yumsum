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

- [ ] **Check the website** at https://yumsum.web.app/app/
  - [ ] Sign in with Google
  - [ ] Log a meal with an AI estimate

- [ ] **Lock down the Firebase API keys** (most important security item)
  Google Cloud → APIs & Services → Credentials. For each of the three auto-created keys (browser, Android, iOS):
  - [ ] Browser key: **Generative Language API** is not in its allowed APIs
  - [ ] Android key: same
  - [ ] iOS key: same

  If unsure which APIs to allow, send Claude a screenshot of one key.

## Feedback emails

- [ ] Create the Gmail account **help.yumsum@gmail.com**
- [ ] Turn on 2-Step Verification for it, then create an app password at myaccount.google.com/apppasswords (copy the 16 characters)
- [ ] Firebase → Extensions → install **Trigger Email from Firestore**:
  - Firestore location: the same as the database (Firestore → Databases shows it)
  - Authentication type: Username & Password
  - SMTP connection URI: `smtps://help.yumsum@gmail.com@smtp.gmail.com:465`
  - SMTP password: the app password
  - Email documents collection: `mail`
  - Default FROM: `YumSum <help.yumsum@gmail.com>`
  - Leave Users collection, Templates collection and Default REPLY-TO blank
- [ ] Optional: Firestore → TTL → add a policy on collection group `mail`, field `delivery.expireAt`, so sent feedback is cleared from the database
- [ ] Send a test from Account Settings → Send feedback and check it arrives

## Tidy up

- [ ] Firebase → Project settings → Your apps: delete `lean_streak (android)`, `LeanStreak Android` and `lean_streak (ios)`
- [ ] Push the commits to GitHub (say "push" to Claude, or use the Sync button)

## Before Play closed testing (Claude can do these, just ask)

- [ ] **Release signing**: create an upload key and wire it into the release build (release builds still use the debug key, which Play rejects). You keep the key file safe, outside Git.
- [ ] Add the Play signing SHA-1 and SHA-256 to **YumSum Android** in Firebase once Play App Signing is set up (Google sign-in and App Check need them)
- [ ] App Check → change **YumSum Android**'s provider from Fraud Defense (the website's reCAPTCHA key, registered by mistake) to **Play Integrity**. It only matters for release builds, which use Play Integrity.
- [ ] Once App Check metrics show nearly all requests verified: enforce App Check for **Cloud Firestore** and **Authentication**, not just AI Logic
- [ ] Authentication → Settings: check email enumeration protection is on, and set a minimum password length
- [ ] Open Food Facts: use a dedicated account with a password used nowhere else (it's built into the Android app)
- [ ] Play developer account, store listing (icon `assets/android/play_store_512.png`, a 1024×500 feature graphic, screenshots, privacy policy https://yumsum.web.app/privacy, account deletion URL) and 12 testers for 14 days

## Known and accepted for now

- Email verification is only checked inside the app; an unverified account could still use the database through Google's API directly. Low risk.
- The daily AI allowance is counted by the app, so a modified app could skip it. App Check, the 10-a-minute per-user limit and the £3 spend cap are the real protection.
