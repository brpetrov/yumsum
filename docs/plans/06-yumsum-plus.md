# Plan 6: YumSum Star

*Written 2 November 2026. Status: planned, not built. You agreed the contents on 1–2 November. Each big feature has its own plan (07–10). This one holds the decisions they all share, the two small features, and the order of work.*

## The short version

1. **YumSum Star** is the paid tier: **£2.99 a month or £17.99 a year**, with a **7-day free trial** of everything.
2. It pays for what costs money each time, or does thinking for you over weeks:
   - photo logging
   - more AI estimates
   - the **Adaptive formula**
   - the **AI weekly review**
   - **full macros**

   "What should I eat?" comes later.
3. **Everything free today stays free**, except photo estimates. The app hasn't launched, so nothing is taken away from anyone.
4. **All of it goes into the first closed test,** so your 12 testers can try it. They get it by a manual grant you set in the Firebase console; a few also try a purchase, which costs them nothing.
5. Logging is never paywalled: typing, barcodes, search, recipes, history and weight stay free for good.

## The name

**YumSum Star**, chosen on 2 November 2026 over YumSum+, Pro, Max and Gold:
- It's catchy, and no other calorie app uses it.
- The tier has a mascot: the smiling star you made from the logo (`design/plus-star.png`), which sits beside its name in the menu and Account Settings. The logo's smiling bowl with the star (`design/plus-hero.png`) heads the YumSum Star page and the card on Today.
- The wordmark is "YumSum Star" with "Star" in the icon's orange.

In the code it is still `plus` (`plusProvider`, `PlusScreen`), from before it had a name, as the Dart package is still `lean_streak`.

## What's in it

| Feature | What you get | Plan | Running cost to you |
|---|---|---|---|
| **Photo logging** | Photograph the plate; the AI lists the items with calories and protein | This plan | About 0.08p a photo |
| **More AI** | 30 AI estimates a day instead of 10, photos included | This plan | Only what's used |
| **Adaptive formula** | A personal adjustment on top of your plan. It learns from your weigh-ins and logged food and adjusts your target each Monday | `08-adaptive-formula.md` | Nothing: it runs on the phone |
| **AI weekly review** | Each Monday, at most 3 short notes on your finished week, in History | `09-ai-weekly-review.md` | About 0.1p a week |
| **Full macros** | Fat, saturates, carbs, sugars, fibre and salt beside calories and protein | `10-full-macros.md` | A little more per AI call (plan 10 measures it) |
| Later: **What should I eat?** | Three dishes that fit what's left today | `05-recipes.md` | About 0.25p a call |

Billing, the paywall and who counts as a subscriber are in `07-billing.md`.

## What stays free for ever

- Typing meals and numbers, the quick-log bar, voice logging, usual and recent meals
- Barcode scanning, food search and contributing to Open Food Facts
- The recipe library, Cooked recently and Log a portion
- History, the calendar and the period review
- Weight & Progress, including the new **weight trend line** from plan 08
- Day off, reminders, the home-screen widget
- Protein tracking
- **10 AI estimates a day**, typed or by voice
- Your data. UK GDPR gives people the right to take their data with them, so an export would be free too.

## Price and trial

- **£2.99 a month or £17.99 a year**, as plan 03 recommends.
  - The year is half the monthly price over 12 months.
  - Both are a third to a quarter of what the big apps charge: MacroFactor is about £60–70 a year, MyFitnessPal Premium about £65–80, Yazio PRO about £35–60.
- **What you keep after Play's 15% fee and 20% VAT:**
  - about **£2.12** from a monthly subscriber
  - about **£12.74 a year (£1.06 a month)** from a yearly one
- **The trial:**
  - **7 days of everything**, once per Google account. Play enforces that.
  - It turns into the chosen plan unless cancelled.
  - It is long enough to:
    - use photo logging every day
    - get one AI weekly review
    - see the Adaptive formula start learning

    Since 3 November the Adaptive formula learns from the first week (plan 08): what you burn moves after a week, and the target changes in small steps from then on. During a 14-day closed test, testers who weigh in will see it working.

## Photo logging and the AI allowance

### What people see

- **Free:**
  - 10 AI estimates a day, typed or by voice.
  - The **photo button stays in the bar** with a small "+" mark, so people know it exists. Tapping it opens the paywall with the trial.
- **YumSum Star:**
  - **30 AI estimates a day**, photos included.
  - The photo button works as it does today.
- **On the website:**
  - The paywall says to subscribe in the Android app.
  - A subscriber who signs in on the web gets everything, because YumSum Star belongs to the account, not the phone.
- **The "N AI estimates left today" hint** works as now, against the person's own limit, once half is used.
- **When a free user's 10 are gone,** the message says so and mentions YumSum Star once: "Today's 10 AI estimates are used up. Type the calories yourself, or get 30 a day with YumSum Star."

### Why 30, not 50

The limit has to cover the worst case, someone who uses every estimate every day:
- At 30 photos a day for a month, that's about **90p** with VAT. That is under the £1.06 a month a yearly subscriber leaves you.
- At 50 it would be about £1.50, which loses money on yearly subscribers.
- Real use is far lower. Even a heavy logger needs about 8–12 estimates a day, about 25–35p a month.

### What doesn't count

These work as today:
- **The automatic protein estimate** when a named meal is saved without protein stays uncounted and free.
- **Reading a label to contribute to Open Food Facts** (`readLabel`) stays free for everyone and counts towards the allowance. It's rare, and it improves the shared database.

### What gets built

- **`lib/repositories/ai_usage_repository.dart`:** `static const int dailyLimit = 20` (raised from 10 for testing on 30 October) becomes `static int limitFor({required bool plus}) => plus ? 30 : 10`.
- **`lib/providers/ai_usage_provider.dart`:** `calorieEstimateServiceProvider` watches `plusProvider` and passes the limit and the subscription to `CalorieEstimateService`.
- **`lib/services/calorie_estimate_service.dart`:**
  - The four checks against `AiUsageRepository.dailyLimit` (in `estimate`, `parseVoiceAudio`, `estimateFromPhoto` and `readLabel`) use the service's own limit.
  - `estimateFromPhoto` also refuses a free user with a `PlusRequiredException`. The button already stops them, so this is a second guard.
- **`lib/screens/dashboard/helpers/quick_log_bar.dart`:**
  - `_limitMessage`, `_aiLeft` and the half-used hint read the person's limit.
  - The photo button gets the "+" mark for free users.
  - `_takePhoto` opens the paywall instead of the camera for them.
- **Tests:**
  - `test/quick_log_bar_test.dart` overrides `plusProvider` both ways: a free user's photo tap opens the paywall, a subscriber's opens the camera.
  - The limit message and hint use 10 or 30.

The allowance is counted on the phone, as plan 03 explains. App Check (only the real app can call the AI), the per-user rate limit and the spend cap are the real protection.

## Timing: Mondays

Weeks run Monday to Sunday, as History counts them. On Monday:
- **The Adaptive formula** may change the target, and Today says so in one line (plan 08). It learns from every weigh-in during the week, but only changes the target on Monday.
- **The AI weekly review** of the finished week is ready in History (plan 09).

The two are separate features. The review mentions the formula's change when there was one.

## Order of work

Everything below goes into the build your 12 testers get. The order puts first what needs the longest to prove, and leaves what needs your Play account until last.

| Step | What | Why then |
|---|---|---|
| 1 | **The YumSum Star switch** (plan 07, first part): the account's YumSum Star record, `plusProvider`, a manual grant you set in the Firebase console, and the paywall screen without real purchases | Every feature below needs it. The manual grant lets you and early testers use YumSum Star before Play billing exists. |
| 2 | **Weight trend line** (plan 08, free part) | Small, useful to everyone, and the Adaptive formula is built on it |
| 3 | **Adaptive formula** (plan 08) | It needs weeks of your own weigh-ins and meals to prove, so it should start running on your phone first |
| 4 | **Photo logging and the allowance** (this plan) | Small once step 1 exists |
| 5 | **AI weekly review** (plan 09) | Needs finished weeks to try, which you'll have by then |
| 6 | **Full macros** (plan 10) | The biggest data change: new fields, a rules deploy, the 40 recipes' figures |
| 7 | **Real Play billing** (plan 07, the rest) | Needs your ID check passed, the app created in Play Console and a payments profile, so it comes last. It must be in the closed-test build |

Then the closed test. Each tester gets YumSum Star by a **manual grant** for the 14 days, because Play's test subscriptions stop after about half an hour (plan 07). All 12 also go on Play's licence-testing list, so the two or three you ask to try a purchase pay nothing. If billing isn't ready when the testers are, start the test with manual grants anyway: the 14 days are the longest wait.

## How to tell it's working

After launch, check once a month:
- **Trials started and converted** (Play Console → Monetise → Subscriptions). Plan 03 says about 1 in 30 daily users on YumSum Star covers everyone's AI. A typical freemium app converts about 2% of downloads.
- **AI cost per subscriber** on <https://aistudio.google.com/billing>, against the £1.06–£2.12 they leave you.
- **Cancellation reasons.** Play asks people who cancel and shows the answers.
- **Weigh-ins.** How many subscribers weigh in at least 3 times a week, since the Adaptive formula depends on it.

## Not in YumSum Star

- **Fasting timers.** A different habit, more notifications, and free apps already do it well.
- **Streaks and badges.** No pressure is part of what YumSum is.
- **Ads.** None anywhere, as decided on 24 October.
- **Meal plans.** "Plan my week" stays a later idea (plan 05).

## Risks

- **People who pay expect polish.** Each feature gets tried on your phone before the closed test, not just in tests.
- **Play approval can be slow.** Your ID check is still pending. The manual grant (step 1) means testers can try YumSum Star even if billing isn't ready, but purchases themselves must be tested before production.
- **Your address goes public** with a payments profile (plan 03). Decide before step 7.
- **One subscription across the web and phones** depends on the account record being right. Plan 07 keeps it written by the server only, so a modified app can't grant itself YumSum Star.

## Checklist

- [x] The name: **YumSum Star** (2 November)
- [x] (Claude) Step 1: YumSum Star switch, manual grant, paywall (plan 07), with admin and debug tools (2 November)
- [ ] (you) Grant yourself YumSum Star in the Firebase console (plan 07 explains how) and try every feature on the phone
- [ ] (Claude) Steps 2–6, one at a time, each tried on your phone
- [ ] (you) Once Google approves your account: create the app, payments profile, subscription and trial (plan 07)
- [ ] (Claude) Step 7: real billing; (you) deploy the functions and test a purchase as a licence tester
- [ ] (you) Closed test with 12 testers: a manual grant each, all on the licence-testing list, two or three try a purchase
