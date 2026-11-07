# Translation

YumSum speaks English and Bulgarian. The rules are in `CLAUDE.md` (Text and translation); this is the how-to, the glossary and the list of what is still English.

## How it fits together

- `l10n.yaml` runs gen-l10n: `lib/l10n/app_en.arb` is the template, `app_bg.arb` the Bulgarian, and the generated `lib/l10n/app_localizations*.dart` (class `AppLocalizations`) are committed.
- `lib/l10n/l10n.dart` has `context.l10n` for widgets (English when the tree has no localisations, as in the widget tests), and the date and number helpers. Import it rather than `app_localizations.dart`.
- `lib/providers/language_provider.dart` has the setting (`languageControllerProvider`, stored as `language`: `en`, `bg` or unset), `languageCodeProvider` (the code shown, and the one to send the Cloud Functions) and `l10nProvider` (the texts for code without a context).
- The worked examples: `lib/screens/language/language_screen.dart`, the Language switch in `AppDrawer` (`lib/widgets/app_frame.dart`), and the reminders in `lib/services/notification_service.dart`, fed from `reminderSyncProvider`.

## Adding a string

1. Add the key to `app_en.arb` with a description saying where it shows:

   ```json
   "progressErrorLoad": "Could not load your weight history.",
   "@progressErrorLoad": {
     "description": "Weight & Progress: the weigh-ins did not load."
   },
   ```

2. Add the same key to `app_bg.arb` (no description needed there):

   ```json
   "progressErrorLoad": "Не успяхме да заредим историята на теглото ти.",
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
| `plan`, `account`, `star`, `notifications`, `feedback`, `legal`, `menu` | Plan Settings (and the plan card, `planPreview…`, `planInfo…`), Settings (with the reminders), YumSum Star, feedback, legal links, the menu |
| `reminder`, `language`, `units` | The reminders themselves, the language, weights and heights with their units |

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

Weights and heights go through `lib/models/units.dart`, which takes the `AppLocalizations` too: `formatWeight(kg, unit, l10n)` ("80.5 kg", "80,5 кг"), `formatWeightChange`, `formatPace`, `formatHeight`, `weightRange` and `heightRange`, built from the `units…` keys. Pass the result into a text as a `String` placeholder (`homeWeightLatest`, `planPaceSlow`). `MeasureInput.show` and `switchTo` take it as well, so the boxes show "79,8" in Bulgarian; typed numbers take either mark.

## Notes for translators

- Address the user informally, with "ти" ("Запиши", "твоят", "планът ти"), as a friendly app would; never "Вие". Write it as a good Bulgarian app would say it, not word for word from the English. Keep `CLAUDE.md`'s copy rules: sentence case, no exclamation marks (but "Благодарим ти!" and "Планът ти е готов!"), errors as "Не успяхме да … Опитай отново.", short enough for a 360dp phone.
- Bulgarian past forms and adjectives about the user carry gender ("ял/яла", "готов/готова"). Phrase around them so every line suits anyone: "Добави храненията си", not "Добави какво си ял".
- YumSum, YumSum Star and Smart Snap are names: keep them in Latin letters. AI Coach is "AI треньор". Units: kcal → ккал, g → г, kg → кг, cm → см; lb, st, ft and in stay as they are (see the glossary).
- Menu and page names (Plan Settings, Weight & Progress) are titles in English; in Bulgarian, write them as ordinary sentence-case phrases ("Настройки на плана").
- Static lists of labels (`const _pages = [...]` in `AppDrawer`, enums with labels such as `DayStatus` in `lib/models/daily_summary.dart` and `MealType` in `lib/models/recipe.dart`) can't call `context.l10n`: turn the label into a getter or a function that takes the `AppLocalizations`.
- Exceptions thrown with English text (`Exception('Not authenticated')`) only need a key where the text reaches the screen; check how the screen shows the error first.
- `main.dart`'s "YumSum could not start" screen runs before Riverpod and the app's localisations, so it reads the stored `language` from `SharedPreferences` and uses `lookupAppLocalizations`.
- The app-icon shortcut's title ('Log by voice', `lib/app/launch_actions.dart`) is set again when the language changes.
- The Cloud Functions get `languageCodeProvider`'s code with each call (`aiEstimate`, `aiWeeklyReview`, `sendVerificationEmail`) and answer in it.
- Text built outside a widget but shown on one, such as the Adaptive formula's line on Home (`adaptiveTodayLineProvider`), watches `l10nProvider`; a widget that can reach `context.l10n` uses that, so a test with `locale: Locale('bg')` sees Bulgarian without the stored setting.

## Glossary

The Bulgarian the app uses for its own words. Keep to it in new text.

| English | Bulgarian |
|---|---|
| Home | Начало |
| meal | хранене |
| log (a meal, a weight) | запиши |
| weigh-in | претегляне |
| target (calories a day) | цел, дневна цел |
| target weight | желано тегло |
| current weight | сегашно тегло |
| height | ръст |
| On track / Close / Off track | В целта / Близо / Извън целта |
| day off | почивен ден |
| pace | темпо |
| maintenance (calories) | поддържащи калории |
| BMI | ИТМ |
| protein, fibre, carbs, fat, sugars, saturates, salt | протеин, фибри, въглехидрати, мазнини, захари, наситени мазнини, сол |
| account | профил |
| sign in / log out | вход, влез / изход |
| reset | нулирай |
| feedback | обратна връзка |
| Plan Settings | Настройки на плана |
| Weight & Progress | Тегло и напредък |
| Account Settings | Настройки на профила |
| History | История |
| Recipes | Рецепти |
| Notifications | Известия |
| AI Coach | AI треньор |
| Adaptive formula | адаптивна формула („Адаптивна формула“ as a heading) |
| YumSum, YumSum Star, Smart Snap | as they are, in Latin letters |
| kcal, g, kg, cm | ккал, г, кг, см |
| lb, st, ft, in | lb, st, ft, in: kept, as imperial units are rare in Bulgaria and the Bulgarian words (фунт, стоун, фут, инч) have no short forms; the toggles read „st и lb“, „ft и in“ and the second boxes „Фунтове“, „Инчове“ |
| decimals | with a comma: 80,5 кг, 0,25 кг |

Address the user as "ти" and keep lines free of the user's gender: „Колко тежиш сега?“ and „Какъв е ръстът ти?“, not „Колко си висок?“; „Не може да се отмени.“ rather than „Сигурен ли си?“.

## Recipes

The library's words are content, not ARB strings: each recipe in `assets/recipes/recipes.json` has a `bg` object with its `name`, `description`, `cuisine`, `ingredients` (`item` and `amount`, one for each English ingredient, in order) and `steps`. `Recipe.textIn(context.l10n.localeName)` picks the language; `test/recipes_asset_test.dart` fails a recipe without complete Bulgarian. A new recipe needs its `bg` too.

- Steps say "ти" in the imperative („Нарежи“, „Загрей“, „Раздели в 2 чинии“), with no forms that show the reader's gender.
- Ingredients by their shop names: кисело мляко, цедено кисело мляко (Greek yoghurt), извара (quark and cottage cheese), сирене (feta and sirene), пилешко филе, филе от пилешки бут, овесени ядки, гъби печурки, зелен фасул, риба тон в собствен сос, заквасена сметана (crème fraîche), прясно мляко 1,5%, „неварен“ for dried pasta and rice.
- Amounts in г, мл, л, с. л., ч. л., бр., глава, скилидки, филии; „на вкус“, „за сервиране“; decimal commas (1,5 л).
- Times as the page bolds them: „5 минути“, „1 минута“, „10–12 минути“ (an en dash, no spaces), „6 часа“, „30 секунди“; ovens „220°C (200°C с вентилатор)“. Keep every number the English step has.
- Dish names translated where Bulgarians would (Пилешко къри с ориз, Пълнени яйца), well-known foreign ones in Cyrillic (Менемен, Бьоф Строганов, Чили кон карне). Cuisines as „Гръцка кухня“.
- Names must differ from every other recipe's name in either language: a logged meal is matched to its recipe by name.

## To translate

Everything the app shows in `lib/` is in the ARBs, and the recipes carry their own Bulgarian (`bg` in `assets/recipes/recipes.json`, see Recipes above). Owner-only Debug tools (`lib/screens/debug/`, `lib/providers/debug_provider.dart`), the AI's facts (`lib/helpers/week_facts.dart`), the country names sent to the AI (`lib/models/user_profile.dart`), log lines and exceptions nobody sees stay English. Nothing else is left to translate.

The legal pages have Bulgarian copies, `tools/hosting/privacy-bg.html` and `terms-bg.html` (`/privacy-bg`, `/terms-bg`), which the app opens in Bulgarian. The English is the one that counts: change the Bulgarian with it, keeping the same meaning, data and periods.
