# YumSum feature notes

How each part of the app works, for when you're working on it. `CLAUDE.md` has the rules and the map; the code is the source of truth, and `docs/plans/` says why things are the way they are. Update the section you touch when a feature changes.

## Screens and navigation

**Home** (`DashboardScreen`, called Today in the code; titled with the user's first name, the date under it):
- Calories, then the protein and macro rings, the day's meals, a month graph and weight.
- The umbrella at the top right takes the day off (see Days).
- `PlusPromptCard` for free users; its cross hides it for 14 days.

**The quick-log bar** (`QuickLogBar`, `lib/screens/dashboard/helpers/quick_log_bar.dart`), pinned at the bottom of Home:
- Type the meal; the calories and protein go in two plain number boxes that appear under it once the bar is in use. The boxes have keys `quick-log-name`, `-kcal` and `-protein`.
- Beside the idle box: round buttons for a photo of the plate (Smart Snap, YumSum Star only: for everyone else the button wears a small star, `_Starred`, and opens `showSmartSnapIntro`, `lib/screens/dashboard/helpers/smart_snap_dialog.dart`: a small dialog, the bowl with a camera (`assets/smart_snap.webp`, 720 px, the owner's illustration) over "Smart Snap" and "Make food logging as easy as taking a photo.", two `FeaturePromises` rows (Skip the manual entry; You're always in control; the owner's copy), Maybe later and Become a Star, which opens `/plus`; the server refuses a free account's photo too), a packet's barcode (phones and browsers) and the mic.
- Once the bar is in use (text, or the keyboard up for it; not desktop's standing focus) they slide away for one round button: a sparkle (tooltip Estimate, greyed until there is a name), or a tick (Save) once there are calories.
- After a typed or voice estimate, where the AI had to assume an item's size, milk or the like, a small dialog asks which it was (`offerEstimateChoices`, see AI).
- A tap on nothing in particular anywhere in the app (`appShellBuilder`), a scroll of Home, or a swipe down on the bar (which shows a drag handle while open) lets go of the box: the keyboard goes and an empty bar folds. The bar's whole panel counts as part of its boxes (`TextFieldTapRegion`): a browser, and any mouse, lets go of a box as soon as the pointer goes down outside it, which folded an empty bar before a chip's tap could land.
- Chips while a box is focused and there are no calories yet (`suggestionsFor` in `lib/helpers/meal_suggestions.dart`), from the latest 120 meals (`recentMealsProvider`, a live query, so a change re-reads only that meal):
  - name empty: up to five meals usually logged around this time of day (`usualMealsAt`: at least twice within 90 minutes of now, not already logged today);
  - typing: up to three of the last 50 distinct meal names that match (`distinctRecentMeals`), own meals first, with a matching recipe (book icon; found by its name in either language, offered in the app's, and left out when it was logged under either name) always given one of the three places, after a packaged-food search chip when not on the web and shown (hidden for now, see Search).

**Other pages:**
- Editing a meal, or adding one to a past day, uses the meal form `showLogMealSheet` (`lib/screens/meals/log_meal_sheet.dart`), which has its own AI estimate.
- The top-left menu (`AppDrawer` in `lib/widgets/app_frame.dart`, on every page) lists Home, Recipes, History, Weight & Progress, AI Coach (with the YumSum Star at its end, as a Star feature; the page's title carries it too), Plan Settings, YumSum Star and Settings, then Debug tools where they're on offer, and Log out. There are no bottom tabs.
- Home is the root and every other page sits one level above it: picking a page from inside another swaps it (`pushReplacement`), so Back always returns Home. YumSum Star opens over the current page instead.
- History (`ReviewScreen`, `/review`): a week/month calendar with the period review; tapping a day opens `showDayMealsSheet` (`lib/screens/review/day_meals_sheet.dart`) to add, edit or delete its meals.
  - AI Coach (`WeeklyNotesCard`, plan 09) sits under the calendar in both views as a card that opens the AI Coach page on that week: the week shown in the week view, and in the month view the latest week that ended in that month, named ("Week of 26 October"). Free users get its prompt (`CoachPrompt`) in both, which opens the page too.
- Plan Settings is `PlanSettingsScreen` in `lib/screens/profile/profile_screen.dart`; Settings is `AccountSettingsScreen` on `/profile`: Account, Password, Notifications (the reminders, `NotificationSettings` in `lib/screens/account/notification_settings.dart`, not on the web), Appearance (System / Light / Dark), Language, YumSum Star, Help & legal and Danger zone.
- Routing: `goRouterProvider` listens to `authStateProvider` and `userProfileProvider` and enforces Splash → Auth → Onboarding → Home; a profile that fails to load goes to `ProfileLoadErrorScreen`.
  - Before all of them, `LanguageScreen` (`/language`, `lib/screens/language/language_screen.dart`) when `languagePromptProvider` says so: no language chosen yet, and the device's region is BG or MT or its language is Bulgarian. It shows "Choose your language" and "Изберете език" with English and Български; choosing saves the setting and the redirect moves on (to Auth, or Home for a signed-in user). Everyone else never sees it and gets English.

## Language

English and Bulgarian, with gen-l10n (`l10n.yaml`): the texts are in `lib/l10n/app_en.arb` (the template) and `app_bg.arb`; `flutter gen-l10n` (or any build or `flutter pub get`) writes `lib/l10n/app_localizations*.dart`, which are committed. How to add a string, the key names and what is still English: `docs/translation.md`.
- The setting: `languageControllerProvider` (`lib/providers/language_provider.dart`), the device setting `language`: `en`, `bg` or unset (English). Changed in Settings' Language switch and on the first-launch `LanguageScreen`; applied at once, as `LeanStreakApp` gives `MaterialApp.router` the locale (`languageCodeProvider`), and with it Material's own texts (date pickers, tooltips) in Bulgarian.
- Widgets read texts with `context.l10n.key` (`lib/l10n/l10n.dart`), English where no localisations are in the tree, as in widget tests. Code without a context (controllers, services, notifications) reads `ref.read(l10nProvider)`, or watches it where the text must follow a change.
- `languageCodeProvider` is also what the Cloud Functions are sent, as `language` with `aiEstimate`, `aiWeeklyReview` and `sendVerificationEmail`, so AI replies and emails match the app. The functions read it with `languageOf` (`functions/src/prompts.ts`): `bg`, or English for anything else and for older apps that send none.
- What shows before Riverpod reads the stored setting itself (`LanguageController.storedIn`): `main()`'s first splash and the "YumSum could not start" screen (`_StartupErrorApp`, through `lookupAppLocalizations`).
- Outside the app's texts: the app-icon shortcut's title is set again when `l10nProvider` changes (`bindLaunchActions`), and the Android widget's strings have a Bulgarian `values-bg/strings.xml`, which Android picks by the phone's language, not the app's.
- Bulgarian copy says "ти", never "Вие", and avoids words that show the user's gender. The glossary is in `docs/translation.md`: meal хранене, log запиши, weigh-in претегляне, target цел, target weight желано тегло, account профил, sign in вход / влез, log out изход, feedback обратна връзка, day off почивен ден, reset нулирай, AI Coach AI треньор, Adaptive formula адаптивна формула.
- Dates and numbers: the `AppFormats` extension on `AppLocalizations` (`weekdayDayMonth`, `dayMonth`, `shortDayMonth`, `monthYear`, `time`, `decimal`, …) formats with intl in the texts' language ("събота, 7 ноември", "1,5"), loading intl's date data on first use. `parseDecimal` reads a typed number with a comma or a point. Dates used as keys (`yyyy-MM-dd`) and the AI's facts stay as they are.
- `reminderSyncProvider` watches `l10nProvider`, so the scheduled reminders are scheduled again in the new language.
- iOS lists `en` and `bg` in `CFBundleLocalizations` (`ios/Runner/Info.plist`).

## Look and feel

- Warm light and dark palettes: `AppPalette.light` / `.dark` in `lib/core/constants/app_colors.dart`; `test/app_colors_contrast_test.dart` checks their WCAG contrast.
- `AppColors` is static getters switched by `AppColors.isDark`, which `LeanStreakApp` sets from the stored ThemeMode (System/Light/Dark in the menu, `themeControllerProvider`) and the platform brightness. So expressions using `AppColors` can't be `const`.
- `AppTheme.light`/`dark` are built from the palettes. On wide browser windows `appShellBuilder` (`lib/app/app.dart`) shows the app as one centred column.
- Colours follow the YumSum icon: cream backgrounds; the icon's orange (`primary`) for actions (buttons, links, focus, the mic); its arc green (`veryGood`) for on track and progress (Home's bars and rings, the month bars, the weight chart); amber for close; raspberry red for off track and errors.
- Fonts: Nunito for body text; Fredoka for headings, app bar titles and big numbers. Fredoka has no Cyrillic, so `AppTheme.display` falls back to `NunitoDisplay`, a pubspec family holding only Nunito ExtraBold: Nunito at Fredoka's own 600 looks thin beside it, and the engines pick a family's face by the file's real weight, so ExtraBold has to be the only one. Rubik (Cyrillic) was compared and not chosen: no closer to Fredoka's round ends than Nunito. All are bundled in `assets/fonts`, their OFL licences registered in `main()`, so Bulgarian never falls back to a system font.
- Shapes are round and roomy: pill buttons and chips, 28px cards on a warm shadow (`AppCard`, `lib/widgets/app_card.dart`), round calendar days, `PillToggle` for two- and three-way switches, `IconBubble` behind icons, `BowlNote` (the smiling bowl) for empty states.
- `AppLogoMark` shows `assets/logo.png` on the icon's gradient tile on phones; the web paints a drawn version (`_BowlPainter`), which stays sharp small.
- App icons for every platform come from `design/` via `python -I tools/make_icons.py`, along with `drawable-xxxhdpi/splash_icon.png`, the bowl alone that Android 12's launch screen shows (`values-v31/styles.xml` and the night one).
- `web/index.html` draws the same splash as `SplashScreen` in HTML and SVG while the app loads, so the hand-over is seamless. `main()` draws `SplashScreen` before Firebase and the reminders are set up, which is what dismisses the phone's launch screen.

## Device settings

SharedPreferences through `sharedPreferencesProvider` (`lib/providers/preferences_provider.dart`), overridden in `main()` so readers never wait (unoverridden it throws). Keys:
- `theme_mode`
- `language` (`en`, `bg`, or unset for English; see Language)
- `reminders.*` (switches, times, `creatine_offered`)
- `off.app_uuid`, `contributions.count`
- `feedback.sent_day`, `feedback.sent_count` (3 feedback messages a day)
- `plus.prompt_hidden_until`
- `adaptive.intro_shown`, `adaptive.lapse_notice` (the Adaptive formula's one-time dialogs)
- `debug.account` (Debug tools' pretend account)

## Firestore data and resets

- The profile is `/users/{uid}`; everything else is in subcollections: `meals`, `daily_summaries` and `weight_entries` (both keyed by date), `ai_usage/{yyyy-MM-dd}`, `day_edits/{yyyy-MM}`, `days_off/{yyyy-MM-dd}` and `weekly_reviews/{yyyy-MM-dd}`, plus the functions' daily limits `contribution_usage/{yyyy-MM-dd}` and `feedback_usage/{yyyy-MM-dd}` (UTC days), which the app can't read or write.
- Period reviews are computed, never stored; only the AI Coach's notes are cached, in `weekly_reviews`, with the facts they were written from. Legacy `check_ins` and `check_in_prompt_status` documents are only deleted with the account.
- Repositories in `lib/repositories/` do the reads and writes; `AccountRepository` does the bulk deletes.
- Reset progress (Weight & Progress) clears `weight_entries` only. Reset all data (Settings, `AccountRepository.resetAllData`) clears meals, summaries, weigh-ins, days off and the AI Coach's notes, but keeps the profile and the AI and past-day counters.
- The app can only read the AI counter, which the AI functions keep (see AI). The rules let the past-day counter only go up by one, and never let the app delete either. `day_edits` only takes the server's month, give or take a day for time zones, so changing the phone's date doesn't start a new count.
- Account deletion: `AccountRepository.deleteAccountData` deletes the data and the profile, then `deleteAccount` (the function) deletes the counters and the login itself, so the counters only start again with a new account.
- Reset all data and account deletion re-authenticate first (`AccountController`): with the email password, or with Google for a Google-only account.
- YumSum Star lives outside the user's tree in `entitlements/{uid}`, which the app can only read (see YumSum Star).

## YumSum Star

The paid tier (plan 06; the code says `plus`).
- **The record:** `entitlements/{uid}`, written by the server (the billing functions, plan 07) or by the owner in the console.
  - A manual grant is `active` true, `source` `manual` and an optional `expiresAt`.
  - Play's records also carry `startedAt`: when YumSum Star last switched on, kept while it stays on and set afresh after a lapse (`functions/src/entitlement.ts`). AI Coach counts weeks from it; a manual grant has none and counts from the beginning.
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
  - `BillingRepository` calls the `verifyPurchase` and `deleteBillingData` functions in `europe-west10` (`functions/`). The other functions are `contributeProduct`, `sendFeedback` and `deleteAccount` (see their features); all are App Check enforced and signed-in only.
  - `plusPurchaseControllerProvider` (`lib/providers/plus_purchase_controller.dart`) listens to Play's purchase stream for the app's life (`LeanStreakApp` keeps it alive). It sends every purchased or restored YumSum Star purchase to `verifyPurchase`, then completes it; the server's write to the record is what switches YumSum Star on. It shows the plan's messages (pending, not confirmed, linked to another account, nothing to restore). Signed in without YumSum Star, it restores quietly once per account at start-up.
  - Buying passes a SHA-256 of the uid as Play's account ID. `verifyPurchase` refuses a purchase whose ID is another account's (`already-exists`, "linked to another account") without linking it; only a purchase with no ID (bought outside the app) goes to the first account that checks it.
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
  - A card in Settings.
  - `PlusPromptCard` on Home.
  - The dimmed macro rings for free users, the shining Adaptive formula button under the weight chart, and the shining AI Coach button on finished weeks in History.
- **Debug tools** (`/debug`, `DebugScreen`), in debug builds and for dev accounts in any build:
  - the User ID to copy;
  - "Pretend to be" (`debugAccountProvider`): free, subscribed, trial, ended or admin, on that device. A pretend account is real enough to change the Adaptive formula on the real plan. The AI functions read only the real record, so AI estimates ask for macros only when it has YumSum Star too (`aiMacrosProvider`), and AI Coach needs it on the real record.
  - "Go through onboarding again": the set-up questions as a preview over Debug tools (see Onboarding), and "Show the YumSum Star card again".

## Plan, weight and the trend

- `HealthCalculator` (`lib/helpers/health_calculator.dart`) is pure static functions: BMI, BMR (Mifflin-St Jeor), TDEE, the daily calorie target with per-gender minimums (male 1,500, female 1,200, other 1,350), the protein target (grams per kg of goal weight, by training frequency) and `macroTargets`.
- Logging a weight (`WeightLogService`) re-plans from it. Deleting the newest weigh-in (the bin on its card on Weight & Progress) takes the plan back to the one before; deleting an older or the only one leaves it.
- Stored plans are recalculated at startup by `activityScaleMigrationProvider` when a profile's `planCalculationVersion` or `activityScaleVersion` is behind the constants in `lib/models/user_profile.dart`.
- **The trend** (free): `weightTrend` in `lib/helpers/weight_trend.dart`, an exponentially smoothed average (0.9 a day, allowing for gaps). A weigh-in more than 3% off the trend is set aside unless the next one agrees. Weight & Progress draws the weigh-ins as dots (hollow when set aside) under the trend line. The chart is padded on all four sides so no dot touches an edge, and its touch tooltip is kept inside the chart.
- Onboarding and Plan Settings accept ages 18–120, matching the legal pages.
- **Units:** weight in kg, lb, or stones and pounds, and height in cm or feet and inches (`lib/models/units.dart`); food stays in grams and kcal. The choice is the profile's `weightUnit` (`kg`, `lb`, `st`) and `heightUnit` (`cm`, `ftin`), so phone and web match (checked in `firestore.rules`); unset, `weightUnitProvider` and `heightUnitProvider` default to kg and cm wherever the user is. Stored weights and heights stay in kg and cm, and the plan maths never sees another unit.
  - Shown in the app's language: `formatWeight` and the others take the `AppLocalizations`, so Bulgarian reads "80,5 кг" and "180 см", with a decimal comma, while lb, st, ft and in keep their Latin symbols (the toggles „st и lb“ and „ft и in“, the second boxes „Фунтове“ and „Инчове“).
  - Typed in `MeasureField` (`lib/widgets/measure_field.dart`): one box, or two for stones and pounds or feet and inches, one decimal at most, with a point or a comma, shown with the language's mark ("79,8" in Bulgarian). A stored value shows rounded but comes back exactly until a box is edited, so saving Plan Settings untouched changes nothing (and doesn't restart the Adaptive formula); switching unit keeps the value. Ranges are checked in kg and cm and shown in the unit, rounded inwards so both ends shown are allowed ("4 st 11 lb–47 st 3 lb").
  - Chosen with one small `UnitsToggle` ("kg, cm", "lb, ft", "st, ft"): the height unit follows the weight's, kg with cm and pounds or stones with feet and inches.
  - Where: onboarding's height, current and target weight cards each show the toggle above the boxes, starting on kg and cm and stored with the profile; Plan Settings has it under UNITS above YOUR BODY, saved with the plan, and puts height and weight side by side only when both are one box; the weigh-in dialog; Weight & Progress (the stats, history, delete question, chart and tooltips) and Home's weight card. Stones show as "12 st 4 lb", pounds to one decimal, and a change in stones in pounds until it passes a stone. Paces (the pace cards, the plan card, "To lose … a week") are in kg, or in pounds for pounds and stones.
  - The chart draws in kg, or in pounds for pounds and stones; in stones its axis is labelled "12 st" or "12 st 7" every 1, 2, 7, 14, 28 or 70 lb, the smallest giving at most 5 lines.
  - AI Coach's facts quote no weights (only how many weigh-ins), so units don't reach it.
- **Onboarding** (`OnboardingScreen`) asks one question per card, with a progress bar, Back and Next (Next stays off until the answer is valid): name, sex, age, height, current weight, the goal (Lose weight or Keep my weight, with one line on what a calorie is), the target weight (only when losing), daily movement, training, whether to track protein (Yes by default), then "Your plan is ready!" with the logo, the plan card shining like the star (`Shine`) and Start. It doesn't ask the pace (moderate) or the country: it stores the phone's region as the profile's `country` (`countryNameFor` in `lib/models/user_profile.dart`: a name for the countries it knows, else the region code, else the UK), which `countryProvider` falls back to; the last card says all of this can be gone over again, in more detail, in Plan Settings. Back on the first card signs out. Debug tools can open it again as a preview (`onboardingPreviewProvider`): the router lets a finished account in, and Start or Back on the first card goes back to Debug tools, saving nothing.

## Protein

`UserProfile.trackProtein` (default true, read through `trackProteinProvider`), on from onboarding and switchable in Plan Settings.
- Off hides protein everywhere: Home's ring, the quick-log box, the meal form, meal rows, the day sheet, the breakdown, the portion sheets, the bar tooltips and the recipes.
- Off also stops `LogMealController`'s automatic protein estimate. Protein the AI returns anyway is still saved, so switching back on loses nothing.

## Macros

YumSum Star only (plan 10), for good: the owner's decision of 4 November 2026, whatever the cost. The AI functions refuse macros to an account without it (see AI).
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
  - Macros aren't shown on recipe tiles (only the high-fibre badge), the AI breakdown, the month graph or the period review.
- **The guide** (`showMacroGuide`, `lib/widgets/macro_guide.dart`), from the rings, Home's card and the day sheet: from the card, first a short calories item (what you burn, with a little taken off if you're losing weight); then the macros in three groups that match the ring colours (aim for, keep in balance, keep under), each with one line on why it matters and one on its target. Keep under opens with one line on why: going over day after day harms your teeth, heart and blood pressure. No country's guidance is named, as the app isn't only for the UK. No figures beyond the targets; the rings have those.

## Adaptive formula

YumSum Star (plan 08).
- **The target:** target = the formula's plan + a personal adjustment (`calculatePlan(adaptiveKcal:)`), applied to the burn before the calorie minimum. Away from the minimum the goal date stays; at the minimum it moves later. It never plans a faster loss than the chosen pace.
- **The calculator:** `AdaptiveFormula` (`lib/helpers/adaptive_formula.dart`, every constant there).
  - `measure` fits one slope through the last 7 to 42 days of weigh-ins, split at breaks of 3+ unlogged days, and compares the measured burn with the formula's. `AdaptiveMeasure.burn` is the formula's burn moved towards the measured one by the confidence.
  - `monday` scales the gap by confidence and applies the limits: 5% of the plan a week (scaled by days ÷ 21 in the first 3 weeks), 15% in all, "unusual" past 20%, a 20 kcal dead band, and two Mondays in a row before a cut.
  - A cut never takes the target more than 50 kcal under what the plan would be at the fast pace (`lowestAdjustment`, `belowFastest`, since 6 November), so it can't make a plan harsher than the harshest one offered: on the fast pace itself that leaves 50 kcal of room for cuts, on the others the 15% limit usually bites first. Raises are unchanged.
  - It acts from a week of data with 3 weigh-ins, 2 in the finished week. Trust grows each week to full at 6, and needs 4 weigh-ins a week for full marks.
- **Only on Mondays:** `adaptiveMondayProvider` (`lib/providers/adaptive_formula_provider.dart`, watched in `LeanStreakApp`) runs on the first open on or after a Monday, once a week (`adaptiveWeek`), never on a weigh-in.
  - It decides from the server's profile and weigh-ins (`fetchProfile`, `fetchEntries`), not the phone's cached copy, since it writes the whole profile; so does the plan update after a version bump (`activityScaleMigrationProvider`).
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
  - Plan Settings: a row with the sum (`adaptiveSumLine`), and "Paused: no weigh-in for 10 days. Weigh in to keep it personal." only when paused (`adaptivePausedLine`, from `adaptiveProgressProvider`; no line on how well it knows you since 5 November); the star for free users, whose tap opens `/plus`.
  - Weight & Progress: `AdaptiveSection` (`lib/screens/progress/helpers/adaptive_section.dart`), under the chart in its card.
    - With YumSum Star: the title, a solid green "✨ On" chip whose white glint sweeps across three times when it appears (none when the phone asks for less motion), and the info button on the right. Then two plain lines, each with an icon and a note: "You burn 2440 kcal a day" (`adaptiveBurn`, measured up to yesterday; "Learnt from your weigh-ins and meals." or, before it has learnt anything, "A first estimate. It learns as you weigh in.") and "Your target is 1620 kcal a day" ("To lose 0.75 kg a week." or "To keep your weight steady."). Then the paused line, only when paused, and this week's line.
    - Free users: the name itself is the button (`TryButton`, `lib/widgets/feature_intro.dart`, shared with AI Coach), a warm orange pill with an arrow and a soft glow that shines when it appears (the star waits in the dialog's Become a Star), over "A customised formula tailored just for you. Adapting with time and your weigh-ins." No info button and no numbers, so it invites rather than knocks the standard plan. A tap opens the dialog, which offers Become a Star.
- **The explainer:** `showAdaptiveIntro` (`lib/screens/dashboard/helpers/adaptive_dialogs.dart`, laid out by `FeatureIntroDialog`, shared with AI Coach), titled "Your calories, personalised" (`adaptiveTitle`) over "Feel more confident about how much to eat, with a smart formula that adapts to you every week." (`adaptiveSubtitle`; the owner's copy, 6 November): four bold promises (Understand what you burn, Built around your body, Stay on track as you change, Make every weigh-in count), each with one short line. With YumSum Star, "Log my weight" opens the weigh-in dialog (`logWeightWithFeedback`); without it (`plus: false`), "Become a Star" with the star opens `/plus`. The other button is Maybe later. It is shown once after subscribing, from Plan Settings and the info button under the chart, and from the free users' button.
- **Tests:** the seeded simulator in `test/adaptive_fixtures.dart`.

## AI Coach

The AI weekly review, YumSum Star (plan 09); users only ever see it called AI Coach. It has its own page, `CoachScreen` (`lib/screens/coach/coach_screen.dart`, `/coach`, in the menu), which History's card opens too.
- **The facts:** the app works out every fact and the AI only writes. `buildWeekFacts` (`lib/helpers/week_facts.dart`, pure) gives the lines the AI is told:
  - the user's country (`countryProvider`), so the foods it suggests fit;
  - the days logged, the target and the calorie minimum, what History's card already shows, and each day;
  - weekdays against the weekend, steady weekdays, the biggest day, days under the minimum, and a usual big day over the last 4 weeks;
  - last week's average against this week's ("this week is 15 kcal a day lower"), when both weeks had 4 judged days;
  - protein, and the first meal of the day (by logging order, only on days whose meals were all logged on the day) with ideas from the library's breakfasts only (the user's own meals aren't suggested back to them, since 5 November);
  - fibre, salt, sugars and saturates against the guides (`macroTargets`), each on days where every meal has it, with where the salt came from and fibre-rich recipes under 2 g of salt;
  - the same nutrients over the last 4 weeks, each week by the same rules: "Fibre has been under the guide for 3 weeks running", or "Fibre met the guide this week, after 2 weeks under the guide" (a week without the nutrient ends the run);
  - how many weigh-ins (never the weights), and the Adaptive formula's change on that week's Monday;
  - the whole recipe library last, one entry each with its meal, kcal, protein, fibre, salt, sugars and saturates per portion, by id, so the AI can pick recipes that fit each note.
  - Days off are left out of every pattern, average and tip; fat and carbs never appear. The same data always gives the same lines.
- **The call:** `WeeklyReviewService` (`lib/services/weekly_review_service.dart`) sends the facts to the `aiWeeklyReview` function (see AI), which checks YumSum Star.
  - `coachInstruction(language)` (`functions/src/prompts.ts`; `weeklyReviewInstruction` is the English) as a system instruction, the facts as the message (at most 16,000 characters), and a response schema (`points`, at most 8, each `{title, text, why, tips, recipes, good}` since prompt version 7, 6 November; `good` only for a note about something that went well). It asks for 5 to 7 notes, most useful first, each with a heading of at most 40 characters, 1 or 2 sentences of at most 220 on what the facts show, a why of one sentence, 1 or 2 tips that start with a verb, and two library recipes named only there; before, 2 to 4 sentences of at most 450: what the facts show, why it matters in everyday terms, then what to do, with cheap everyday foods (no brands, no numbers) and two recipes from the library that fit. A nutrient off for weeks running is the first note.
  - In Bulgarian (`language: 'bg'`, `weeklyReviewConfigFor`) the English rules stay and three parts change: how to write (natural everyday Bulgarian with "ти", never "Вие"; no past participles or adjectives about the user, which show gender, so the present, the simple past or the food as the subject), the lengths (a heading of at most 50, a text of 260, a why of 190, tips of 140, as Bulgarian runs longer, all within what the app keeps) with Bulgarian example titles, and a closing section on the app's own words (протеин, фибри, сол, захари, наситени мазнини, дневната цел, почивен ден, претегляне), days in lower case, „…“ quotes, and the facts' numbers written the Bulgarian way: 7,4 for 7.4 and 1850 for 1,850. The user's meal names and the recipe names stay as the facts write them. Prompt version 10 adds examples of natural Bulgarian sentences, avoids literal English metaphors, and shares food naming guidance with estimates (ordinary yoghurt is „кисело мляко“, with „цедено“ reserved for explicitly Greek or strained yoghurt). The English instruction is unchanged. The version labels new notes only; saved weeks keep their original notes.
  - `parseReviewPoints` keeps at most 8 notes as `ReviewPoint`s, dropping any whose text is over 600 characters or title over 80, with a number not in the facts (a decimal comma and a space or comma between thousands read as the facts' point and comma), or with a shaming word in either (English, and a few Bulgarian stems such as провал and мързел); the why (at most 300) and each tip (at most 200, 3 kept) are held to the same and dropped on their own, and recipes are kept as named, 3 at most; a bare string counts as untitled and not good. None left is a failure, and nothing is saved.
- **When:** only the latest finished week is ever written (`reviewWritable`, since 6 November), for a subscriber whose YumSum Star began by that week's Sunday (`Entitlement.startedAt`; a hand-typed grant has none and counts from the beginning), when they open the page, and only if the week has at least 4 judged days (logged, not taken off). Earlier weeks show what was saved, so paging back never costs a call, and someone who joins mid-week is told their first notes come on Monday. Once YumSum Star ends, the notes stay readable and no more are written.
  - `weeklyReviewProvider` reads the saved notes first (null when there are none), and for the latest week rebuilds the facts (reading 4 weeks of summaries and meals) and keeps the notes (`{title, text, good, why, tips, recipes}` each; the rules check only that there are at most 8 and `basis` is up to 12,000 characters, as checking each note's fields went past their limit of 1000 checks a request and refused every save from 6 to 8 November) in `weekly_reviews/{Monday}` with `basis`: `weeklyReviewPromptVersion`, `Language bg` for notes in Bulgarian (none for English, so English notes saved before kept their basis), and the facts as sent. Since 8 November a week is written once: saved notes are shown whatever changed since (the facts, the prompt version or the language), and the version only labels new notes. Behind that, `aiWeeklyReview` keeps its reply for the latest finished week (worked out from the phone's date, `latestFinishedWeek` in `functions/src/ai.ts`) in `coach_replies/{Monday}` and gives it back to any later call that week without asking Gemini or counting it, so an app that fails to save, or asks again, costs nothing more. Deleting the account deletes them.
  - `refreshHistory` invalidates it. Runs that overlap for the same week share one call (`_writingProvider`), and the week's weigh-ins are counted with a query for that week only (`countEntriesInRange`).
  - Past weeks are kept for good, one small document each, so the page can page back through them.
- **The page** (`CoachScreen`): a header card (`_WeekHeader`) with the coach small (48 px) beside the week's name, "Last week" over its dates (`weekLabel`, `lib/widgets/period_bar.dart`, the year only once it isn't this one) for the latest finished week or just the dates for an earlier one, and Previous and Next between the first week (the first logged one, or the one YumSum Star began in) and the latest; no Latest button. Swiping the page sideways, by touch or mouse, does the same: left for Next, right for Previous, nothing where that arrow is off (a fling, or a slower drag of 80 px; `_page`). It opens on the week History asked for (`?week=yyyy-MM-dd`, a finished Monday) or else the latest finished week. Under it, each note is an `AppCard` with a dot (green for one about something that went well), its title in the display font and the text; or, for a thin week, why there are none; "No notes on this week. AI Coach writes them during the week after, when you open this page." for a week it never wrote; a spinner ("Looking over your week"); or "Could not get this week's notes. Try again." with Try again. Numbers keep their units on one line, and a library recipe named in a note is an orange underlined link to its page, shown without the AI's quotes and by its name in the app's language (`_NoteText`; the AI is given the English names, and either is recognised). The recipe chips under a note use the app's language too. The info button opens `showCoachIntro` (the coach beside the title, Close only).
  - A new subscriber, until a week finished with YumSum Star is in, gets `_FirstNotes` instead: the coach beside "Your first notes come on Monday" and "3 days to go", then what it's doing meanwhile and the Monday's date.
  - Someone whose YumSum Star has ended keeps the page while any notes are saved (`hasWeeklyReviewsProvider`): `_Ended` ("YumSum Star has ended, so no new notes are written. The ones you have stay." with Become a Star) over the weeks, which show their saved notes or "No notes on this week."
  - Everyone else without YumSum Star gets the page without the bar: the coach illustration (`assets/coach.webp`, 720 px, shown 156 px wide so Become a Star is on screen on a phone), "Your AI Coach" (`coachTitle`, also the dialog's title), "Get fresh advice tailored just for you, every Monday, to help you eat better and reach your goals." (`coachSubtitle`, also the dialog's subtitle), the four promises (`coachPromises`, `FeaturePromises`: Spot what's holding you back, Build a more balanced diet, Get advice you can put into practice, Start every week with direction; the owner's copy, 6 November) and Become a Star, which opens `/plus`.
- **In History** (`lib/screens/review/weekly_notes.dart`): `WeeklyNotesCard` under the calendar in both views is a slim card ("Read your notes on this week.", or "Your notes on this week come on Monday." for a week still going) that opens the page on that week with `openPage`, swapping History for it so Back lands on Home. A week before YumSum Star began (`firstCoachWeek`) gets no card. Free users get `CoachPrompt`: the shining AI Coach button (`TryButton`) and "See what's working, what's holding you back, and get personal tips on how to improve.", both opening the page.
  - Nothing on Home.

## Days

- **Daily summaries** (`lib/services/daily_summary_service.dart`): `recomputeForDate` rebuilds a day from its meals whenever one is logged, edited or deleted (and on a day-off toggle or weigh-in), and deletes the summary when the day has no meals.
  - It holds the calorie, protein and macro totals, the meal count, and a status: within ±10% of target is green, ±20% yellow, else red.
- **Not judged mid-day:** a day only shows its status once it is finished, on track or over target (`hasSettledStatus` in `lib/widgets/day_status.dart`).
- **Day off:** the umbrella on Home (`confirmDayOff` explains it first; tap again to go back on plan; `DailySummaryService.setDayOff`).
  - It is stored in `days_off/{date}` (`DayOffRepository`), because the summary is rewritten on every meal change and deleted when a day has no meals. `recomputeForDate` copies it into `DailySummary.dayOff`.
  - A day off never shows a status.
  - Period reviews count its calories but leave it out of the tally, the consistency rate and best/worst day, reporting a days-off count instead.
- **Past-day changes:** adding, editing or deleting a meal on an earlier day uses one of 10 a calendar month (`DayEditRepository.monthlyLimit`). Once they're used up, `LogMealController` fails with `EditLimitExceededException`. Admin has no limit.
- **Period reviews** (`lib/services/period_review_service.dart`): weekly and monthly figures from the summaries, under the History calendar for finished days. They're built from the calendar's summaries (`reviewSummariesProvider`, a live range query, also behind Home's month card), so a meal change re-reads only its day.

## AI

- **Model:** Gemini 3.5 Flash-Lite (`aiModelId`) for estimates, and Gemini 3.8 Flash with its thinking low (`coachModelId`, `weeklyReviewConfig`) for AI Coach since 6 November 2026 (prompt version 8), called only from two Cloud Functions in `functions/src/ai.ts` (since 5 November 2026; before, the app called Firebase AI Logic directly and anyone with a web App Check token could too). They use the Gemini Developer API through `@google/genai` with the `GEMINI_API_KEY` Functions secret, so there's no key in the app. Not Vertex AI: the Gemini API's prepaid credit is the hard cap on what AI costs, and Vertex AI is billed on the normal Cloud cycle with no cap.
  - `aiEstimate` (`kind`: `meal`, `voice`, `photo`, `label` or `nutrients`) and `aiWeeklyReview` (`facts`): App Check enforced, signed in only, `europe-west10`, at most 10 instances, like the billing functions. A `photo` always needs YumSum Star (`star: true` in `estimateAsk`: Smart Snap), like macros; a `label` never does.
  - The app sends only what the user gave (the meal text, the WAV or JPEG in base64, the name and calories, the week's facts), the `country`, `macros` (true for YumSum Star) and the phone's date (`callAi` in `lib/services/calorie_estimate_service.dart`). The server owns the prompts, the model, the config and AI Coach's schema (`functions/src/prompts.ts`) and returns the model's JSON as it is, which the app parses.
- **Billing:** the Blaze plan with the Gemini API's paid tier (since 24 October 2026, required for UK/EU users). $5 is prepaid in AI Studio with auto-reload off (plan 03).
- **Estimates** (`CalorieEstimateService`):
  - Every estimate prompt (`meal`, `voice`, `photo`, `nutrients`; not `label`) opens with `nutritionContext`, built from the country alone. The app's `countryProvider` (`lib/providers/country_provider.dart`) gives the device's region (the phone's in the app, the browser's language region on the web), else the profile's stored `country`, else the UK, and never writes it back. Since 7 November Plan Settings asks neither the country nor usual food; the profile keeps both fields as stored, and the server ignores an older app's `usualFood`. In English it keeps meal and item names in the language the user wrote; with `language: 'bg'` (`Profile.language`) the meal, item and option names come back in natural Bulgarian ("Капучино", "Пържени картофи") even when typed in English, keeping the user's Bulgarian words and brand names as written, which the app's option filter relies on. A label is copied as printed either way.
  - Estimates return calories, protein and a per-item breakdown with grams (`EstimateItem`).
  - Typed and voice meals are listed one item per food as the user would name it (a curry or a sandwich is one item; fish and chips two; a full English each of its foods), with the cooking fat inside the item, never on its own, and nothing the user didn't name: no side, sauce, topping, drink or extra dish (`itemRules` in `prompts.ts`). The one exception is a side a dish is almost always eaten with, such as rice with a curry, when no amount or brand was given: it goes in the same item, named ("chicken curry with rice"). Without an amount, one standard single portion as the country's nutrition guides give it.
  - A typed meal's reply answers to a response schema (`mealConfig`) rather than a JSON template in the prompt, so it can't come back broken. Voice and photos still use the template.
  - Where the user left out what swings an item's calories most (its size, the milk or sugar, full-fat or diet, homemade or takeaway, fried or grilled), the typed and voice prompts have the model go with the usual version, say what it `assumed` (for its own benefit: naming it keeps the options to versions of the same thing, and the app doesn't read it) and give up to 3 `options`, the other common versions, each a complete item named in full (`choices` in `prompts.ts`; not photos, which show their size). Where the size is what's missing (chips, a coffee, a glass of wine), it assumes the regular size and the options are the small and the large one. No options for what the user said (an amount, a size such as a pint or a bowl), a branded or chain product, small differences, or an item's parts. The app keeps options at least 30 kcal from the item and from each other (`optionGap`), under new names that keep every word of the item's name the user typed (or said, from the voice transcript), and 3 at most, which catches the model asking about nothing or arguing with the user; then it asks with `showEstimateChoice` (`lib/widgets/estimate_choice_dialog.dart`): "Which did you have?" over the version it went with, ticked, and the others, each with its calories. A tap swaps that version in and the boxes follow, as for a corrected weight; dismissing keeps the first. One dialog an item, at most two a meal (`offerEstimateChoices`), after the bar's typed and voice estimates and the meal form's.
  - **The test set** (`functions/eval/`, `npm run eval` in `functions/`): 33 typed meals in `meals.json`, each with a kcal range for one standard UK portion and marked specific where the app should never ask, run 3 times through the real prompt and the app's option filter. It prints how many land in range, how far the same words move between runs, and needless questions; every run goes to `eval/last-run.txt`. About a penny a run. Run it before and after any prompt change. On 6 November 2026 the rules above took it from 86% in range (a Big Mac logged as a meal with fries and a Coke, chips as a chip-shop portion, fish and chips with sauce, peas and its frying oil again, one broken reply) to 93–95%, and needless questions from 12 to 7–8 of 48; temperature 0.3 made no difference, so it stays at the default, as Google advises for Gemini 3 models.
  - `EstimateBreakdown` shows the breakdown as one line that expands on tap; correcting an item's grams rescales it (`resized`, `totalOf`) with no further AI call.
  - `estimateFromPhoto` sends a resized JPEG with the same prompt.
- **AI Coach** is the one call that isn't an estimate (see AI Coach): no `nutritionContext`, a system instruction and a response schema.
- **Voice:** records a short clip with `record` (16 kHz mono PCM, wrapped as WAV by `lib/helpers/wav.dart`) and sends the audio to Gemini (`parseVoiceAudio`), which understands English, Bulgarian or a mix with no language setting. Recording ends on Stop, after a pause once something was said, or at 30 s.
- **The daily allowance:** typed, voice and photo estimates and a contribution's label read share 20 a user a day for now (`limits` in `functions/src/ai.ts`, and `AiUsageRepository.dailyLimit` for the app's messages; plan 06 makes it 10 free and 30 for YumSum Star).
  - The server counts it in `users/{uid}/ai_usage/{date}` (`count`) in a transaction before asking Gemini, so calls at the same time are all counted, and failed calls and "no food" answers count too. The app can only read it.
  - The date is the phone's, accepted only while it is today somewhere from UTC−12 to UTC+14, so changing the phone's date doesn't give a new day.
  - The save-time fill-in (`estimateNutrients`) and AI Coach don't use it, but have caps of their own so they can't be scripted: 50 and 10 a day (`nutrients` and `coach` in the same document).
  - The admin entitlement has no limits. Macros and AI Coach are refused (`permission-denied`) without YumSum Star, from `entitlements/{uid}` (`isPlusAt` in `functions/src/entitlement.ts`).
  - The app still checks the count first, only to say the allowance is used up without a call. The bar shows how many are left once half are used, and the mic says so before recording once none are.
- **Errors:** the server tells Gemini's errors apart by status and wording (`geminiError`), and the app maps the callable's code (`aiCallError`).
  - `resource-exhausted` → `DailyLimitExceededException`.
  - `failed-precondition`: not switched on (a disabled API or a bad key) → `aiNotSwitchedOnMessage`; 402 or billing → `aiPausedMessage`.
  - `unavailable`: quota or 429 → `aiBusyMessage`, not retried (the paid tier's limits are per minute); 5xx and lost connections get up to 3 attempts on the server first.
  - Anything else gets the call's own message, such as "Could not estimate calories. Try again."
- **Logging:** each call's token counts go to the functions' log ("AI tokens").
- **App Check:** every AI call carries a token (`lib/core/config/app_check.dart`), which the functions enforce. The phone apps activate it in `main()`; the web starts it on demand (`ensureAppCheck`), before every Cloud Functions call and 3 seconds after Home shows, because Firestore and Auth (which don't enforce it) wait for its reCAPTCHA token once it runs, and reCAPTCHA's 850 KB script slowed every start. Only the Cloud Functions are enforced (Firestore and Auth are not, as of 7 November 2026).
  - Debug builds use the debug provider; its token, printed in the log at startup, must be registered under App Check → Apps → Manage debug tokens.
  - Release builds use Play Integrity on Android and DeviceCheck on iOS. Play Integrity only passes an app installed from Google Play, so a release build installed from the PC is refused ("App attestation failed"). Build that one with `--dart-define=APP_CHECK_DEBUG=true`: it uses the debug provider too, and its token needs registering like a debug build's.
  - The web uses reCAPTCHA Enterprise (Fraud Defense in Google Cloud) with the public site key in `recaptchaSiteKey`.
  - `web/index.html` turns the debug token on for localhost. Run the web app on a fixed port (the VS Code "YumSum (Edge)" config uses `--web-port 5000`): the token is stored per origin in the browser profile Flutter keeps under `.dart_tool/chrome-device`, and must be registered under the `lean_streak (web)` app.

## Packaged foods and Open Food Facts

- **Scanning (phones and browsers):** the bar's barcode button opens `MealCameraPage.barcode` (`camera` plugin, 720p). The camera page is the router's `/camera` (`cameraRoute`, the photo steps as `extra`, none for a barcode), so a browser's Back closes it like any other page; a reload goes Home.
  - Every preview frame (NV21 on Android, BGRA on iOS) goes to ML Kit's on-device barcode reader (`google_mlkit_barcode_scanning`, retail formats only), and the first barcode closes the page.
  - The photo button opens `MealCameraPage.photos`, a shutter for the AI.
  - The page lets the camera go when the app is backgrounded and picks it up on return.
  - Every browser, a phone's or a desktop's, gets the same page (`hasLiveCamera`, `lib/screens/dashboard/helpers/meal_photo.dart`): the browser's camera through `camera_web`, shown at its own size, with the same dark card, and "Choose a photo instead" (`pickMealPhoto`) under the shutter and when the camera can't start. Only the desktop app goes straight to the file picker.
  - In a browser the back camera is found with one request for it (`yumsumBackCamera` in `web/camera.js`, `webBackCamera` in `lib/screens/dashboard/helpers/web_camera_web.dart`, a stub elsewhere), once a visit (`_webCamera`), and handed to camera_web by its id (`camerasMetadata`; camera_web is pinned, as its `CameraMetadata` isn't exported). camera_web's own `availableCameras` opens every camera in turn, and on a Galaxy S24+ (7 November 2026) Firefox left the front camera running after it, so the back one was refused ("too many other open camera devices") and the page said "The camera could not start." A camera the browser says is busy (`_busy`) is still tried again every second for up to 5 seconds, since Firefox lets a stopped camera go a few seconds later.
  - In a browser the barcode is read by `web/camera.js` (`readWebBarcode`), which looks at the preview's video four times a second: with the browser's own `BarcodeDetector` where it reads shop barcodes (Chrome on Android), else the barcode-detector ponyfill and its zxing-wasm reader, copied into `web/barcode/` (about 1 MB, versions and licences in its README) and fetched from our own site the first time a barcode is looked for. If they can't be loaded the page says "Could not start the barcode reader. Try again."
  - ML Kit needs iOS 15.5+, so an iOS build has to raise the deployment target (still 13.0).
- **Lookup:** `FoodLookupService.byBarcode` calls `/api/v2/product/{code}.json`. Only the barcode is sent; `app_name` and the User-Agent identify the app. An unknown barcode is reported with a nudge to photograph the packet.
- **Search:** hidden since 7 November: the "Search foods" chip shows only while `showFoodSearchChip` in `quick_log_bar.dart` is true, and it is false; the barcode scan still uses Open Food Facts. Shown, the chip (typed name, no calories, 3+ characters) opens `showFoodSearchSheet` (`FoodLookupService.search`, the country from `countryProvider` first). It isn't on the web, because `search.openfoodfacts.org` sends no CORS header. Its flow test in `test/quick_log_bar_test.dart` is skipped while it's hidden.
- **Portions:** `showPortionSheet` asks for the grams (prefilled from `serving_size`, else `quantity`, else 100). Done fills the bar's boxes with the label figures, and the meal is saved from the bar. No AI call, no allowance used.
- **Pack photos:** `PackPhoto` (`lib/widgets/pack_photo.dart`) shows the front of the pack (`PackagedFood.imageUrl`, from `image_front_small_url`): 48px in search results, 72px in the amount sheet, left out when there's none.
- **Contributing an unknown product** (`BarcodeLookup.listed` false), via `_offerContribution` in the bar:
  1. `inviteToContribute`.
  2. `takeProductPhotos`: `MealCameraPage` with `photoSteps`, each on a `PhotoStepCard` ("Step 1 of 2" and a tip): the front, then the nutrition table.
  3. `showContributeSheet`, prefilled by `readLabel` (one Gemini call with both photos, counted, told to copy the label and never guess), for the user to check.
- **Adding nutrition to a listed product without calories** (`BarcodeLookup.needsNutrition`, a `ListedProduct`): "Add its nutrition" takes one photo of the table and shows a form with only the figures, plus the name or serving size if the product has none.
  - `FoodContributionService.addNutrition` sends just those, and the nutrition photo if it has none, never touching the name, brand or front photo.
  - A listed product with calories but no name is not offered.
- **Sending:** `FoodContributionService` builds the form fields and hands them, with the photos (base64, in order) and the per-install `app_uuid`, to the `contributeProduct` function (`functions/src/off.ts`). The function accepts only the fields the app writes, then posts to `cgi/product_jqm2.pl` and each photo to `cgi/product_image_upload.pl` (`front_<lc>`, `nutrition_<lc>`) on world.openfoodfacts.org, under the app's shared account, with `app_name`, `app_version`, the `app_uuid` (so moderators can block one contributor) and the `YumSum/<version> (help.yumsum@gmail.com)` User-Agent.
  - `product_name_<lc>`, with `lc` from the language `readLabel` reads off the pack, else `productLanguage`.
  - `add_brands`.
  - `add_countries` and `cc`, from `countryProvider`, only for recognised UK/Bulgaria spellings.
  - `nutriment_<id>` per 100 g, or per 100 ml for volume packs.
- **The account:** only the function has it, as the Functions secrets `OFF_USER_ID` and `OFF_PASSWORD`; nothing about it is in the app.
  - `contributeProduct` takes 10 calls a day per account (`contribution_usage`), every try counted. Past that the sheet says "You've sent all you can today. You can send more tomorrow."; a refusal from Open Food Facts (`aborted`) says it didn't accept it, and anything else that it couldn't reach them.
  - `FoodContributionService.isConfigured` is always true now; contributing still isn't offered on the web.
  - `--dart-define=OFF_DRY_RUN=true` (the "YumSum (Android, contribute dry run)" config) only prints what would be sent and never calls the function; the AI reading still runs and counts.
- **Afterwards:** a thank-you screen counts contributions per device, and the product can go straight to the portion sheet. Set-up steps are in plan 01.

## Recipes

- **The library:** bundled as `assets/recipes/recipes.json`, read strictly by `Recipe.fromJson` (`lib/models/recipe.dart`, `parseRecipes`), loaded once by `recipesProvider`.
- **Bulgarian:** each recipe carries a `bg` object beside its English: `name`, `description`, `cuisine`, `ingredients` (an `item` and `amount` for each English ingredient, in the same order, whose figures they share) and `steps`. Photos and numbers aren't repeated.
  - `Recipe.bg` holds it; `textIn(language)` gives the words to show (the Bulgarian when the app is in Bulgarian, else the English), `nameIn` the name alone. Screens pass `context.l10n.localeName`.
  - The English fields stay the recipe's own: the AI's facts (`week_facts.dart`) use them, so the library adds nothing to AI Coach's `basis`.
  - A logged recipe is named in the app's language (`mealName(portions, l10n)`: "Pasta bolognese × 1.5", „Паста болонезе × 1,5“). Stored names are never rewritten; `isNamed` matches either name and optional `bg.previousNames`, any case, so Cooked recently, the quick-log bar and AI Coach's links still recognise a meal after a Bulgarian title is edited. Current and former names must stay unique across the library.
- **`RecipesScreen`** (`/recipes`):
  - A search box (`searchRecipes`): every word must be in the name, meal, cuisine, labels or ingredients, in English or Bulgarian, whatever the app's language. Plurals, accents and half-typed words don't matter; Bulgarian words lose their last vowel or plural ending (`_stem`: яйца and яйце, домати and домат). A few everyday words stand for others (`_alsoMeans`: fish, pasta, veggie, cheese…, and риба, паста, сирене, фета, йогурт). A word that only describes the next one, like the egg in egg noodles or пилешки in пилешки бульон, counts only when the search names both (`_describes`); мляко after кисело is yoghurt, found by "мляко" only with "кисело" (`_describedBy`). Bulgarian fillers (и, с, със, на…) are skipped like English ones.
  - "Cooked recently" (`recentlyCookedRecipes`: the last 14 days' meal names in either language, a ` × n` suffix (point or comma) stripped; hidden while searching).
  - Category `ChoiceChip`s, and photo tiles under a heading per meal (kept when one meal is picked), each with a + that logs.
  - A recipe with at least 8 g of fibre a portion (`Recipe.highFibre`, the same line AI Coach's fibre ideas use) has `FibreBadge` (`lib/widgets/fibre_badge.dart`) in its photo's top-left corner: a drawn wheat sprig, "Rich in fibre" as its tooltip. The recipe page's photo has it as a pill with "Rich in fibre" beside the sprig (`showLabel`). Shown to everyone, as it gives no figures.
- **`RecipeScreen`** (`/recipes/:id`; takes a `Recipe` as `extra` for recipes outside the library):
  - Prep, cook (`minutes` − `prepMinutes`) and serves, the ingredients, and "How to make it" with times and oven temperatures in bold (`_timeOrHeat`: "10 to 12 minutes", "220°C (200°C fan)", and „10–12 минути“, „1 час“, „220°C (200°C с вентилатор)“). An amount keeps its number and unit together, and „с. л.“ and „ч. л.“ whole.
  - From 600 px wide, the photo sits beside the title and the ingredients beside the steps.
- **Logging:** both screens go through `logRecipePortion` (`lib/screens/recipes/log_recipe_portion.dart`): `showRecipePortionsSheet` (halves, ½–10), then `LogMealController.submit` with the recipe's protein and macros, named "Name × 1.5" when not one portion.
- **Photos:** they aren't in the app. `RecipePhoto` loads `https://yumsum.web.app/recipes/<id>.webp` through `recipeImageProvider` (`cached_network_image`).
  - The WebPs are 640×480 and under 80 KB, made by `python -I tools/make_recipe_photos.py <folder>` (or `--placeholders`).
  - They live in `tools/hosting/recipes/`, which `build_hosting.ps1` copies to the website (long cache, CORS open).
- **Tests:** `test/recipes_asset_test.dart` checks fields, ranges, ingredient sums within 10%, macros, that every photo is present, and that every recipe has complete Bulgarian: a step for each step with the same numbers, an amount for each ingredient with the same numbers, no Latin letters outside the descriptions and °C, decimal commas, no straight quotes, and names unique across both languages. `test/recipes_bg_test.dart` shows the real library in Bulgarian at 360dp. Tests override `recipesProvider` and `recipeImageProvider` (`test/recipe_fixtures.dart`; `testRecipe(…, bgName:)` for a Bulgarian name).
- **Plans:** the recipe-writer brief and photo prompt are in plan 05; AI "What should I eat?" is planned for YumSum Star.

## Sign-in and account

- **Email and password:** sign-up sends a verification email and signs out; unverified sign-ins fail with `EmailNotVerifiedException`.
  - The confirmation email is ours (`sendVerificationEmail`, `functions/src/email.ts`, called through `verificationEmailProvider`): Firebase's own can't be restyled and comes from lean-streak-project.firebaseapp.com. The function takes the link from `generateEmailVerificationLink` and sends `verificationEmail(link, language)` in the app's `language` (English or Bulgarian: the same design and the same copy rules, "ти" in Bulgarian; `inLanguage` sets the link's `lang=bg` so Firebase's confirmation page is Bulgarian too) (the logo from the website, "Confirm your email", one orange button, the link as text, tables and inline styles for mail apps) as "YumSum" <help.yumsum@gmail.com> through Gmail, with an app password in the `GMAIL_APP_PASSWORD` secret. Nothing is sent to a confirmed account, and 5 a day per account at most (`email_usage`). If it fails, the app sends Firebase's plain one, so a new account always gets a link. When the domain is bought (plan 02), only the sender changes.
- **Google:**
  - The web uses Firebase's popup.
  - Phones use `google_sign_in` 7, which needs the web client ID that the google-services plugin reads from `google-services.json`. `googleSignIn()` in `auth_controller.dart` initialises the plugin once, as it requires.
  - Backing out (`backedOutOfGoogle`) isn't shown as an error.
- **Google-only accounts** (`hasPasswordLogin` false in `account_controller.dart`): Reset all data and Delete account are confirmed with Google instead of a password (`showPasswordConfirmDialog(askPassword: false)`), and Settings hides Change email and the password reset.

## Notifications, widget and shortcuts

- **Reminders:** `NotificationService` (`flutter_local_notifications`, Android/iOS only) schedules a daily meal reminder (20:30), a weigh-in reminder (Saturday 20:00 by default; a day or every day, and a time) and a daily creatine reminder (off by default, 09:00).
  - The switches are Settings' Notifications section (`NotificationSettings`).
  - `reminderSyncProvider` keeps the schedules in step, asking for permission once on first run. Their texts (and Android's channel names) come from `l10nProvider`, and a change of language schedules them again.
- **The creatine offer:** Home offers the creatine reminder once (`offerCreatineReminder`), from the day after sign-up to the end of the first week (`shouldOfferCreatine`), and either way says where to find it.
- **Launch actions:** a tap on the weigh-in reminder becomes `LaunchAction.logWeight` (`lib/app/launch_actions.dart`, bound in `main()` before Firebase so a cold-start tap isn't lost), and Home opens the log-weight dialog.
- **Android widget:** `LogWidgetProvider.kt` (a `home_widget` `HomeWidgetProvider`) draws `res/layout/log_widget.xml`, a 2×1 mini log bar (`res/xml/log_widget_info.xml`, colours in `values(-night)/colors.xml`).
  - Taps open `leanstreak://log/text` or `leanstreak://log/voice`, which `launchActionForUri` maps to `LaunchAction.typeLog` / `voiceLog`.
  - Each link carries `?key=` and this install's launch key (`launchKeyFor`: random, kept in the app's preferences and copied into home_widget's for the widget, which is redrawn when it changes). Links without it are ignored, so another app can open YumSum but can't start the mic.
  - Flutter deep linking is off in the manifest so go_router never sees those URIs, and `MainActivity` blanks the intent on a relaunch from Recents.
- **App-icon shortcut:** `quick_actions`, type `log_voice:` and the launch key, uses the same path. Its title (`shortcutLogVoice`) is set again whenever the language changes.
- The widget's four strings are in `res/values/strings.xml` and, in Bulgarian, `res/values-bg/strings.xml`, picked by the phone's language. The quick-log bar consumes the shortcut and widget actions.

## Feedback, crashes and legal pages

- **Crash reporting:** `firebase_crashlytics`, on Android/iOS only (it has no web build); the handlers are set in `main()` after Firebase.
- **Feedback:** Settings' feedback tile opens `showFeedbackDialog` (`lib/widgets/feedback_dialog.dart`): a Problem/Idea/Other `PillToggle`, which sets the prompt and the subject, over one message box.
  - `FeedbackRepository` sends the kind, text and app version to the `sendFeedback` function (`functions/src/feedback.ts`), which adds the uid and email from the sign-in and posts it as JSON to the Formspree form (in the help.yumsum Formspree account), which emails `supportEmail` (help.yumsum@gmail.com, `lib/core/constants/app_info.dart`) with the user's email as reply-to.
  - The function holds each account to 3 a day (`feedback_usage`, UTC days; a failed send doesn't count). The dialog's count on the device says so before sending; when the server refuses (`FeedbackLimitReached`), the dialog shows the same limit line. The free plan takes 50 messages a month.
- **Legal pages:** `tools/hosting/privacy.html` and `terms.html`, copied to the hosting root by `build_hosting.ps1` and served at `/privacy` and `/terms` (`cleanUrls`).
  - Bulgarian copies, `privacy-bg.html` and `terms-bg.html`, are served at `/privacy-bg` and `/terms-bg`, with the same design, `lang="bg"`, and a line at the top saying the English wins where they differ. Each page links to its other language in the top line. A change to the English needs the same change in the Bulgarian.
  - `LegalLinks` (`lib/core/constants/legal_links.dart`) holds the URLs, including the Open Food Facts credit; `privacyPolicy(language)` and `terms(language)` take `languageCodeProvider`'s code and give the `-bg` page for Bulgarian.
  - `LegalFooter` (on sign-in; on the web it also has the reCAPTCHA attribution line), Settings' legal section and the YumSum Star page open them (`test/legal_links_test.dart`).
  - `MedicalNote` is the health disclaimer under the plan preview. Both widgets are in `lib/widgets/legal_links.dart`.

## Hosting and release

- **Signing:** release builds are signed with the upload key named in `android/key.properties` (gitignored; the key file is outside the repo, alias `upload`). Without that file they fall back to the debug key, which Play rejects.
- **VS Code configs** (`.vscode/launch.json`): `--web-port 5000` for Edge (App Check), and the Android phone with and without the contribute dry run (`OFF_DRY_RUN`).
- **Building the site:** `tools/build_hosting.ps1` builds the web app into `build/hosting`, an `/app` build plus a `/webkit` build for Safari/iOS behind a small redirect page, and copies the legal pages and recipe photos. `web/flutter_bootstrap.js` leaves CanvasKit's variant to Flutter, so Chrome and Edge get the smaller Chromium one and Safari the full one. It clears Flutter's web build caches first: one kept an 18 October plugin list, so until 6 November the `/app` build had no Cloud Functions and AI failed in every browser but Safari.
- **Start-up on the web:** nothing outside the site can hold it up for good. Checked on 7 November 2026 by stalling each outside service in turn with WebKit as an iPhone: only Firebase's own scripts (www.gstatic.com) still stop it, and then the splash says "Taking longer than usual. Check your connection." after 15 seconds, with Reload on the web (`SplashScreen`, `lib/helpers/page_reload.dart`).
  - On phones and in Safari, Firebase Auth waited for Google's pop-up helper (apis.google.com and a firebaseapp.com frame) before it reported who was signed in, with no time limit, so a slow helper left the app on its logo (iPhones). A hook in `web/index.html` on `window.firebase_auth` (where FlutterFire puts the module) lets Auth start without it and loads it straight after, so the Google pop-up is still ready.
  - Firestore and Auth waited for App Check's reCAPTCHA token for as long as reCAPTCHA took, so a stalled one held up the profile (and so the splash) and email sign-in. App Check now starts after start-up (see App Check), and a hook on `window.firebase_app_check` gives the reCAPTCHA token 6 seconds; past that Firebase carries on with no token, which only the Cloud Functions refuse, and later asks fail at once until reCAPTCHA answers.
  - `web/index.html` preloads Firebase's modules (`modulepreload`), which FlutterFire only starts fetching once `main.dart.js` has run, and connects early to securetoken and Firestore.
  - The hooks rely on Firebase's internal names in JS SDK 13.1.0 (`_shouldInitProactively`, `_popupRedirectResolver`, `_initialize`, `_initializationPromise`, `ReCaptchaEnterpriseProvider.prototype.getToken`), and the preloads on its version. `tools/build_hosting.ps1` stops when FlutterFire loads another version: update the links and check the names, or the old waits come back.
- **Hosting:** Firebase Hosting serves it with SPA rewrites at `yumsum.web.app` (target `app`). The old default site `lean-streak-project.web.app` (target `old`, public folder `tools/hosting-redirect`) 301-redirects every path there. Targets are mapped in `.firebaserc`.
