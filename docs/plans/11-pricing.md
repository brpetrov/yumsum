# Plan 11: The price of YumSum Star

*Written 4 November 2026. Status: the research questions are answered below (by research agents, 4 November); two things are yours (the questions for you, and measuring the AI's real token use on the phone); the price itself isn't decided yet. It replaces the placeholders in plans 03, 06 and 07.*

## The short version

1. **Today's prices are a guess.** £2.99 a month, £17.99 a year and a 7-day trial come from one line in plan 03 on 23 October ("competitors charge £10.99–£15.99; a cheap, honest YumSum Star stands out"). Plans 06 and 07 and the Play Console steps took them on as they were.
2. **Nothing is set up in Play Console yet,** so the price is free to change. The YumSum Star page shows Play's own prices, so the app needs no change for a new price, only the docs, the terms page and a test.
3. **This plan lists what has to be known to price it properly,** how each question is researched, and what was found. Each research question is written so it can be handed to an agent as it stands.
4. **Then the price is worked out** as in "How the price gets decided" and recorded here, with the date.

## What's already known

So nobody researches it again. Each line says where it came from.

**Money in and out**
- **Play keeps 15%** of subscription sales while you earn under $1M a year, and **Google charges and pays UK and EU VAT** (plan 03, checked 23 October).
- **What's left to you** (plan 06):
  - about **£2.12** from £2.99 a month
  - about **£12.74 a year (£1.06 a month)** from £17.99 a year

**What YumSum Star costs to run** (plans 03, 06, 09)
- **Gemini 3.5 Flash-Lite:** $0.30 per million input tokens and $2.50 per million output, with thinking counted as output. That's about 0.06–0.09p a call, on an **assumed** 400 tokens in and 250 out.
  - The real numbers have **never been measured** (plan 03, step A6).
  - Every answer has carried macros since then, so the output is bigger.
- **Smart Snap** (photo logging): about 0.08p a photo.
- **30 AI estimates a day:** about 90p a month in the worst case, someone using all 30 as photos every day. A heavy logger needs 8–12 a day, about 25–35p a month.
- **AI Coach:** about 0.1p a week.
- **Detailed Macros:** a little more per call, never measured.
- **Adaptive Formula:** nothing, as it runs on the phone.
- **Firestore and Cloud Functions:** inside the free allowances at small scale.

**The free tier**
- 10 AI estimates a day, typed or by voice.
- The code still allows 20 for everyone while testing (`AiUsageRepository.dailyLimit`). Plan 06's 10 free and 30 with YumSum Star isn't built yet.

**Competitors, rough figures from plan 06** (2 November)
- MacroFactor about £60–70 a year
- MyFitnessPal Premium about £65–80 a year
- Yazio PRO about £35–60 a year
- monthly plans at £10.99–£15.99

**Benchmarks used so far** (plan 03)
- About 2% of downloads pay (RevenueCat's 2025 median).
- About 1 in 30 daily users on YumSum Star at £2.99 covers everyone's AI.

**Decisions that stay**
- No ads.
- No lifetime unlock on its own.
- Buying through Play Billing inside the app.
- One subscription, `yumsum_plus`, with the base plans `monthly` and `annual` and the trial offers `monthly-trial` and `annual-trial` (plan 07).

**Constraints**
- Your address goes public with the payments profile.
- The £1,000 trading allowance.
- The new UK subscription rules (DMCC Act).

## Questions for you

These are yours, not the agents'. Answer them before the price is chosen.

- **Q1. What's the aim?** Covering the free users' AI with a bit over, or earning properly? They lead to different prices.
- **Q2. Where?** The UK first, Bulgaria second. Does anywhere else matter at launch? This decides how much regional pricing matters.
- **Q3. Selling on the website.** On 31 October you liked the idea of Stripe on the website. It saves Play's fee but makes you the seller for VAT. B7 below has what that involves.
- **Q4. Launch price.** Launch low and raise it later for new subscribers, or launch at the right price? C4 has Play's rules on raising prices.
- **Q5. Measure the tokens** (B2). This needs your phone and a debug build; the agents can't do it.

## The research questions

**Rules for every researcher.** Paste them in with each question.
- Facts only, each with a URL and the date checked. Write "not found" rather than guess. Mark anything from memory that couldn't be confirmed online as "unconfirmed".
- Use primary sources first: Google's own pages, the app's Play listing (`?gl=GB&hl=en_GB`), its website, or the report's own page. Say when only a blog has the figure.
- Give money in the source's currency without converting it, and say where each price is from: Google Play UK, App Store UK, the website, or another country.
- No recommendations. The decision is made later.
- Return markdown tables plus short notes, and end with what couldn't be found.

**Context for every researcher.** YumSum is a calorie and protein tracker for Android, not yet launched, starting in the UK and Bulgaria. YumSum Star has:
- AI photo logging
- 30 AI estimates a day (10 free)
- an adaptive target
- a weekly AI review
- full macros

The placeholder price is £2.99 a month or £17.99 a year, with a 7-day trial, sold only through Google Play Billing.

### A. What people pay for calorie apps

**A1. The big apps' UK prices**
- **Ask:** for MyFitnessPal, Yazio, Lose It!, Lifesum, MacroFactor, Cronometer, Carbon Diet Coach, FatSecret and Nutracheck, give:
  - the monthly, yearly and lifetime price
  - the trial length
  - the Play listing's in-app price range
  - what the paid tier gates: photo or AI logging, macros, barcode and an adaptive target
- **Why:** where "cheap" sits next to them, and what they charge for the same features.
- **Return:** one table.

**A2. The AI photo apps**
- **Ask:** the same columns as A1 for Cal AI, SnapCalorie, Foodvisor, Calorie Mama, Bitesnap and any UK-made AI calorie app. Add what the free tier allows for AI or photo scans.
- **Why:** Smart Snap leads the YumSum Star page, so these set what people expect to pay for AI.
- **Return:** one table.

**A3. The cheap end**
- **Ask:** 6–10 calorie, food or macro apps on Play at £1–£5 a month, including Lean Streak (leanstreak.co.uk, said to be £1.99 a month). For each, give:
  - the price
  - the install band
  - the rating and review count
  - what's paid
- **Why:** they're the nearest neighbours at our price.
- **Return:** one table.

**A4. Health and fitness subscription benchmarks**
- **Ask:** from RevenueCat's State of Subscription Apps (2026 and 2025), Adapty and others:
  - the median monthly and yearly price
  - the share of subscribers on yearly plans
  - trial-to-paid conversion
  - install-to-paid and install-to-trial conversion
  - retention at month 1, month 3 and year 1
  - revenue per install

  Say for each number which year it's from, whether it's Health & Fitness or all apps, and which platform.
- **Why:** these turn a price into likely income.

**A5. Price points, the yearly discount and the trial**
- **Ask:** evidence, not opinion, on:
  - the usual yearly-to-monthly ratio (a year costs about N months) and how it shifts which plan people choose
  - conversion and revenue at different price levels
  - 3-, 7- and 14-day trials against trial starts, conversion and revenue
  - .99 endings
- **Why:** this sets the yearly price and the trial length.

### B. What it costs you

**B1. Gemini prices today**
- **Ask:** the paid prices per million tokens for:
  - Gemini 3.5 Flash-Lite, separately for text, image and audio input, output, and thinking
  - Gemini 3.1 Flash-Lite and its retirement date

  Also:
  - the tokens per image at default and low media resolution, and per second of audio
  - batch or caching discounts
  - whether Firebase AI Logic adds a charge of its own
  - whether anything changed after 23 October 2026
- **Where:** ai.google.dev pricing and media-resolution pages, and firebase.google.com AI Logic pricing.

**B2. Real tokens per call (you, not an agent)**
- **Do:** five typed, five voice and five photo estimates and one AI Coach, all with macros on, in a debug build. Read the debug log line "AI tokens: in …, out …, thinking …" for each.
- **Return:** the average in, out and thinking tokens for each kind of call.
- **Why:** this replaces the assumed 400 in and 250 out, which predate macros and AI Coach.

**B3. Firebase at 1,000 and 10,000 monthly users**
- **Ask:** the current free quotas and prices, in europe-west2 where they vary, for:
  - Firestore reads, writes, deletes and storage
  - Cloud Functions 2nd gen
  - Auth
  - App Check: Play Integrity's daily quota, and reCAPTCHA on the web
  - Hosting

  Then work out the monthly Firestore cost, showing the arithmetic, with each user active 15 days a month. On each active day assume about 60 reads (Home about 10, History about 50) and about 10 writes (3 meals at 3 writes each, plus a weigh-in every other day at 2).
- **Why:** the running cost beyond the AI.

**B4. Play's fee, exactly**
- **Ask:**
  - the fee on subscriptions under $1M a year, and whether it's 15% from the first day or needs enrolment
  - what changed in the UK from 30 June 2026: the service fee and the billing fee, and alternative billing and external offers in the UK and EEA, with their fees
  - payout timing and currency, and the conversion cost on euro sales
- **Where:** Play Console Help.

**B5. VAT and the order of the sums**
- **Ask:**
  - is Google the merchant of record for VAT in the UK and in every EU country?
  - is the 15% taken after VAT? Work a £2.99 UK sale and a €2.99 Bulgarian sale through to what you receive.
- **Why:** every net figure in this plan depends on it.

**B6. Refunds and failed payments**
- **Ask:**
  - Play's grace period, account hold and refund defaults for subscriptions
  - the typical refund rate and the typical involuntary churn (failed payments) for Play subscriptions
- **Why:** the share of income to take off before counting it.

**B7. Selling on the website through Stripe**
- **Ask:**
  - Stripe's UK fees, including Stripe Billing
  - whether Play's payments policy lets the app honour a subscription bought on the website when the app doesn't mention it
  - the UK and EEA external-offer programmes and their fees
  - VAT when you're the seller: the UK £90,000 threshold, and whether EU consumers mean non-Union OSS registration from the first sale
  - Bulgaria's VAT rate
- **Why:** this answers Q3.

### C. Who pays, and how many

**C1. Android against iOS**
- **Ask:** how Android compares with iOS on conversion, price paid, revenue per install and retention, in health and fitness or all subscription apps.
- **Why:** the launch is Android only, and most benchmarks lean on iOS.

**C2. Regional prices**
- **Ask:**
  - how Play sets other countries' prices from a base price: exchange rates, price templates or recommended prices
  - any recommended prices for Bulgaria or the EU
  - evidence that localised prices raise revenue
- **Why:** Bulgaria's price.

**C3. A metered free tier as the reason to pay**
- **Ask:**
  - evidence on "N free uses a day" against gating whole features as the reason people pay
  - what Cal AI, Yazio and MyFitnessPal give free for AI or photo logging

  "Not found" is a fine answer.
- **Why:** the free 10 a day is YumSum's main nudge to pay.

**C4. Raising the price later**
- **Ask:**
  - Play's rules for changing existing subscribers' prices: opt-in and opt-out, notice, frequency, size limits, and countries where opt-out isn't allowed
  - whether old subscribers can be kept on their price
  - data on how many leave after a rise
- **Why:** this answers Q4.

### D. Rules that shape the price page

**D1. The UK subscription rules (DMCC Act)**
- **Ask:**
  - the start date, and whether the regulations have been laid or passed
  - the information needed before subscribing
  - the reminder notices (before a trial ends, before a yearly renewal, every 6 months): when they're due and in what form
  - cooling-off, including the renewal cooling-off
  - easy cancellation
  - **who is the trader when the subscription is sold through Google Play**
  - anything specific to free trials or yearly plans
- **Where:** gov.uk, legislation.gov.uk and the CMA.

**D2. Play's subscription rules**
- **Ask:**
  - showing a yearly plan as a monthly cost
  - whether a base plan can have an introductory price (for example £0.99 for the first month) as well as a free trial
  - the minimum and maximum prices in pounds and euros, and whether any amount is allowed
  - whether a free trial can be offered more than once per account
  - the billing periods allowed
- **Where:** Play Console Help and the subscriptions policy.

### E. Beyond monthly and yearly

**E1. One-off AI top-ups**
- **Ask:**
  - Play's rules for consumable products, for example "20 extra AI estimates for 99p"
  - calorie or AI apps that sell credits or scans alongside a subscription, with their prices

**E2. Lifetime purchases**
- **Ask:**
  - calorie or nutrition apps that sell a lifetime unlock, and its price next to their yearly price
  - whether any of them cap AI use for lifetime buyers

## What the research found

*From five research agents, all checked 4 November 2026. Labels:*
- *"(secondary)": a blog or vendor quoting the original*
- *"(unconfirmed)": a search snippet or a figure the agent couldn't check*
- *"not found": it was looked for and isn't there*

*Short source names are listed under Sources.*

### What changes from what was known

- **Play's fee is confirmed at 15%**, as 10% service fee plus 5% billing fee, from the first payment and with no enrolment. Google takes the VAT off first, so £2.99 still leaves about **£2.12**. What the 5% is worked out on isn't stated.
- **Cheaper Gemini models exist.** The answer the AI writes is about 80% of each call's cost:
  - 3.1 Flash-Lite charges $1.50 per million output tokens against 3.5's $2.50, and runs until at least 7 May 2027.
  - 2.5 Flash-Lite charges $0.10 in and $0.40 out, with no shutdown date.

  Either would need the accuracy check from October run again.
- **A photo is about 1,120 input tokens** at default resolution, or 280 at low. That's more than the 400 assumed for a whole call, but input is still cheap next to output.
- **Our yearly price is generous.** £17.99 is 6 months of £2.99. The health and fitness median year is about 4 months ($39.94 against $9.99).
- **Android pays far less than the benchmarks suggest.** 0.9% of Android downloads pay within 35 days, against 2.6% on iOS (secondary, all apps). Plan 03's 2% mixed both platforms.
- **The UK subscription rules start on 1 January 2027.** They need a reminder before a trial turns paid and before each yearly renewal, in a form that can be kept, such as email; an in-app message doesn't count. Who must send it when Play does the selling is still open.
- **Firebase costs nothing at 1,000 monthly users** and about $4 a month at 10,000.

### A. What people pay

**A1. The big apps (UK)**

Most stores list products without saying whether they're monthly or yearly; "unclear" marks those.

| App | Monthly | Yearly | Trial | Photo or AI logging |
|---|---|---|---|---|
| MyFitnessPal | £15.99 | £64.99 | 7 days | Meal Scan is paid |
| MacroFactor | £10.99 | £62.99 (6 months £41.99) | 7 days | The whole app is paid; the adaptive target is its core |
| Carbon Diet Coach | £11.99 | £99.99 (6 months £59.99) | 7 days (its website) | Built around adaptive coaching |
| Cronometer | £9.99 | £59.99 | None mentioned | Photo and voice logging are paid; barcode is free |
| Lifesum | £7.49 | £49.99 (another product says £99.99) | Yes, length not found | Not found |
| Yazio | Unclear | £35.90 | Not stated | AI recognition moved to Pro (help centre, unconfirmed) |
| Lose It! | Unclear | Unclear; lifetime £59.99 | Yes, length not stated | Photo and AI voice logging are paid |
| FatSecret | £7.69–£10.99 (unclear) | £29.00–£44.99 (unclear) | None stated | Photo scan is paid (secondary) |
| Nutracheck | £3.99–£6.99 (unclear) | £23.99–£34.99 (unclear) | 7 days | Barcode and photo search are paid; the free plan allows 5 entries a day (unconfirmed) |

**A2. The AI photo apps**

| App | Price | Trial | Free AI |
|---|---|---|---|
| Cal AI | £2.99 to £37.00, periods unclear | 3 days | None: results need a subscription |
| SnapCalorie | £19.99 a month, £149 a year | None stated | "Core features free", no limit given |
| Foodvisor | £14.99 a month, £35.99 a year | A trial product exists | Not found |
| Calorie Mama | Not found (Play range £9.49–£39.49; rated 2.79) | Not found | Not found |
| Bitesnap | Its Play listing is gone; it looks discontinued | — | — |

- **UK-made AI apps:**
  - Fueld (London) has no price found.
  - Carbs & Cals is £6.99–£35.99 on Play.
  - Vitl is iPhone only.

**A3. The cheap end**
- **Play shows only a price range**, so no cheap app's monthly price could be confirmed.
- **Reviewers mention** Calz paying £17.99 a year and MyNetDiary £24 a year.
- **Big cheap-end apps:** Calz (1M+ installs, rated 4.73), Fitia (10M+, 4.73) and MyNetDiary (5M+, 4.66).
- **Lean Streak** has no Play listing to be found, and its £1.99 couldn't be checked.

**A4. Health and fitness benchmarks** (RevenueCat 2026 unless said; platforms mixed, mostly iOS)

| Measure | Figure |
|---|---|
| Median monthly price | $9.99 |
| Median yearly price | $39.94 |
| Subscriptions that are yearly | 68% (2025: 67%) |
| Downloads that start a trial within 30 days | 6.9% |
| Trials that turn paid | 37.7% (2025: 39.9%; Adapty 35.0%) |
| Downloads that pay within 35 days | 2.9% (top quarter above 6.2%) |
| Revenue per download | $0.48 by day 14, $0.66 by day 60 |
| Revenue per payer | $24.23 in month 1, $35.64 in year 1 |
| Monthly subscribers who renew the first time | 57% |
| Yearly subscribers who renew after the first year | 25% |
| Year-one retention, all apps (2025) | Monthly 13.8%, yearly 33.9% |
| Refund rate | 4.71% (Adapty) |

Retention by month for health and fitness exists only as charts: not found as numbers.

**A5. Price points, the yearly discount and the trial**

*The yearly discount*
- A year costs about **4 months** at the health and fitness medians; 3 to 3.5 across all apps (secondary).
- No study was found on how the ratio changes which plan people choose.

*Price level*
- High-priced apps convert more downloads to paid than low-priced ones: 2.8% against 1.4% (all apps).
- That compares apps at different price tiers; it isn't one app tested at different prices.
- No head-to-head test of $2.99, $4.99 and $9.99 was found.

*Trial length* (RevenueCat 2026, all apps)
- Trials that turn paid:
  - 25.5% at 4 days or less
  - **37.4% at 5–9 days**
  - 42.5% at 17–32 days
- 55% of 3-day trials are cancelled on the first day.
- In health and fitness, 54% of trials are 5–9 days, and 18% of apps have no trial.
- Trial starts and revenue by length: not found.

*Prices ending in .99:* no data found.

### B. What it costs you

**B1. Gemini prices** (Google's pricing page; no change since 23 October)

| Model | Input (text, image or audio) | Output, thinking included | Shutdown |
|---|---|---|---|
| 3.5 Flash-Lite (ours) | $0.30 | $2.50 | None set |
| 3.1 Flash-Lite | $0.25 (audio $0.50) | $1.50 | Not before 7 May 2027 |
| 2.5 Flash-Lite | $0.10 (audio $0.30) | $0.40 | None set |

*Prices per million tokens.*

- **Tokens:**
  - a photo is about 1,120 at default resolution and about 280 at low
  - audio is 25 a second, so a 10-second note is about 250
- **Firebase AI Logic adds no charge of its own.**
- **Batch prices are half,** but they're for slow background jobs, not logging. Whether batch or caching works through AI Logic: not found.

**B3. Firebase**
- **Free each day:** 50,000 Firestore reads, 20,000 writes and 20,000 deletes.
- **Beyond that, in London:** $0.039 per 100,000 reads and $0.117 per 100,000 writes.
- **Other free allowances:**
  - Cloud Functions: 2 million calls a month
  - Auth: free to 50,000 monthly users
  - Play Integrity: 10,000 checks a day
  - reCAPTCHA on the web: 10,000 a month
- **At 1,000 monthly users the cost is $0,** under every daily allowance on an average day.
- **At 10,000 it's about $4 a month** (reads $2.93, writes $1.05). Both cases assume 15 active days a month, 60 reads and 10 writes a day.

**B4. Play's fee**
- **In the UK and EEA since 30 June 2026,** subscriptions on the first $1M a year cost a 10% service fee plus a 5% billing fee: 15% from the first payment, with no enrolment found.
- **Payouts** come around the 15th of the next month, in the payments profile's currency. Euro sales are converted at the rate on the day of the order; the conversion cost was not found.
- **Bulgaria uses the euro** from 1 January 2026.

**B5. VAT**
- **Google is the seller for VAT** in the UK and every EU country, unless you use your own billing.
- **The order of the sums:** VAT comes off first, then the fee.

| | UK sale | Bulgarian sale |
|---|---|---|
| Price | £2.99 | €2.99 |
| VAT at 20% | £0.50 | €0.50 |
| Net of VAT | £2.49 | €2.49 |
| 10% service fee | £0.25 | €0.25 |
| 5% billing fee | £0.12 | €0.12 |
| **You get** | **about £2.12** | **about €2.12** |

What the 5% billing fee is worked out on isn't stated, so that line is unconfirmed.

**B6. Refunds and failed payments**
- **Refunds:** Play may refund within 48 hours of a purchase, after which it's your call. Health and fitness apps refund about 4.7% of payments: 3.0–3.5% on monthly plans, 4.2% on yearly (Adapty).
- **Failed payments:**
  - they cause **32% of cancellations on Play**, against 15% on the App Store (RevenueCat 2026)
  - account hold is on by default, with grace and hold together at least 30 days
  - a grace period recovers 57% more failed payments

**B7. Selling on the website**
- **Stripe's fees:**
  - UK cards: 1.5% + 20p
  - EEA cards: 2.5% + 20p
  - Stripe Billing adds 0.7%
- **What Play allows:** an app may unlock what was bought elsewhere, as long as it sells nothing in the app and doesn't link to the website's payment page. You may email people about it.
- **Play's external-offer programmes in the UK and EEA:**
  - they let the app point to the website
  - the service fee still applies, without the 5% billing fee
  - the reports disagree on the rate for links: 10%, or 20% for existing installs
- **VAT when you're the seller:**
  - UK sales need registration only above £90,000
  - EU consumers need the non-Union OSS from the first sale, with no threshold for a UK seller (secondary)
  - Bulgaria's VAT is 20%

### C. Who pays, and how many

**C1. Android against iOS** (secondary, all apps, quoting RevenueCat and Adapty 2026)

| Measure | iOS | Android |
|---|---|---|
| Downloads that pay within 35 days | 2.6% | **0.9%** |
| Trials that turn paid | 32.6% | 32.5% |
| Revenue per download by day 60 | $0.42 | **$0.16** |
| Revenue per payer in year 1 | $23.38 | $21.62 |
| Share of cancellations from failed payments | 15.2% | 32.2% |

- **Share of all subscription revenue:** Android is about 15% (Adapty, unconfirmed).
- **What it means:** Android users who start a trial convert as well as iOS users, but far fewer start one.
- **Health and fitness figures by platform:** not found.

**C2. Regional prices**
- **How Play sets other countries' prices:** it converts your price at the day's exchange rate with local price patterns. You can type your own price for each country.
- **Price templates:** Play removed them on 27 October 2025.
- **Purchasing-power suggestions:** none published by Play for Bulgaria or the EU (not found).
- **Evidence that local prices raise revenue:** vendor claims only (unconfirmed).

**C3. A daily free allowance as the reason to pay**
- **Daily allowance against locked features:** no conversion data either way. Only 5% of 809 apps use a usage meter; locking whole features is far more common.
- **AI apps:** they earn 41% more per customer and lose customers 30% faster (RevenueCat 2026).
- **Free AI in the big apps:**
  - Cal AI gives no free scans.
  - Yazio moved AI recognition to Pro.
  - MyFitnessPal's Meal Scan is paid.

  None of them was found with a free daily AI allowance like YumSum's.

**C4. Raising the price later**
- **By default a rise needs consent.** Subscribers who don't accept are cancelled at the renewal 37 days later.
- **A rise without consent ("opt-out") is allowed:**
  - in the UK and Bulgaria
  - once a year per plan per country
  - up to 50%
  - with 30 days' notice
- **Existing subscribers keep their old price by default** (legacy price cohorts), until you end that.
- **How many leave after a rise:** only unconfirmed figures, 10–25% for rises of 30% or more.

### D. Rules that shape the price page

**D1. The UK subscription rules (DMCC Act)**

*When*
- **From 1 January 2027,** for subscriptions taken out from then.
- **Not final yet:** the draft regulations and guidance were published on 19 October 2026 and still need Parliament's approval.

*Before buying,* shown together, near the button:
- that it renews until cancelled
- the first charge after a trial, with its date and amount
- how often and how much, with the monthly equivalent for a yearly plan
- how to cancel
- when reminders come
- the cooling-off rights

*Reminders*
- before a trial or discount turns into the full price
- about every 6 months on monthly plans
- an extra, earlier one before a yearly renewal

They must be in a form that can be kept, such as email or text; a passing in-app message doesn't count. YumSum can't send email today.

*Cooling-off*
- 14 days from buying.
- A fresh 14 days after a trial turns paid, and after every yearly renewal.

*Cancelling* must be as easy as buying, online when bought online.

*Who must comply when Play sells:* the guidance says "the trader with whom the consumer enters into the subscription contract", and names neither Google nor the developer. It's still open.

**D2. Play's subscription rules**
- **A yearly plan can't be shown mainly as a monthly cost;** the yearly price must be the big number. This matches plan 07.
- **One offer can hold a free trial followed by an introductory price,** for example 7 days free, then £0.99 for the first month. The introductory price can't be above the base price.
- **Prices:** £0.05–£300 and €0.05–€350 (unconfirmed), typed per country.
- **"New customer" offers** go only to someone who has never had any subscription in the app.
- **Billing periods:** weekly to yearly, including 3 and 6 months. The sources differ on the exact list.

### E. Beyond monthly and yearly

**E1. Top-ups**
- **Play allows consumable products,** such as "20 extra AI estimates". They must use Play Billing and be used only in the app.
- **Examples** (US App Store, unconfirmed):
  - ScanCal sells 25 to 250 credits for $3.99–$29.99.
  - CalorieScan sells 5 scans for $1.99 and 60 for $8.99.

  Both sit alongside a subscription.

**E2. Lifetime**
- **Lose It!** is the only calorie app found selling one: £59.99 in the UK.
- **Cronometer and MacroFactor** sell none; Yazio, Lifesum and FatSecret: not found.
- **An AI limit for lifetime buyers:** not found for any app.

### The gaps that matter

- **Real tokens per call** (B2, yours). This is still the biggest unknown in the cost.
- **Health and fitness figures for Android alone.**
- **Who sends the UK reminder notices** when Play sells.
- **What the 5% billing fee is worked out on,** and the cost of converting euros.
- **Most competitors' monthly prices on Play,** since Play shows only ranges.

## How the price gets decided

Once B2 is measured and Q1–Q4 are answered, I work out:

1. **Cost per subscriber a month** at three levels of use, using the measured tokens and today's Gemini prices, plus AI Coach, macros and Firebase's share:
   - light: 3 AI estimates a day
   - typical: 8–12 a day
   - worst case: all 30 a day, as photos
2. **What you keep per subscriber** after VAT, Play's fee and the refund and failed-payment share:
   - monthly at £1.99, £2.49, £2.99, £3.49, £3.99 and £4.99
   - yearly at 6, 7 and 8 months' worth
3. **Margins** at each price and level of use. Plan 06's rule stays: **a yearly subscriber must not lose money at worst-case use.** If no sensible yearly price meets it, the YumSum Star allowance comes down from 30 instead.
4. **Subscribers needed per 100 daily free users** to pay for their AI, at each price.
5. **Income at 1,000 and 10,000 downloads.** This is downloads × the conversion benchmarks, with Android's discount (C1) and refunds taken off, set against the £1,000 trading allowance.
6. **What if:**
   - the AI price doubles
   - Play's fee is 30%
   - conversion is half the benchmark
7. **The recommendation:**
   - the monthly and yearly price
   - the trial length
   - Bulgaria's price
   - whether a top-up or an introductory price is worth adding

   It goes here with the date. Then these follow:
   - plans 03, 06 and 07
   - `tools/hosting/terms.html`
   - `test/plus_screen_test.dart`, if any wording changes
   - the base plans in Play Console

## Checklist

- [x] (Claude) The questions and how to research them (4 November)
- [x] (agents) A1–A5, B1, B3–B7, C1–C4, D1, D2, E1, E2 (4 November)
- [ ] (you) Q1–Q4
- [ ] (you) B2: measure the tokens on the phone
- [ ] (Claude) Work out the price as above and record it here
- [ ] (Claude) Update plans 03, 06 and 07 and the terms page to the chosen price
- [ ] (you) Set the prices on the base plans in Play Console (plan 07)

## Sources

For "What's already known":
- Plan 03: Gemini prices, Play's fee, VAT, the conversion benchmark, and all its sources
- Plan 06: what's in YumSum Star, the running costs, and the competitor figures
- Plan 07: the product and base-plan IDs, and the paywall wording rules
- Plan 09: AI Coach's cost

For "What the research found", by short name (all checked 4 November 2026):

**Benchmarks and pricing research**
- **RevenueCat 2026:** <https://www.revenuecat.com/state-of-subscription-apps/>
  - renewals: <https://www.revenuecat.com/blog/average-subscription-renewal-rates-by-app-category/>
  - trials: <https://www.revenuecat.com/blog/growth/7-day-trial-subscription-app.md>
  - failed payments on Play: <https://www.revenuecat.com/blog/growth/google-play-billing-error-churn-how-to-fix>
- **RevenueCat 2025:** <https://www.revenuecat.com/state-of-subscription-apps-2025/> and <https://www.revenuecat.com/blog/growth/annual-subscriptions-apps-pros-cons.md>
- **Adapty:**
  - <https://adapty.io/blog/health-fitness-app-subscription-benchmarks/>
  - <https://adapty.io/state-of-in-app-subscriptions/>
  - refunds: <https://adapty.io/blog/refund-rate-metrics-and-benchmarking/>
  - trial lengths: <https://adapty.io/blog/markdown/trial-conversion-rates-for-in-app-subscriptions.md>
  - price index: <https://adapty.io/app-subscription-pricing-index/>
- **Android against iOS** (secondary): <https://thesocialoutline.com/blog/ios-vs-android-subscription-economics>
- **Usage meters against locks:** <https://www.lazyweb.com/research/should-i-use-a-usage-meter-or-a-hard-lock-to-gate.md>
- **Price-rise churn** (unconfirmed): <https://subi.co/post/how-to-raise-subscription-prices>

**Competitors**
- **Google Play UK listings** (`?gl=GB&hl=en_GB`) and **App Store UK pages** (`apps.apple.com/gb/app/…`) for each app
- **Cronometer:** <https://cronometer.com/gold/>
- **MacroFactor:** <https://help.macrofactorapp.com/en/articles/393-how-macrofactor-subscriptions-and-bundles-work>
- **MyFitnessPal:** <https://www.myfitnesspal.com/premium> and <https://www.myfitnesspal.com/premium-plus>
- **Yazio:** <https://help.yazio.com/hc/ru/articles/39137901903889-What-is-the-AI-Calorie-Tracking-Feature-and-how-does-it-work>
- **Carbon:** <https://joincarbon.com/how-it-works>
- **Cal AI:** <https://calai.app>
- **Free photo scanning** (Nutrola, a competitor): <https://nutrola.app/en/blog/free-calorie-tracker-with-photo-scanning-2026>

**Google and Firebase**
- **Gemini prices:** <https://aistudio.google.com/docs/pricing>
- **Shutdowns:** <https://aistudio.google.com/docs/deprecations>
- **Tokens per image:** <https://aistudio.google.com/docs/media-resolution>
- **AI Logic:** <https://firebase.google.com/docs/ai-logic/pricing>
- **Firebase:** <https://firebase.google.com/pricing>
- **Firestore:** <https://cloud.google.com/firestore/pricing>
- **Cloud Run:** <https://cloud.google.com/run/pricing>
- **Auth:** <https://firebase.google.com/docs/auth>
- **App Check:** <https://firebase.google.com/docs/app-check>
- **Play Integrity:** <https://developer.android.com/google/play/integrity/setup>

**Google Play**
- **Service fees:** <https://support.google.com/googleplay/android-developer/answer/112622>
- **Lower fees:** <https://support.google.com/googleplay/android-developer/answer/16954621>
- **The 30 June change:** <https://android-developers.googleblog.com/2026/06/play-expanded-billing.html>
- **The UK announcement:** <https://blog.google/company-news/inside-google/around-the-globe/google-europe/united-kingdom/google-play-updates-uk-developers/>
- **Payouts:** <https://support.google.com/googleplay/android-developer/answer/137997>
- **Currency:** <https://support.google.com/googleplay/android-developer/answer/1169947>
- **VAT:** <https://support.google.com/googleplay/android-developer/answer/138000>
- **Base plans and offers:** <https://support.google.com/googleplay/android-developer/answer/12154973>
- **Opt-out countries:** <https://support.google.com/googleplay/android-developer/answer/13542779>
- **Price changes:** <https://developer.android.com/google/play/billing/price-changes>
- **Prices:** <https://support.google.com/googleplay/android-developer/answer/6334373>
- **Price ranges:** <https://support.google.com/googleplay/android-developer/answer/10532353>
- **Subscriptions policy:** <https://support.google.com/googleplay/android-developer/answer/9900533>
- **Payments policy:** <https://support.google.com/googleplay/android-developer/answer/9858738> and its FAQ <https://support.google.com/googleplay/android-developer/answer/10281818>
- **Refunds:** <https://support.google.com/googleplay/answer/15574908>
- **Billing:** <https://developer.android.com/google/play/billing/integrate>

**UK rules, tax and Stripe**
- **DMCC government response:** <https://www.gov.uk/government/consultations/consultation-on-the-implementation-of-the-new-subscription-contracts-regime/outcome/government-response-to-consultation-on-the-implementation-of-the-new-subscription-contracts-regime-web-accessible-version>
- **Draft guidance:** <https://assets.publishing.service.gov.uk/media/6acf97da2de3184ccf8b814e/subscription-contracts-rules-guidance.pdf>
- **Summaries** (secondary):
  - <https://bratby.law/subscription-contracts-rules/>
  - <https://dwfgroup.com/de-de/news-and-insights/insights/2026/10/dmcca-subscription-contracts-regime-preparing-for-the-new-restrictions>
  - <https://www.stephensonharwood.com/insights/subscription-reforms-brought-forward-to-january-2027-is-your-business-ready/>
- **Stripe:** <https://stripe.com/gb/pricing>
- **UK VAT threshold:** <https://www.gov.uk/vat-registration-thresholds>
- **Non-Union OSS:** <https://revenue.ie/en/vat/vat-ecommerce/non-union-scheme/index.aspx>
- **Bulgarian VAT:** <https://taxsummaries.pwc.com/bulgaria/corporate/other-taxes>
- **Bulgaria's euro:** <https://www.bta.bg/en/news/926015-bulgaria-clears-last-hurdle-to-eurozone-entry-on-january-1-2026>
