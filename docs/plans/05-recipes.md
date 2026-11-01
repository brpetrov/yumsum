# Plan 5: Recipes

*Written 31 October 2026. Status: built and tested, with the full library of 40 recipes (written by Claude on 31 October, then redone the same day to the brief below: easy, common, fairly quick, high in protein and modest in calories). All 40 real photos are in, and on 1 November each recipe was checked against its photo and adjusted to match; 4 photos showed the wrong dish and are being redone. Next: those 4, then publish.*

## What it is

- **Recipes** in the menu: a grid of photo tiles, filtered by Breakfast, Lunch, Dinner or Snack. Each tile shows calories and protein per portion and the time, and **Fits today** when a portion fits what's left of today's calories. Fits today only shows once something is logged, since before that everything "fits".
- **Logging is the point.** Every tile has a round **+** that logs portions straight away, and the recipe page has a **Log a portion** button. Both ask how many portions, in halves from ½ to 10, then log the meal for today with the recipe's own protein, so no AI is used. More than one portion is logged as "Pasta bolognese × 1.5", so the day's list explains the calories.
- **Cooked recently**, at the top of the page: recipes logged in the last two weeks, one tap to log another portion. Nothing extra is stored; it's worked out from the meals.
- **In the quick-log bar,** typing a recipe's name offers it as a chip with a book icon, beside the user's own meals. The user's own meals keep at least two of the three places, and a matching recipe always gets one. With nothing typed, recipes never appear.
- **The library is free; the AI is Plus.** The library costs nothing per use. "What should I eat?" (below) is the Plus feature, added once billing exists.

## Where things live

| What | Where |
|---|---|
| The recipes | `assets/recipes/recipes.json`, inside the app (about 1 KB each) |
| The photos | `tools/hosting/recipes/<id>.webp` in the repo, published with the website at `https://yumsum.web.app/recipes/<id>.webp` |
| The check | `test/recipes_asset_test.dart` |
| Photo converter | `tools/make_recipe_photos.py` |

**Photos are not inside the app,** so it stays the same size. The app downloads a photo the first time its tile shows and keeps it on the phone. Offline, a photo never seen before shows a plain box. The website's free allowance (10 GB a month) covers about 5,000 full browses of 40 photos, then costs about 12p per GB.

**Order matters:** deploy the website with the photos **before** releasing an app that lists the recipes. Otherwise the website answers a missing photo with its loading page, and the tile shows the plain box.

## Filling the library (for you)

1. **Write the recipes.** Give the brief below to the cheaper model. Save its answer as `assets/recipes/recipes.json`, replacing the three samples, or keep them if they fit.
2. **Check them:** `flutter test test/recipes_asset_test.dart`. It names any recipe that's wrong: a missing field, a number out of range, or ingredients that don't add up to the per-portion figures within 10%. Fix the JSON, or ask the model to, and run it again.
3. **Make the photos** in ChatGPT with the prompt below, one per recipe. Save each as the recipe's id (`pasta-bolognese.png`) into one folder.
4. **Convert them:** `python -I tools/make_recipe_photos.py <that folder>`. This crops each to 4:3, makes a 640×480 WebP under 80 KB in `tools/hosting/recipes/`, and skips any file that isn't named after a recipe. Delete the three placeholder WebPs first if you replace those recipes.
5. **Switch on the count check:** in `test/recipes_asset_test.dart`, uncomment the "library is complete" line, then run the test again.
6. **Publish:** `tools/build_hosting.ps1`, then `firebase deploy --only hosting:app`. Check that `https://yumsum.web.app/recipes/pasta-bolognese.webp` opens.
7. **Try it** on the phone: the menu, then Recipes, a tile, Log a portion.

### The brief for the recipe writer

> Write 40 recipes as one JSON array, nothing else. They are for YumSum, a calorie and protein tracker used across Europe.
>
> **Mix:** 8 breakfasts, 12 lunches, 14 dinners, 6 snacks. Easy, common dishes that people in Europe already cook at home on a weeknight: nothing fancy, nothing restaurant-only. Ingredients any supermarket sells (no saffron, bresaola, quinoa or the like). No fiddly techniques: no rolling, layering, skewering or breadcrumbing.
>
> **Easy and quick:** at most 4 steps and 9 ingredient lines; at most 40 minutes, most of them 30 or less.
>
> **One plate:** the ingredients are everything in a portion and all of it is on the plate, so the photo can show it. No "serve with" sides that the photo would leave out.
>
> **Nutrition:** high in protein, modest in calories. Per portion: breakfasts at most 450 kcal and at least 20 g protein; lunches at most 500 kcal and 25 g; dinners at most 550 kcal and 30 g; snacks at most 250 kcal and 12 g. Protein gives at least a quarter of the calories in every recipe (protein × 4 ÷ kcal ≥ 0.25). Tags: `high-protein` when protein is 30% or more of the calories, `quick` for 20 minutes or less, `low-calorie` for 350 kcal or less (snacks 150), plus `vegetarian` and `vegan` where true.
>
> **Figures:** for every ingredient, give its kcal and protein for the amount used in the whole recipe, from per-100 g values in the UK government's CoFID tables (McCance and Widdowson's) or Open Food Facts' generic entries. Then per portion = the sum ÷ servings, rounded to whole numbers. The totals are checked, so they must add up.
>
> **Writing:** metric amounts; common supermarket ingredients; British English; sentence case; short imperative steps of one to three sentences; no exclamation marks.
>
> **Order:** breakfasts, lunches, dinners, snacks; within each, lowest calories first.
>
> **Each recipe is an object with exactly these fields:**
>
> | Field | Type | Rule |
> |---|---|---|
> | `id` | text | kebab-case English name, unique, e.g. `pasta-bolognese` |
> | `name` | text | up to 60 characters, sentence case, e.g. "Pasta bolognese" |
> | `description` | text | optional, one line, up to 140 characters |
> | `cuisine` | text | up to 30 characters, e.g. "Italian" |
> | `category` | text | `breakfast`, `lunch`, `dinner` or `snack` |
> | `tags` | list of text | any of `high-protein`, `vegetarian`, `vegan`, `quick`, `low-calorie`; no repeats; may be empty |
> | `servings` | whole number | 1–12; the ingredient amounts are for this many |
> | `minutes` | whole number | prep plus cooking |
> | `kcalPerPortion` | whole number | 50–1500 |
> | `proteinPerPortion` | whole number, grams | 0–150 |
> | `ingredients` | list | each `{"item": "Lean beef mince, 5% fat", "amount": "500 g", "kcal": 625, "protein": 105}` |
> | `steps` | list of text | the method, in order |
>
> **Example of one recipe:**
> ```json
> {
>   "id": "greek-yoghurt-berry-bowl",
>   "name": "Greek yoghurt berry bowl",
>   "description": "Thick yoghurt with berries, oats and honey.",
>   "cuisine": "Greek",
>   "category": "breakfast",
>   "tags": ["high-protein", "vegetarian", "quick"],
>   "servings": 1,
>   "minutes": 5,
>   "kcalPerPortion": 330,
>   "proteinPerPortion": 30,
>   "ingredients": [
>     { "item": "Greek yoghurt, 0% fat", "amount": "250 g", "kcal": 143, "protein": 25 },
>     { "item": "Mixed berries", "amount": "100 g", "kcal": 40, "protein": 1 },
>     { "item": "Rolled oats", "amount": "25 g", "kcal": 93, "protein": 3 },
>     { "item": "Honey", "amount": "1 tsp", "kcal": 22, "protein": 0 },
>     { "item": "Walnuts, chopped", "amount": "5 g", "kcal": 34, "protein": 1 }
>   ],
>   "steps": [
>     "Spoon the yoghurt into a bowl.",
>     "Top with the berries, oats and walnuts.",
>     "Drizzle over the honey."
>   ]
> }
> ```

### Photos with Codex

Paste this into Codex, in this repository:

> For every recipe in `assets/recipes/recipes.json` that doesn't already have an image in `recipe-photos`, generate one image with the photo prompt in `docs/plans/05-recipes.md` (section "The photo prompt"), replacing [DISH NAME] with the recipe's `name` followed by exactly what is on the plate, taken from its ingredients (for example "Tuna rice cakes: two round puffed rice cakes topped with flaked tinned tuna and cucumber slices"). Show only those ingredients, nothing extra. Use the bowl or glass variant where the dish is served that way (soups, yoghurt, overnight oats, the smoothie, edamame). Save each image as `<id>.png` in a folder called `recipe-photos` at the repository root, where `<id>` is the recipe's `id`. Don't commit that folder. When all 40 exist, run `python -I tools/make_recipe_photos.py recipe-photos`, which replaces the placeholders in `tools/hosting/recipes/`, then run `flutter test test/recipes_asset_test.dart` and confirm it passes. Show me a contact sheet of all 40 so I can check the style matches.

The placeholders are a plain plate drawing, about 3 KB each. Real photos come out at 35 to 80 KB, so a folder full of 3 KB files means the photos weren't replaced. Don't publish the website until they are.

### The photo prompt

Use the same prompt for every photo, changing only the dish name:

> Overhead food photograph of **[DISH NAME]**, freshly cooked and plated on a plain matte cream ceramic plate, on a warm light-oak table. Soft natural daylight from the upper left, gentle shadows, realistic textures, slightly warm colour grade. The plate is centred and fills most of the frame; a small linen napkin in muted terracotta at one edge. No cutlery, no hands, no text, no logos, no extra dishes. Landscape 3:2, photorealistic, sharp focus on the food.

For drinks or bowls, swap "plated on a plain matte cream ceramic plate" for "in a plain matte cream ceramic bowl" or "in a clear glass", and keep everything else the same.

## Later: "What should I eat?" (Plus)

- One AI call returns three dishes that fit what's left today (calories and protein), in the same format as the library, so they open on the same recipe page and log the same way. An optional one-line wish box: "something with chicken", "vegetarian", "quick".
- About 0.25p a call. A daily user would cost about 8p a month, against the £2.12 kept from a £2.99 Plus.
- Hidden until Plus billing exists, so nothing is given away and taken back later. Billing would go through Play billing with a small Cloud Function and no other services, to keep fees down.
- In the code: the recipe page already accepts a recipe that isn't in the library, and a missing photo already shows the plain box.
- Other Plus ideas, not planned: **Plan my week** (seven dinners from the library that fit the target, with a shopping list, and no AI cost), Save for later, a restaurant-menu photo, a weekly check-in.
