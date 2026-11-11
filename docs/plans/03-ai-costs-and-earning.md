# Plan 3: AI costs, and earning from the app fairly

*Written 23 October 2026 from Google's pricing, billing and terms pages and Play's fee pages, all checked that day. AI prices and quotas change often, so recheck before deciding.*

## The short version

1. **The free AI tier can't be used for the public launch.** Google's Gemini API terms say: *"You may use only Paid Services when making API Clients available to users in the European Economic Area, Switzerland, or the United Kingdom."* LeanStreak's users are in the UK and Bulgaria, so the Firebase project has to move to the paid **Blaze** plan before launch. That's a legal requirement, not just a capacity problem.
2. **The paid tier is cheap per person.** It's about **£0.07 a month for someone who uses AI three times a day, every day**, and most entries (typed numbers, barcodes, chips) use no AI at all.
3. **Costs grow with users, so the app has to earn something once it's popular.** The fair way: **logging stays free forever, and only the AI, which costs real money each time, gets a free daily allowance with a cheap YumSum Star for more.** No banner ads.

## Decided (24 October 2026)

- **No ads**, not even in the free version.
- **10 free AI estimates a day** (typed, voice and photo together), down from 20.
- **Paying for more comes later, not at launch.** The options to choose from then: YumSum Star (a subscription), a "protein bar" one-off top-up of AI estimates, or a protein-bar tip. Inside the Play app any of these must go through Google Play's billing. A Buy Me a Coffee link is fine on the website, but Play's payments policy doesn't allow one in the app.
- Contributing to Open Food Facts can wait until after launch. It stays hidden until the app has an account.

## Where things stood on 23 October

- The Firebase project is on the free **Spark** plan, and AI goes through Firebase AI Logic on Gemini's free tier.
- Google no longer publishes free-tier limits. One measurement in September 2026 found **15 requests a minute and 500 a day for the whole app**, shared by every user, resetting at about 08:00 UK time. That's roughly 80–170 AI users a day, and a busy lunchtime could hit the per-minute cap.
- On the free tier, Google may use what's sent to improve its products. That doesn't apply to UK and EU users, but it's another reason to go paid.
- **Gaps in the 20-a-day AI limit:**
  - Voice notes and the automatic protein estimate don't count towards it.
  - The counter lives in a Firestore document the user is allowed to write, so a modified app could reset it.
  - The only real ceiling today is Firebase's default of **100 AI requests per minute per user**. That's very high.
- When the AI is busy for a minute (HTTP 429), the app says "limit for today", which is wrong. A paused paid account (HTTP 402) shows a vague error.

## What the AI costs on the paid tier

**Gemini 3.5 Flash-Lite**, the model the app uses: $0.30 per million input tokens (text, images and audio alike) and $2.50 per million output tokens, with the AI's "thinking" counted as output. The answer it writes back costs about 80% of each call.

| One call | Roughly |
|---|---|
| Typed estimate | $0.00075 (about 0.06p) |
| 10-second voice note | $0.00096 |
| Meal photo | $0.0011 |
| Label read for a contribution (2 photos) | $0.0013 |

**Per month, if every user is active every single day** (an overestimate), at a typical mix of 60% typed, 20% voice and 20% photo:

| Daily users | 3 AI calls a day | 6 AI calls a day |
|---|---|---|
| 100 | $7.70 (about £7 with VAT) | $15 (about £14) |
| 1,000 | $77 (about £69) | $154 (about £138) |
| 10,000 | $770 (about £690) | $1,540 (about £1,380) |

Google adds **20% UK VAT**, and you pay in pounds. These figures assume about 400 input and 250 output tokens per call. *Measured 5 November 2026 (plan 11, B2):* a typed estimate is about 360 in and 145 out, voice 640 and 160, a photo 1,480 and 220, with no thinking; so about 0.04p, 0.055p and 0.09p a call with VAT. The table above overstates by about a third.

**Paid-tier safety rails Google gives you:**
- **Prepaid credit.** You top up from $5. At $0, AI stops for everyone with an HTTP 402 until you top up again; auto-reload is optional.
- **A monthly cap per billing account:** $250 at first (Tier 1), $2,000 after you've paid $100 (Tier 2). There's also a $10 per 10-minute spend limit at first, which stops a runaway bug cold.
- **A Firebase spend-cap budget for AI Logic.** It pauses AI for the rest of the month when reached, so you can never be surprised by a big bill.

## Step A: before launch (protect yourself)

1. **Move the project to Blaze**, link a billing account, and **prepay $10–$20**. The rest of Firebase still includes the same free allowances as Spark: Firestore reads and writes, Auth, Hosting.
2. **Set a spend-cap budget** on Firebase AI Logic, for example **£20 a month**, with email alerts at 50% and 90%. Firebase console → Usage and billing → Budgets.
3. **Lower the per-user rate limit** from 100 to about **10 requests a minute**. Google Cloud console → Quotas & System Limits → "Generate content requests per user".
4. **Count every AI call.** *Done 24 October:* voice notes now count, and the mic says so before recording once the allowance is used up. The automatic protein estimate on saving a meal still doesn't count: it costs about a fifth of an estimate and comes with saving, so counting it would use up the allowance without the user asking for AI.

   *Not done: tightening the Firestore rules on the counter.* A rule can't make it tamper-proof. Deleting the day's document resets it, and deleting an account needs that delete to work. Changing the phone's date also starts a fresh day. The counter is a fair limit for ordinary use. The real protection is App Check (only the genuine app can call the AI), the per-user rate limit and the spend cap. A tamper-proof allowance needs a small server function, which comes with YumSum Star.

   *Done 5 November 2026:* the server counts it now (see "AI through our own functions" below).
5. **Clearer messages.** *Done 24 October:*
   - "The AI is busy right now. Try again in a minute." for quota and 429 errors, which on the paid tier are per-minute limits. They aren't retried automatically, because a per-user minute limit doesn't clear in a few seconds.
   - "Today's 10 AI estimates are used up…" only for the daily allowance
   - "AI estimates are paused for now…" for an empty prepaid balance (402) or a billing problem
6. **Measure real usage.** *Started 24 October:* the app now prints Gemini's token counts for every call in the debug log ("AI tokens: in …, out …, thinking …"). I'll read them off during the next phone test and update the figures above.
7. **Cut the cost per call.** *Done 24 October:* the unused "note" is gone from the typed and photo answers. *Waiting for the measurements:* updating the AI library (2.3 → current) so photos can be sent at **low resolution**, which uses about 75% fewer image tokens. Worth doing only if photos turn out to be a real share of the cost.

   There's an alternative model: Gemini 3.1 Flash-Lite is about a third cheaper, but it's retired in May 2027. I'd stay on 3.5 unless costs bite.
8. **Show people their allowance.** *Done 24 October:* "3 AI estimates left today" appears above the bar, in muted text, once half is used and the meal has no calories yet.

With all of that, **100 daily users cost about £5–£7 a month**, and nothing can run away from you.

## AI through our own functions (5 November 2026)

The app no longer calls Gemini itself. Anyone could copy the website's App Check token and call Firebase AI Logic with any prompt, with no account, so the allowance and the YumSum Star gates were only checked on the phone. Now two Cloud Functions (`functions/src/ai.ts`) hold the prompts, count the allowance before each call and check YumSum Star.

They use the Gemini Developer API with a key kept as a secret, not Vertex AI. The $5 prepaid credit only covers the Gemini API; Vertex AI is billed on the normal Cloud cycle, so nothing would cap what AI costs.

Set-up, in this order:
1. **A key for the functions.** In <https://aistudio.google.com/apikey>, create a key in `lean-streak-project`, called "YumSum functions". In Google Cloud console → APIs & Services → Credentials, restrict it to the **Generative Language API**. It never goes in the app.
2. **Keep it as a secret:** run `firebase functions:secrets:set GEMINI_API_KEY` in the project folder and paste the key. The first time, it switches on Secret Manager.
3. **Deploy the functions, then the rules, then the app:** `firebase deploy --only functions`, `firebase deploy --only firestore:rules`, then the website (`tools/build_hosting.ps1`, `firebase deploy --only hosting:app`) and a new Android build. The rules stop the app writing `ai_usage`, so the old app's estimates fail until the new one is in: do them together.
4. **Check it works:** one estimate on the phone puts "AI tokens" in the functions' log (Firebase console → Functions → Logs) and adds 1 to `count` in `users/{uid}/ai_usage/{today}`.
5. **Close the old way in**, once the new build is everywhere: in Google Cloud console → APIs & Services, disable the **Firebase AI Logic API** (leave the Generative Language API on), and untick it on the app's keys (the key step in `04-owner-checklist.md`).
6. **Check the cap still applies:** the £3 cap is on "Gemini Developer API (AI Logic)". If the functions' calls don't show under it, set a project spend cap in AI Studio → Spend. The $5 prepaid credit covers them either way.

## Step B: how to earn from it fairly

What's fair to users:
- **Free for ever:** typing meals and numbers, barcode scanning, food search, recent and usual meals, history, weight, reminders, Day off, contributing to Open Food Facts.
- **Metered, because each use costs money:** AI estimates (typed, voice, photo). Everyone gets a **free daily allowance**, for example 10 a day, plenty for normal use.
- **YumSum Star, for people who want more:** decided on 2 November 2026; see `06-yumsum-plus.md`. Photo logging, 30 AI estimates a day, the Adaptive formula, the AI weekly review and full macros, at £3.99 a month or £29.99 a year (£25.99 until 11 November) with a 7-day trial (priced on 4 November 2026, `11-pricing.md`).

Nothing a free user relies on is ever taken away or hidden behind a paywall later. That's the difference from the apps people complain about: MyFitnessPal moved its barcode scanner behind Premium in 2022.

### The options, compared

| Option | What it earns | Verdict |
|---|---|---|
| **YumSum Star subscription** at **£3.99 a month or £29.99 a year** (plan 11; the year was £25.99 until 11 November, £2.99 and £17.99 when this was written) | You keep 85% after Play's fee, and Google handles VAT. So £3.99 a month is about **£2.83** to you, enough to pay for about 40 daily users' AI at 3 calls a day. | **Recommended.** Competitors charge £7.49–£15.99 a month; an honest YumSum Star at a quarter of that stands out. |
| **Rewarded ad, opt-in** ("watch a short ad for 5 more AI estimates today") | About 0.4–0.8p per view, enough for 4–9 AI calls | **Optional extra** for free users who run out. Never forced. |
| **Banner ads** | About $0.04–$0.15 per daily user a month | **Not recommended.** It barely covers AI, ads are the top complaint in calorie-app reviews, Play forbids ads where people usually tap (next to the log bar), and it needs a consent pop-up and extra Data safety entries. |
| **Interstitial (full-screen) ads** | More money | **No.** It interrupts logging, which is exactly what people hate. |
| **Lifetime unlock** | One-off | **Not on its own.** The AI keeps costing money every month, so a one-off sale can't cover it for ever. A lifetime YumSum Star with a fair-use AI cap could come later. |
| **Tip jar** ("buy me a protein bar", £2.49) | Small, but goodwill | **Fine** as a Play Billing purchase. A Ko-fi link breaks Play's payment rules. |
| **Bring your own AI key** | £0 cost to you | **No.** Gemini's terms are for developers, not consumers, and it's confusing. |

### When to switch YumSum Star on

*Changed 2 November 2026:* YumSum Star goes into the first closed test, so the testers can try it (`06-yumsum-plus.md`). Until it does, you pay the AI yourself (Step A keeps it to a few pounds).

To cover everyone's AI, roughly **1 in 40 daily users (about 2.5%)** needs to be on YumSum Star at £3.99, if they all use AI three times a day; fewer if many just type numbers or scan. A typical freemium app converts about 2% of downloads (RevenueCat's 2025 median), so this is realistic but not guaranteed. Adjusting the free allowance (say 10 down to 7 a day) is the lever if it isn't.

### Building YumSum Star

- **Play Billing with our own Cloud Functions,** not RevenueCat, to keep third-party fees out (decided 31 October; how it works is in `07-billing.md`). RevenueCat stays the fallback: free until you earn $2,500 a month, then 1%.
- A **paywall screen** that is honest and short: what you get, the price, "cancel any time in Google Play".
- The AI allowance checks the subscription. Proper enforcement then moves server-side with a small Cloud Function, which is available on Blaze.
- Play's fee: 10% plus a 5% billing fee, so **15%** for subscriptions and one-off purchases while you earn under $1M a year. You may need to enrol for the reduced rate in Play Console.

## Money admin (UK, individual)

- **Up to £1,000 a year** of income is covered by the **trading allowance**: no need to tell HMRC, but keep records. Above that, register for **Self Assessment by 5 October** after the tax year. You then choose either the £1,000 allowance or your actual costs (AI, domain, Play fee), not both.
- **VAT:** Google charges and pays VAT on Play sales in the UK and EU, so you don't. You'd only register for VAT yourself above £90,000 a year.
- **Your address goes public once you charge money on Play.** A personal account then shows your **full address** on the store listing. PO boxes aren't accepted for the payments profile. Decide whether you're happy with that, or want a business address service, before turning on YumSum Star.
- **Check your employment contract** for clauses on side businesses or who owns what you build in your spare time.
- **New UK subscription rules from January 2027** (DMCC Act): clear information before purchase, renewal reminders and easy cancellation. Play's own subscription screens cover most of this, but the paywall text should be clear.

## Checklist

**Before launch**
- [x] Blaze plan + billing account + prepay (done 24 October: **$5** in AI Studio, auto-reload off, so AI can never cost more than that)
- [x] Spend-cap budget on AI Logic (done 24 October: **£3 a month** on "Gemini Developer API (AI Logic)"; the other services are unused)
- [x] Per-user AI rate limit down to about 10 a minute (done 24 October)
- [ ] Check the paid tier works: one AI estimate shows up as usage on <https://aistudio.google.com/billing>
- [x] (me) Free allowance down to 10 a day; voice notes count (protein on save doesn't; Firestore rules can't make the counter tamper-proof, see step 4). Back up to 20 a day for now on 30 October, while testing
- [x] (me) Correct 429 and 402 handling and messages
- [x] (me) Read the logged token use during the next phone test, then update the figures here (5 November, plan 11)
- [x] (me) Drop the unused "note"
- [ ] (me) Low-resolution photos (`mediaResolution` in `functions/src/prompts.ts` since the AI moved to the server), if the measurements say photos matter
- [x] (me) "AI estimates left today" hint

**AI through our own functions (see above)**
- [x] (me) The functions, the read-only `ai_usage` rule and the app calling them (5 November 2026)
- [ ] The functions' Gemini key, as the `GEMINI_API_KEY` secret
- [ ] Deploy the functions, the rules and the app together
- [ ] One estimate shows in the functions' log and in `ai_usage`
- [ ] Disable the Firebase AI Logic API and untick it on the app's keys
- [ ] Check the spend cap covers the functions' calls

**YumSum Star (before the closed test, see `06-yumsum-plus.md`)**
- [x] Decide the free allowance and YumSum Star contents (2 November 2026: `06-yumsum-plus.md`)
- [ ] Play Billing, Cloud Functions and the paywall (`07-billing.md`); the server-side AI allowance came first, on 5 November
- [ ] Optional: opt-in rewarded ad for extra AI; tip-jar purchase
- [ ] Payments profile (think about your public address first); tax registration if over £1,000

## Sources

- Gemini API pricing: <https://ai.google.dev/gemini-api/docs/pricing>
- Gemini API terms (UK/EEA paid-only clause; 18+): <https://ai.google.dev/gemini-api/terms>
- Rate limits: <https://ai.google.dev/gemini-api/docs/rate-limits>
- Billing tiers, caps and prepaid credit: <https://ai.google.dev/gemini-api/docs/billing>
- Error codes: <https://ai.google.dev/gemini-api/docs/api-errors>
- Image resolution and tokens: <https://ai.google.dev/gemini-api/docs/media-resolution>
- Firebase AI Logic pricing: <https://firebase.google.com/docs/ai-logic/pricing>
- Firebase AI Logic quotas (100 requests a minute per user): <https://firebase.google.com/docs/ai-logic/quotas>
- Firebase AI Logic and App Check: <https://firebase.google.com/docs/ai-logic/app-check>
- Firebase spend caps: <https://firebase.google.com/docs/projects/billing/avoid-surprise-bills>
- Free-tier measurement (third party, unofficial): <https://aiplug.work/en/blog/gemini-free-tier-limits>
- Play service fees (UK from 30 June 2026): <https://support.google.com/googleplay/android-developer/answer/16954621> and <https://support.google.com/googleplay/android-developer/answer/112622>
- Play payments policy: <https://support.google.com/googleplay/android-developer/answer/9858738>
- Play ads policy: <https://support.google.com/googleplay/android-developer/answer/9857753>
- VAT on Play sales: <https://support.google.com/googleplay/answer/2850368?hl=en-GB>
- Payments profile and public address: <https://support.google.com/googleplay/android-developer/answer/13628312>
- UK ad eCPM figures: <https://business.mistplay.com/resources/mobile-ads-ecpm/>
- AdMob consent for UK and EU users: <https://developers.google.com/admob/flutter/privacy/gdpr>
- Calorie-app review analysis (by a competitor, so possibly biased): <https://nutrola.app/en/blog/we-analyzed-50000-calorie-tracker-reviews-what-users-actually-complain-about-2026>
- RevenueCat pricing: <https://www.revenuecat.com/pricing>
- UK trading allowance: <https://www.gov.uk/guidance/tax-free-allowances-on-property-and-trading-income>
- Setting up as a sole trader: <https://www.gov.uk/set-up-sole-trader>
