# Translation

YumSum speaks English and Bulgarian. The rules are in `CLAUDE.md` (Text and translation); this is the how-to and the list of what is still English.

## How it fits together

- `l10n.yaml` runs gen-l10n: `lib/l10n/app_en.arb` is the template, `app_bg.arb` the Bulgarian, and the generated `lib/l10n/app_localizations*.dart` (class `AppLocalizations`) are committed.
- `lib/l10n/l10n.dart` has `context.l10n` for widgets (English when the tree has no localisations, as in the widget tests), and the date and number helpers. Import it rather than `app_localizations.dart`.
- `lib/providers/language_provider.dart` has the setting (`languageControllerProvider`, stored as `language`: `en`, `bg` or unset), `languageCodeProvider` (the code shown, and the one to send the Cloud Functions) and `l10nProvider` (the texts for code without a context).
- The worked examples: `lib/screens/language/language_screen.dart`, the Language switch in `AppDrawer` (`lib/widgets/app_frame.dart`), and the reminders in `lib/services/notification_service.dart`, fed from `reminderSyncProvider`.

## Adding a string

1. Add the key to `app_en.arb` with a description saying where it shows:

   ```json
   "progressErrorLoad": "Could not load your weight. Try again.",
   "@progressErrorLoad": {
     "description": "Weight & Progress: shown when the entries don't load."
   },
   ```

2. Add the same key to `app_bg.arb` (no description needed there):

   ```json
   "progressErrorLoad": "Не можахме да заредим теглото ви. Опитайте отново.",
   ```

3. Run `flutter gen-l10n` (a build or `flutter pub get` does it too).
4. Use it: `Text(context.l10n.progressErrorLoad)` in a widget, or `ref.read(l10nProvider).progressErrorLoad` in a controller or service. Where text outside a widget must change with the language (something scheduled or cached), watch `l10nProvider` instead, as `reminderSyncProvider` does.
5. Widget tests find the English text unchanged, since they get English. To check the Bulgarian, pump `LeanStreakApp` with `language: 'bg'` stored, as `test/language_test.dart` does, or read `lookupAppLocalizations(const Locale('bg'))`.

A key missing from `app_bg.arb` shows in English; gen-l10n lists it as untranslated.

### Key names

lowerCamelCase, `<area><Thing>`:

| Area prefix | Where |
|---|---|
| `common` | Words used in many places: `commonCancel`, `commonSave`, `commonTryAgain` |
| `auth`, `onboarding` | Sign-in, onboarding |
| `home`, `quickLog`, `meal`, `camera`, `food`, `contribute`, `macro` | Home, the quick-log bar, the meal form, Smart Snap and barcodes, packaged foods, contributing, macros |
| `history`, `coach`, `progress`, `adaptive`, `recipes` | History, AI Coach, Weight & Progress, the Adaptive formula, Recipes |
| `plan`, `account`, `star`, `notifications`, `feedback`, `legal`, `menu` | Plan Settings, Account Settings, YumSum Star, the Notifications page, feedback, legal links, the menu |
| `reminder`, `language` | The reminders themselves, the language |

Then what it is: `…Title`, `…Button`, `…Hint`, `…Error<What>` (`mealErrorSave`: "Could not save the meal. Try again."), `…Tooltip`. Reuse a `common` key only where the word is the same in Bulgarian too.

### Placeholders and plurals

Values go in as placeholders, so Bulgarian can move them:

```json
"homeKcalLeft": "{kcal} kcal left",
"@homeKcalLeft": {
  "description": "Home: calories left today.",
  "placeholders": { "kcal": { "type": "int" } }
},
```

Counts use ICU plurals. Bulgarian has only `one` and `other`:

```json
"historyDaysLogged": "{count, plural, =0{No days logged} one{1 day logged} other{{count} days logged}}",
```

```json
"historyDaysLogged": "{count, plural, =0{Няма записани дни} one{1 записан ден} other{{count} записани дни}}",
```

Decimals inside a text: pass the formatted string (`l10n.decimal(kg)`) as a `String` placeholder.

### Dates and numbers

From `AppFormats` in `lib/l10n/l10n.dart`, on any `AppLocalizations`:

| Was | Use | English | Bulgarian |
|---|---|---|---|
| `DateFormat('EEEE, d MMMM')` | `l10n.weekdayDayMonth(d)` | Saturday, 7 November | събота, 7 ноември |
| `DateFormat('EEE, d MMM')` | `l10n.shortWeekdayDayMonth(d)` | Sat, 7 Nov | сб, 7 ное |
| `DateFormat('d MMMM')` | `l10n.dayMonth(d)` | 7 November | 7 ноември |
| `DateFormat('d MMM')` | `l10n.shortDayMonth(d)` | 7 Nov | 7 ное |
| `DateFormat('d MMM yyyy')` | `l10n.shortDayMonthYear(d)` | 7 Nov 2026 | 7 ное 2026 |
| `DateFormat('MMMM yyyy')` | `l10n.monthYear(d)` | November 2026 | ноември 2026 |
| `DateFormat('MMMM')` | `l10n.month(d)` | November | ноември |
| `DateFormat('HH:mm')` | `l10n.time(d)` | 20:30 | 20:30 |
| anything else | `l10n.date(d, 'pattern')` | | |
| `x.toStringAsFixed(1)` | `l10n.decimal(x)` (`l10n.decimal(x, 2)`) | 1.5 | 1,5 |
| `double.tryParse(text)` on typed numbers | `parseDecimal(text)` | takes 1.5 | and 1,5 |

Bulgarian day and month names are lower case; wrap one that starts a line in `capitalised(…)`. Leave `yyyy-MM-dd` keys, `week_facts.dart` and anything sent to the AI as they are.

## Notes for translators

- Address the user informally, with "ти" ("Запиши", "твоят", "планът ти"), as a friendly app would; never "Вие". Write it as a good Bulgarian app would say it, not word for word from the English. Keep `CLAUDE.md`'s copy rules: sentence case, no exclamation marks (but "Благодарим ти!" and "Планът ти е готов!"), errors as "Не успяхме да … Опитай отново.", short enough for a 360dp phone.
- Bulgarian past forms and adjectives about the user carry gender ("ял/яла", "готов/готова"). Phrase around them so every line suits anyone: "Добави храненията си", not "Добави какво си ял".
- YumSum, YumSum Star and Smart Snap are names: keep them in Latin letters. AI Coach is "AI треньор". Units: kcal → ккал, g → г, kg → кг.
- Menu and page names (Plan Settings, Weight & Progress) are titles in English; in Bulgarian, write them as ordinary sentence-case phrases ("Настройки на плана").
- Static lists of labels (`const _pages = [...]` in `AppDrawer`, enums with labels such as `DayStatus` in `lib/models/daily_summary.dart` and `MealType` in `lib/models/recipe.dart`) can't call `context.l10n`: turn the label into a getter or a function that takes the `AppLocalizations`.
- Exceptions thrown with English text (`Exception('Not authenticated')`) only need a key where the text reaches the screen; check how the screen shows the error first.
- `main.dart`'s "YumSum could not start" screen runs before Riverpod and the app's localisations: read the stored `language` from the `SharedPreferences` it already has and use `lookupAppLocalizations`.
- The app-icon shortcut's title ('Log by voice', `lib/app/launch_actions.dart`) is set once at start-up: set it again when `languageCodeProvider` changes.
- The Cloud Functions are to get `ref.read(languageCodeProvider)` with each call (`aiEstimate`, `aiWeeklyReview`, `sendVerificationEmail`); the functions themselves still need to use it.

## To translate

Rough counts of user-facing strings, from a script over the string literals, so ±20%. Owner-only Debug tools (`lib/screens/debug/`, `lib/providers/debug_provider.dart`), the AI's facts (`lib/helpers/week_facts.dart`), the country names sent to the AI (`lib/models/user_profile.dart`) and log lines stay English and aren't listed. Grouped into three parts of about 300 strings each, by area, so the parts rarely touch the same file.

### Part 1: start, account and the app's frame (about 300)

| File | Strings |
|---|---|
| `lib/screens/auth/auth_screen.dart` | 29 |
| `lib/screens/onboarding/onboarding_screen.dart` | 42 |
| `lib/widgets/plan_choices.dart` | 24 |
| `lib/widgets/health_plan_preview_card.dart` | 35 |
| `lib/screens/profile/profile_screen.dart` (Plan Settings) | 52 |
| `lib/screens/profile/profile_load_error_screen.dart` | 5 |
| `lib/screens/account/account_settings_screen.dart` | 51 |
| `lib/providers/account_controller.dart` | 16 |
| `lib/widgets/password_confirm_dialog.dart` | 2 |
| `lib/widgets/legal_links.dart` | 10 |
| `lib/widgets/app_frame.dart` (menu) | 16 |
| `lib/widgets/feedback_dialog.dart` | 14 |
| `lib/widgets/splash_screen.dart` | 2 |
| `lib/main.dart` (start-up error) | 4 |
| `lib/app/launch_actions.dart` (shortcut) | 1 |

### Part 2: Home and logging (about 300)

| File | Strings |
|---|---|
| `lib/screens/dashboard/dashboard_screen.dart` | 31 |
| `lib/screens/dashboard/helpers/quick_log_bar.dart` | 26 |
| `lib/screens/dashboard/helpers/adaptive_dialogs.dart` | 16 |
| `lib/screens/dashboard/helpers/contribute_sheet.dart` | 42 |
| `lib/screens/dashboard/helpers/creatine_offer.dart` | 7 |
| `lib/screens/dashboard/helpers/day_off_dialog.dart` | 11 |
| `lib/screens/dashboard/helpers/food_search_sheet.dart` | 4 |
| `lib/screens/dashboard/helpers/meal_camera_page.dart` | 16 |
| `lib/screens/dashboard/helpers/meal_photo.dart` | 6 |
| `lib/screens/dashboard/helpers/plus_prompt_card.dart` | 2 |
| `lib/screens/dashboard/helpers/portion_sheet.dart` | 5 |
| `lib/screens/dashboard/helpers/smart_snap_dialog.dart` | 8 |
| `lib/screens/dashboard/helpers/web_camera_web.dart` | 10 |
| `lib/screens/meals/log_meal_sheet.dart` | 15 |
| `lib/widgets/estimate_breakdown.dart` | 6 |
| `lib/widgets/estimate_choice_dialog.dart` | 3 |
| `lib/widgets/meal_row.dart` | 7 |
| `lib/widgets/fibre_badge.dart` | 1 |
| `lib/widgets/macro_rings.dart` | 13 |
| `lib/widgets/macro_totals.dart` | 8 |
| `lib/widgets/macro_guide.dart` | 35 |
| `lib/services/calorie_estimate_service.dart` | 14 |
| `lib/services/food_contribution_service.dart` | 7 |
| `lib/services/food_lookup_service.dart` | 7 |

### Part 3: History, AI Coach, weight, recipes, reminders and YumSum Star (about 280)

| File | Strings |
|---|---|
| `lib/screens/review/review_screen.dart` | 25 |
| `lib/screens/review/day_meals_sheet.dart` | 15 |
| `lib/screens/review/weekly_notes.dart` | 6 |
| `lib/widgets/period_bar.dart` | 3 |
| `lib/widgets/calorie_bars.dart` | 2 |
| `lib/models/daily_summary.dart` (day statuses) | 3 |
| `lib/services/period_review_service.dart` | 5 |
| `lib/screens/coach/coach_screen.dart` | 31 |
| `lib/screens/progress/progress_screen.dart` | 36 |
| `lib/screens/progress/helpers/adaptive_section.dart` | 13 |
| `lib/screens/progress/helpers/log_weight_dialog.dart` | 9 |
| `lib/providers/adaptive_formula_provider.dart` (Adaptive lines) | 16 |
| `lib/screens/recipes/recipes_screen.dart` | 12 |
| `lib/screens/recipes/recipe_screen.dart` | 16 |
| `lib/screens/recipes/recipe_portions_sheet.dart` | 6 |
| `lib/screens/recipes/log_recipe_portion.dart` | 2 |
| `lib/models/recipe.dart` (meal types, tags) | 7 |
| `lib/screens/notifications/notifications_screen.dart` | 17 |
| `lib/screens/plus/plus_screen.dart` | 45 |
| `lib/widgets/plus_mark.dart` | 4 |
| `lib/providers/plus_purchase_controller.dart` | 5 |

### Outside `lib/`, for the owner to decide

- `assets/recipes/recipes.json`: 40 recipes' names, ingredients and steps, which are content, not ARB strings.
- `android/app/src/main/res/values/strings.xml`: the home-screen widget's 4 strings. Android picks them by the phone's language, so they go in a new `values-bg/strings.xml`.
- The website (`tools/hosting/`: legal pages) and the Cloud Functions' emails and AI replies.
