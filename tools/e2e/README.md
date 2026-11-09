# Browser tests

Signs in to the website as the test account and goes through it as a person would: onboarding (for a new account), logging a meal, its chip, Log again, Edit and Delete, the targets dialog, Recipes, History, a weigh-in, AI Coach, Plan Settings, YumSum Star, Settings (Bulgarian and back, dark mode), Reset all data and Log out. Buttons and boxes are found by the names Flutter gives them for screen readers.

```bash
cd tools/e2e
npm install && npx playwright install chromium firefox webkit   # once
export YUMSUM_TEST_EMAIL=… YUMSUM_TEST_PASSWORD=…              # the test account; never commit them
node run.js chromium                 # desktop Chrome
node run.js firefox
node run.js webkit "iPhone 13"       # Safari's engine as an iPhone (every iPhone browser uses it)
node run.js chromium "Pixel 7"       # Chrome as an Android phone
```

- It writes to the test account and clears it at the end with Reset all data (`KEEP=1` keeps it). `WRONG=1` tries a wrong password first; `BASE=` points it at another copy of the site, such as a local build on port 5000.
- Firebase allows only so many sign-ins an hour: after many runs it answers "Too many attempts". Wait, and run a few at a time.
- AI estimates aren't tested: App Check's reCAPTCHA refuses robot browsers. Camera, barcode and voice need real devices.
- A failed check saves a screenshot in `shots/`. `node steps.js chromium -- "tap:Recipes" dump` runs steps one by one and prints what's on screen, for writing new checks.
