# Plan 13: Servings and the whole pack on the scan sheet

*Written and built 8 November 2026. Status: live on the website; the phone app has it from its next build. How it works now is in `docs/features.md` (Packaged foods, Portions).*

## Why

After a barcode scan, a food search or a fresh contribution, the portion sheet showed the product and a grams box, starting at the pack's serving or 100. Someone who ate 3 cookies had to know what a cookie weighs. Open Food Facts often knows: `serving_size` is text like "1 biscuit (12.5 g)" or "30 g (3 cookies)", `serving_quantity` is the serving in grams, and `quantity` and `product_quantity` give the pack. The app fetched `serving_size` and `quantity` and only pulled the grams out.

## What was decided

- **Chips above the grams box:** 1 serving, 2 servings, 3 servings and Whole pack, each setting the grams. The chip for the grams in the box is selected, so typing other grams deselects them.
- **Whole pack** shows only where the pack's size is known and isn't one of the serving chips. With only a pack size, it's the only chip.
- **The serving line:** "Serving: 1 biscuit (12.5 g)" under the chips, the pack's own words, when they say more than the grams ("30 g" alone isn't shown).
- **The serving never falls back to the pack** any more: a 400 g jar isn't a serving. The box starts at the serving or 100. A single-serve pack with no serving given (a can, a bar) now starts at 100 g, one tap from Whole pack.
- **No AI.** Packs with no serving at all keep the grams box. Asking the AI what a piece weighs is a later idea, best with the estimate choices (plan 12).

## How it's built

- `PackagedFood` (`lib/services/food_lookup_service.dart`) carries `servingLabel` and `packGrams` beside `servingGrams`. Both lookups fetch `serving_quantity` and `product_quantity` too. The contribute sheet's product fills them from what was typed or listed.
- `lib/screens/dashboard/helpers/portion_sheet.dart` draws the chips (`ChoiceChip`) and the serving line.
