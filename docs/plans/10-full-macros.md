# Plan 10: Full macros

*Written 2 November 2026. Status: planned, not built.*

## The short version

1. **YumSum Star shows the rest of the food label beside calories and protein:** fat, saturates, carbs, sugars, fibre and salt.
   - Today gets one quiet line that opens on a tap, and each meal shows its own figures on a tap.
   - They are plain totals with no targets. Only fibre (aim for 30 g a day) and salt (no more than 6 g) get the UK guide.
2. **Saved for everyone, shown only to YumSum Star.** Free users never see them. When someone subscribes or starts the trial, their history is already there.
3. **Packet labels and recipes cost nothing, so their figures are always saved.** That covers barcodes, search, contributions and the 40 recipes.
   - The AI gives six totals for the meal, not for each item. On paper that adds about 14% to a typed estimate.
   - If your measurement on the phone says 15% or less, every estimate asks for them. Otherwise only YumSum Star estimates do.
4. **Data first, display last.** First one `Nutrients` value on meals and daily summaries, with six optional fields in `firestore.rules` (you deploy those before anything writes them). Then the sources, then the display.
5. **The 40 recipes need the six figures** for every ingredient and portion. They come from the same tables as their calories, and the recipe test checks them.

## What the user sees

### Free

Nothing changes: no macros line and no teaser on Today. The paywall (plan 07) lists the feature:

> **Full macros:** fat, saturates, carbs, sugars, fibre and salt for your meals. Meals you've already logged show theirs too.

If the cost check leaves the AI asking only YumSum Star users, the second sentence becomes "Barcodes and recipes you've already logged show theirs too."

### YumSum Star

**Today.** One muted line sits under the protein bar, or under the calorie bar when protein is off. A tap opens it:

```
Daily protein                          96 / 120 g
[█████████████████████░░░░░░]
Fat 54 g · carbs 180 g · salt 4.2 g              ⌄
```

Open:

```
Fat               54 g     Saturates        18 g
Carbs            180 g     Sugars           62 g
Fibre   at least  12 g     Salt            4.2 g
Aim for 30 g of fibre a day, and no more than 6 g of salt.
1 meal not counted (no macro info)
Tap a meal to see its macros.
```

- **The closed line shows only fat, carbs and salt.** Four figures don't fit on a 360dp phone, and salt is the one with a limit.
- **No bars, no colours, no "over".** Today isn't judged mid-day, and these figures have no targets.
- **When there's nothing to show:**
  - With nothing logged, the line is hidden.
  - When none of today's meals has macros, it reads "No macro info for today's meals" and doesn't open.

**Meal rows**, on Today and in History's day sheet. A tap on the row shows the meal's figures under it, muted, over two lines if needed:

```
Chicken wrap                            520 kcal
12:40                               38 g protein  ⋮
Fat 18 g · saturates 6 g · carbs 52 g · sugars 5 g · fibre 4 g · salt 2.1 g
```

- A meal without figures says "No macro info for this meal."
- Only the ⋮ menu is tappable on a row today, so the tap doesn't clash with anything.

**Other places:**
- **History's day sheet:** the same block as Today, under the "1,850 of 2,000 kcal · 120 g protein" header.
- **Recipe page:** one muted line with the six per portion, under "430 kcal · 38 g protein per portion".
- **Amount sheet for a packet** (barcode or search): one muted line with the six for the amount chosen, under the portion's calories.

**Not shown:**
- recipe tiles
- the bar's AI breakdown, which has no per-item macros
- the month graph's tooltips
- the period review

See Later.

### Upgrading and lapsing

- **History shows at once.** Everything is read from the saved meals. Once `plusProvider` turns true (a subscription, the trial or your manual grant), every past day shows its macros, with nothing to copy or work out.
- **A lapse hides them, and they keep being saved.**
- **Older meals have none.** Meals logged before this release have no macros, so those days show "N meals not counted".

### Missing values

| Case | Shown as |
|---|---|
| A nutrient missing from some of the day's meals | "at least" before the total, e.g. "Fibre at least 12 g". Fibre is optional on UK labels, so this will be common for packets. |
| A meal with no macros at all | Left out of the totals, with "N meals not counted (no macro info)", like protein's note |
| A meal with only some | The ones it has, on its row |

## The nutrients

| Nutrient | Shown as | Meal and summary field | Recipe JSON (ingredient / portion) | Open Food Facts | AI key |
|---|---|---|---|---|---|
| Fat | Fat | `fatGrams` | `fat` / `fatPerPortion` | `fat_100g` | `fat` |
| Saturates | Saturates | `saturatesGrams` | `saturates` / `saturatesPerPortion` | `saturated-fat_100g` | `saturates` |
| Carbohydrate | Carbs | `carbsGrams` | `carbs` / `carbsPerPortion` | `carbohydrates_100g` | `carbs` |
| Sugars | Sugars | `sugarsGrams` | `sugars` / `sugarsPerPortion` | `sugars_100g` | `sugars` |
| Fibre | Fibre | `fibreGrams` | `fibre` / `fibrePerPortion` | `fiber_100g` | `fibre` |
| Salt | Salt | `saltGrams` | `salt` / `saltPerPortion` | `salt_100g`, else `sodium_100g` × 2.5 | `salt` |

- **Units:** grams.
  - Carbohydrate is counted as a UK label gives it, without fibre.
  - Salt is always salt, never sodium.
- **Sodium to salt:** salt = sodium × 2.5, the rule in UK labelling law. It's used only for a product that has `sodium_100g` but no `salt_100g`.
- **Rounding:**
  - Figures are stored to 0.1 g.
  - They're shown in whole grams, except salt, which gets one decimal ("4.2 g").
- **Flat fields, not a nested map.** The rules check each field with `optionalNumber`, as they already do for `proteinGrams`. A map would need its own key check.
- **Protein stays where it is** (`proteinGrams`, `trackProtein`). It isn't one of the six.

**In code:** one `Nutrients` class (`lib/models/nutrients.dart`) with six `double?` fields: `fat`, `saturates`, `carbs`, `sugars`, `fibre` and `salt`. Every carrier gains one field instead of six. It has:
- `fromFields` / `toFields` for Firestore. Only known values are written, rounded to 0.1 g. A meal with none gets no fields and reads back as null.
- `scaled(factor)`, for portions and changed calories
- `Nutrients.total(...)`: each nutrient summed over the meals that have it
- `nutrientsFromOff(map, suffix)`: reads Open Food Facts' ids, with the sodium rule. It takes either a product's `nutriments` (suffix `_100g`) or a label reading (the ids in `labelNutrientIds`).

It's a class rather than a record typedef because it carries these helpers.

## Where the numbers come from

| Source | Free user | YumSum Star |
|---|---|---|
| Barcode and food search | Saved | Saved |
| Contribution, then Log it | Saved | Saved |
| Recipe (tile +, Log a portion, chip) | Saved | Saved |
| Chip for one of your own meals | Copied | Copied |
| AI estimate, typed or voice | Saved if the cost check allows | Saved |
| AI estimate, photo | No photos (YumSum Star only, plan 06) | Saved |
| Fill-in when a named meal is saved without them | Not asked | Asked |
| Calories typed with no name | None | None |

No AI call is ever made just to fill in figures a free user can't see.

### The AI

**Prompts.** `_promptTemplate`, `_voicePromptTemplate` and `_photoPromptTemplate` each gain one sentence when the service is asked for macros:

> Also give the whole meal's fat, saturates, carbohydrate, sugars, fibre and salt in grams, as a UK food label would: carbohydrate without fibre, salt rather than sodium. Give them for the meal only, not for each component. Whole grams, except salt to one decimal.

- **The JSON:** each reply gains `"macros": {"fat": <number>, "saturates": <number>, "carbs": <number>, "sugars": <number>, "fibre": <number>, "salt": <number>}` after `protein_g`.
- **Voice:** the voice prompt treats macros like protein:
  - estimated from the food even when the user said the calories
  - `"macros": null` when nothing says what the food was ("400 calories for lunch")

**Parsing.**
- **`parseNutrients(map['macros'])`** sits next to `parseEstimateItems`.
  - It keeps non-negative numbers and leaves out anything else.
  - It drops the whole set when saturates come out above fat, or sugars above carbs. That means the model mixed them up.
- **The records:** `CalorieEstimate` and `VoiceMealParsed` gain `Nutrients? macros`. `EstimateItem`, `resized` and `totalOf` don't change.

**Corrected weights.** When a weight is changed in the breakdown, the meal's macros scale with its calories: 440 → 520 kcal multiplies every figure by 520/440. This is rough: more rice should mean more carbs, not more fat. Exact figures need per-item macros (Later).

**The fill-in on saving.**
- **The call:** `estimateProtein(name, kcal)` becomes `estimateNutrients(name, kcal)` and returns `({int? protein, Nutrients? macros})`. It asks for macros only for YumSum Star.
- **When it runs:** `LogMealController` calls it for a named meal in two cases:
  - protein is missing and tracked, as now
  - macros are missing and the user has YumSum Star
- **Allowance:** it still doesn't count, as plan 06 keeps it.
- **Protein off:** protein it returns anyway is saved, as now.

**Who is asked.**
- A constant in `lib/services/calorie_estimate_service.dart`, `macrosForEveryone`, starts `false`.
- Estimates ask for macros when `macrosForEveryone || plus`. Plan 06 already has `calorieEstimateServiceProvider` pass the service the user's `plus`.

### The cost check

Assumptions: about 35 more output tokens (the `macros` object) and 70 more input tokens (the sentence), at $2.50 and $0.30 per million. That's about $0.00011 more per call.

| One call | Now (plan 03) | With the six totals | Rise |
|---|---|---|---|
| Typed estimate | $0.00075 | $0.00086 | +14% |
| 10-second voice note | $0.00096 | $0.00107 | +11% |
| Meal photo (YumSum Star only) | $0.0011 | $0.0012 | +10% |
| Fill-in on saving (macros for YumSum Star only) | about $0.00015 | about $0.00026 | +70%, but only for subscribers |

- **Per item would cost too much.** Macros for each of about 5 items add about 175 output tokens, which is +60% or more a call.
- **A bare list of six numbers** instead of named keys would halve the extra. But a mixed-up order would go unnoticed, so I'd rather not.

**The trade-off, plainly.**
- **Asking everyone** costs about 1p a month per free user who estimates 3 meals a day, roughly £9 a month at 1,000 such users. It buys the moment when someone starts the trial and finds months of fat, carbs and salt already there.
- **Asking only YumSum Star** costs free users nothing. Their history then shows macros only for packets and recipes.

**The rule.** Measure a typed estimate both ways on your phone (Steps for you):
- 15% or less: set `macrosForEveryone` to `true`.
- More than 15%: leave it `false`.

Decide before the closed test, so the testers' history is what launch will be.

### Packets

- **`PackagedFood`** gains `Nutrients? macrosPer100g`. It isn't rounded like `kcalPer100g`, because 0.4 g of salt per 100 g matters.
- **`parsePackagedFood`** fills it with `nutrientsFromOff(n, suffix: '_100g')`. Values may be numbers or strings, which `_number` already handles.
- **`Portion`** (`portion_sheet.dart`) gains `Nutrients? macros`, and `portionFor` scales it by grams ÷ 100.
- **`_food()`** in `contribute_sheet.dart` builds the figures from the form's boxes (`_figure`), so a product someone has just added logs with its fat and salt too.
- **No request changes.** The barcode and search requests already ask for the whole `nutriments`.

### Recipes

- **`Recipe`** gains `macrosPerPortion` and `macrosFor(portions)`.
  - All six per-portion fields are required and checked strictly, like the rest.
  - The ranges in `Recipe.fromJson`: fat 0–150 g, saturates 0 to fat, carbs 0–300 g, sugars 0 to carbs, fibre 0–80 g, salt 0–15 g. Decimals are allowed.
- **`Ingredient`** gains `Nutrients? macros`, from optional `fat` … `salt` keys.
- **Logging:** `logRecipePortion` passes `recipe.macrosFor(portions)`, and recipe chips in `suggestionsFor` pass `macrosPerPortion`.

**The data job.** I fill in the 40 recipes with this brief, or you give it to the cheaper model as in plan 05. Then run `flutter test test/recipes_asset_test.dart`:

> Add six figures to every recipe in `assets/recipes/recipes.json`. Change nothing else unless a check below fails.
>
> - For every ingredient, add `fat`, `saturates`, `carbs`, `sugars`, `fibre` and `salt`. Give grams for the amount used in the whole recipe, from the same per-100 g source as its kcal and protein: the UK's CoFID tables (McCance and Widdowson's), or Open Food Facts' generic entries. Carbs as a UK label gives them, without fibre. Salt, not sodium (salt = sodium × 2.5). At most one decimal place.
> - Then give each portion `fatPerPortion`, `saturatesPerPortion`, `carbsPerPortion`, `sugarsPerPortion`, `fibrePerPortion` and `saltPerPortion`: the sum ÷ servings, to one decimal place.
> - Where a step seasons with salt without saying how much, add 0.5 g per portion (a pinch) to `saltPerPortion` only, not to an ingredient.
> - Check every portion: 4 × protein + 4 × carbs + 9 × fat + 2 × fibre should be within 15% of its kcal. Where it isn't, find the wrong figure and fix it, and list every recipe you changed and why.

29 of the 40 recipes season with salt in their method, so the pinch rule matters.

**The asset test** (`test/recipes_asset_test.dart`) gains three checks:
- **The sums add up.** Ingredient sums ÷ servings are within 1 g + 10% of each per-portion figure. For salt, the per-portion figure must be between the sum and the sum plus 0.5 g, with 0.2 g + 10% either side.
- **Saturates ≤ fat and sugars ≤ carbs,** per ingredient and per portion.
- **The energy check** above, within 15%.

### Chips, edits and corrections

- **The quick-log bar** has no boxes for macros. It keeps them beside the calories they came with (`_macros`, `_macrosKcal`).
  - `_fill` takes them as an optional argument, so every fill sets them: AI, voice, photo, portion or chip.
  - `_save` passes them scaled by the saved kcal ÷ `_macrosKcal`. That one rule covers a weight corrected in the breakdown (`_itemsChanged` passes them on unchanged) and calories typed over.
  - Editing the name, the clear button and starting the mic drop them.
- **The meal form** (`showLogMealSheet`) keeps an estimate's macros and their calories the same way, and passes them scaled on save.
- **Edits.** `LogMealController.submit` gains `Nutrients? macros`.
  - Today it rebuilds the `Meal` from its arguments, so an edit would wipe the macros.
  - When an edit passes none, it keeps the meal's own, scaled to the new calories, unless the name changed.
  - A renamed meal loses them, because hidden figures for a different food are worse than none. For YumSum Star, the fill-in on saving puts new ones in.
- **Chips.** `MealSuggestion` gains `Nutrients? macros`, from the meal or the recipe, so re-logging copies them like protein.

## What gets built

Plan 06 puts this at step 6, so `plusProvider` (plan 07) exists by then. Each step leaves the app working, and nothing shows until step 5.

### Step 1: the data

- `lib/models/nutrients.dart` (new): `Nutrients`.
- `lib/models/meal.dart`:
  - a `Nutrients? macros` field
  - `fromFirestore` reads it
  - `toFirestore` adds `...?macros?.toFields()`
- `lib/models/daily_summary.dart`: the same field, left out when there's none, like protein.
- `lib/services/daily_summary_service.dart`: `buildSummary` sets `macros: Nutrients.total(...)` over the day's meals. They go in the summary so History and the weekly review (plan 09) can use them later without a backfill.
- `firestore.rules`:
  - one helper, used by `validMeal` and `validSummary`
  - the six names added to both `hasOnly` lists

  ```
  function optionalMacros(d) {
    return optionalNumber(d.get('fatGrams', null))
      && optionalNumber(d.get('saturatesGrams', null))
      && optionalNumber(d.get('carbsGrams', null))
      && optionalNumber(d.get('sugarsGrams', null))
      && optionalNumber(d.get('fibreGrams', null))
      && optionalNumber(d.get('saltGrams', null));
  }
  ```
- `lib/providers/log_meal_controller.dart`: `submit` gains `macros`, with the edit rule above. The rule is a small pure function, so it can be tested without Firestore.
- `tools/hosting/privacy.html`, two sentences:
  - "meals (names, calories, protein and the time you logged them)" gains "and, where known, fat, saturates, carbohydrate, sugars, fibre and salt"
  - "returns the calories, protein and a breakdown" becomes "returns the calories, protein, other nutrients and a breakdown"
- The three fake `LogMealController`s in the tests gain the argument.

### Step 2: packets

`food_lookup_service.dart`, `portion_sheet.dart` (`Portion`, `portionFor`), `contribute_sheet.dart` (`_food()`), and in `quick_log_bar.dart` `_macros`, `_fill`, `_save` and `_usePackagedFood`. `meal_suggestions.dart` gets `MealSuggestion.macros` from meals.

### Step 3: recipes

1. The data job in `assets/recipes/recipes.json`.
2. `lib/models/recipe.dart`, in the same change, since the strict parser needs the data.
3. `log_recipe_portion.dart` and the recipe chips.
4. The asset test, `test/recipe_test.dart` and `test/recipe_fixtures.dart`.
5. Plan 05's brief gains the same lines, for future recipes.

### Step 4: the AI

- `calorie_estimate_service.dart`:
  - the three prompts
  - `parseNutrients`
  - the two records
  - `macrosForEveryone`
  - `estimateNutrients`
- `log_meal_controller.dart`: when the fill-in runs.
- `quick_log_bar.dart`: `_estimate`, `_finishListening` and `_takePhoto` pass the result's macros to `_fill`.
- `log_meal_sheet.dart`: keeps the estimate's macros.

Then you measure (Steps for you), and I set `macrosForEveryone`.

### Step 5: showing them

- `lib/providers/user_profile_provider.dart`: `showMacrosProvider`, true with YumSum Star, next to `trackProteinProvider`.
- `lib/widgets/macro_totals.dart` (new):
  - `MacroTotals`, the block for Today and the day sheet, built from a list of meals
  - `macrosLine(Nutrients)`, the one-line form for rows, the recipe page and the amount sheet
- `dashboard_screen.dart`: `_TodayCard` shows `MacroTotals`, with `showMacros` passed down the way `trackProtein` is.
- `lib/widgets/meal_row.dart`: a `showMacros` flag beside `showProtein`. It becomes stateful, to open on a tap.
- `lib/screens/review/day_meals_sheet.dart`: the block under the header, and `showMacros` on its rows.
- `lib/screens/recipes/recipe_screen.dart` (`_RecipeBody`): the per-portion line.
- `portion_sheet.dart`: `showMacros` like `showProtein`, and the line for the amount.
- The paywall line, in plan 07's paywall.
- `CLAUDE.md`:
  - a "Full macros" point under Key Domain Logic
  - the new fields under Firestore structure

## Tests

| Test | What it covers |
|---|---|
| `test/nutrients_test.dart` (new) | Scaling, totals over meals that have each nutrient, Firestore round trip with unknowns left out, rounding to 0.1 g, the edit rule |
| `daily_summary_service_test` | Summary macros are totals over meals that have them, and are left out when no meal has any |
| `food_lookup_service_test` | Macros read from `nutriments` for barcode and search; sodium × 2.5 when salt is missing; string values; none at all gives null |
| `portion_sheet_test` | `portionFor` scales macros; the line shows for YumSum Star only |
| `contribute_sheet_test` | The product handed to Log it keeps the label's macros |
| `meal_suggestions_test` | Chips carry macros from meals and recipes |
| `quick_log_bar_test` | Covers four things:<br>• barcode, estimate and chip fills are saved with macros<br>• a corrected weight or typed calories scale them<br>• editing the name drops them<br>• the fake's `submit` gains `macros` |
| `calorie_estimate_service_test` | `parseNutrients`: good, missing, negative, saturates above fat. The prompts mention macros only when asked. |
| `log_meal_sheet_test` | The estimate's macros are saved, scaled to edited calories. An edit with the same name keeps them; a renamed meal drops them. The fake's `submit` gains `macros`. |
| `recipe_test`, `recipe_fixtures.dart` | The new fields and their ranges |
| `recipes_asset_test` | Sums, saturates ≤ fat, sugars ≤ carbs, the energy check |
| `recipe_screens_test` | Log a portion passes macros; the recipe page line shows for YumSum Star only; the fake's `submit` |
| `day_meals_sheet_test` | The block shows for YumSum Star and not for free; a tap on a row shows its macros |
| `test/macro_totals_test.dart` (new) | Closed line, open grid, "at least", the guides, "not counted", the empty cases |

Tests override `plusProvider` both ways, as plan 06's do.

## Steps for you

1. **Deploy the rules after step 1**, before any build from step 2 goes on your phone. Debug builds write to the real database.

   ```
   firebase deploy --only firestore:rules
   ```

   An app that writes the new fields under the old rules can't save those meals ("Could not save meal").
2. **Measure the cost after step 4,** in a debug build on the phone, with `macrosForEveryone` still `false`.
   - Type the same 10 everyday meals and tap the sparkle for each: once signed in without YumSum Star, then once with your manual grant.
   - Send me the "AI tokens: in …, out …, thinking …" lines from the debug console.
   - Each call costs in × $0.30 + (out + thinking) × $2.50 per million tokens. I'll compare the averages, set the switch, and update plan 03's figures from the same lines (its token check is still open).
3. **Look over a few recipes** after the data job. Check the fat and salt look right for the dish.
4. **Publish the privacy page** with the app release: `tools/build_hosting.ps1`, then `firebase deploy --only hosting:app`.
5. **Try it on the phone:**
   - Scan a packet. The amount sheet shows its macros line, and the saved meal shows them on a tap.
   - Log 1.5 portions of a recipe. Each figure is one and a half times the per-portion figure.
   - Estimate a typed meal and correct a weight. The macros scale.
   - Edit a meal's calories, and the macros scale. Rename it, and new ones appear after saving.
   - Remove your grant, and every macro hides. Grant it again, and they're back, history included.
   - Switch protein off. The line moves under the calorie bar.

Play's Data safety form needs no change: these are more details of the same meals, stored the same way.

## Risks

- **AI macros are rougher than its calories,** and a free user doesn't see them until they upgrade. The two mix-up checks drop the worst. The rest is an estimate, like the calories.
- **Fibre is optional on UK labels,** so packets often lack it. "At least" says so, but fibre will read low for people who live on packets.
- **Scaling by calories is approximate** after a corrected weight or edited calories.
- **Recipe salt counts a pinch of seasoning** (0.5 g a portion). People who salt more eat more.
- **Deploy order.** The rules must be live before any build that writes the new fields.
- **Cost.** If everyone is asked, it shows in the monthly AI-cost check plan 06 describes.
- **Health framing:**
  - The figures are plain totals, with no colours and no targets.
  - The UK reference intakes for fat, saturates and sugars aren't shown as targets.
  - `MedicalNote` already covers the plan.

## Later

- **Macro targets:** a fat and carb split, or the UK reference intakes as guides (70 g fat, 20 g saturates, 260 g carbohydrate, 90 g sugars).
- **Per-item macros** in the breakdown, if the cost allows (about +60% a call).
- **Macros in History:** the period review, the month graph's tooltips and the AI weekly review. The summaries already carry them.
- **A "Show macros" switch** for subscribers who don't want them.
- **Typing macros by hand** in the meal form.
- **A backfill for new subscribers:** fill in their last 30 days of named meals in one go, about 2p a subscriber.
- **Low-salt and high-fibre labels** on recipes.

## Checklist

- [ ] (Claude) Step 1: `Nutrients`, meals, summaries, rules, edits, privacy page
- [ ] (you) `firebase deploy --only firestore:rules`
- [ ] (Claude) Step 2: packets and contributions
- [ ] (Claude) Step 3: the recipe data job and parser; (you) look over a few recipes
- [ ] (Claude) Step 4: the AI; (you) measure; (Claude) set `macrosForEveryone`
- [ ] (Claude) Step 5: Today, meal rows, day sheet, recipe page, amount sheet, paywall line
- [ ] (you) Phone checklist, then publish the privacy page with the release

## Sources

Checked on 2 November 2026:
- NHS, fibre (30 g a day for adults): <https://www.nhs.uk/live-well/eat-well/digestive-health/how-to-get-more-fibre-into-your-diet/>
- NHS, salt (no more than 6 g a day for adults): <https://www.nhs.uk/live-well/eat-well/food-types/salt-nutrition/>
- UK reference intakes (energy 2,000 kcal, fat 70 g, saturates 20 g, carbohydrate 260 g, sugars 90 g, protein 50 g, salt 6 g), retained Regulation (EU) 1169/2011, Annex XIII Part B: <https://www.legislation.gov.uk/eur/2011/1169/annex/XIII>
- Definitions, including salt = sodium × 2.5, Annex I: <https://www.legislation.gov.uk/eur/2011/1169/annex/I>
- Energy factors (fat 9, carbohydrate 4, protein 4, fibre 2, alcohol 7 kcal/g), Annex XIV: <https://www.legislation.gov.uk/eur/2011/1169/annex/XIV>
- What a label must show (fibre is optional), Article 30: <https://www.legislation.gov.uk/eur/2011/1169/article/30>
- DHSC technical guidance on nutrition labelling: <https://www.gov.uk/government/publications/technical-guidance-on-nutrition-labelling>

Not rechecked today:
- SACN, Carbohydrates and Health (2015), behind the 30 g fibre guideline: <https://www.gov.uk/government/publications/sacn-carbohydrates-and-health-report>
- CoFID (McCance and Widdowson's): <https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid>
- Open Food Facts API: <https://openfoodfacts.github.io/openfoodfacts-server/api/>
- Gemini API pricing, as in plan 03: <https://ai.google.dev/gemini-api/docs/pricing>
