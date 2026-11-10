# Plan 12: The estimate's questions, the amount and the kind

*Written and built 8 November 2026. Status: live (`aiEstimate` and the website). How it works now is in `docs/features.md` (AI, Estimates); this is why it is the way it is.*

## Why

After a typed or spoken estimate the app asks "Which did you have?" where the AI had to assume something. It used to ask one thing an item, and the prompt listed size among the milk, homemade or takeaway and the rest. So "зелеви сърми" asked with meat or without (a fifth either way) and never how many (3 against 8 is two and a half times). The owner wanted a smarter helper: ask the amount **and** the kind where both are unknown, with a clear order of what matters, and up to 6 choices in all. No new AI calls: the prompt is a little longer and the reply a few fields longer; the app does the arithmetic.

## What was decided

1. **The amount first.** Asked when the user gave none or a vague one ("a bowl", "a plate", "some", "a handful", "a few"):
   - food in pieces (sarmi, meatballs, pancakes, biscuits, slices): counts;
   - portions (rice, chips, soup, pasta): small, regular, large;
   - one-piece foods of varying size (a pizza, a bag of nuts): the sizes, or half and whole;
   - drinks: the sizes they're sold in.
   A count without a size ("2 slices of pizza", "a beer") asks the size as the kind instead. Never for a number, a size, a weight, a volume, "a"/"an" before one food, or a branded product.
2. **The kind second,** where it moves the calories about 15% or more: with or without meat, fried or grilled, homemade or takeaway (a restaurant portion folded in), full-fat or diet, the milk or sugar, and a part that adds a quarter or more (dressing, mayonnaise, butter, sauce).
3. **Three unknowns:** the two that move the calories most; the third folded into what's assumed.
4. **At most 6 chips** across both rows, counting the ticked one in each; kinds give way to amounts. **At most two items a meal** are asked, those whose answers move the calories most, in the meal's order.
5. **Not asked:** anything under 30 kcal of difference, recipe chips, barcodes, photos.

## How it's built

- **The reply:** an item may carry `amount` (the one assumed, "5 pieces", "regular", "средна" in Bulgarian) and `amounts` (`{amount, grams}`, up to 3, the grams of the whole item), beside the old `assumed` and `options` (complete items at the same grams). The typed meal's schema (`mealConfig`) has them; the voice template spells them out (`optionsJson`).
- **The app** (`parseEstimateItems`, `answered`, `lib/widgets/estimate_breakdown.dart`) filters them, caps the chips and works out any combination by scaling the kind picked by the amount's grams, as for a corrected weight.

## 10 November 2026: chips in the breakdown instead of a dialog

The owner tried the "Quick question" dialog and hated it: it interrupted every vague estimate, and an odd suggestion ("Pizza" for "Medium pizza") was annoying rather than helpful. Other calorie apps show what they assumed as a list to edit instead of asking. So the dialog is gone: the breakdown under the boxes opens by itself and shows each item's other amounts and kinds as small chips under it, the assumed ones ticked. A tap swaps that version in; ignored, the assumption is logged. Every item with choices shows them, so the two-items-a-meal limit went too. The app also drops a kind that adds nothing beyond the item's own words but a size, a count or a number (`_anotherKind`), and the eval's filter does the same.

## What the test set showed (`npm run eval`, 3 runs of 44 meals)

| | before | after |
|---|---|---|
| In range | 125/132 (95%) | 122/132 (92%) |
| Needless questions (specific meals) | 12/54 | 16/54 |
| Vague meals asked | 66/78 | 78/78 |
| Piece foods asked the count | 0/9 | 9/9 |

Eleven meals were added for this (`pieces` marks the piece foods). Of the 16 needless questions, 6 come from rules agreed here ("bowl of porridge" counts as vague; "boiled egg" asks how many); the rest are kinds the old prompt asked too. Accuracy lost about 3 points, mostly the full English, where each part's standard serving adds up high.

## What the first tries taught

- **Flash-Lite asks amounts the user gave** ("5 meatballs", "large oat latte", "a pint"), however the prompt puts it: needless questions went from 12 to 25. The app drops amounts that repeat a number or size word the user said (`_sizeWords`): back to 12. Only numbers and sizes count, not the food's name ("5 сърми" for "сърми") or a vague measure ("a bowl").
- **It often leaves out `amount`** for portions while giving `amounts`: the prompt and schema now ask for it, and the app shows a missing one as Regular.
- **"A usual serving" inflated portions** (chips at 945 kcal "regular"): it now says one standard serving, as nutrition guides give it, like `itemRules`.
- **Raw or cooked weight was dropped:** asked for "200 g grilled chicken breast", it called 330 kcal raw and 470 cooked, which would make the log worse.
- **"regular" came back as "редовна"** in Bulgarian: the word is now given in the app's language.
