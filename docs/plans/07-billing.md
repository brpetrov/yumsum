# Plan 7: Billing

*Written 2 November 2026. Status: steps A, B and C built (2–4 November); D, trying it on the phone, waits on your Play Console steps.*

## The short version

1. **YumSum Star is sold only in the Android app, through Google Play Billing** (the official `in_app_purchase` plugin), and checked by three small Cloud Functions of our own. No RevenueCat, so Google's 15% is the only fee. This replaces plan 03's RevenueCat recommendation; RevenueCat stays the fallback if the server side proves too much.
2. **Whether someone has YumSum Star lives in one document per account that only the server writes**, `entitlements/{uid}`. The app reads it through `plusProvider`, so it works on the website (and a future iPhone app) for anyone who subscribed on Android. You can also write that document yourself in the Firebase console (a **manual grant**), so every YumSum Star feature can be built and tested before billing works.
3. **The paywall is short and honest:** what you get, £3.99 a month or £25.99 a year (priced 4 November, `11-pricing.md`), 7 days free once per Google account, "Cancel any time in Google Play".
4. **Testers get YumSum Star by manual grant.** Play's test subscriptions renew every few minutes and stop after six renewals (about half an hour for monthly), so they can't cover a 14-day closed test. Testers try a purchase once; the grant covers the rest.
5. **Your steps start once Google approves your ID and the app exists:** payments profile (your address goes public), the subscription, a Pub/Sub topic, one deploy, access for the functions' service account, licence testers. Running costs stay inside Google's free allowances at this size.

## Decided (1–2 November 2026)

- **YumSum Star** (`plus` in code) contains: photo logging, 30 AI estimates a day instead of 10, the Adaptive formula (`08-adaptive-formula.md`), the AI weekly review (`09-ai-weekly-review.md`), full macros (`10-full-macros.md`), and later "What should I eat?" (`05-recipes.md`). The gates are in `06-yumsum-plus.md`; this plan gives them `plusProvider` to read and a paywall to open.
- **One subscription, `yumsum_plus`**, with two auto-renewing base plans, `monthly` (£3.99) and `annual` (£25.99), each with a 7-day free trial offer.
- **Bought only in the Android app.** The website's paywall says to subscribe in the Android app.
- **Google Play Billing with our own functions; no RevenueCat**, to keep third-party fees at zero.
- **When YumSum Star ends,** the Adaptive formula keeps its last value for 2 more weeks with a notice, then switches off (plan 08). The entitlement records when it ended. Play's grace period for failed payments keeps everything on meanwhile.
- **All of YumSum Star is in the first closed test**, with every tester on Play's licence-testing list so any purchase they make is a free test purchase.

## What Google currently requires

- **Play Billing Library 8 or newer.** Version 7's deadline for new apps and updates was 31 August 2026, extended to 1 November 2026, which passed yesterday. Version 8 is accepted until 31 August 2027 (extension to 1 November 2027), version 9 until 31 August 2028.
- **The plugin meets it.** `in_app_purchase` 3.3.1 uses `in_app_purchase_android` 0.5.x. Every 0.5 release ships Play Billing Library 8.0.0 or later, and the newest, 0.5.5 (October 2026), ships 9.1.0. Version 8 removed the purchase-history call, which doesn't matter here: restoring a subscription only needs the purchases that are active now.
- **Acknowledge every new subscription within 3 days,** or Google refunds it and takes it back. Renewals need no acknowledgement. Google recommends doing it on the server, which is what `verifyPurchase` does.
- **Free trials:** Play only returns the offers a person is eligible for, so the paywall shows "7 days free" only to someone who can have it. Trials can run from 3 days to 3 years.

## Who has YumSum Star: the entitlement document

**Where:** a top-level collection, `entitlements/{uid}`, not the profile and not under `users/{uid}`.

- Not the profile: `UserProfileRepository.createProfile` overwrites the whole `/users/{uid}` document with `set()`, and the profile rule in `firestore.rules` checks only a few fields, so a modified app could write `plus: true` into it.
- Not under `users/{uid}`: everything there belongs to the user, who can write it, and goes with Reset all data or Delete account. Keeping the server's documents outside makes the rule obvious and the console grant one level deep.

**The rules** (added to `firestore.rules`):

```
match /entitlements/{userId} {
  allow read: if isOwner(userId);
}
```

No write rule, so only the functions (which bypass the rules) can write it. `playPurchases`, below, gets no rule at all, so no app can read or write it.

**Fields:**

| Field | Type | Meaning |
|---|---|---|
| `active` | boolean | Play (or your grant) gives YumSum Star now |
| `expiresAt` | timestamp, optional | End of the paid period or the trial. Play pushes it on during a grace period. Left out on a manual grant with no end |
| `inTrial` | boolean | In the 7 free days |
| `productId` | text | `yumsum_plus` |
| `basePlan` | text | `monthly` or `annual` |
| `state` | text | `active`, `grace`, `cancelled`, `hold`, `paused`, `pending` or `expired`, for the Account Settings row |
| `endedAt` | timestamp, optional | When YumSum Star last switched off; cleared when it comes back. Plan 08 counts its 2 weeks from here |
| `source` | text | `play` or `manual` |
| `purchaseId` | text | The current Play purchase, as a SHA-256 of its token (Play only) |
| `updatedAt` | timestamp | Last write |

**Server bookkeeping:** `playPurchases/{purchaseId}` records which account each Play purchase belongs to (`uid`, `linkedAt`, `orderId`). The raw token isn't stored: every notification from Play carries it anyway.

### Manual grants

You can switch YumSum Star on for anyone by hand. Firebase console → Firestore → `entitlements` (Start collection the first time) → Add document:

- **Document ID:** the person's User UID, from Authentication → Users (search by email). The ID is the only link to `users/{uid}`; Firestore has no joins.
- **Fields:** `active` (boolean, true), `source` (string, `manual`), `email` (string, their email, so the list reads by name; Play writes it on purchases), and `expiresAt` (timestamp) if it should end. Leave the rest out.

It takes effect within seconds, on the phone and the website. Delete the document to take it away.

**Your own account** also gets `admin` (boolean, true): YumSum Star for good, no daily AI limit and no limit on changing past days. A debug build has **Debug tools** in the menu, which shows your User ID to copy and can pretend to be a free, subscribed, trial, ended or admin account on that phone only. (Built 2 November.)

**A live manual grant wins:** the functions never overwrite a `manual` document that is still active and unexpired; they only record the purchase in `playPurchases`. To try a real purchase on an account that has a grant, delete the grant first.

## In the app

**New packages:** `in_app_purchase` (3.3.1), `cloud_functions` (the 5.x line, which matches the app's `firebase_core` 3.15), and `crypto` (already in the build through another package; listed directly because the app now uses it).

**New files:**

| File | What it does |
|---|---|
| `lib/models/entitlement.dart` | `Entitlement` with `fromFirestore`, forgiving of missing fields (a hand-typed grant has only three) |
| `lib/repositories/entitlement_repository.dart` | Watches `entitlements/{uid}` |
| `lib/repositories/billing_repository.dart` | Calls `verifyPurchase` and `deleteBillingData` (region `europe-west10`) |
| `lib/services/billing_service.dart` | A thin wrapper round `InAppPurchase`: is Play available, load the plans, buy, restore, the purchase stream |
| `lib/providers/plus_provider.dart` | `entitlementProvider`, `plusProvider`, `billingServiceProvider`, `billingRepositoryProvider` and `plusPurchaseControllerProvider` |
| `lib/screens/plus/plus_screen.dart` | The paywall, and `showPlusPaywall(context)` for the gates to call |

### `plusProvider`

```dart
/// Whether the signed-in account has YumSum Star now. False while loading,
/// so a gate never flashes open.
final plusProvider = StreamProvider.autoDispose<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref
      .watch(entitlementRepositoryProvider)
      .watch(uid)
      .map((e) => e?.isPlusAt(DateTime.now()) ?? false);
});
```

- `isPlusAt` is `active` and (`expiresAt` missing or still ahead). Checking the date on the device as well means a missed notification from Play can't leave YumSum Star on for ever.
- Gates read it as `ref.watch(plusProvider).valueOrNull ?? false`. A subscriber sees the locked look for a moment at start-up, while the document loads.
- `entitlementProvider` (`StreamProvider.autoDispose<Entitlement?>`) gives the details (state, dates, plan) to Account Settings, the paywall and plan 08. `Entitlement.endedAt` returns the stored `endedAt`, or `expiresAt` once that has passed, which covers a missed notification and an expired manual grant.
- **In tests** (which never touch Firebase): `plusProvider.overrideWith((ref) => Stream.value(true))`, and `entitlementProvider.overrideWith(...)` with a ready-made `Entitlement` where the screen shows details. The paywall's tests also override `billingServiceProvider` and `billingRepositoryProvider` with fakes.

### Buying

1. **Load the plans:** `queryProductDetails({'yumsum_plus'})`. The plugin returns one entry per base plan and per offer the person is eligible for. An offer whose first pricing phase is free is the trial. Prices come from Play already formatted (`£3.99` in the UK, euros in Bulgaria), so nothing is hard-coded.
2. **Buy:** `buyNonConsumable` with a `GooglePlayPurchaseParam` for the chosen plan or trial offer, and `applicationUserName` set to the SHA-256 of the user's uid (64 characters, Play's limit). Play uses it to spot fraud, and Google asks for a hash rather than a raw account ID.
3. **Listen:** `plusPurchaseControllerProvider` listens to `purchaseStream` for the whole life of the app (Android only), started from `LeanStreakApp` beside `reminderSyncProvider`, as the plugin asks.
   - `purchased` or `restored`: show "Checking with Google Play", send the token (`verificationData.serverVerificationData`) to `verifyPurchase`, then call `completePurchase`. The server has already acknowledged by then; the app ignores the plugin's answer, because I couldn't confirm what Play says to a second acknowledgement.
   - `pending`: "Google Play is waiting for your payment. YumSum Star switches on once it goes through." Nothing is granted. Google says pending payments apply to prepaid plans, so with auto-renewing plans this should be rare.
   - `canceled` (the person closed Play's sheet): nothing.
   - `error`: the message below. "Already owned" runs a restore instead.
4. **Show the result:** the entitlement document changes, `plusProvider` turns true, and the paywall closes with "YumSum Star is on." (with a trial: "YumSum Star is on. Your free week ends on 9 November.").

### Restoring and catching up

- **Restore purchase** on the paywall calls `restorePurchases()`, and each active purchase it finds goes to `verifyPurchase`.
- **At start-up** on Android, signed in and without YumSum Star, the app restores quietly once. This picks up a purchase whose check never finished (the app was closed straight after paying, or the phone lost signal), within Play's 3 days. Errors stay silent here.
- **One subscription, one account:** a purchase made in the app belongs to the account that bought it, whose SHA-256 Play keeps as its obfuscated account ID; any other account that checks it is told it's linked to another account, and nothing is linked (5 November 2026). A purchase with no ID (bought outside the app) belongs to the first YumSum account that checks it. Restoring it on another account says so. If the first account no longer exists, the purchase moves to the new one.

### The paywall

*Built 2 November as a one-screen promo* (`lib/screens/plus/plus_screen.dart`): the smiling bowl with its star, "YumSum Star" and "Shine bright with these smart perks.", the five features (Smart Snap, Triple the AI estimates, Adaptive Formula, AI Assisted Coach, Detailed Macros) with a line each, Yearly (the yearly price as the big number, with a "Save N%" badge and "£X a month" worked out from Play's prices: "Save 46%" and "£2.17 a month" at £25.99 and £3.99) and Monthly tiles, the "Start 7 days free" button with the terms under it, and Restore purchase, Terms and Privacy. Until billing exists the prices are written in and the buttons show "Coming soon"; step C below loads Play's prices and starts the purchase. A screen under 800 px tall gets a smaller bowl and tighter rows, so it still fits without scrolling. The plan as first written follows.

Route `/plus` (`AppRoutes.plus`, `PlusScreen`), pushed on top of the current page, so Back returns to it. Copy follows CLAUDE.md: British English, sentence case, no "Please", no exclamation marks.

**On Android:**

- **Heading:** "YumSum Star". Under it: "Logging stays free. YumSum Star adds:"
- **One line each, with an icon:**
  - "Log a meal from a photo of your plate"
  - "30 AI estimates a day, instead of 10"
  - "Adaptive Formula: Learns your real burn and tunes your target." (Built on the YumSum Star page; plan 08 has the rules.)
  - "A weekly review in History, written by the AI"
  - "Carbs and fat too, not just calories and protein" (plan 10 settles the wording)
  - "What should I eat?" is added only once it exists.
- **Two plans:** "Yearly: £25.99 a year" (with the saving in small type) and "Monthly: £3.99 a month". Play's subscriptions policy counts an annual plan shown mainly as a monthly cost as misleading, so the yearly price is the big number.
- **Button:** "Start 7 days free" when the trial is offered, otherwise "Subscribe".
- **Under the button, in readable type:** "Free until 9 November, then £25.99 a year. Renews every year until you cancel. Cancel any time in Google Play; cancel before 9 November and you pay nothing." Without a trial: "£3.99 a month. Renews every month until you cancel. Cancel any time in Google Play."
- **At the bottom:** "Restore purchase", "Terms of use", "Privacy policy" (`LegalLinks`).
- **Already on YumSum Star:** the status from Account Settings, below, instead of the plans.

**Messages:**

| When | Text |
|---|---|
| Play can't be reached | "Could not reach Google Play. Check your connection and try again." |
| The check fails | "Could not confirm your purchase. Try Restore purchase in a few minutes. If it still fails, Google Play refunds you automatically within 3 days." |
| The purchase is on another account | "This Google Play subscription is linked to another YumSum account. Sign in with that account to use it." |
| Restore finds nothing | "No YumSum Star subscription found on this Google account." |

**On the website:** the same heading and lines, then "Subscribe in the YumSum app for Android. YumSum Star then works here too, when you sign in with the same account." with a Google Play link once the app is public. No prices, because Play's local prices aren't available there.

**On an iPhone build:** "YumSum Star can't be bought on iPhone yet." Apple's rules don't let a UK app point people to another way to pay, so the iPhone version doesn't mention Android.

**The UK's new subscription rules** (Digital Markets, Competition and Consumers Act; draft regulations laid on 19 October 2026, start expected January 2027) ask for the key facts together, just before purchase: the price, how often it's charged, when the trial ends and the first charge comes, and how to cancel. The text under the button does that, and Play's own purchase sheet is the final "Subscribe" step. Cancelling is in Google Play, online, in a few taps. Reminder notices are the open question; see Risks.

### Where it opens from

Every entry point calls `showPlusPaywall(context)`. Each belongs to its own plan:

- **The photo button** on the quick-log bar, for free users, with a small "+" mark (plan 06).
- **Plan Settings' Adaptive formula switch** (plan 08).
- **The locked weekly review line** in History (plan 09).
- **Macros** (plan 10).
- **Account Settings' "YumSum Star" row**, below.

Also, as you decided on 2 November: a **YumSum Star row in the menu** for everyone, with the orange badge, and a **YumSum Star card on Today** for people without it, which its cross hides for two weeks. No pop-up at start. (Built.)

### Account Settings

A new section, `YUMSUM+`, above Help & legal in `account_settings_screen.dart`: one row, "YumSum Star", whose second line follows the state:

| State | Second line | Tap |
|---|---|---|
| Free | "Photo logging, 30 AI estimates a day and more" | The paywall |
| Trial | "Free trial until 9 November" | Manage in Google Play |
| Active | "Renews on 3 December" | Manage in Google Play |
| Cancelled | "Ends on 3 December" | Manage in Google Play |
| Grace | "Payment problem. Fix it in Google Play to keep YumSum Star." | Manage in Google Play |
| Hold | "Off until the payment problem is fixed in Google Play" | Manage in Google Play |
| Manual | "On until 16 November", or "On" | Nothing |

Manage in Google Play opens `https://play.google.com/store/account/subscriptions?sku=yumsum_plus&package=com.bpetrov.yumsum`, which also works from the website.

**Delete account:** while a Play subscription is renewing (`source` play, state not cancelled or expired), the delete dialog adds one line: "Deleting your account doesn't cancel YumSum Star. Cancel it in Google Play first, or it keeps renewing." Play's account-deletion rules also ask that the deletion web page (plan 04) says to cancel subscriptions first.

**Deleting the entitlement:** the app can't delete a server-only document, so `AccountController.deleteAccount` calls `deleteBillingData` straight after re-authentication, before `AccountRepository.deleteAccountData`. If that call fails, nothing has been deleted yet and the usual "Could not delete your account." shows. Reset all data leaves YumSum Star alone.

## The server: Cloud Functions

A new `functions/` folder: TypeScript, 2nd gen, region `europe-west10` (Berlin, beside the Firestore database), Node.js 22 runtime, with `firebase-functions`, `firebase-admin` and `@googleapis/androidpublisher`. `firebase.json` gets a `functions` section. Three functions:

- `src/index.ts`: the three functions, kept thin.
- `src/entitlement.ts`: `entitlementFrom(subscription, previous, now)`, a pure function from Play's answer to the document's fields, which is where the tests go.
- `src/play.ts`: the two Play Developer API calls.

They run as the project's default service account (`296684319013-compute@developer.gserviceaccount.com`), which you invite into Play Console. That means no key file to keep safe or rotate. A dedicated account would be tidier, but needs extra Cloud permissions set by hand; not worth it for one app.

### `verifyPurchase` (callable)

App Check enforced (`enforceAppCheck: true`) and signed-in only. Takes `{purchaseToken}`.

1. Read the purchase with `purchases.subscriptionsv2.get` (package `com.bpetrov.yumsum`). Refuse it unless the line item's product is `yumsum_plus`, and with "already linked" when its `obfuscatedExternalAccountId` is set and isn't the SHA-256 of the caller's uid (`boughtFor`).
2. Link it in a transaction on `playPurchases/{sha256(token)}`. If it's already linked to another account that still exists, refuse with "already linked". A link to a deleted account moves to this one.
3. Write `entitlements/{uid}` from `entitlementFrom()` (unless a live manual grant is there), with this purchase as `purchaseId`.
4. If Play says `ACKNOWLEDGEMENT_STATE_PENDING` and the state is active or in grace, acknowledge with `purchases.subscriptions.acknowledge`. An "already acknowledged" answer is fine.
5. Return whether YumSum Star is on, so the paywall can say so.

**From Play's state to the document:**

| `subscriptionState` | `active` | `state` |
|---|---|---|
| `SUBSCRIPTION_STATE_ACTIVE` | true | `active` |
| `SUBSCRIPTION_STATE_IN_GRACE_PERIOD` | true | `grace` |
| `SUBSCRIPTION_STATE_CANCELED` | true until `expiryTime` | `cancelled` |
| `SUBSCRIPTION_STATE_ON_HOLD` | false | `hold` |
| `SUBSCRIPTION_STATE_PAUSED` | false | `paused` |
| `SUBSCRIPTION_STATE_EXPIRED` (also after a refund or revoke) | false | `expired` |
| `SUBSCRIPTION_STATE_PENDING` | false | `pending` |
| `SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED` | false | `expired` |

`expiresAt` is the line item's `expiryTime`, `basePlan` its `offerDetails.basePlanId`, and `inTrial` whether its `offerPhase` is the free trial. `endedAt` is set to now when `active` goes from true to false, and cleared when it goes back to true.

### `playNotifications` (Pub/Sub)

Triggered by Play's Real-time Developer Notifications on the topic `play-billing`, with retries on. Google's advice is not to trust the notification's type but to read the purchase again, so the function is the same for every type:

1. Decode the message. Ignore any other package. Log and stop on a `testNotification` (Play Console's "Send test message").
2. Take the token from `subscriptionNotification` (renewed, cancelled, in grace, on hold, recovered, restarted, expired, revoked and the rest), or from `voidedPurchaseNotification` when `productType` is 1 (a refunded subscription).
3. Find the account in `playPurchases`. A token it doesn't know is followed back through `linkedPurchaseToken` (a plan change) or `outOfAppPurchaseContext.expiredPurchaseToken` (resubscribing in the Play Store after expiry). If it's still unknown, log and stop: the app links it on its next start.
4. Read the purchase with `subscriptionsv2.get`, write the entitlement (only if this purchase is the account's current `purchaseId` or newer, so a late "expired" for a replaced purchase doesn't switch YumSum Star off), and acknowledge if Play says it's still pending.

Anything permanent (an unknown token, another app) returns normally so Pub/Sub doesn't retry it for days. Chargeback reviews (`pendingRefundReviewNotification`, which Google asks you to answer within 24 hours) are only logged for now; at this size they should be rare.

### `deleteBillingData` (callable)

App Check enforced, signed-in only. Deletes `entitlements/{uid}` and the caller's `playPurchases`. It doesn't cancel the Play subscription.

### What it costs

| Item | At YumSum's size |
|---|---|
| Cloud Functions | About 3 calls per subscriber a month (the check, a renewal, the odd change). 1,000 subscribers is about 3,000 calls, against 2 million free a month. |
| Pub/Sub | About 2 KB per notification (Google's figure), well inside its free allowance |
| Container images (Artifact Registry) | A few pence a month at most. Say yes when the first deploy offers a cleanup policy (it deletes old images after a day). |
| Google Play Developer API | No charge |
| Google Play's fee | 15%, as a 10% service fee plus a 5% billing fee, taken after VAT (plan 11). £3.99 a month leaves about £2.83; £25.99 a year about £18.41 |

## Protection

- **The entitlement can't be faked from the app:** only the functions write it, and the rules let a person read only their own.
- **App Check** with Play Integrity still stops modified Android apps from calling the AI, and now also guards the three callables.
- **The daily allowance is still counted on the device** (`lib/repositories/ai_usage_repository.dart`), now 10 or 30 (plan 06). On Android, App Check covers that gap. On the website, someone technical could change the limit in their browser and still pass App Check, because it's the genuine page; the 10-a-minute per-user limit and the £3 spend cap still bound them.
- **Server-side counting** (AI calls going through a callable function that counts them) is a later phase, only if the usage logs or spend alerts show abuse.

## Testers and the closed test

- **Licence testers pay nothing:** they see test cards in Play's purchase sheet ("Test card, always approves", "always declines", and slow cards that approve or decline after a few minutes). Anyone in a test track who isn't a licence tester pays real money, so every closed tester goes on the list.
- **Test subscriptions run fast and stop after six renewals** (Google's figures):

| Real | In a test |
|---|---|
| 7-day free trial | 3 minutes |
| 1 month | 5 minutes |
| 1 year | 30 minutes |
| Grace period | 5 minutes |
| Account hold | 10 minutes |
| Not acknowledged | Refunded after 3 minutes (5 in Google's table) |
| Renewals | 6, then it ends (about 33 minutes for monthly with the trial, about 3 hours for yearly) |

- **So for the 14 days, testers get a manual grant** (`expiresAt` a week after the test should end). Ask two or three of them to try a purchase first, before you add their grant.
- **Don't hold the closed test back for billing.** The 14-day clock is the longest wait (plan 04). If the app is ready before the subscription is, start the test with manual grants and add the paywall in an update.
- **Licence testers can buy from a debug build** run from VS Code, as long as the products exist. Google's Play Billing Lab app can repeat the free trial and jump a test subscription into grace or hold.

## Steps for you

**Now (no Play Console needed)**

1. **Decide about your address.** The payments profile shows your full address on the store listing (plan 03). PO boxes aren't accepted.
2. **Once I've built step A below:** deploy the rules (`firebase deploy --only firestore:rules`), then give yourself a manual grant to try the YumSum Star features.

**Once Google approves your ID and you've created the app (plan 04)**

3. **Payments profile:** Play Console → Payments profile → Create payments profile.
4. **Upload a build with billing** to Internal testing (Test and release → Testing → Internal testing), with just you as a tester. I'll build it; the plugin adds the billing permission. Play only lets you create subscriptions once a build with billing is uploaded.
5. **Create the subscription:** Monetize with Play → Products → Subscriptions → Create subscription.
   - Product ID `yumsum_plus` (it can never be changed or reused), name "YumSum Star", and its benefits (photo logging, 30 AI estimates a day, Adaptive formula, AI weekly review).
   - Base plan `monthly`: auto-renewing, 1 month, £3.99. Base plan `annual`: auto-renewing, 1 year, £25.99. Let Play convert the other countries' prices, then set Bulgaria's to €3.99 and €25.99 (plan 11).
   - On each base plan: **grace period 7 days**, account hold left at Play's automatic length (60 days minus the grace period), resubscribe on.
   - On each base plan, Add offer: `monthly-trial` and `annual-trial`, eligibility **New customer acquisition → Never had this subscription**, one phase: **Free trial, 7 days**.
   - Activate the base plans and offers.
6. **Pub/Sub topic:** Google Cloud console (project `lean-streak-project`) → Pub/Sub → Create topic, ID `play-billing`. Open its Permissions, Add principal `google-play-developer-notifications@system.gserviceaccount.com`, role **Pub/Sub Publisher**, Save.
7. **Turn on the Play API:** Google Cloud console → APIs & Services → Enable APIs → **Google Play Android Developer API** → Enable.
8. **Deploy:** `firebase deploy --only functions,firestore:rules`. The first deploy switches on a few Google Cloud services itself (say yes) and offers the image cleanup policy (say yes).
9. **Give the functions access to Play:** Play Console → Users and permissions → Invite new users → email `296684319013-compute@developer.gserviceaccount.com` → App permissions → YumSum → tick **View financial data, orders, and cancellation survey responses** and **Manage orders and subscriptions** → Invite user. Google doesn't say how quickly this takes effect; if the first checks fail with a permission error, wait a few hours before changing anything.
10. **Real-time notifications:** Monetize with Play → Monetization setup → Real-time developer notifications → Enable, topic `projects/lean-streak-project/topics/play-billing`, **Send test message**, then check Firebase console → Functions → `playNotifications` → Logs for the test. Choose "Get notifications for subscriptions and all voided purchases" and Save.
11. **Licence testers:** Play Console → Settings → License testing → add your Gmail and every tester's, Save.
12. **Try it yourself** with the phone checklist below.
13. **Closed test:** the same build (or newer) to Closed testing with the 12 testers. Once each has signed up, add their manual grant with `expiresAt` 3 weeks ahead, so it ends by itself (plan 15, D).
14. **Legal pages:** I'll draft the changes; you deploy hosting (`tools/build_hosting.ps1`, then `firebase deploy --only hosting:app`).
    - `tools/hosting/privacy.html`: a "Subscriptions" item under What we collect (Google Play takes the payment and we never see card details; we keep the subscription's status, plan, trial, renewal and end dates and Play's purchase reference, linked to your account, to switch YumSum Star on wherever you sign in); Google Play under Who else sees it; deleted with the account.
    - `tools/hosting/terms.html`: a YumSum Star section (what's included, prices shown before you buy, the trial once per Google account, automatic renewal until cancelled in Google Play, YumSum Star stays until the end of the paid period, refunds through Google Play and your legal rights, deleting the account doesn't cancel it). "The service" currently says the app is free of charge; it becomes "YumSum is free to use; YumSum Star is an optional paid subscription."
15. **Data safety form:** add Financial info → **Purchase history** (collected, not shared, for app functionality and account management). Google's own pages don't say whether Play's billing data needs declaring; billing services advise declaring it, and over-declaring is the safe side.
16. **Store listing:** mention YumSum Star as optional in the full description. The "In-app purchases" label appears by itself.

## Build order (for me)

- **A. The entitlement** (needs nothing from Play): model, repository, `entitlementProvider`, `plusProvider`, the rule, the Account Settings row, tests. This unblocks plans 06, 08, 09 and 10, which can all be built and tried with manual grants.
- **B. The functions:** `verifyPurchase`, `playNotifications`, `deleteBillingData`, the mapping tests, `firebase.json`; the delete-account call and dialog line.
- **C. The paywall:** `BillingService`, the purchase controller, restore at start-up, the paywall, the legal page drafts.
- **D. On the phone,** with your steps 3–11 done.

Once built, CLAUDE.md gets the new collections, the functions and the deploy command.

### As built (4 November)

- **Functions** (`functions/`): `firebase-functions` 7, `firebase-admin` 14, `@googleapis/androidpublisher`, Node 22, all in `europe-west10` with at most 10 instances each as a cost cap. `npm test` runs 39 tests of `entitlementFrom` on Google's own example answers. `firebase.json`'s predeploy builds them, from PowerShell too.
- **Where it differs from the plan above:**
  - A notification writes the record only for the stored `purchaseId`, when there's none yet, or for a purchase that replaced it (through `linkedPurchaseToken` or `expiredPurchaseToken`). A purchase found that way gets its own `playPurchases` link, because Play drops the replaced token once it's acknowledged.
  - `endedAt` is the old `expiresAt` when that had already passed (a late notification), otherwise now.
  - `playPurchases.orderId` is the line item's `latestSuccessfulOrderId`; the top-level `latestOrderId` is gone from the API.
  - After a failed acknowledge, the purchase is read again and it only counts as failed if Play still says pending. `verifyPurchase` logs it and still answers; `playNotifications` throws so Pub/Sub retries.
  - Play's 400, 404 and 410 count as an unknown token. Play errors are logged without their request URL, which contains the token.
- **The app:** Play Billing Library 8 (through `in_app_purchase_android` 0.5.0). `verifyPurchase`'s `{plus}` answer isn't used: the record changing is what switches YumSum Star on. Deleting an account calls `deleteBillingData` only when the account has a record. Since 5 November 2026 every deletion ends with the `deleteAccount` function (the counters and the login), so all accounts depend on the functions for that.

## Testing

**Automated (no Firebase, no Play):**

- `test/entitlement_test.dart`: a hand-typed manual grant, `isPlusAt` before and after `expiresAt`, `endedAt` falling back to `expiresAt`.
- `test/plus_purchase_controller_test.dart`: a fake `BillingService` whose purchase stream is a `StreamController<List<PurchaseDetails>>`, and a fake `BillingRepository`. Purchased → verified, then completed; pending → nothing granted; check fails → message and no completion; restored → verified; already owned → restore; Play unavailable → the message.
- `test/plus_screen_test.dart`: trial and no-trial wording, yearly price as the big number, the web text, an existing subscriber sees the status, Restore purchase.
- `test/account_settings_test.dart`: the row in each state; the delete dialog's extra line only while a Play subscription renews.
- `functions/test/`: `entitlementFrom()` against Play's own example answers for every state, with Node's built-in test runner (`npm test`). No emulator: the handlers stay thin, and the phone checklist covers them end to end.

**On the phone, with licence testers** (Firestore console and the functions' logs open):

- [ ] Paywall: both plans with "7 days free" and £ prices
- [ ] Buy monthly with "Test card, always approves": "Checking with Google Play", then on. `entitlements/{uid}` shows `active`, `inTrial`, `monthly`. No refund email 5 minutes later (acknowledged)
- [ ] About 3 minutes later the trial ends: a renewal arrives, `inTrial` false
- [ ] The website, same account: YumSum Star features unlocked
- [ ] Manage in Google Play → cancel: "Ends on …", still on; after expiry off, `endedAt` set, plan 08's notice shows
- [ ] Reinstall, sign in: on again (start-up restore); Restore purchase also works
- [ ] A second YumSum account on the same phone, Restore purchase: "linked to another YumSum account"
- [ ] Switch Play's payment to "always declines": grace (still on, Payment problem row), then hold (off), then back to "always approves": on again
- [ ] A slow card that declines: never switches on. One that approves: on after a few minutes
- [ ] Close the app the moment Play says paid; open it again: switches on by itself
- [ ] Play Console → Order management → refund and revoke a test order: off shortly after
- [ ] Delete account while subscribed: the dialog warns; afterwards no `entitlements` or `playPurchases` documents for that uid, and the subscription is still in Play
- [ ] Manual grant: on within seconds; delete it: off
- [ ] Airplane mode on the paywall: "Could not reach Google Play…"
- [ ] Buy yearly with Play Billing Lab's repeat-trial option: `annual`, yearly wording everywhere

## Risks

- **More server work than RevenueCat.** About 200 lines of TypeScript plus Cloud set-up. If it proves too much, RevenueCat is the fallback (free until $2,500 a month of revenue, then 1%, plan 03); the entitlement document and `plusProvider` would stay, fed by RevenueCat's webhook instead.
- **A missed notification leaves the document stale.** The expiry check on the device ends YumSum Star on time anyway, and the start-up restore puts it back on for someone Play says is still subscribed.
- **The UK subscription rules aren't final.** The draft regulations still need Parliament's approval, and I couldn't find whether Google (selling through Play) or you count as the trader. If reminder notices before a trial ends or a yearly renewal fall to you, they must be in writing that can be kept (email counts; an in-app message that can't be kept doesn't), and the app has no way to send email today. Recheck in December, when the guidance should be out.
- **Your address goes public** with the payments profile (plan 03).
- **Plan 06 is being written alongside this one.** If it reads `plusProvider` differently, one of the two changes before building.
- **The functions' account is broad.** The default service account can also do other things in the project; acceptable while it only runs our three functions.
- **First call after a quiet spell is slow:** a few seconds while a function starts, covered by "Checking with Google Play".

## Later

- **iPhone (App Store):** the same plugin uses StoreKit 2; a `verifyAppStorePurchase` function and App Store Server Notifications feed the same document with `source: appstore`.
- **Server-side AI counting,** only if abuse shows.
- **A lifetime option** (a one-off product with a fair-use AI cap, plan 03).
- **Switching between monthly and yearly in the app** (for now, in Google Play).
- **Stopping renewal automatically when an account is deleted:** the API can (`subscriptionsv2.cancel`); for now the dialog says to do it.

## Checklist

**Me**
- [x] A: entitlement, `plusProvider`, rule, Account Settings row, tests
- [x] B: the three functions, mapping tests, delete-account call and dialog line (4 November)
- [x] C: paywall, purchase controller, restore, legal page drafts (4 November)
- [ ] D: phone checklist with you
- [ ] CLAUDE.md updated

**You**
- [ ] Decide about the public address
- [ ] Deploy the rules; give yourself a manual grant
- [ ] Payments profile
- [ ] Billing build to Internal testing
- [ ] Subscription `yumsum_plus`: two base plans, grace 7 days, two trial offers, activated
- [ ] Pub/Sub topic `play-billing` with Play's publisher account
- [ ] Google Play Android Developer API enabled
- [ ] `firebase deploy --only functions,firestore:rules`
- [ ] Service account invited in Play Console with the two permissions
- [ ] Real-time notifications on, test message seen in the logs
- [ ] Licence testers added
- [ ] Closed test; manual grants for the testers
- [ ] Privacy policy and terms deployed
- [ ] Data safety: Purchase history
- [ ] Store listing mentions YumSum Star

## Sources

- Play Billing Library deadlines: <https://developer.android.com/google/play/billing/deprecation-faq>
- Play Billing Library release notes (8.0 removals; 9.0 and 9.1 dates): <https://developer.android.com/google/play/billing/release-notes>
- `in_app_purchase` changelog: <https://pub.dev/packages/in_app_purchase/changelog>
- `in_app_purchase_android` changelog (Billing Library versions): <https://pub.dev/packages/in_app_purchase_android/changelog>
- Integrating billing (eligible offers, detecting purchases, pending): <https://developer.android.com/google/play/billing/integrate>
- Obfuscated account ID (hash, 64 characters): <https://developer.android.com/reference/com/android/billingclient/api/BillingFlowParams.Builder>
- Subscription lifecycle (3-day acknowledgement, grace, hold, cancel, revoke, resubscribe): <https://developer.android.com/google/play/billing/lifecycle/subscriptions>
- Subscriptions (subscription centre link, pending only for prepaid): <https://developer.android.com/google/play/billing/subscriptions>
- `purchases.subscriptionsv2` fields and states: <https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2>
- `purchases.subscriptions.acknowledge`: <https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/acknowledge>
- Real-time notifications set-up: <https://developer.android.com/google/play/billing/getting-ready>
- Real-time notification types: <https://developer.android.com/google/play/billing/rtdn-reference>
- Service account access (no project linking; invite in Users and permissions): <https://developers.google.com/android-publisher/getting_started>
- Testing (licence testers, test cards, renewal times, Play Billing Lab): <https://developer.android.com/google/play/billing/test>
- Licence testing in Play Console: <https://support.google.com/googleplay/android-developer/answer/6062777>
- Creating subscriptions (IDs, account hold, resubscribe, trial offers): <https://support.google.com/googleplay/android-developer/answer/140504>
- Base plans and offers (eligibility, trial lengths): <https://support.google.com/googleplay/android-developer/answer/12154973>
- Play subscriptions policy (what the offer must show): <https://support.google.com/googleplay/android-developer/answer/9900533>
- Play account-deletion requirements (say to cancel subscriptions first): <https://support.google.com/googleplay/android-developer/answer/13327111>
- Grace period lengths (third party; I couldn't confirm Google's current options or default): <https://www.revenuecat.com/blog/engineering/google-play-lifecycle>
- Firebase pricing (Cloud Functions free allowance): <https://firebase.google.com/pricing>
- Pub/Sub-triggered functions: <https://firebase.google.com/docs/functions/pubsub-events>
- Managing functions (image cleanup policy): <https://firebase.google.com/docs/functions/manage-functions>
- App Check on callable functions: <https://firebase.google.com/docs/app-check/cloud-functions>
- UK subscription rules: <https://www.tlt.com/insights-and-events/insight/dmcc-act-subscription-contracts-regime-brought-forward-by-the-pm-what-do-businesses-need-to-know>, <https://www.lewissilkin.com/insights/2026/09/15/key-takeaways-the-subscription-shake-up-are-you-ready-for-january-2027-102o14n> and <https://www.alston.com/en/insights/publications/2026/10/uk-subscription-rules-dmcca>
- Data safety and purchase history (a billing service's advice, not Google's): <https://www.revenuecat.com/docs/google-plays-data-safety>
- RevenueCat pricing: <https://www.revenuecat.com/pricing>
