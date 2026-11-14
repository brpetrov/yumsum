# Plan 15: The launch tracker

*Started 14 November 2026. This is the one to-do list from here to the public launch. It replaces the old plan 15 (from draft to closed test) and takes over the open items of plans 02 and 04. The other plans keep the detail: 14 has every Play form answer and the store texts, 07 the billing clicks, 02 the email background.*

## How we use it

- Work top to bottom. A section starts when the one before it is done, unless it says it can wait.
- A task is ticked, with its date, once it's done and checked. Not before.
- Lines are short on purpose. If one is unclear, ask in the chat and we go through it there.
- Anything you mention on the side goes into the **Queue** at the bottom with its date, and the current task carries on. The queue is sorted into the sections when we next plan.
- **You** marks what only you can do (consoles, the phone). **Claude** marks what I do.

**Now:** 1.1, Verify and Apply the email domain in Firebase. Then section 2's forms.

## 1. Email

### 1.1 Sign-in emails from yumsum.app (before the test)

- [x] You: buy yumsum.app at Cloudflare, under help.yumsum@gmail.com (13 Nov)
- [x] The website answers at yumsum.app and Google sign-in works there (13 Nov)
- [x] Claude: the legal links, the old site's redirect and the browser tests use yumsum.app (13 Nov; in the Play app from build 0.1.0+4)
- [x] You: the four email records in Cloudflare: SPF, `firebase=` and two DKIM (14 Nov, seen on public DNS)
- [ ] You: Firebase → Authentication → Templates → Customize domain → `yumsum.app` → **Verify**, then **Apply custom domain** (not started when checked on 14 Nov)
- [ ] You: on any template, Customize action URL → `https://yumsum.app/__/auth/action`
- [ ] Claude: send a confirmation email and a reset email to the test account. They come from noreply@yumsum.app, reach the inbox in Gmail and Outlook, and the link opens on yumsum.app
- [ ] Claude: `docs/features.md` and CLAUDE.md say where the emails now come from

### 1.2 An inbox at yumsum.app (can wait until the test is running)

help.yumsum@gmail.com stays the contact address until this is done.

- [ ] Decide where help@yumsum.app lives. Zoho Mail Free sends and receives as help@yumsum.app. Cloudflare forwarding into help.yumsum's Gmail is simpler, but replies still come from the Gmail address. Plan 02, step 2
- [ ] You: create help@yumsum.app, with privacy@ as a second name for it
- [ ] You: its records in Cloudflare: MX, DKIM, and the provider's part added to the one SPF record, beside Firebase's
- [ ] You: a DMARC record, starting at `p=none`
- [ ] Test: a message in from Gmail and from Outlook, and a reply out that isn't junked
- [ ] Claude: help@yumsum.app replaces help.yumsum@gmail.com wherever people see it: the privacy, terms and delete-account pages, the reply address on Firebase's emails, where feedback is sent
- [ ] You: the same in Play Console → Store settings

### 1.3 Our own styled emails, through Resend (can wait until after the test)

Firebase's plain emails are enough for testers. Ours carry the logo, in English and Bulgarian, and are already written (`functions/src/email.ts`); they only need a sender that isn't junked.

- [ ] You: a Resend account under help.yumsum@gmail.com; add yumsum.app (region Europe) and its records in Cloudflare
- [ ] You: `firebase functions:secrets:set RESEND_API_KEY`, pasting a sending-only key at the prompt
- [ ] Claude: the functions send through Resend instead of Gmail. The app asks them first and sends Firebase's own email whenever ours fails (Resend's free tier stops at 100 a day and 3,000 a month)
- [ ] Test both emails, and the fallback

## 2. Play Console: finish setting up the app

A closed test can't start until every line here is done. The answers are in plan 14, section 2.

- [x] Main store listing: name, descriptions, icon, feature graphic, eight pictures (12 Nov)
- [x] Store settings: email, and website `https://yumsum.app` (14 Nov)
- [ ] Store settings: category **Health & Fitness**
- [x] Privacy policy: `https://yumsum.app/privacy` (14 Nov)
- [ ] Target audience and content: 18 and over only. This unlocks Data safety
- [ ] Data safety: the answers went in on 14 Nov, with `https://yumsum.app/delete-account` as the delete account link. Open it → Preview → **Submit** (plan 14, 2.3, if the draft wasn't kept)
- [ ] Ads: none
- [ ] Advertising ID: no
- [ ] Government apps: no
- [ ] Financial features: none
- [ ] Health apps: nutrition and weight management only
- [ ] Content ratings: the questionnaire (plan 14, 2.2)
- [ ] Sign in details: the test account, and the instructions in plan 14, 2.1

## 3. A quick test yourself, from Play

The first try failed on Google sign-in (fixed in 0.1.0+3). The second failed on the sign-up email, which was held and junked; that's why section 1 comes first.

- [x] Internal testing is live with you as its tester; Play's signing keys are in Firebase; Play Integrity is linked (10–12 Nov)
- [x] Continue with Google works in the Play install (0.1.0+3, 12 Nov)
- [ ] Claude, when you say "build": 0.1.0+4, carrying the sign-up fixes, Firebase's emails, the yumsum.app links and the ring fix. You upload it to Internal testing
- [ ] Email sign-up with an address you haven't used: the email comes within a minute, not into junk, and its link takes you into onboarding
- [ ] Forgot password: the same checks
- [ ] Continue with Google, once more
- [ ] Log a meal each way: typed with an AI estimate, the mic, a photo, a barcode
- [ ] Open every page in the menu
- [ ] Debug tools → Send a test crash report; it shows in Firebase → Crashlytics within a few minutes
- [ ] The same sign-up and sign-in on yumsum.app, on the phone and on the PC

## 4. Out to testers: the closed test

- [ ] You: collect the testers' Gmail addresses. Play needs 12 opted in on Android; aim for 14 or 15. Helpers on iPhones use yumsum.app and don't count
- [ ] Test and release → Closed testing → Create release → Add from library → the build tested in section 3
- [ ] Countries: the United Kingdom, Bulgaria and wherever else the testers are
- [ ] Testers: an email list with every Gmail; copy the join link
- [ ] Settings → License testing: the same Gmails, so nobody pays real money for YumSum Star
- [ ] Send for review. Google checks the first closed release, which takes a few days; the temporary name `com.bpetrov.yumsum (unreviewed)` goes then
- [ ] Once approved: send the message below
- [ ] Claude, as each tester joins: a YumSum Star grant that ends by itself after 3 weeks (`expiresAt`)
- [ ] 12 or more opted in for 14 days in a row, with a nudge on days 5 and 10
- [ ] Watch Crashlytics and the inbox. Fixes go up as new builds, which keep the clock running

> Hi, I've made a calorie tracking app called YumSum and need Android testers for Google Play. Here's the link: [join link]. Tap "Become a tester", then "Download it on Google Play" and install it. Please keep it installed and stay in the test for 14 days. Use it now and then, log a meal or two, and tell me anything that's broken or confusing (there's a Send feedback button in Settings). Thank you!

## 5. The rest Play needs before the public launch

Billing can be set up while the 14 days run. The clicks are in plan 07, "Steps for you".

- [ ] Decide which address and phone number the public sees. The payments profile and trader status both show them
- [ ] Trader status, on Play Console's home page (by February 2027, and before YumSum Star is sold)
- [ ] Payments profile
- [ ] Google Cloud: turn on the Google Play Android Developer API, and make the Pub/Sub topic `play-billing` with Play's publisher account
- [ ] The subscription `yumsum_plus`: monthly £3.99, yearly £29.99, 7 days free on each
- [ ] The functions' service account invited in Play Console; real-time notifications on
- [ ] Buy it with a test card on the phone, with Claude: the checklist in plan 07, "Testing"
- [ ] Two or three testers try buying it with test cards
- [ ] The Bulgarian store listing (texts in plan 14)
- [ ] Firebase → Authentication → Settings: email enumeration protection is on
- [ ] After the 14 days: Dashboard → **Apply for production**. Claude drafts the answers from the testers' feedback and the fixes
- [ ] Production release: 20% first, then everyone after a few quiet days
- [ ] Once nearly all requests pass App Check: enforce it for Firestore and Authentication

## 6. Features and ideas

Nothing here is agreed. Each one is talked through before any code.

- [ ] Adaptive formula: show the pace you're really on beside the one you chose (talked about on 13 Nov). Other ideas from that talk: let a cut go past the fast pace's floor, cap a big gap instead of ignoring it, show the measured burn
- [ ] `docs/adaptive-formula-explained.md`: correct its "Your own numbers" section, then commit it
- [ ] A YumSum page for the email links (new password, email confirmed) at yumsum.app/account, instead of Firebase's grey one
- [ ] A landing page at yumsum.app, with www.yumsum.app redirecting to it
- [ ] Google's sign-in screen showing YumSum's name and links (Search Console, then Google Cloud's Branding page)
- [ ] iPhone: TestFlight for the helpers on iOS
- [ ] Find out why about 15 AI requests went out in 15 seconds on 10 Nov: repeated taps, or the app retrying
- [ ] Open Food Facts: contribute a real product from the phone and check its page
- [ ] Recipes: read through the 40 and change what you'd cook differently
- [ ] Recheck the UK subscription rules in December (plan 07, Risks)
- [ ] Android build: move to built-in Kotlin once the plugins support it (after the closed test)

## Queue

Side mentions, newest last, each with its date. They move into a section when we next plan.

- Nothing yet.

## Good to know

- A debug build reinstalled on the phone gets a new App Check debug token. Until it's registered in Firebase, the AI says "Could not estimate calories".
- Debug tools' pretend YumSum Star never reaches the server. Macros and photo logging need a real grant on the account.
- The Gemini spend cap is £10 a month.
