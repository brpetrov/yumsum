# Plan 14: Play store listing and forms

*Written 9 November 2026, for you to copy into Play Console. Every claim was checked against the code and `docs/features.md`. Where I could not be sure it says "Check:". The test account's email and password go into the console only, never into this file.*

## 1. Store listing

### English (United Kingdom)

**App name** (30 max): `YumSum: Calorie Tracker` (23)

**Short description** (80 max): `Log meals fast by typing, voice, photo or barcode. AI estimates calories.` (73)

**Full description** (4000 max, 2169 characters):

```
YumSum is a calorie and protein tracker built to be quick. Say or type what you ate, and it is logged in seconds.

LOG A MEAL YOUR WAY
- Type it, or tap the mic and say it.
- Scan a packet's barcode and pick your portion.
- Snap your plate or a nutrition label (plate photos are a YumSum Star feature).
- Pick from your recent meals, or log a recipe portion.
- Add the calories and protein yourself whenever you like.

AI ESTIMATES
Not sure what's in your meal? Ask for an estimate. YumSum gives calories, protein and a breakdown by item, which you can correct. When it has to guess how much or which kind, it asks you. There is a daily allowance of AI estimates, and you can always enter numbers yourself. Estimates are only estimates and can be wrong.

YOUR PLAN
- A daily calorie target worked out from your details and your goal.
- A protein target and a clear view of your day on the home screen.
- Weight in kg, lb or stones, with a trend line that smooths out the daily ups and downs.
- Take a day off when you need one.

HISTORY AND PROGRESS
- A calendar of your weeks and months, with each day's meals.
- Edit, copy or delete any meal, and add meals to past days.
- Weight and progress charts.

RECIPES
A library of recipes with photos. Log a portion in one tap.

REMINDERS AND SHORTCUTS
Optional reminders for meals and weigh-ins, an app-icon shortcut and a home-screen widget for quick logging.

YUMSUM STAR (OPTIONAL SUBSCRIPTION)
YumSum is free to use. YumSum Star adds:
- Smart Snap: log a meal from a photo.
- Triple the AI estimates each day.
- Adaptive formula: your calorie target adjusts to how your weight really changes.
- AI Coach: a short weekly review of your finished weeks.
- Detailed macros: fat, carbohydrate, fibre, salt and more.
Pay monthly or yearly through Google Play, and cancel any time in Google Play. A free trial is offered where you are eligible.

YOUR DATA
No ads. No selling your data. Delete your account and data any time in the app.

IMPORTANT
YumSum is for adults aged 18 and over. It gives general estimates, not medical advice. Talk to a doctor or dietitian before changing your diet.

Available in English and Bulgarian.
```

### Bulgarian (bg)

**Име** (30 max): `YumSum: Калории и протеин` (25)

**Кратко описание** (80 max): `Записвай храната бързо с текст, глас, снимка или баркод. AI оценява калориите.` (78)

**Пълно описание** (4000 max, 2326 characters):

```
YumSum е бърз тракер за калории и протеин. Кажи или напиши какво си ял и то е записано за секунди.

ЗАПИШИ ХРАНА ПО ТВОЙ НАЧИН
- Напиши я или натисни микрофона и я кажи.
- Сканирай баркода на опаковка и избери порцията си.
- Снимай чинията или етикета с хранителната информация (снимката на чинията е функция на YumSum Star).
- Избери от последните си храни или запиши порция от рецепта.
- Въведи калориите и протеина сам, когато поискаш.

ОЦЕНКИ С AI
Не си сигурен какво има в ястието? Поискай оценка. YumSum дава калории, протеин и разбивка по продукти, които можеш да поправиш. Когато трябва да налучка колко или какъв вид, те пита. Има дневен лимит на оценките с AI, а числата винаги можеш да въведеш сам. Оценките са само приблизителни и може да грешат.

ТВОЯТ ПЛАН
- Дневна цел за калории, изчислена от данните и целта ти.
- Цел за протеин и ясен поглед върху деня ти на началния екран.
- Тегло в кг, фунтове или стоуни, с линия на тенденцията, която заглажда дневните колебания.
- Вземи почивен ден, когато ти трябва.

ИСТОРИЯ И НАПРЕДЪК
- Календар на седмиците и месеците ти с храните за всеки ден.
- Редактирай, копирай или изтрий всяка храна и добавяй храни към минали дни.
- Графики на теглото и напредъка.

РЕЦЕПТИ
Библиотека с рецепти със снимки. Запиши порция с едно докосване.

НАПОМНЯНИЯ И ПРЕКИ ПЪТИЩА
По избор напомняния за храна и претегляне, пряк път от иконата на приложението и приспособление за началния екран за бързо записване.

YUMSUM STAR (ПО ИЗБОР, АБОНАМЕНТ)
YumSum се ползва безплатно. YumSum Star добавя:
- Smart Snap: запис на храна от снимка.
- Три пъти повече оценки с AI на ден.
- Адаптивна формула: калорийната ти цел се нагажда към това как наистина се променя теглото ти.
- AI Coach: кратък седмичен преглед на приключилите ти седмици.
- Подробни макроси: мазнини, въглехидрати, фибри, сол и други.
Плащаш месечно или годишно през Google Play и можеш да отмениш по всяко време в Google Play. Предлага се безплатен пробен период, ако имаш право на него.

ТВОИТЕ ДАННИ
Без реклами. Не продаваме данните ти. Можеш да изтриеш профила и данните си по всяко време в приложението.

ВАЖНО
YumSum е за пълнолетни, на 18 и повече години. Дава общи приблизителни оценки, а не медицински съвети. Поговори с лекар или диетолог, преди да променяш храненето си.

Приложението е на английски и български.
```

Check: the Bulgarian text uses "Smart Snap", "AI Coach" and "YumSum Star" as the app does; compare with `lib/l10n/app_bg.arb` if you want the listing to match the app's exact Bulgarian names (the app calls Smart Snap „Запис със снимка“ in places).

Check: prices are left out on purpose. Plan 11 sets £3.99 a month, £25.99 a year and 7 days free, but Play shows its own prices on the listing.

## 2. App content forms

| Form | Answer | Why |
|---|---|---|
| Privacy policy URL | `https://yumsum.web.app/privacy` | Served from `tools/hosting/privacy.html`, effective 9 November 2026. |
| Ads | No, the app contains no ads | No ad SDK in `pubspec.yaml` or the Android build; the policy says no advertising or ad trackers. |
| App access | All or some functionality is restricted, so add instructions (2.1) | Everything sits behind sign-in. |
| Content rating | Category: Utility, Productivity, Communication or other (2.2) | A tracking tool, not a game. |
| Target audience | 18 and over only | Terms and policy say not for under 18; onboarding accepts ages 18 to 120; plan 04 says 18+. |
| Appeals to children | No | 18+ only. |
| News app | No | Not a news app. |
| Government app | No | Made by an individual developer. |
| Financial features | My app doesn't provide any financial features | Only a Play subscription through Google Play Billing; no banking, loans, crypto or payments of its own. |
| Health apps | Yes. Features: Nutrition and weight management. Not a medical device, no diagnosis or treatment | Calorie, protein and weight tracking with general estimates; the terms say "Not medical advice". |
| Data safety | See 2.3 | |
| Account deletion | See section 3 | |

Check: in the Health apps form, do not tick the medical or clinical categories. If Play asks for a health disclaimer, the terms page and the listing's "Important" paragraph cover it.

### 2.1 Reviewer instructions (App access)

Paste into the instructions box. The email and password go into the console's own credential fields, not here.

```
YumSum needs an account. Sign in with the test email and password entered in the credentials fields. The account is already set up, so you go straight to Home.
1. Type a meal in the bar at the bottom, such as "chicken salad", tap the sparkle for an AI estimate, then the tick to save.
2. Open the menu (top left) for Recipes, History, Weight & Progress, AI Coach, Plan Settings, YumSum Star and Settings.
3. YumSum Star features (photo logging, AI Coach, Adaptive formula, macros) are switched on for this account.
4. Delete account is in Settings.
Google sign-in and email sign-up also exist. Email sign-up needs a confirmed email address, so use the test account.
```

Check: the test account must be a real, email-verified account with onboarding finished and YumSum Star granted by hand (`entitlements/{uid}`: `active` true, `source` `manual`). If you want the reviewer on the free tier, cut step 3.

### 2.2 Content rating questionnaire (IARC)

- Category: Utility, Productivity, Communication or other.
- Violence, sexual content, profanity, controlled substances, gambling, horror: No to all.
- Users interact or exchange content with other users: No. Nothing a user writes is shown to another user (feedback goes only to the developer).
- Shares the user's location with others: No.
- Digital purchases: Yes (the YumSum Star subscription).
- Unrestricted web access: No.
- Expected result: rated for everyone; the 18+ audience setting is separate.

### 2.3 Data safety

Global answers:
- Collects or shares user data: Yes.
- All data encrypted in transit: Yes (HTTPS to Firebase, the Cloud Functions and Open Food Facts).
- Users can request deletion: Yes (in-app Delete account, and the web page in section 3).
- Account creation methods: email and password; Google sign-in.
- Independent security review: No.

"Collected" means it leaves the device to us or a provider working for us. "Shared" means passed to a third party for its own purposes (Google's definition excludes providers acting on our behalf).

| Play data type | Collected / shared | Required or optional | Purpose | What it is in the code |
|---|---|---|---|---|
| Personal info: Name | Collected | Required | Account management, App functionality | Name from onboarding, or your Google account's name. |
| Personal info: Email address | Collected | Required | Account management, App functionality | Firebase sign-in; also the reply address on feedback (Formspree). |
| Personal info: User IDs | Collected | Required | Account management, App functionality | Firebase uid. |
| Health and fitness: Health info | Collected | Required | App functionality, Personalisation | Weight, target weight, height, age, sex, goal, and each meal's calories, protein and nutrients. Check: Play has no "diet" type; Health info is the safest fit for weight and meals. |
| Health and fitness: Fitness info | Collected | Required | App functionality, Personalisation | Activity level and training frequency, used for the calorie target. Check: could be filed under Health info alone; declaring both is the cautious choice. |
| Photos and videos: Photos | Collected and Shared | Optional | App functionality | Plate and label photos go through our Cloud Functions to the Google Gemini API and are not stored. A product you choose to contribute sends two photos to Open Food Facts, which publishes them. Check: marked Shared because the policy says Google may use Gemini content on this tier to improve its products and Open Food Facts publishes contributed photos; if you treat Gemini as your processor, only the Open Food Facts part is sharing. |
| Audio: Voice or sound recordings | Collected | Optional | App functionality | The mic first uses the phone's own speech recogniser (`speech_to_text`); only where that can't start, a short WAV clip is sent to Gemini through `aiEstimate` and not stored. Check: Android's recogniser may itself send audio to Google (the phone's service, not ours); I could not confirm from the code whether it works on the device alone. |
| App activity: Other user-generated content | Collected and Shared | Optional | App functionality | Typed or spoken meal text goes to Gemini for estimates (same Check as Photos). Feedback goes to Formspree and Gmail. |
| App activity: In-app search history | Collected and Shared | Optional | App functionality | Food search words and barcode numbers go to Open Food Facts with nothing about you. Check: Play may treat this as not collected because no identifier goes with it; declaring it is the cautious choice. |
| App activity: App interactions | Collected | Required | App functionality | Meals, weigh-ins, days off, daily AI-use counts and AI Coach notes in your account. Check: these are your own records, and some owners file them only under Health info. |
| Financial info: Purchase history | Collected | Optional (only if you subscribe) | App functionality | Subscription status, plan, trial, renewal and end dates and Google Play's purchase reference (`entitlements`, `playPurchases`). Card details are never seen. |
| App info and performance: Crash logs | Collected | Required (no opt-out found in the app) | Analytics | Firebase Crashlytics, Android and iOS only: device model, OS and app version and the trace of a crash or of an error the app showed, under a random installation ID and the account's uid; kept 90 days. |
| App info and performance: Diagnostics | Collected | Required | Analytics, Fraud prevention, security and compliance | Crashlytics diagnostics and Firebase's basic technical data. Check: declare only if you count these as collected beyond crash logs. |
| Device or other IDs | Collected | Required | Fraud prevention, security and compliance; App functionality | Firebase installation ID and Play Integrity / App Check tokens on AI and billing calls; a random installation ID also goes to Open Food Facts when you contribute a product. |
| Location | Not collected | | | No location permission. The country comes from the device's region setting and goes to the AI and, on a contribution, to Open Food Facts. Check: I treat a region setting as not "location"; confirm you agree. |
| Contacts, Calendar, Messages, Web browsing, Files and docs | Not collected | | | |

For every collected row: encrypted in transit Yes; users can request deletion Yes.

Who receives data (from `functions/src`, `lib/services` and the privacy policy):
- Google Gemini API: meal text, photos, label photos, voice clips, and the week's summary for AI Coach (`ai.ts`).
- Open Food Facts: barcode numbers and search words; for a contribution, photos, details, a random installation ID and the country (`off.ts`, `food_lookup_service.dart`).
- Formspree and Gmail: feedback (kind, text, app version, uid, email) and the confirmation and reset emails (`feedback.ts`, `email.ts`).
- Google Play: subscription status.
- Firebase (Auth, Firestore, Hosting, App Check, Crashlytics): the account store, security and crash reports.

## 3. Account deletion

Web link for Play: `https://yumsum.web.app/delete-account` (live since 9 November 2026, with `/delete-account-bg`): the steps in the app, deleting by email without it, and what is and isn't deleted.

- In the app (Settings > Delete account, confirmed with the password or Google) it deletes the profile, every meal, daily summary, weigh-in, day off and AI Coach note, the YumSum Star record and its Play purchase links, then the daily-count records and the sign-in account itself (`deleteAccountData` in `account_repository.dart`, `deleteAccount` in `functions/src/account.ts`).
- It does not cancel a Google Play subscription (cancel it in Play), a feedback email already sent stays in the developer's mailbox until asked to delete it, and photos contributed to Open Food Facts stay published there.

The page names the same exceptions, plus crash reports kept for 90 days.

## 4. Graphics checklist

- [x] App icon 512 x 512: `assets/android/play_store_512.png`
- [x] Feature graphic 1024 x 500: `tools/e2e/store/feature-graphic.png` (from `store/feature.html`, `node feature_shot.js`)
- [x] Six phone screenshots, 1080 x 1920: `tools/e2e/store/en-1-home.png` to `en-6-history.png` (`node screenshots.js` in `tools/e2e`, signed in as the test account): Home, typing with chips, the targets dialog, Recipes, Weight & Progress, History. YumSum Star's page and an AI estimate are best taken on the phone (the website's Star page says to subscribe in the Android app, and robot browsers can't use the AI).

Suggested six screenshots, in order (captions 30 characters max, counts in brackets):

| # | Screen | English | Bulgarian |
|---|---|---|---|
| 1 | Home: calories, rings and meals | `Your day at a glance` (20) | `Денят ти накратко` (17) |
| 2 | Quick-log bar mid-estimate | `Log a meal in seconds` (21) | `Запиши храна за секунди` (23) |
| 3 | AI estimate with its breakdown | `AI estimates, you correct` (25) | `AI оценява, ти поправяш` (23) |
| 4 | Barcode scan and portion sheet | `Scan packets, pick portion` (26) | `Сканирай и избери порция` (24) |
| 5 | Weight and progress chart | `Weight trend, no guesswork` (26) | `Тенденция на теглото` (20) |
| 6 | YumSum Star page | `Go further with YumSum Star` (27) | `Повече със YumSum Star` (22) |

Optional 7th and 8th: Recipes, and AI Coach on a finished week in History.

## Check: summary

Search this file for "Check:" to find every item left for you.
