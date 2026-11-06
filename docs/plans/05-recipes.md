# Plan 5: Recipes

*Written 31 October 2026. Status: built and tested, with the full library of 40 recipes (written by Claude on 31 October, then redone the same day to the brief below: easy, common, fairly quick, high in protein and modest in calories). All 40 real photos are in. On 1 November each photo was checked against its recipe: 11 matched, and the other 29 were redone from the plate descriptions under "Photo redo" and checked again; all 40 now show their recipe's portion. Next: publish.*

## What it is

- **Recipes** in the menu: a grid of photo tiles, filtered by Breakfast, Lunch, Dinner or Snack. Each tile shows calories and protein per portion and the time. *Changed 6 November:* the **Fits today** chip, and the recipe page's "Fits what's left today", are gone; they said little.
- **Logging is the point.** Every tile has a round **+** that logs portions straight away, and the recipe page has a **Log a portion** button. Both ask how many portions, in halves from ½ to 10, then log the meal for today with the recipe's own protein, so no AI is used. More than one portion is logged as "Pasta bolognese × 1.5", so the day's list explains the calories.
- **Cooked recently**, at the top of the page: recipes logged in the last two weeks, one tap to log another portion. Nothing extra is stored; it's worked out from the meals.
- **In the quick-log bar,** typing a recipe's name offers it as a chip with a book icon, beside the user's own meals. The user's own meals keep at least two of the three places, and a matching recipe always gets one. With nothing typed, recipes never appear.
- **The library is free; the AI is YumSum Star.** The library costs nothing per use. "What should I eat?" (below) is a YumSum Star feature, added once billing exists (`06-yumsum-plus.md`).

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
> **Easy and quick:** at most 9 ingredient lines; at most 45 minutes in all, most of them 30 or less, with the times honest (water coming to the boil, the oven heating).
>
> **One plate:** a portion, sides included, fits on one plate or in one bowl, so its photo can show all of it.
>
> **Nutrition:** high in protein, modest in calories. Per portion: breakfasts at most 450 kcal and at least 20 g protein; lunches at most 500 kcal and 25 g; dinners at most 550 kcal and 30 g; snacks at most 250 kcal and 12 g. Protein gives at least a quarter of the calories in every recipe (protein × 4 ÷ kcal ≥ 0.25). Tags: `high-protein` when protein is 30% or more of the calories, `quick` for 20 minutes or less, `low-calorie` for 350 kcal or less (snacks 150), plus `vegetarian` and `vegan` where true.
>
> **Figures:** for every ingredient, give its kcal and protein for the amount used in the whole recipe, from per-100 g values in the UK government's CoFID tables (McCance and Widdowson's) or Open Food Facts' generic entries. Then per portion = the sum ÷ servings, rounded to whole numbers. The totals are checked, so they must add up.
>
> **Macros (plan 10):** also give every ingredient `fat`, `saturates`, `carbs`, `sugars`, `fibre` and `salt` in grams for the amount used, from the same per-100 g source, at most one decimal place: carbs as a UK label gives them, without fibre; salt, not sodium (salt = sodium × 2.5). Each portion's `fatPerPortion`, `saturatesPerPortion`, `carbsPerPortion`, `sugarsPerPortion`, `fibrePerPortion` and `saltPerPortion` is the sum ÷ servings, to one decimal place. Where a step seasons with salt without saying how much, add 0.5 g per portion (a pinch) to `saltPerPortion` only, not to an ingredient. Check every portion: 4 × protein + 4 × carbs + 9 × fat + 2 × fibre should be within 15% of its kcal.
>
> **Writing:** metric amounts; common supermarket ingredients; British English; sentence case; no exclamation marks.
>
> **Steps:** 3 to 7, each one to three short imperative sentences, so a beginner can cook it without guessing. Start with the prep (what to chop and how). Every cooking step says the heat ("a large frying pan over a medium heat", "220°C (200°C fan)"), how long, written in digits ("5 minutes", "10 to 12 minutes"; the app shows these in bold), and how to tell it's done ("until soft", "no pink in the middle", "until it flakes easily"). Say when to start a second thing ("Meanwhile…", "When the sauce has 15 minutes left…"). The last step splits it into equal portions, so each matches the calories logged, and for dishes that keep, says how long: 2 days in the fridge, cooked rice only until the next day, 3 months frozen for soups, sauces and chilli (Food Standards Agency). Salt, pepper and water may be used without being listed.
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
> | `minutes` | whole number | prep plus cooking, start to finish |
> | `prepMinutes` | whole number | the chopping and mixing before anything cooks; at most `minutes` (all of it for a dish with no cooking) |
> | `kcalPerPortion` | whole number | 50–1500 |
> | `proteinPerPortion` | whole number, grams | 0–150 |
> | `fatPerPortion`, `saturatesPerPortion`, `carbsPerPortion`, `sugarsPerPortion`, `fibrePerPortion`, `saltPerPortion` | grams, one decimal place | fat 0–150, saturates up to the fat, carbs 0–300, sugars up to the carbs, fibre 0–80, salt 0–15 |
> | `ingredients` | list | each `{"item": "Lean beef mince, 5% fat", "amount": "500 g", "kcal": 625, "protein": 105, "fat": 25, "saturates": 11, "carbs": 0, "sugars": 0, "fibre": 0, "salt": 1}` |
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
>   "prepMinutes": 5,
>   "kcalPerPortion": 330,
>   "proteinPerPortion": 30,
>   "fatPerPortion": 6.2,
>   "saturatesPerPortion": 1,
>   "carbsPerPortion": 36.7,
>   "sugarsPerPortion": 20.9,
>   "fibrePerPortion": 6.1,
>   "saltPerPortion": 0.3,
>   "ingredients": [
>     { "item": "Greek yoghurt, 0% fat", "amount": "250 g", "kcal": 143, "protein": 25, "fat": 0.5, "saturates": 0.3, "carbs": 9.5, "sugars": 9, "fibre": 0, "salt": 0.3 },
>     { "item": "Mixed berries", "amount": "100 g", "kcal": 40, "protein": 1, "fat": 0.3, "saturates": 0, "carbs": 6.5, "sugars": 6, "fibre": 3.6, "salt": 0 },
>     { "item": "Rolled oats", "amount": "25 g", "kcal": 93, "protein": 3, "fat": 2, "saturates": 0.4, "carbs": 15, "sugars": 0.3, "fibre": 2.3, "salt": 0 },
>     { "item": "Honey", "amount": "1 tsp", "kcal": 22, "protein": 0, "fat": 0, "saturates": 0, "carbs": 5.5, "sugars": 5.5, "fibre": 0, "salt": 0 },
>     { "item": "Walnuts, chopped", "amount": "5 g", "kcal": 34, "protein": 1, "fat": 3.4, "saturates": 0.3, "carbs": 0.2, "sugars": 0.1, "fibre": 0.2, "salt": 0 }
>   ],
>   "steps": [
>     "Spoon the yoghurt into a bowl and smooth the top.",
>     "Scatter over the berries, oats and walnuts. Frozen berries can go straight on; they soften in about 5 minutes.",
>     "Drizzle over the honey and eat straight away."
>   ]
> }
> ```

### Photos with Codex

Paste this into Codex, in this repository:

> For every recipe in `assets/recipes/recipes.json` that doesn't already have an image in `recipe-photos`, generate one image with the photo prompt in `docs/plans/05-recipes.md` (section "The photo prompt"), replacing [DISH NAME] with the recipe's `name` followed by exactly what is on the plate, taken from its ingredients (for example "Tuna rice cakes: two round puffed rice cakes topped with flaked tinned tuna and cucumber slices"). Show only those ingredients, nothing extra. Use the bowl or glass variant where the dish is served that way (soups, yoghurt, overnight oats, the smoothie, edamame). Save each image as `<id>.png` in a folder called `recipe-photos` at the repository root, where `<id>` is the recipe's `id`. Don't commit that folder. When all 40 exist, run `python -I tools/make_recipe_photos.py recipe-photos`, which replaces the placeholders in `tools/hosting/recipes/`, then run `flutter test test/recipes_asset_test.dart` and confirm it passes. Show me a contact sheet of all 40 so I can check the style matches.

### Photo redo (1 November)

Paste this into Codex:

> Regenerate the 29 photos listed under "Photo redo" in `docs/plans/05-recipes.md` with the photo prompt in that file, using each line's description in place of [DISH NAME] (bowl variant where it says bowl), and overwrite `recipe-photos/<id>.png`. Each photo shows one portion and only what its description lists. Then run `python -I tools/make_recipe_photos.py recipe-photos` and `flutter test test/recipes_asset_test.dart`, and show me a contact sheet of the 29 with their ids.

One portion each:

- `greek-yoghurt-berry-bowl` (bowl): thick Greek yoghurt topped with strawberries, raspberries and blueberries, a sprinkle of plain rolled oats, a few chopped walnuts and a thin drizzle of honey. Raw rolled oats, not granola clusters; no seeds.
- `tofu-scramble`: one slice of toasted wholemeal bread topped with golden turmeric tofu scramble, wilted spinach, softened onion and halved cherry tomatoes. No peppers.
- `lighter-full-english`: two grilled bacon medallions, two poached eggs, a spoonful of baked beans, grilled mushrooms, one grilled tomato cut in half and one slice of wholemeal toast. No sausages, no hash brown, no fried eggs.
- `skyr-overnight-oats` (bowl): creamy overnight oats with chia seeds through them, topped with mixed berries and a drizzle of honey. No banana, no nuts.
- `tomato-feta-omelette`: a folded three-egg omelette filled with halved cherry tomatoes, wilted spinach and crumbled feta, with one slice of wholemeal toast on the plate.
- `menemen`: Turkish menemen (soft eggs cooked into chopped tomatoes, green peppers and onion) topped with crumbled feta and chilli flakes, with one slice of wholemeal bread at the side of the plate.
- `pea-and-ham-soup` (bowl): smooth, blended, bright green pea soup with shredded ham on top and a swirl of white yoghurt. No vegetable chunks, no carrots.
- `tuna-white-bean-salad`: a bed of rocket topped with flaked tinned tuna, cannellini beans, halved cherry tomatoes, thinly sliced red onion and a few capers, glossy with olive oil.
- `prawn-egg-open-sandwich`: two slices of dark rye bread spread with dill yoghurt, topped with cucumber slices, sliced boiled egg, small pink cooked prawns and dill sprigs.
- `red-lentil-soup` (bowl): smooth, blended red lentil soup, orange and velvety, with a light dusting of paprika and a lemon wedge. No whole lentils or vegetable chunks.
- `potatoes-herb-quark`: boiled new potatoes in their skins beside a generous spoonful of white quark mixed with grated cucumber, chopped pink radishes, chives and dill, with a drizzle of oil.
- `tuna-nicoise-salad`: lettuce with chunks of flaked tinned tuna (not a seared tuna steak), halved new potatoes, green beans, quartered boiled eggs, cherry tomatoes and black olives.
- `chicken-souvlaki-wrap`: one thin, soft wholemeal tortilla wrap, folded open, filled with grilled chicken chunks, white tzatziki with grated cucumber, sliced tomato and red onion. Not a thick pitta; no lettuce.
- `tuna-pasta-salad`: pasta shapes with flaked tuna, yellow sweetcorn, diced red pepper and sliced spring onions in a light creamy dressing. No tomatoes, no cucumber.
- `shopska-salad-chicken`: chopped tomatoes, cucumber, red pepper and red onion with finely grated white cheese heaped on top and parsley, sliced grilled chicken breast, and one warm wholemeal pitta at the side of the plate.
- `turkey-steaks-mustard-mash`: one golden pan-fried turkey steak in a creamy mustard sauce, a mound of mashed potato and green beans.
- `greek-lemon-chicken-potatoes`: roasted chicken thighs and golden potato wedges with lemon, garlic and oregano, and green beans.
- `chicken-goulash` (bowl): chicken chunks, potato chunks, red pepper and onion in a deep red paprika and tomato sauce, with a spoonful of white yoghurt on top.
- `garlic-prawn-spaghetti`: spaghetti with pink king prawns, halved cherry tomatoes, sliced garlic, wilted rocket, chilli flakes and parsley.
- `salmon-dill-potatoes`: a baked salmon fillet, new potatoes tossed in butter and dill, green beans and a small spoonful of white dill yoghurt sauce.
- `spinach-feta-frittata`: two wedges of thick spinach, feta and cherry tomato frittata, with a small pile of mixed salad leaves and one slice of wholemeal bread.
- `chicken-curry`: mild chicken curry in a tomato and coconut sauce with wilted spinach through it, beside white basmati rice.
- `chilli-con-carne`: chilli con carne (beef mince, kidney beans, red pepper) over white rice, with a spoonful of white yoghurt on top.
- `cottage-cheese-tomato-pasta`: pasta shapes in a smooth, creamy pink tomato sauce with wilted spinach, and grated cheese on top. No tomato chunks, no cheese curds.
- `beef-burgers-wedges`: one lean beef burger with a slice of melted cheese, lettuce, tomato and red onion in a brown wholemeal bun (no sesame seeds, not brioche), with oven potato wedges.
- `chocolate-yoghurt-pot` (bowl): smooth chocolate Greek yoghurt topped with fresh raspberries. No chocolate shavings.
- `chilli-edamame` (bowl): shelled green edamame beans, out of their pods, with chilli flakes, sea salt and a lemon wedge. No pods, no nuts.
- `tuna-rice-cakes`: two round puffed rice cakes (the crunchy supermarket kind) topped with flaked tinned tuna mixed with a little yoghurt, thin cucumber slices and black pepper. Not fishcakes.
- `cottage-cheese-crispbreads`: three rectangular rye crispbreads spread thickly with white cottage cheese, topped with cucumber slices, chives and black pepper.

The 11 that already match, and are not to be redone: quark pancakes (the first version, with berries), smoked salmon and eggs on rye, chicken noodle soup, chicken Caesar salad, egg mayo sandwich, pasta bolognese, beef stroganoff, chicken stir-fry, cod with chorizo, devilled eggs and the berry smoothie. Rejected images are kept in `recipe-photos/rejected/`, where the converter doesn't look.

The placeholders are a plain plate drawing, about 3 KB each. Real photos come out at 35 to 80 KB, so a folder full of 3 KB files means the photos weren't replaced. Don't publish the website until they are.

### The photo prompt

Use the same prompt for every photo, changing only the dish name:

> Overhead food photograph of **[DISH NAME]**, freshly cooked and plated on a plain matte cream ceramic plate, on a warm light-oak table. Soft natural daylight from the upper left, gentle shadows, realistic textures, slightly warm colour grade. The plate is centred and fills most of the frame; a small linen napkin in muted terracotta at one edge. No cutlery, no hands, no text, no logos, no extra dishes. Landscape 3:2, photorealistic, sharp focus on the food.

For drinks or bowls, swap "plated on a plain matte cream ceramic plate" for "in a plain matte cream ceramic bowl" or "in a clear glass", and keep everything else the same.

## Later: "What should I eat?" (YumSum Star)

- One AI call returns three dishes that fit what's left today (calories and protein), in the same format as the library, so they open on the same recipe page and log the same way. An optional one-line wish box: "something with chicken", "vegetarian", "quick".
- About 0.25p a call. A daily user would cost about 8p a month, against the £2.83 kept from a £3.99 YumSum Star month.
- Hidden until YumSum Star exists, so nothing is given away and taken back later. Billing goes through Play billing with our own Cloud Functions and no other services, to keep fees down (`07-billing.md`).
- In the code: the recipe page already accepts a recipe that isn't in the library, and a missing photo already shows the plain box.
- Other YumSum Star ideas, not planned: **Plan my week** (seven dinners from the library that fit the target, with a shopping list, and no AI cost), Save for later, a restaurant-menu photo. (The weekly check-in idea became the Adaptive formula and the AI weekly review, plans 08 and 09.)
