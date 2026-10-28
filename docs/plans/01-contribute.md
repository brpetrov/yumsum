# Plan 1: Contribute to Open Food Facts

*Written 23 October 2026. Status: built and tested in the app; waiting for an Open Food Facts account before it switches on.*

## Why

When a scanned barcode isn't in Open Food Facts, the user has the packet in their hand. With two photos they can add it, and the next person who scans that packet gets an instant answer. That's a small good deed, and the app presents it that way: "Be the first to add this … for you and for everyone who scans it after you."

It also fixes LeanStreak's weakest spot. Bulgarian products and UK supermarket own brands are often missing, and every contribution fills a gap for every app that uses Open Food Facts, not just ours.

## How it works for the user

1. They scan a barcode. If Open Food Facts has never heard of it, a sheet appears: **Be the first to add this**, with **Contribute** and **Not now**. A product it does have but with no calories isn't offered, because that's someone else's entry and contributing would overwrite it. The user is told it has no calories yet.
2. The camera asks for two photos: **1 of 2 · The front of the pack**, then **2 of 2 · The nutrition table**.
3. One AI call reads both photos and fills in a form: name, brand, pack size, serving size, and energy, protein, fat, saturates, carbohydrate, sugars, fibre and salt per 100 g. The AI is told to copy what's printed and never guess. Anything it can't read stays blank.
4. The user checks the figures against the packet, fixes anything wrong, and taps **Contribute**. A line under the form says the photos and details will be public under open licences.
5. A thank-you screen appears: "Thank you! … is now on Open Food Facts, for you and for everyone who scans it after you." From the second contribution it adds a count, e.g. "That's 3 products you've added". **Log it** goes straight to the usual amount sheet.

**Not now** gives the old behaviour: the "isn't in the food database" message, and the camera ignores that barcode next time so the user can photograph the meal instead. Backing out after tapping Contribute just closes things quietly, so a later scan can offer it again. Closing the thank-you instead of tapping Log it still counts as contributed. The form can't be closed while it's sending.

## What's built

| Part | Where |
|---|---|
| Invitation, check form, thank-you | `lib/screens/dashboard/helpers/contribute_sheet.dart` |
| Two-photo camera mode | `MealCameraPage(photoSteps: …)`, `takeProductPhotos` in `meal_photo.dart` |
| AI label reading | `CalorieEstimateService.readLabel`, `parseLabelReading` (counts towards the 20-a-day AI limit) |
| Upload | `lib/services/food_contribution_service.dart` |
| Wiring in the bar | `_offerContribution` in `quick_log_bar.dart` |
| Legal | privacy page (contributions section), terms ("Contributing to Open Food Facts"), and a "Food data from Open Food Facts" credit in Account Settings → Help & Legal |
| Tests | `test/food_contribution_service_test.dart`; the full scan → contribute → log flow in `test/quick_log_bar_test.dart` |

### What gets sent

This follows Open Food Facts' own Flutter app and their server code (checked 23 October 2026):

- **Details:** a form `POST` to `/cgi/product_jqm2.pl` with these fields:
  - `code`
  - `product_name_<lang>`, plus `lang` and `lc`: the language the AI reads off the pack (e.g. `bg`, `en`, `sr`), or `bg` for a Cyrillic name and `en` otherwise if it can't tell
  - `add_brands`, which appends, so it never wipes what's there
  - `add_countries` (`en:united-kingdom` or `en:bulgaria`) and `cc` (`uk`, not `gb`, or `bg`). These are sent only when the profile's country is one of the common ways of writing the UK or Bulgaria; otherwise Open Food Facts goes by where the request came from.
  - `quantity` and `serving_size`
  - `nutrition_data_per`: `100ml` when the pack or serving size is in ml, cl or l, otherwise `100g`
  - `nutriment_<id>` and `nutriment_<id>_unit` for each figure
- **Account fields:** the app's shared account (`user_id`, `password`) plus `app_name`, `app_version` and `app_uuid`.
  - `app_uuid` is a random ID kept per install, so Open Food Facts' moderators can block one bad contributor without blocking the whole app.
  - A `comment` of "LeanStreak 0.1.0 user <app_uuid>", as their docs ask. Nothing personal.
- **Photos:** two multipart `POST`s to `/cgi/product_image_upload.pl`, front first.
  - Each has `imagefield` set to `front_<lang>` or `nutrition_<lang>`, with the file in `imgupload_<imagefield>`.
  - The server sets them as the product's front and nutrition pictures. Only a photo sent as the front becomes the front picture.
- **Result checks:**
  - **Details saved:** `{"status":1}`.
  - **Photo saved:** `"status ok"`, or an existing `imgid` when it's a retry.
  - **Wrong password:** returns an HTML page and counts as a failure.
  - **Any failure:** the user sees a short message and can tap Contribute again.

### Rules this follows

- **Data from the packet.** Open Food Facts' terms say data must "come directly from the label and packaging" and photos "must have been taken by the contributors themselves". The camera only takes new photos; there's no gallery picker. The AI copies the label, and the user checks it before anything is sent.
- **Licences.** Photos are published under CC BY-SA and data under the Database Contents License, and Open Food Facts asks apps to get users' agreement in their own terms. LeanStreak's terms now say so, and the form repeats it in one line.
- **Credit.** Account Settings links to Open Food Facts, as their licence asks of apps that reuse the data.
- **Thanking contributors.** Their docs ask apps to congratulate users "for their contribution to Open Food Facts and the common good", which is what the thank-you screen does.

## Set-up steps (for you)

The feature stays hidden until the app has an Open Food Facts account. Test on their **test server** first: it has its own accounts and its own database, so nothing real is touched.

1. **Create a test account.** Go to <https://world.openfoodfacts.net/cgi/user.pl>; if the browser asks for a login, use `off` / `off`. Choose a username such as `leanstreak-app`. It's a username, not an email: the app sends the username.
2. **Fill in `config/off_account.json`** in the project (it already exists, empty; git ignores it):
   ```json
   {
     "OFF_USER_ID": "leanstreak-app",
     "OFF_PASSWORD": "the password you chose",
     "OFF_HOST": "world.openfoodfacts.net"
   }
   ```
   Don't paste the password into chat. Put it straight into the file.
3. **Run the app** with the VS Code "YumSum (Android)" configuration, which passes that file. From a terminal: `flutter run --dart-define-from-file=config/off_account.json`.
4. **Try it with a real packet.** Barcode lookups still come from the real database, so pick something it doesn't know: a local Bulgarian product or a supermarket own brand. Contribute it, then open `https://world.openfoodfacts.net/product/<barcode>` (login `off` / `off`). Check the name, figures, language and both photos.
5. **When you're happy, create the real account** at <https://world.openfoodfacts.org> with the project email from Plan 2, not your personal Gmail.
6. **Fill in Open Food Facts' API usage form:** <https://docs.google.com/forms/d/e/1FAIpQLSdIE3D8qvjC_zRJw1W8OmuHhsWJ_NSckiiniAHlfaVwUZCziQ/viewform>. Their docs ask apps to do this "so that we can identify your usage and prevent potential bans."
7. **Optional but worth doing:** email `reuse@openfoodfacts.org`, or post in the `#api` channel on their Slack. Say you'd like the LeanStreak account listed as an app account, so each install's edits show as "leanstreak.<id>" rather than all under one username. Mention that the label is read by AI and checked by the user. They have no written rule on AI-read labels, and it's better they hear it from us.
8. **Switch to the real server:** set `OFF_HOST` to `world.openfoodfacts.org` with the real username and password. The release build needs the same `--dart-define-from-file` flag.

## Phone checklist

- [ ] Unknown barcode → invitation → Contribute → both camera steps → form prefilled
- [ ] The AI's figures match the packet; a missing figure stays blank (not guessed)
- [ ] Contribute → thank-you → Log it → amount sheet starts at the pack or serving size
- [ ] The product page on the test server has both photos, the right language and the figures
- [ ] Not now, closing the camera, and closing the form each leave the bar as before
- [ ] Offline: a clear message; Contribute works once the connection is back
- [ ] A Bulgarian product gets a Bulgarian name and `lang=bg`; a UK one gets `en`

## Risks

- **The shared password is inside the app.** Anyone determined can extract it. Open Food Facts documents this "global account" approach for apps, and the per-install ID limits the damage. If it's ever abused, change the password and ship an update. A server in between would need Cloud Functions, which needs the paid Firebase plan (see Plan 3).
- **Wrong figures.** The AI can misread a label. The check step, the "never guess" prompt, and Open Food Facts' volunteer moderation are the safeguards.
- **Rate limit.** Open Food Facts allows about 15 requests a minute per IP address. One contribution is 3 requests, so a person can't hit it. Many users behind the same mobile-network IP could, but that's unlikely at our size.
- **Search lag.** It's unknown how fast a new product reaches the Search foods results. A barcode scan finds it within seconds.

## Later

- Retry quietly in the background if the connection drops after the details were saved (Open Food Facts recommends queueing writes).
- An optional third photo of the ingredients list.
- "Products you've added" in Account Settings, linking to each product page.
- Show the product's Nutri-Score after contributing, since Open Food Facts calculates it once nutrition and category are in.
- Offer to fill in missing nutrition for products that exist but have no figures.

## Sources

- API introduction (auth, app account, `app_uuid`, test server, rate limits, usage form): <https://openfoodfacts.github.io/openfoodfacts-server/api/>
- Adding missing products (`add_` fields, comment, congratulating users): <https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/adding-missing-products/>
- Uploading photos: <https://openfoodfacts.github.io/openfoodfacts-server/api/tutorial-uploading-photo-to-a-product/>
- Server code for saving details: <https://github.com/openfoodfacts/openfoodfacts-server/blob/main/cgi/product_jqm2.pl>
- Server code for photo uploads: <https://github.com/openfoodfacts/openfoodfacts-server/blob/main/cgi/product_image_upload.pl>
- Official Flutter app (saves product details through `product_jqm2.pl`): <https://github.com/openfoodfacts/smooth-app>
- Terms of use (data from packaging, licences): <https://world.openfoodfacts.org/terms-of-use>
