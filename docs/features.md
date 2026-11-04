# YumSum feature notes

How each part of the app works, for when you're working on it. `CLAUDE.md` has the rules and the map; the code is the source of truth, and `docs/plans/` says why things are the way they are. Update the section you touch when a feature changes.

## Screens and navigation

**Home** (`DashboardScreen`, called Today in the code; titled with the user's first name, the date under it):
- Calories, then the protein and macro rings, the day's meals, a month graph and weight.
- The umbrella at the top right takes the day off (see Days).
- `PlusPromptCard` for free users; its cross hides it for 14 days.
- `WeeklyNotesLine` above the month card, for YumSum Star, until last week's AI Coach notes have been seen (see AI Coach).

**The quick-log bar** (`QuickLogBar`, `lib/screens/dashboard/helpers/quick_log_bar.dart`), pinned at the bottom of Home:
- Type the meal; the calories and protein go in two plain number boxes that appear under it once the bar is in use. The boxes have keys `quick-log-name`, `-kcal` and `-protein`.
- Beside the idle box: round buttons for a photo of the plate, a packet's barcode (phones only) and the mic.
- Once the bar is in use (text, or the keyboard up for it; not desktop's standing focus) they slide away for one round button: a sparkle (tooltip Estimate, greyed until there is a name), or a tick (Save) once there are calories.
- A tap on nothing in particular anywhere in the app (`appShellBuilder`), a scroll of Home, or a swipe down on the bar (which shows a drag handle while open) lets go of the box: the keyboard goes and an empty bar folds.
- Chips while a box is focused and there are no calories yet (`suggestionsFor` in `lib/helpers/meal_suggestions.dart`):
  - name empty: up to five meals usually logged around this time of day (`usualMealsAt`: at least twice within 90 minutes of now, not already logged today);
  - typing: up to three of the last 50 distinct meal names that match (`distinctRecentMeals`), own meals first, with a matching recipe (book icon) always given one of the three places, after a packaged-food search chip when not on the web.

**Other pages:**
- Editing a meal, or adding one to a past day, uses the meal form `showLogMealSheet` (`lib/screens/meals/log_meal_sheet.dart`), which has its own AI estimate.
- The top-left menu (`AppDrawer` in `lib/widgets/app_frame.dart`, on every page) lists Home, History, Recipes, Weight & Progress, Plan Settings, Notifications and Account Settings, then YumSum Star, and Debug tools where they're on offer. There are no bottom tabs.
- Home is the root and every other page sits one level above it: picking a page from inside another swaps it (`pushReplacement`), so Back always returns Home. YumSum Star opens over the current page instead.
- History (`ReviewScreen`, `/review`): a week/month calendar with the period review; tapping a day opens `showDayMealsSheet` (`lib/screens/review/day_meals_sheet.dart`) to add, edit or delete its meals.
  - For finished weeks in the week view, YumSum Star users get the AI Coach's notes (`WeeklyNotesCard`, plan 09) above the review.
  - It takes an optional `initialWeek` as `extra`, which opens it in the week view on that week.
- Plan Settings is `PlanSettingsScreen` in `lib/screens/profile/profile_screen.dart`; Account Settings is `AccountSettingsScreen` on `/profile`.
- Routing: `goRouterProvider` listens to `authStateProvider` and `userProfileProvider` and enforces Splash → Auth → Onboarding → Home; a profile that fails to load goes to `ProfileLoadErrorScreen`.

## Look and feel

- Warm light and dark palettes: `AppPalette.light` / `.dark` in `lib/core/constants/app_colors.dart`; `test/app_colors_contrast_test.dart` checks their WCAG contrast.
- `AppColors` is static getters switched by `AppColors.isDark`, which `LeanStreakApp` sets from the stored ThemeMode (System/Light/Dark in the menu, `themeControllerProvider`) and the platform brightness. So expressions using `AppColors` can't be `const`.
- `AppTheme.light`/`dark` are built from the palettes. On wide browser windows `appShellBuilder` (`lib/app/app.dart`) shows the app as one centred column.
- Colours follow the YumSum icon: cream backgrounds; the icon's orange (`primary`) for actions (buttons, links, focus, the mic); its arc green (`veryGood`) for on track and progress (Home's bars and rings, the month bars, the weight chart); amber for close; raspberry red for off track and errors.
- Fonts: Nunito for body text; Fredoka for headings, app bar titles and big numbers (no Cyrillic, so it falls back to Nunito). Both are bundled in `assets/fonts`, their OFL licences registered in `main()`.
- Shapes are round and roomy: pill buttons and chips, 28px cards on a warm shadow (`AppCard`, `lib/widgets/app_card.dart`), round calendar days, `PillToggle` for two- and three-way switches, `IconBubble` behind icons, `BowlNote` (the smiling bowl) for empty states.
- `AppLogoMark` shows `assets/logo.png` on the icon's gradient tile on phones; the web paints a drawn version (`_BowlPainter`), which stays sharp small.
- App icons for every platform come from `design/` via `python -I tools/make_icons.py`, along with `drawable-xxxhdpi/splash_icon.png`, the bowl alone that Android 12's launch screen shows (`values-v31/styles.xml` and the night one).
- `web/index.html` draws the same splash as `SplashScreen` in HTML and SVG while the app loads, so the hand-over is seamless. `main()` draws `SplashScreen` before Firebase and the reminders are set up, which is what dismisses the phone's launch screen.

## Device settings

SharedPreferences through `sharedPreferencesProvider` (`lib/providers/preferences_provider.dart`), overridden in `main()` so readers never wait (unoverridden it throws). Keys:
- `theme_mode`
- `reminders.*` (switches, times, `creatine_offered`)
- `off.app_uuid`, `contributions.count`
- `feedback.sent_day`, `feedback.sent_count` (3 feedback messages a day)
- `plus.prompt_hidden_until`
- `adaptive.intro_shown`, `adaptive.lapse_notice` (the Adaptive formula's one-time dialogs)
- `weekly_review.seen` (the Monday of the latest week whose AI Coach notes History has shown)
- `debug.account` (Debug tools' pretend account)

## Firestore data and resets

- The profile is `/users/{uid}`; everything else is in subcollections: `meals`, `daily_summaries` and `weight_entries` (both keyed by date), `ai_usage/{yyyy-MM-dd}`, `day_edits/{yyyy-MM}`, `days_off/{yyyy-MM-dd}` and `weekly_reviews/{yyyy-MM-dd}`.
- Period reviews are computed, never stored; only the AI Coach's notes are cached, in `weekly_reviews`, with the facts they were written from. Legacy `check_ins` and `check_in_prompt_status` documents are only deleted with the account.
- Repositories in `lib/repositories/` do the reads and writes; `AccountRepository` does the bulk deletes.
- Reset progress (Weight & Progress) clears `weight_entries` only. Reset all data (Account Settings, `AccountRepository.resetAllData`) clears meals, summaries, weigh-ins, days off and the AI Coach's notes, but keeps the profile and the AI and past-day counters.
- The rules only let those counters go up by one, and only delete them once the profile is gone; account deletion deletes the profile first.
- Reset all data and account deletion re-authenticate first (`AccountController`): with the email password, or with Google for a Google-only account.
- YumSum Star lives outside the user's tree in `entitlements/{uid}`, which the app can only read (see YumSum Star).

## YumSum Star

The paid tier (plan 06; the code says `plus`).
- **The record:** `entitlements/{uid}`, written by the server (the billing functions, plan 07) or by the owner in the console.
  - A manual grant is `active` true, `source` `manual` and an optional `expiresAt`.
  - `admin` true is YumSum Star for good with no daily AI limit (`aiDailyLimitProvider` is null) and no past-day change limit.
  - `dev` true is admin plus Debug tools in every build.
- **Providers** (`lib/providers/plus_provider.dart`): `entitlementProvider` (with Debug tools' pretend account applied), `plusProvider`, `adminProvider`, and `realEntitlementProvider` / `debugToolsProvider`, which read the real record so pretending never hides Debug tools. Tests override `entitlementProvider`.
- **The page:** gates call `showPlusPaywall`, which opens `PlusScreen` (`/plus`), a one-screen promo (a smaller bowl on screens under 800 px tall).
  - It names Smart Snap (photo logging), Triple the AI estimates, Adaptive Formula, AI Coach (the weekly review) and Detailed Macros.
  - On Android the yearly and monthly tiles show Play's own prices (`starPlansProvider`), with the yearly price as the big number, its monthly cost and saving worked out from Play's figures. "Start 7 days free" and the trial wording only when Play offers this Google account the trial; otherwise "Subscribe".
  - Restore purchase, and "Could not reach Google Play…" with Try again when the plans don't load.
  - Once YumSum Star switches on after a purchase or restore started there, it closes with "YumSum Star is on." (and the trial's end date).
  - On the web it says to subscribe in the Android app; on an iPhone, that it can't be bought there yet.
- **Billing** (plan 07), Android only (`playBilling`):
  - `BillingService` (`lib/services/billing_service.dart`) wraps `in_app_purchase`: the plans (`starPlansFrom` picks each base plan's trial offer when Play lists one), buy, restore, complete.
  - `BillingRepository` calls the `verifyPurchase` and `deleteBillingData` functions in `europe-west2` (`functions/`).
  - `plusPurchaseControllerProvider` (`lib/providers/plus_purchase_controller.dart`) listens to Play's purchase stream for the app's life (`LeanStreakApp` keeps it alive). It sends every purchased or restored YumSum Star purchase to `verifyPurchase`, then completes it; the server's write to the record is what switches YumSum Star on. It shows the plan's messages (pending, not confirmed, linked to another account, nothing to restore). Signed in without YumSum Star, it restores quietly once per account at start-up.
  - Buying passes a SHA-256 of the uid as Play's account ID.
  - Deleting an account calls `deleteBillingData` first when the account has a record. The delete dialog warns while a Play subscription still renews (`renewsInPlay`).
  - Tests use `test/billing_fixtures.dart` (`FakeBillingService`, `FakeBillingRepository`); screens that open the page or pump `LeanStreakApp` override `billingServiceProvider` and `realEntitlementProvider`.
- **The look** (`lib/widgets/plus_mark.dart`):
  - `PlusMark`: the wordmark, with "Star" in orange.
  - `PlusStar`: the smiling star, `assets/plus/star.webp`.
  - `PlusHero`: the bowl with the star on a drawn glow, `assets/plus/hero.webp`.
  - Both images come from the owner's pictures in `design/plus-*.png`.
- **Where it shows:**
  - A row in the menu.
  - `StarBadge` beside the logo in the menu header and beside the name on Home: the star for members, a "Become a Star" chip for everyone else, nothing while the record loads.
  - The members' star shines when it appears (`Shine`, `lib/widgets/shine.dart`): a white glint sweeps across it three times, then rests, and again when a page that covered it goes away (so each return to Home, which stays under the menu's pages), but not after a dialog or sheet; none when the phone asks for less motion. The Adaptive formula's On chip and the free Adaptive formula and AI Coach buttons use it too.
  - A card in Account Settings.
  - `PlusPromptCard` on Home.
  - The dimmed macro rings for free users, the shining Adaptive formula button under the weight chart, and the shining AI Coach button on finished weeks in History.
- **Debug tools** (`/debug`, `DebugScreen`), in debug builds and for dev accounts in any build:
  - the User ID to copy;
  - "Pretend to be" (`debugAccountProvider`): free, subscribed, trial, ended or admin, on that device. A pretend account is real enough to change the Adaptive formula on the real plan.

## Plan, weight and the trend

- `HealthCalculator` (`lib/helpers/health_calculator.dart`) is pure static functions: BMI, BMR (Mifflin-St Jeor), TDEE, the daily calorie target with per-gender minimums (male 1,500, female 1,200, other 1,350), the protein target (grams per kg of goal weight, by training frequency) and `macroTargets`.
- Logging a weight (`WeightLogService`) re-plans from it. Deleting the newest weigh-in (the bin on its card on Weight & Progress) takes the plan back to the one before; deleting an older or the only one leaves it.
- Stored plans are recalculated at startup by `activityScaleMigrationProvider` when a profile's `planCalculationVersion` or `activityScaleVersion` is behind the constants in `lib/models/user_profile.dart`.
- **The trend** (free): `weightTrend` in `lib/helpers/weight_trend.dart`, an exponentially smoothed average (0.9 a day, allowing for gaps). A weigh-in more than 3% off the trend is set aside unless the next one agrees. Weight & Progress draws the weigh-ins as dots (hollow when set aside) under the trend line.
- Onboarding and Plan Settings accept ages 18–120, matching the legal pages.

## Protein

`UserProfile.trackProtein` (default true, read through `trackProteinProvider`), asked in onboarding and switchable in Plan Settings.
- Off hides protein everywhere: Home's ring, the quick-log box, the meal form, meal rows, the day sheet, the breakdown, the portion sheets, the bar tooltips and the recipes.
- Off also stops `LogMealController`'s automatic protein estimate. Protein the AI returns anyway is still saved, so switching back on loses nothing.

## Macros

YumSum Star only (plan 10). `macrosForEveryone` in `calorie_estimate_service.dart` stays false for good: the owner's decision of 4 November 2026, whatever the cost.
- **Data:** fat, saturates, carbs (without fibre, as UK labels give it), sugars, fibre and salt (never sodium; sodium × 2.5).
  - In grams, as one `Nutrients` value (`lib/models/nutrients.dart`) on `Meal.macros` and `DailySummary.macros` (totals over the meals that have them).
  - Stored as six optional flat fields to 0.1 g: `fatGrams`, `saturatesGrams`, `carbsGrams`, `sugarsGrams`, `fibreGrams`, `saltGrams`. They're in both `hasOnly` lists in `firestore.rules`.
- **Sources:**
  - Open Food Facts nutriments (`PackagedFood.macrosPer100g` via `nutrientsFromOff`, scaled by `portionFor`) and a contribution's label figures. These are saved for everyone, as they cost nothing.
  - Recipes (`Recipe.macrosPerPortion`, `macrosFor`). Every ingredient has the six; the asset test checks the sums, saturates ≤ fat, sugars ≤ carbs, and 4 × protein + 4 × carbs + 9 × fat + 2 × fibre within 15% of the kcal.
  - Chips (`MealSuggestion.macros`).
  - The AI, for YumSum Star only: estimates ask for six whole-meal totals, with no per-item macros. `parseNutrients` drops a set with saturates above fat or sugars above carbs. `LogMealController`'s fill-in on saving (`estimateNutrients`, uncounted) adds them to a named meal that has none.
- **Keeping them right:** the quick-log bar and the meal form keep macros with the calories they came with and scale them to the calories saved; a new name, Clear or the mic drops them. An edit given none keeps the meal's own, scaled to its new calories, unless it was renamed (`macrosAfterEdit`).
- **Home:** `MacroRings` (`lib/widgets/macro_rings.dart`), under the calorie bar, with no heading.
  - Rings in the bars' green: protein (when tracked), then carbs, fat and fibre, then the limits: sugars, saturates and salt, scrolling to the right.
  - Each is against a target from the plan (`HealthCalculator.macroTargets`): fat 30% of the calories, carbs the rest after protein and fat, saturates at most 10%, all sugars at most 18%, fibre at least 30 g, salt at most 6 g.
  - Colours: protein and fibre stay green however far over. Carbs and fat are judged like the calorie bar: green up to 10% over, amber up to 20%, red past that. Sugars, saturates and salt turn amber past their limit and red past 20% over.
  - A tap on a ring opens the guide. The card's info button, at its top right beside the status pill, opens it with calories first ("Your targets").
  - A ring's round ends are allowed for, so a ring just under its target stops short of the top and a full one's ends meet there.
  - Free users see the protein ring live and the rest dimmed (30% opacity) and part-filled, with no figures, under an "Unlock full macros" chip; a tap anywhere there opens `/plus`.
- **Elsewhere:**
  - History's day sheet uses `MacroTotals` (`lib/widgets/macro_totals.dart`): one line of fat, carbs and salt that opens to all six, with "at least" where some meals lack a figure.
  - A `MealRow` with macros shows an orange "Nutrition" hint beside its time, and a tap shows its `macrosLine`, with protein between fibre and salt as on a food label when protein tracking is on.
  - There's one line on the recipe page and the amount sheet.
  - Macros aren't shown on recipe tiles, the AI breakdown, the month graph or the period review.
- **The guide** (`showMacroGuide`, `lib/widgets/macro_guide.dart`), from the rings, Home's card and the day sheet: from the card, first a short calories item (what you burn less a set amount for your pace, never below the minimum); then the macros in three groups that match the ring colours (aim for, keep in balance, keep under), each with one line on why it matters and one on how its target is set. No figures; the rings have those.

## Adaptive formula

YumSum Star (plan 08).
- **The target:** target = the formula's plan + a personal adjustment (`calculatePlan(adaptiveKcal:)`), applied to the burn before the calorie minimum. Away from the minimum the goal date stays; at the minimum it moves later. It never plans a faster loss than the chosen pace.
- **The calculator:** `AdaptiveFormula` (`lib/helpers/adaptive_formula.dart`, every constant there).
  - `measure` fits one slope through the last 7 to 42 days of weigh-ins, split at breaks of 3+ unlogged days, and compares the measured burn with the formula's. `AdaptiveMeasure.burn` is the formula's burn moved towards the measured one by the confidence.
  - `monday` scales the gap by confidence and applies the limits: 5% of the plan a week (scaled by days ÷ 21 in the first 3 weeks), 15% in all, "unusual" past 20%, a 20 kcal dead band, and two Mondays in a row before a cut.
  - It acts from a week of data with 3 weigh-ins, 2 in the finished week. Trust grows each week to full at 6, and needs 4 weigh-ins a week for full marks.
- **Only on Mondays:** `adaptiveMondayProvider` (`lib/providers/adaptive_formula_provider.dart`, watched in `LeanStreakApp`) runs on the first open on or after a Monday, once a week (`adaptiveWeek`), never on a weigh-in.
  - It prints an "Adaptive: …" debug line plus the window's JSON.
  - `test/adaptive_replay_test.dart` replays that JSON from the gitignored `config/adaptive_replay.json`.
- **Always on with YumSum Star:** there is no switch. Without enough weigh-ins it simply has nothing to say and the plan stands.
- **Profile fields** (in `firestore.rules` too):
  - `adaptiveKcal`
  - `adaptiveWeek` and `adaptiveFrom` (yyyy-MM-dd)
  - `adaptiveNote` (the Monday's `AdaptiveNote`; `off` after a lapse or a reset, which the next run treats as starting fresh)
  - `adaptiveChanges` (the last 6 `{week, from, to}`)
- **Resets and pauses:**
  - Every re-plan passes the adjustment on (weigh-ins, the migration, Plan Settings).
  - Changing age, height, gender, movement or training resets it and sets `adaptiveFrom` to that day, as Reset progress and Reset all data do.
  - Turning the creatine reminder on sets `adaptiveFrom` 28 days ahead.
  - Without YumSum Star it is frozen for 2 weeks from `Entitlement.endedAt` (a one-time dialog says when), then goes to 0.
- **Where it shows:**
  - Home: that week's result as one line on the target card (`adaptiveTodayLineProvider`).
  - Plan Settings: a row with the sum (`adaptiveSumLine`) and how well it knows you (`adaptiveStageLine`, from `adaptiveProgressProvider`); the star for free users, whose tap opens `/plus`.
  - Weight & Progress: `AdaptiveSection` (`lib/screens/progress/helpers/adaptive_section.dart`), under the chart in its card.
    - With YumSum Star: the title, a solid green "✨ On" chip whose white glint sweeps across three times when it appears (none when the phone asks for less motion), and the info button on the right. Then two plain lines, each with an icon and a note: "You burn 2440 kcal a day" (`adaptiveBurn`, measured up to yesterday; "Learnt from your weigh-ins and meals." or, before it has learnt anything, "A first estimate. It learns as you weigh in.") and "Your target is 1620 kcal a day" ("To lose 0.75 kg a week." or "To keep your weight steady."). Then the stage and this week's line.
    - Free users: the name itself is the button (`TryButton`, `lib/widgets/feature_intro.dart`, shared with AI Coach), a warm orange pill with an arrow and a soft glow that shines when it appears (the star waits in the dialog's Enable), over "A customised formula tailored just for you. Adapting with time and your weigh-ins." No info button and no numbers, so it invites rather than knocks the standard plan. A tap opens the dialog, which offers Enable.
- **The explainer:** `showAdaptiveIntro` (`lib/screens/dashboard/helpers/adaptive_dialogs.dart`, laid out by `FeatureIntroDialog`, shared with AI Coach), titled "Adaptive formula" over "A target that learns from you": four bold promises (finds your real burn, adapts to your body, beats plateaus, learns as you go), each with one short line. With YumSum Star, "Log weight now" opens the weigh-in dialog (`logWeightWithFeedback`); without it (`plus: false`), "Enable" with the star opens `/plus`. The other button is Close. It is shown once after subscribing, from Plan Settings and the info button under the chart, and from the free users' button.
- **Tests:** the seeded simulator in `test/adaptive_fixtures.dart`.

## AI Coach

The AI weekly review, YumSum Star (plan 09); users only ever see it called AI Coach.
- **The facts:** the app works out every fact and the AI only writes. `buildWeekFacts` (`lib/helpers/week_facts.dart`, pure) gives the lines the AI is told:
  - the days logged, the target and the calorie minimum, what History's card already shows, and each day;
  - weekdays against the weekend, steady weekdays, the biggest day, days under the minimum, and a usual big day over the last 4 weeks;
  - protein, and the first meal of the day (by logging order, only on days whose meals were all logged on the day) with ideas from the user's own first meals and the library's breakfasts;
  - fibre, salt, sugars and saturates against the guides (`macroTargets`), each on days where every meal has it, with where the salt came from and fibre-rich recipes under 2 g of salt;
  - how many weigh-ins (never the weights), and the Adaptive formula's change on that week's Monday.
  - Days off are left out of every pattern, average and tip; fat and carbs never appear. The same data always gives the same lines.
- **The call:** `WeeklyReviewService` (`lib/services/weekly_review_service.dart`).
  - `weeklyReviewInstruction` as a system instruction, the facts as the message, and a response schema (`points`, at most 3).
  - `parseReviewPoints` keeps at most 3 notes, dropping any over 160 characters, with a number not in the facts, or with a shaming word; none left is a failure, and nothing is saved.
- **When:** only for finished weeks with at least 4 judged days (logged, not taken off), when a subscriber opens the week in History.
  - `weeklyReviewProvider` rebuilds the facts each time and keeps the notes in `weekly_reviews/{Monday}` with `basis`: `weeklyReviewPromptVersion` and the facts as sent. The AI is asked again only when `basis` changes, so raise the version whenever the instruction or the facts change.
  - `refreshHistory` invalidates it.
- **Where it shows** (`lib/screens/review/weekly_notes.dart`):
  - `WeeklyNotesCard`, first in a finished week's review: the notes and "Written by AI from what you logged.", or why there are none for a thin week, a spinner, or "Could not get this week's notes. Try again." with Try again. Numbers keep their units on one line. The info button opens `showCoachIntro`.
  - Free users get the shining AI Coach button (`TryButton`) and a line on weeks that would have notes, and nothing on thin weeks. Either opens `showCoachIntro(plus: false)`, whose Enable opens `/plus`.
  - `WeeklyNotesLine` on Home, for YumSum Star: when last week had 4 judged days and its notes haven't been shown (`weekly_review.seen`, which only moves on). It opens History on last week.

## Days

- **Daily summaries** (`lib/services/daily_summary_service.dart`): `recomputeForDate` rebuilds a day from its meals whenever one is logged, edited or deleted (and on a day-off toggle or weigh-in), and deletes the summary when the day has no meals.
  - It holds the calorie, protein and macro totals, the meal count, and a status: within ±10% of target is green, ±20% yellow, else red.
- **Not judged mid-day:** a day only shows its status once it is finished, on track or over target (`hasSettledStatus` in `lib/widgets/day_status.dart`).
- **Day off:** the umbrella on Home (`confirmDayOff` explains it first; tap again to go back on plan; `DailySummaryService.setDayOff`).
  - It is stored in `days_off/{date}` (`DayOffRepository`), because the summary is rewritten on every meal change and deleted when a day has no meals. `recomputeForDate` copies it into `DailySummary.dayOff`.
  - A day off never shows a status.
  - Period reviews count its calories but leave it out of the tally, the consistency rate and best/worst day, reporting a days-off count instead.
- **Past-day changes:** adding, editing or deleting a meal on an earlier day uses one of 10 a calendar month (`DayEditRepository.monthlyLimit`). Once they're used up, `LogMealController` fails with `EditLimitExceededException`. Admin has no limit.
- **Period reviews** (`lib/services/period_review_service.dart`): weekly and monthly figures from the summaries, under the History calendar for finished days.

## AI

- **Model:** Gemini 3.5 Flash-Lite through Firebase AI Logic (`firebase_ai`, the Gemini Developer API backend, `FirebaseAI.googleAI()`), so there's no API key in the app. The project needs AI Logic enabled (console → Build → AI Logic).
- **Billing:** the Blaze plan with the Gemini API's paid tier (since 24 October 2026, required for UK/EU users). $5 is prepaid in AI Studio with auto-reload off, there's a £3/month spend cap on "Gemini Developer API (AI Logic)", and the per-user limit is lowered to 10 requests a minute (plan 03).
- **Estimates** (`lib/services/calorie_estimate_service.dart`):
  - Every estimate prompt (`estimate`, `parseVoiceAudio`, `estimateFromPhoto`, `estimateNutrients`; not `readLabel`) opens with `nutritionContext`, built from the profile's `country` and `usualFood` (asked in onboarding, editable in Plan Settings; older profiles default to the UK and Bulgarian home cooking). It also keeps meal and item names in the user's language.
  - Estimates return calories, protein and a per-item breakdown with grams (`EstimateItem`).
  - `EstimateBreakdown` shows the breakdown as one line that expands on tap; correcting an item's grams rescales it (`resized`, `totalOf`) with no further AI call.
  - `estimateFromPhoto` sends a resized JPEG with the same prompt.
- **AI Coach** is the one call that isn't an estimate (see AI Coach): no `nutritionContext`, a system instruction and a response schema. It shares `aiModelId`, `generateWithRetries` and `decodeAiJson` with the estimates.
- **Voice:** records a short clip with `record` (16 kHz mono PCM, wrapped as WAV by `lib/helpers/wav.dart`) and sends the audio to Gemini (`parseVoiceAudio`), which understands English, Bulgarian or a mix with no language setting. Recording ends on Stop, after a pause once something was said, or at 30 s.
- **The daily allowance:** typed, voice and photo estimates and a contribution's `readLabel` share `AiUsageRepository.dailyLimit` (20 a user a day for now; plan 06 makes it 10 free and 30 for YumSum Star), counted in Firestore.
  - The save-time fill-in (`estimateNutrients`) doesn't count, and nor does AI Coach.
  - The counter is client-side and not tamper-proof; App Check, the per-user rate limit and the spend cap are the real protection.
  - The bar shows how many are left once half are used, and the mic says so before recording once none are.
- **Errors:** `aiErrorMessage` maps server errors by their wording.
  - Not enabled → `aiNotSwitchedOnMessage`.
  - 402 or billing → `aiPausedMessage`.
  - Quota or 429 → `aiBusyMessage`, not retried (the paid tier's limits are per minute).
  - 5xx and connection errors get up to 3 attempts.
- **Logging:** each call's token counts go to the debug log ("AI tokens: …").
- **App Check:** every AI call carries a token (`lib/core/config/app_check.dart`, activated in `main()`). App Check enforcement is mandatory for AI Logic from 2 November 2026.
  - Debug builds use the debug provider; its token, printed in the log at startup, must be registered under App Check → Apps → Manage debug tokens.
  - Release builds use Play Integrity on Android and DeviceCheck on iOS.
  - The web uses reCAPTCHA Enterprise (Fraud Defense in Google Cloud) with the public site key in `recaptchaSiteKey`.
  - `web/index.html` turns the debug token on for localhost. Run the web app on a fixed port (the VS Code "YumSum (Edge)" config uses `--web-port 5000`): the token is stored per origin in the browser profile Flutter keeps under `.dart_tool/chrome-device`, and must be registered under the `lean_streak (web)` app.

## Packaged foods and Open Food Facts

- **Scanning (phones):** the bar's barcode button opens `MealCameraPage.barcode` (`camera` plugin, 720p).
  - Every preview frame (NV21 on Android, BGRA on iOS) goes to ML Kit's on-device barcode reader (`google_mlkit_barcode_scanning`, retail formats only), and the first barcode closes the page.
  - The photo button opens `MealCameraPage.photos`, a shutter for the AI.
  - The page lets the camera go when the app is backgrounded and picks it up on return.
  - Elsewhere `openMealCamera` (`lib/screens/dashboard/helpers/meal_photo.dart`) falls back to a file picker, and the barcode button isn't shown (`hasBarcodeScanner`).
  - ML Kit needs iOS 15.5+, so an iOS build has to raise the deployment target (still 13.0).
- **Lookup:** `FoodLookupService.byBarcode` calls `/api/v2/product/{code}.json`. Only the barcode is sent; `app_name` and the User-Agent identify the app. An unknown barcode is reported with a nudge to photograph the packet.
- **Search:** the search chip (typed name, no calories, 3+ characters) opens `showFoodSearchSheet` (`FoodLookupService.search`, the profile's country first). It isn't on the web, because `search.openfoodfacts.org` sends no CORS header.
- **Portions:** `showPortionSheet` asks for the grams (prefilled from `serving_size`, else `quantity`, else 100). Done fills the bar's boxes with the label figures, and the meal is saved from the bar. No AI call, no allowance used.
- **Pack photos:** `PackPhoto` (`lib/widgets/pack_photo.dart`) shows the front of the pack (`PackagedFood.imageUrl`, from `image_front_small_url`): 48px in search results, 72px in the amount sheet, left out when there's none.
- **Contributing an unknown product** (`BarcodeLookup.listed` false), via `_offerContribution` in the bar:
  1. `inviteToContribute`.
  2. `takeProductPhotos`: `MealCameraPage` with `photoSteps`, each on a `PhotoStepCard` ("Step 1 of 2" and a tip): the front, then the nutrition table.
  3. `showContributeSheet`, prefilled by `readLabel` (one Gemini call with both photos, counted, told to copy the label and never guess), for the user to check.
- **Adding nutrition to a listed product without calories** (`BarcodeLookup.needsNutrition`, a `ListedProduct`): "Add its nutrition" takes one photo of the table and shows a form with only the figures, plus the name or serving size if the product has none.
  - `FoodContributionService.addNutrition` sends just those, and the nutrition photo if it has none, never touching the name, brand or front photo.
  - A listed product with calories but no name is not offered.
- **Sending:** `FoodContributionService` posts to `cgi/product_jqm2.pl` and each photo to `cgi/product_image_upload.pl` (`front_<lc>`, `nutrition_<lc>`), under the app's shared account, with a random per-install `app_uuid` so moderators can block one contributor.
  - `product_name_<lc>`, with `lc` from the language `readLabel` reads off the pack, else `productLanguage`.
  - `add_brands`.
  - `add_countries` and `cc`, only for recognised UK/Bulgaria spellings.
  - `nutriment_<id>` per 100 g, or per 100 ml for volume packs.
- **The account:** set at build time with `--dart-define-from-file=config/off_account.json` (`OFF_USER_ID`, `OFF_PASSWORD`, `OFF_HOST`; gitignored, copy `config/off_account.example.json`; the VS Code Android config passes it).
  - `OFF_HOST` defaults to `world.openfoodfacts.org`; `world.openfoodfacts.net` is their test server, with its own accounts and the shared basic-auth login off:off.
  - Without an account (`FoodContributionService.isConfigured`), or on the web, contributing isn't offered.
  - `--dart-define=OFF_DRY_RUN=true` (the "YumSum (Android, contribute dry run)" config) offers it anyway but only prints what would be sent; the AI reading still runs and counts.
- **Afterwards:** a thank-you screen counts contributions per device, and the product can go straight to the portion sheet. Set-up steps are in plan 01.

## Recipes

- **The library:** bundled as `assets/recipes/recipes.json`, read strictly by `Recipe.fromJson` (`lib/models/recipe.dart`, `parseRecipes`), loaded once by `recipesProvider`.
- **`RecipesScreen`** (`/recipes`):
  - A search box (`searchRecipes`): every word must be in the name, meal, cuisine, labels or ingredients. Plurals, accents and half-typed words don't matter. A few everyday words stand for others (`_alsoMeans`: fish, pasta, veggie, cheese…). A word that only describes the next one, like the egg in egg noodles, counts only when the search names both (`_describes`).
  - "Cooked recently" (`recentlyCookedRecipes`: the last 14 days' meal names, a ` × n` suffix stripped; hidden while searching).
  - Category `ChoiceChip`s, and photo tiles under a heading per meal (kept when one meal is picked), each with a + that logs.
- **`RecipeScreen`** (`/recipes/:id`; takes a `Recipe` as `extra` for recipes outside the library):
  - Prep, cook (`minutes` − `prepMinutes`) and serves, the ingredients, and "How to make it" with times and oven temperatures in bold.
  - From 600 px wide, the photo sits beside the title and the ingredients beside the steps.
- **Logging:** both screens go through `logRecipePortion` (`lib/screens/recipes/log_recipe_portion.dart`): `showRecipePortionsSheet` (halves, ½–10), then `LogMealController.submit` with the recipe's protein and macros, named "Name × 1.5" when not one portion. "Fits today" (`fitsRemaining`) shows once something is logged.
- **Photos:** they aren't in the app. `RecipePhoto` loads `https://yumsum.web.app/recipes/<id>.webp` through `recipeImageProvider` (`cached_network_image`).
  - The WebPs are 640×480 and under 80 KB, made by `python -I tools/make_recipe_photos.py <folder>` (or `--placeholders`).
  - They live in `tools/hosting/recipes/`, which `build_hosting.ps1` copies to the website (long cache, CORS open).
- **Tests:** `test/recipes_asset_test.dart` checks fields, ranges, ingredient sums within 10%, macros, and that every photo is present. Tests override `recipesProvider` and `recipeImageProvider` (`test/recipe_fixtures.dart`).
- **Plans:** the recipe-writer brief and photo prompt are in plan 05; AI "What should I eat?" is planned for YumSum Star.

## Sign-in and account

- **Email and password:** sign-up sends a verification email and signs out; unverified sign-ins fail with `EmailNotVerifiedException`.
- **Google:**
  - The web uses Firebase's popup.
  - Phones use `google_sign_in` 7, which needs the web client ID that the google-services plugin reads from `google-services.json`. `googleSignIn()` in `auth_controller.dart` initialises the plugin once, as it requires.
  - Backing out (`backedOutOfGoogle`) isn't shown as an error.
- **Google-only accounts** (`hasPasswordLogin` false in `account_controller.dart`): Reset all data and Delete account are confirmed with Google instead of a password (`showPasswordConfirmDialog(askPassword: false)`), and Account Settings hides Change email and the password reset.

## Notifications, widget and shortcuts

- **Reminders:** `NotificationService` (`flutter_local_notifications`, Android/iOS only) schedules a daily meal reminder (20:30), a weigh-in reminder (Saturday 20:00 by default; a day or every day, and a time) and a daily creatine reminder (off by default, 09:00).
  - The switches are on the Notifications page (`NotificationsScreen`).
  - `reminderSyncProvider` keeps the schedules in step, asking for permission once on first run.
- **The creatine offer:** Home offers the creatine reminder once (`offerCreatineReminder`), from the day after sign-up to the end of the first week (`shouldOfferCreatine`), and either way says where to find it.
- **Launch actions:** a tap on the weigh-in reminder becomes `LaunchAction.logWeight` (`lib/app/launch_actions.dart`, bound in `main()` before Firebase so a cold-start tap isn't lost), and Home opens the log-weight dialog.
- **Android widget:** `LogWidgetProvider.kt` (a `home_widget` `HomeWidgetProvider`) draws `res/layout/log_widget.xml`, a 2×1 mini log bar (`res/xml/log_widget_info.xml`, colours in `values(-night)/colors.xml`).
  - Taps open `leanstreak://log/text` or `leanstreak://log/voice`, which `launchActionForUri` maps to `LaunchAction.typeLog` / `voiceLog`.
  - Flutter deep linking is off in the manifest so go_router never sees those URIs, and `MainActivity` blanks the intent on a relaunch from Recents.
- **App-icon shortcut:** `quick_actions`, id `log_voice`, uses the same path. The quick-log bar consumes the shortcut and widget actions.

## Feedback, crashes and legal pages

- **Crash reporting:** `firebase_crashlytics`, on Android/iOS only (it has no web build); the handlers are set in `main()` after Firebase.
- **Feedback:** Account Settings' feedback tile opens `showFeedbackDialog` (`lib/widgets/feedback_dialog.dart`): a Problem/Idea/Other `PillToggle`, which sets the prompt and the subject, over one message box.
  - `FeedbackRepository` posts it as JSON to a Formspree form (`FeedbackRepository.endpoint`, in the help.yumsum Formspree account), which emails `supportEmail` (help.yumsum@gmail.com, `lib/core/constants/app_info.dart`) with the user's email as reply-to.
  - There's no Firestore and no extension involved. The free plan takes 50 messages a month.
- **Legal pages:** `tools/hosting/privacy.html` and `terms.html`, copied to the hosting root by `build_hosting.ps1` and served at `/privacy` and `/terms` (`cleanUrls`).
  - `LegalLinks` (`lib/core/constants/legal_links.dart`) holds the URLs, including the Open Food Facts credit.
  - `LegalFooter` (on sign-in; on the web it also has the reCAPTCHA attribution line) and Account Settings' legal section open them.
  - `MedicalNote` is the health disclaimer under the plan preview. Both widgets are in `lib/widgets/legal_links.dart`.

## Hosting and release

- **Signing:** release builds are signed with the upload key named in `android/key.properties` (gitignored; the key file is outside the repo, alias `upload`). Without that file they fall back to the debug key, which Play rejects.
- **VS Code configs** (`.vscode/launch.json`): `--web-port 5000` for Edge (App Check), and `--dart-define-from-file=config/off_account.json` for Android (Open Food Facts).
- **Building the site:** `tools/build_hosting.ps1` builds the web app into `build/hosting`, an `/app` build plus a `/webkit` build for Safari/iOS behind a small redirect page, and copies the legal pages and recipe photos.
- **Hosting:** Firebase Hosting serves it with SPA rewrites at `yumsum.web.app` (target `app`). The old default site `lean-streak-project.web.app` (target `old`, public folder `tools/hosting-redirect`) 301-redirects every path there. Targets are mapped in `.firebaserc`.
