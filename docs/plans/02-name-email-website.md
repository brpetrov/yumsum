# Plan 2: Name, email and website

*Written 23 October 2026, from registry, trade mark and provider checks made that day. Prices change, so check them again before paying.*

The app currently uses your personal Gmail in five places and Firebase's default web address. Before a public launch it needs its own identity: a name you can keep, a domain, an email address and a small website. **Do these steps in order.** The name comes first, because every later step uses it.

## Step 0: decide the name (do this first)

On 23 October 2026 the research found **two other products called LeanStreak, both in the same niche:**

| Who | What | Since |
|---|---|---|
| **leanstreak.co.uk** | A live UK fat-loss meal-plan app: calorie and protein targets, recipes, streaks. Free for 7 days, then £1.99 a month. | Domain registered 23 Sep 2026 |
| **getleanstreak.com** and **leanstreak.ai** | A calorie, macro and voice-logging app "coming soon to iPhone", with @leanstreak social accounts | Both registered 27 Sep 2026 |

Also, **leanstreak.com** is parked and for sale at $2,995, and **leanstreak.app** is registered and parked at GoDaddy. Neither the App Store nor Google Play had a LeanStreak app yet.

The UK one matters most. It's trading in the UK, in your category, under the same name. If it registers "LeanStreak" as a UK trade mark (which costs from £205), it could ask you to stop using the name after you've built a following. Even without a trade mark, two same-name apps confuse people in store searches.

**My recommendation: rename now, while it costs nothing.** No store listing, domain or users depend on the name yet.

How to choose:
1. Write down 5–10 candidates. Aim for short, easy to say, and not built on "lean", "macro" or "cal", which are crowded. Something that hints at simplicity or protein would suit the app.
2. For each candidate, check:
   - the **UK IPO** search: <https://trademarks.ipo.gov.uk/ipo-tmtext/start>
   - **TMview**, which covers the UK, EU and US: <https://www.tmdn.org/tmview/>
   - **Google Play** and the **App Store**, by searching for the name
   - **domain availability** at a registrar (step 1)

   Automated checks of the UK IPO and TMview were blocked, so these two need doing by hand. The US register had no "LeanStreak" mark.
3. Pick the one that's clear everywhere.
4. Optional: register it as a UK trade mark, **£205 for one class**. Software is class 9 and online services are class 42; each extra class is £60. It takes about 3–4 months. That's worth doing once the app has users, not before.

The rest of this plan says "yourname" for whatever you choose.

## Step 1: buy the domain

- **Where:** Cloudflare Registrar sells at cost and also gives you free DNS and email forwarding. Porkbun is similar and simple.
- **Which ending:**

  | Ending | About | Note |
  |---|---|---|
  | `.com` | $10.50 a year | The safest choice |
  | `.uk` | $5.30 a year | Cheapest, and fits a UK developer |
  | `.app` | $8.20 the first year, then $14.20 | HTTPS only, which works fine with Firebase Hosting |

- Avoid premium-priced names, and check the renewal price as well as the first-year price.
- **Cost:** £5–£12 a year.

## Step 2: email

You'll want a few addresses on one inbox:
- `hello@yourname…` for the store listing and people writing in
- `support@` and `privacy@` as aliases of it
- `noreply@` for Firebase's sign-in emails

| Option | Cost | Good | Bad |
|---|---|---|---|
| **Zoho Mail Free** | £0 | Your own domain, up to 5 users, web and phone app | No IMAP (no Outlook or Apple Mail); only offered in some regions |
| **Zoho Mail Lite** | About £1 a user a month | IMAP, 5–10 GB | Small storage |
| **Google Workspace Business Starter** | £5.90 a user a month (annual plan, before VAT) | Gmail as you know it, best deliverability | Costs the most |
| ~~Cloudflare forwarding + Gmail "Send mail as"~~ | £0 | — | Google is ending "Send as" for third-party addresses in **January 2027**, so don't build on it |

**My suggestion:** start on Zoho Mail Free, and move to Workspace if the app grows. Use the new address for:
- the Play Console developer email
- the Firebase project's support email
- the Open Food Facts account (Plan 1)
- the app's Send feedback link

## Step 3: DNS records for the email

Your email provider gives you the exact values. In outline:

1. **MX records**, which say where mail for the domain goes.
2. **One SPF record** (`v=spf1 include:… -all`). A domain may only have one, so the mail provider and Firebase (step 5) go into the same record.
3. **DKIM**, a signing key from the mail provider.
4. **DMARC.** Start with `v=DMARC1; p=none; rua=mailto:dmarc@yourname…`, then tighten it later.

Gmail rejects or spams mail from domains without SPF or DKIM.

## Step 4: the website

This uses Firebase Hosting, which you already have. Custom domains and SSL certificates are free.

1. In the Firebase console: **Hosting → Add custom domain** and enter `yourname…`.
2. Add the **TXT** record it shows, and keep it for good, because it's also used to renew the certificate. Then add the **A** records it shows.
3. Wait for the certificate. It's usually a few hours, at most 24.
4. Add `www` with the option to redirect it to the main domain.

What the site should hold:

| Address | What |
|---|---|
| `/` | A simple, light **landing page**: what the app does, 3–4 screenshots, the Google Play badge, a contact address. It doesn't need the Flutter app. |
| `/privacy`, `/terms` | Already exist |
| `/delete-account` | **Required by Google Play** for apps with accounts: how to delete your account, both in the app and by emailing privacy@ |
| `/app` | The web version of the app, already built there |

**Keep the landing page light.** On the free plan Firebase Hosting allows 360 MB of transfer a day. A first visit to the web app downloads about 3 MB, so roughly 110–120 first visits a day fit; returning visitors use their browser cache. A plain HTML landing page is a few hundred KB, so most visitors never load the app.

## Step 5: sign-in emails from your domain

Verification and password-reset emails currently come from Firebase's address.

1. Firebase console → **Authentication → Templates** → edit a template → **Customize domain**.
2. Enter `yourname…` and add the TXT and CNAME records it shows. Merge the SPF part into your one SPF record.
3. Wait for **Verification complete** (up to 24 hours), then **Apply custom domain**.
4. Optional: change the **action URL** so links read `https://yourname…/__/auth/action`.

On the free plan you can send 1,000 verification emails a day and 150 password resets.

## Step 6: Google sign-in branding

For Google's sign-in screen to show your app's name and logo, Google verifies the brand:
- the homepage must be on a domain you've verified in **Google Search Console**
- it must describe the app, not just be a login page
- it must link to the same privacy policy as the consent screen

It usually takes 2–3 working days after you submit. This happens in Google Cloud console → **APIs & Services → OAuth consent screen**.

## Step 7: update the app

Once the domain and email exist, I'll change:
- `LegalLinks` (privacy, terms and feedback) in `lib/core/constants/legal_links.dart`
- the feedback `mailto:` address (currently your Gmail)
- the Open Food Facts User-Agent in `food_lookup_service.dart` and `food_contribution_service.dart` (currently your Gmail, sent with every lookup)
- the contact address on the privacy page and terms
- the app name everywhere, if you renamed it: the store title, the app label and icon text, the web title and the legal pages. The Android package ID `com.bpetrov.leanstreak` can stay, because users never see it.

## Step 8: Google Play developer account

- **Account type:** personal. An organisation account needs a D-U-N-S number or a company; a nutrition tracker doesn't need one.
- **Cost:** **$25 once.** You'll need ID and a card in your legal name, and Play will check you own an Android phone through the Play Console app.
- **What the public sees:** your **legal name, country and developer email**. If you start charging money through Play, your **full address** too. That's one reason to think about the business address question in Plan 3 before monetising.
- **Before Production:** a **closed test with at least 12 testers, opted in for 14 days in a row**. Line up friends, family and gym mates early.
- **Forms to complete:**
  - the Health apps declaration (Health & fitness → Nutrition and weight management)
  - Data safety
  - the privacy policy URL
  - the account-deletion URL (step 4)
  - content rating
- **Store text:** say plainly that it's "not a medical device and does not diagnose, treat, cure or prevent any medical condition", as Play requires for health apps.

## Costs at a glance (first year)

| Item | Cost |
|---|---|
| Name and trade mark search | £0 |
| Domain | £5–£12 |
| Email (Zoho Free) | £0, or Workspace at about £71 a year |
| Website and SSL (Firebase) | £0 |
| Google Play account | $25 (about £19) once |
| UK trade mark (optional, later) | £205 for one class |
| **Minimum total** | **About £25–£31** |

## Checklist

- [ ] Shortlist names; check the UK IPO, TMview, the stores and domains; pick one
- [ ] Buy the domain
- [ ] Set up email (Zoho Free) with hello@, support@, privacy@ and noreply@
- [ ] Add the MX, SPF, DKIM and DMARC records
- [ ] Connect the domain to Firebase Hosting; add www and the redirect
- [ ] Build the landing page and `/delete-account`; I can write both
- [ ] Switch Firebase Auth emails to the domain
- [ ] Verify the domain in Search Console; submit OAuth branding
- [ ] I update the links, emails and name in the app
- [ ] Create the Play Console account; recruit 12 testers; start the closed test

## Sources

- Domain records: RDAP lookups via <https://rdap.org> (23 Oct 2026); the two sites <https://leanstreak.co.uk> and <https://getleanstreak.com>
- UK trade marks: <https://www.gov.uk/how-to-register-a-trade-mark>
- Cloudflare Registrar: <https://developers.cloudflare.com/registrar/faq/>
- Porkbun prices: <https://porkbun.com/products/domains>
- Google Workspace UK pricing: <https://workspace.google.com/intl/en_uk/pricing.html>
- Zoho Mail pricing: <https://www.zoho.com/mail/zohomail-pricing.html>
- Gmail "Send as" ending: <https://support.google.com/mail/answer/22370>
- Gmail's rules for senders: <https://support.google.com/a/answer/81126>
- Firebase Hosting custom domain: <https://firebase.google.com/docs/hosting/custom-domain>
- Firebase pricing and limits: <https://firebase.google.com/pricing>
- Firebase Auth custom email domain: <https://firebase.google.com/docs/auth/email-custom-domain>
- Firebase Auth limits: <https://firebase.google.com/docs/auth/limits>
- Google brand verification: <https://support.google.com/cloud/answer/13464321>
- Play developer account and public details: <https://support.google.com/googleplay/android-developer/answer/13628312>
- Play testing requirements (12 testers, 14 days): <https://support.google.com/googleplay/android-developer/answer/14151465>
- Play user-data and privacy-policy rules: <https://support.google.com/googleplay/android-developer/answer/10144311>
- Play health apps declaration: <https://support.google.com/googleplay/android-developer/answer/14738291>
