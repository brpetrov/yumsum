# Plan 8: Adaptive formula

*Written 2 November 2026. Status: planned, not built. A YumSum Star feature (plan 06), with a free weight trend line that can ship first. Every number below is a starting value. It was checked in a simulation of the rules (noisy daily weights, your own plan, and each bad case in the table), and gets tuned with your real data.*

## The short version

1. **Your target = your plan + a personal adjustment.** The formula stays exactly as it is. The Adaptive formula adds one number, for example −80 kcal a day, learnt from your weigh-ins and the food you log.
2. **It only changes your target on Mondays.** It looks back over the last 3 to 6 weeks (never older) and asks: given what you actually ate, did your weight do what the formula predicted? If yes, nothing changes. If not, the formula has your burn wrong, so it corrects it. Eating over target isn't punished; it's counted.
3. **It moves in small, careful steps.** Each move is at most 5% of your plan, and it can never move more than 15% in total. A cut needs two Mondays in a row agreeing; a raise needs one. Your minimum (1,500 kcal for men, 1,200 for women) never changes. At the minimum, your goal date moves later instead.
4. **Bad data can't push it around.** One heavy weigh-in is one dot on a line. A typo is set aside. Half-logged days are left out, and so are breaks in logging. With too little data it changes nothing and says why.
5. **Weigh-ins are the fuel.** It needs at least 3 a week, and daily is best. With weekly weigh-ins it never acts, and it says so.
6. **Free users get the weight trend line** on Weight & Progress. It can ship on its own, first.

## How a good coach adjusts calories

A good coach starts you on an estimate, the same kind of formula YumSum uses. Then they watch, and they:

- **Look at the trend, not single days.** Weight jumps 1–2 kg overnight with salt, carbohydrate, a big meal or a period. Fat doesn't.
- **Compare the trend with what you ate.** If you ate 1,830 a day and lost 0.4 kg a week, your body burned about 2,270. That number is the truth about you. The formula was a guess.
- **Wait for 2–4 weeks of data** before changing anything, and change in small steps, about 100 kcal.
- **Cut slowly and raise quickly.** Cutting someone who is already in a deficit risks hunger, lost muscle and giving up. A raise is low risk.
- **Never go below a safe minimum.** If the numbers say "eat less" at the minimum, the coach says "it'll take longer".
- **Ask about the odd week:** a holiday, illness, starting creatine, a new diet's early water loss.
- **Don't judge.** Eating over target isn't a reason to cut your target. It's part of the sum.

The Adaptive formula does each of these, the same way, every Monday:

| A coach… | The Adaptive formula… |
|---|---|
| looks at the trend | fits a straight line through 3–6 weeks of weigh-ins |
| compares it with what you ate | works out your **measured burn** from your logged food and that line |
| waits for enough data | needs 3 weeks, 8 weigh-ins and 4 logged days a week before it acts |
| makes small changes | moves at most 5% of your plan a week, and 15% in all |
| cuts slowly | needs two Mondays in a row to cut, one to raise |
| keeps a minimum | never goes below 1,500 (men), 1,200 (women) or 1,350 (other); the goal date moves instead |
| asks about odd weeks | leaves out half-logged days, breaks in logging, typos, a new account's first 2 weeks and creatine's first 4 |
| doesn't judge | uses what you actually ate, whatever your target was |

## The minimums are right

The formula's floors (`HealthCalculator.calorieFloor`: male 1,500, female 1,200, other 1,350) match the standard advice. Harvard Health: *"calorie intake should not fall below 1,200 a day in women or 1,500 a day in men, except under the supervision of a health professional."* 1,350 for Other is the midpoint. The Adaptive formula never goes below them.

## The algorithm

It runs on the phone: no server, no AI, no cost. All of it is one pure calculator, so every rule can be tested without Firebase.

### What it reads

- **Weigh-ins:** every `WeightEntry` (one per day, `weightKg`).
- **Logged days:** the `DailySummary` documents for the window (`totalCalories`, `targetCalories`). A day with no summary had no meals logged, because `DailySummaryService.recomputeForDate` deletes the summary of a day with no meals. Days off are real eating, so they count like any other day.
- **The profile:** height, age, gender, movement, training, pace, the current adjustment and the adaptive fields below.

### Step 1: the window

On Monday it looks at days up to Sunday. The window starts at the **latest** of:
- 42 days before Monday (6 weeks; nothing older is ever used)
- 14 days after the account was created (`createdAt`): a new diet loses 1–2 kg of water and stored carbohydrate (glycogen) in its first days, which isn't fat and would look like a huge burn
- `adaptiveFrom`, when set (after a change of details in Plan Settings, or turning on the creatine reminder; see the table)
- the first day with anything logged

Its length, from that start to Sunday, is **L days**.

### Step 2: which days count

- A day **counts** if it has a summary and its calories are at least **60% of that day's target** (`totalCalories ≥ 0.6 × targetCalories`).
- A day under 60% is **left out** as probably half-logged. One such day in a 4-week window moves the average by about 30 kcal, so the rule matters only when it happens often. Leaving out a genuinely low day (illness, a fast) raises the measured burn a little, which errs towards a higher target, the safe side.
- **High days always count.** People don't log food they didn't eat.
- **A break** is 3 or more days in a row with nothing logged. Nobody knows what was eaten then, so the weight change across the break is left out too (step 4).

### Step 3: which weigh-ins count (the trend and the typo rule)

The **trend** is your weight without the daily ups and downs: an exponentially smoothed average, the one The Hacker's Diet uses (smoothing constant 0.9, so each day's weigh-in moves the trend 10% of the way towards it). With gaps between weigh-ins:

> trend = trend + (1 − 0.9^g) × (weigh-in − trend), where g = days since the last counted weigh-in

The first weigh-in starts the trend. The free chart draws this same line.

**The typo rule:** a weigh-in more than **3% away from the trend** (2.4 kg at 80 kg) is **set aside**. If the next weigh-in is also more than 3% away, on the same side, both count and the trend moves: it was real (back from a holiday, or a new scale). Otherwise the set-aside one is ignored for good. If it's the latest weigh-in, it waits for the next one. The rule runs over all your weigh-ins, but only weigh-ins inside the window are used for learning.

### Step 4: how fast your weight is changing

It fits the **straight line that best fits the counted weigh-ins** in the window (least squares). Its slope is your rate of change, in kg a day.

A break (step 2) splits the window into stretches. Each stretch gets its own starting level but they share one slope, and weigh-ins on break days aren't used:

> slope = Σ (t − t̄ₛ)(w − w̄ₛ) ÷ Σ (t − t̄ₛ)²

Here t is the day, w the weight, and t̄ₛ, w̄ₛ the average day and weight of that weigh-in's stretch. With no breaks, this is the ordinary line of best fit. A stretch needs 2 weigh-ins to count.

**Scatter** is how far the weigh-ins sit from the line: the square root of the average squared distance, as a percentage of your average weight.

### Step 5: the measurement

> **measured burn** = average calories on the days that count − slope × 7,700
>
> **formula burn** = the formula's maintenance (`HealthCalculator.tdee` of `bmr` at the average counted weight, with your movement and training)
>
> **gap** = measured burn − formula burn

Losing makes the slope negative, so the loss adds to the burn. Losing 0.4 kg a week is 0.4 × 7,700 ÷ 7 = 440 kcal a day from your body's stores. 7,700 kcal a kg is the number the plan itself uses (pace × 1,100 a day = pace × 7,700 ÷ 7). Using the same number means the corrected plan delivers the loss it promises, by its own maths.

The formula burn is worked out at the average weight of the window, not your latest weigh-in, so it compares like with like (the plan drops about 15 kcal a day per kg lost, as it does today).

### Step 6: enough data to act?

Checked in this order. The first that applies is that Monday's result, and the target stays the same:

| Check | Needs | Otherwise |
|---|---|---|
| Recent weigh-in | a weigh-in in the last 10 days | **Paused** |
| Enough weeks | L ≥ 21 days (3 weeks) | **Learning** |
| Enough weigh-ins | 8 or more counted, spanning 14 days or more, and 2 or more in the finished week | **Not enough weigh-ins** |
| Enough logging | days that count ≥ 4/7 of L (the "logged enough" rule `PeriodReviewService` uses), and 4 or more in the finished week | **Not enough days logged** |

### Step 7: confidence

Four marks, each from 0 to 1, multiplied together:

| Mark | Formula | Meaning |
|---|---|---|
| **Weigh-ins (W)** | weigh-ins a week ÷ 4, at most 1 | 4 or more a week is full marks; 3 a week 0.75; 2 a week 0.5 |
| **Days logged (D)** | days that count ÷ L | logging every day is 1; 5 days in 7 is 0.71 |
| **Steadiness (S)** | 0.5% ÷ scatter, at most 1 | weigh-ins within 0.5% of the line (0.4 kg at 80 kg) are full marks; twice as scattered, half marks |
| **Weeks (T)** | (L ÷ 7 − 1) ÷ 5 | 3 weeks 0.4, 4 weeks 0.6, 5 weeks 0.8, 6 weeks 1.0 |

> **confidence = W × D × S × T**

For example, someone weighing every morning, logging every day, with weigh-ins 0.4 kg either side of the line, scores 0.4 after 3 weeks, 0.6 after 4 and 1.0 after 6. Someone weighing 3 times a week with 2 unlogged days a week scores 0.75 × 0.71 = 0.53 of that. In the simulation, typical real-life scatter put a daily weigher at about 0.4, 0.55, 0.7 and 0.85 in weeks 3 to 6.

### Step 8: the Monday decision

1. **Aim** = gap × confidence, rounded towards zero to the nearest 10 kcal. If it's 60% sure, it aims for 60% of the gap. It re-measures every Monday, so the aim grows as confidence does, and it settles gradually.
2. **Unusual:** if the aim is more than **20% of the plan target**, it doesn't believe the data. The target stays and Today says the numbers look unusual.
3. **Total limit:** the aim is held within **±15% of the plan target**. The formula is rarely off by more for one person.
4. **Dead band:** if the aim is within **50 kcal** of the current adjustment, nothing changes.
5. **Step** = aim − current adjustment, at most **5% of the plan target** (rounded down to 10 kcal: 80 for a 1,670 plan).
6. **Raise** (step above 0): made now.
7. **Cut** (step below 0): made only if **last Monday also wanted a cut**, meaning last Monday's result was "first sign" or "lowered", 7 days earlier. Otherwise this Monday is the **first sign**: nothing changes, and it checks again next Monday.

A missed Monday (the app not opened all week) breaks the chain, so a cut waits again. Only the latest week is ever processed; missed weeks aren't caught up.

**It never plans a faster loss than the pace you chose** (decided 2 November). A cut only brings your real loss back to that pace, at most 0.75 kg a week on the fast plan; it never deepens the deficit beyond it. If you lose faster than your pace, the target goes up (a raise, made the same Monday), and Today says so: "You're losing faster than your plan, so your target goes up a little."

### Step 9: the target and the goal date

The adjustment corrects the formula's burn, so it's applied inside `calculatePlan`, before the minimum:

> target = the higher of the minimum and (formula burn + adjustment − pace × 1,100)
>
> pace actually planned = (formula burn + adjustment − target) ÷ 1,100 kg a week
>
> goal date = from your current weight at that pace, as today

Away from the minimum, this is simply **plan target + adjustment**, and the goal date doesn't move: the formula was wrong about your burn, not about the pace you chose. Only at the minimum does the pace drop, so **the goal date moves later**, and Today says so. Maintain works the same way: the target is maintenance + adjustment, and a cut never takes it below the minimum.

### The numbers in one place

| Setting | Starting value |
|---|---|
| Trend smoothing | 0.9 (10% a day towards each weigh-in) |
| Typo rule | 3% from the trend, confirmed by the next weigh-in |
| Window | 21 to 42 days, ending Sunday |
| New account left out | first 14 days |
| Creatine left out | 28 days from turning the reminder on |
| Half-logged day | under 60% of that day's target |
| Break | 3 or more days in a row with nothing logged |
| Minimum data | 8 weigh-ins over 14 days, 2 in the finished week; 4/7 of days counting, 4 in the finished week |
| Paused | no weigh-in for 10 days |
| Confidence | W × D × S × T, with full marks at 4 weigh-ins a week, every day logged, 0.5% scatter and 6 weeks |
| Dead band | 50 kcal |
| Step limit | 5% of the plan target a week |
| Total limit | 15% of the plan target |
| Unusual | aim over 20% of the plan target |
| Cut | two Mondays in a row; raise, one |
| kcal per kg | 7,700 |

## What goes wrong, and what it does

"Simulated" means the rules were run on made-up but realistic data: daily weight scatter of about 0.5 kg, intake varying by 250 kcal a day, 200 runs per case.

| What goes wrong | What it does |
|---|---|
| **One heavy weigh-in** (salty takeaway, +1.5 kg) | It's one dot among 20 or more on a straight line. It moves the measure by a few kcal, inside the dead band. |
| **A typo** (97.8 for 79.8) | More than 3% from the trend, so set aside unless the next weigh-in agrees. Simulated: same result as without it. A small slip under 3% (2.2 kg) moved the measure by up to 60 kcal for one week and changed nothing. The typo still changes the plan's own target until deleted, as it does today (see Later). |
| **Saving the pre-filled weight without changing it** | One dot, as above. |
| **Weighing in pounds by mistake** | The first is set aside. If the following ones are also in pounds, the jump is huge and the result is "unusual". |
| **A forgotten meal, day well under 60%** | Left out. |
| **A forgotten dinner that still clears 60%** | Counted. Once a week, it looks like logging about 120 kcal a day low, and is treated as under-logging (next row). |
| **Logging everything 10% low** | It lowers the target until the planned loss happens. Simulated (man, 2,240 plan, 0.5 kg a week): without it he loses 0.27 kg a week; with it, 0.47. |
| **A genuinely low day** (ill, fasting) | Left out. This errs towards a slightly higher target. |
| **Big days** (birthday, weekends) | Counted, always. Being over target is never punished: it's in the sum. |
| **Big weekends**, +1.2 kg of water every other Saturday | Simulated: no effect. |
| **Not enough weigh-ins or logging** | No change. Today says why. |
| **Weekly weigh-ins only** | Never acts ("Not enough weigh-ins this week"). One a week over 6 weeks leaves the burn uncertain by about ±180 kcal (worked out for 0.7 kg of day-to-day scatter), too rough to act on. |
| **No weigh-in for 10 days** | Paused. Today says so until the next weigh-in. |
| **A holiday**: 2 weeks with no logging or weighing, eating 1,000 kcal a day more | The break and the weight jump across it are left out. Simulated: no change. Without the break rule it would have cut by up to 160 kcal for about 3 weeks. |
| **Ill for a week** (eats little, loses 1.5 kg of water, regains it) | The low days are left out. Simulated: no meaningful change. |
| **Periods** (about ±0.8 kg of water over the month) | Spread across a 3–6 week line. Simulated: no worse than without. Two Mondays are needed to cut. |
| **Starting creatine** (extra water in the muscles: about 0.5–1 litre with a loading dose, by the ISSN's figure; over about 4 weeks at 3 g a day) | With the creatine reminder turned on, the next 28 days are left out. Without it, the water looks like slower loss. Simulated: 1 kg over 4 weeks cut step by step to −240 over 3 weeks, then went back over the next 4. 1.5 kg in one loading week cut 80, said "unusual" twice, then went back. The minimum still holds. |
| **A new diet's first days** (water and glycogen loss) | A new account's first 14 days are left out. Simulated without that rule: a wrong raise of 80 kcal for 5 weeks. |
| **Beginners gaining muscle while losing fat** (weight flat) | It can't tell muscle from fat, so it reads this as a lower burn and may cut. The caps, two-Monday rule and minimum limit it. The How it works dialog doesn't promise otherwise. |
| **The formula is right, but weigh-ins bounce** | It wanders a little. Simulated: after 10 weeks, the adjustment sat between about −70 and +90 in 8 runs out of 10 (median 0). 80 kcal is 0.07 kg a week. |
| **Changing details or activity in Plan Settings** | The adjustment goes back to 0 and learning starts again from that day, so it never double-counts a correction or fights a real change (e.g. starting to train). |
| **Deleting a weigh-in** | It isn't in the data next Monday. |
| **Reset progress or Reset all data** | The adjustment goes back to 0: the data it learnt from is gone. |
| **Two phones** | Both compute the same result from the same data. Whichever runs first records the week, and the other sees it's done. |
| **First open of the week on a phone with an empty offline cache** | It finds too little data, so no change that week. That's the safe side. |
| **Maintain mode** | Works the same and keeps your weight steady. Simulated: someone burning 200 less than the formula reached −210 and stopped gaining. |
| **Switching it off, then on** | Off: back to the plain plan at once. On: starts fresh at 0, learning from the recent weeks already logged. |
| **YumSum Star ends** | Frozen for 2 weeks, then back to the plain plan (see What you see). |
| **"2,000 to 1,500 after one weigh-in"** | Impossible; see below. |

## Your plan, week by week

Your plan: male, 29, 170 cm, 79.8 kg, goal 73 kg at the faster pace (0.75 kg a week). The formula's resting burn (BMR) is about **1,720**, and your movement and training multiply it by 1.45: a **formula burn of 2,495**. 2,495 − 825 (0.75 × 1,100) gives your **target of 1,670** and a goal date of **4 January 2027**.

You eat about **1,830** a day, 160 over. At 1,830 the formula predicts a deficit of 665 a day: **about 0.6 kg a week**.

These tables assume you weigh in every morning, log every day, keep eating 1,830, and start on Monday 2 November. Real weigh-ins bounce, so the steps then come out a little smaller and a week later at times. Two things change every week even without the Adaptive formula, as they do today:
- your plan's target drops about 15 kcal per kg you lose
- your goal date moves later whenever you lose slower than your chosen pace, because each weigh-in re-plans from your new weight

**(a) You lose about 0.6 kg a week: the formula is right about you.**

| Monday | Result | Target | Goal date |
|---|---|---|---|
| 9 and 16 Nov | Learning | 1,662, 1,654 | 7 and 9 Jan |
| 23 Nov onwards | "No change this week: your weight matches what you eat." | 1,645 → 1,620 by 14 Dec → 1,604 by 28 Dec | 10 Jan → 15 Jan → 19 Jan |

The gap comes out within 5 kcal of 0, every week. Nothing changes. The goal just lands later, about 19 January instead of 4 January, because of the extra 160 a day: 6.8 kg at 0.6 kg a week instead of 0.75.

**(b) You lose about 0.4 kg a week: you burn about 225 less than the formula thinks.**

Measured burn = 1,830 + 0.4 × 1,100 = 2,270. Gap = 2,270 − 2,495 = **−225**.

| Monday | Weeks of data | Confidence | Aim | What happens | Target | Goal date |
|---|---|---|---|---|---|---|
| 9 Nov | 1 | – | – | Learning | 1,665 | 9 Jan |
| 16 Nov | 2 | – | – | Learning | 1,660 | 12 Jan |
| 23 Nov | 3 | 0.4 | −90 | **First sign:** waits a week | 1,654 | 16 Jan |
| 30 Nov | 4 | 0.6 | −130 | Lowered by **80** (the 5% limit): adjustment −80 | **1,568** | 19 Jan |
| 7 Dec | 5 | 0.8 | −170 | Lowered by 80: adjustment −160. Plan 1,642 − 160 = 1,482, so the target stops at the **minimum** | **1,500** | 23 Jan |
| 14 Dec | 6 | 1.0 | −220 | Lowered by 60: adjustment −220. Still at the minimum, so the goal date moves instead | 1,500 | **30 Jan** (25 Jan without the adjustment) |
| 21 Dec | 6 | 1.0 | −220 | No change | 1,500 | 3 Feb |

From 7 December Today says: "Your target is at your minimum, so your goal date is now 23 January", and later dates as they move. With realistic bouncing weigh-ins, the simulation's typical path was −80 on 30 November, −80 on 7 December and −150 (the minimum) on 14 December.

**(c) You lose about 0.8 kg a week: you burn about 215 more.**

| Monday | What happens | Target |
|---|---|---|
| 23 Nov | Raised by 80 (one Monday is enough for a raise) | 1,718 |
| 30 Nov | Raised by 50 (aim +130) | 1,756 |
| 7 Dec | No change: the aim (+170) is within 50 of +130 | 1,745 |
| 14 Dec | Raised by 80: adjustment +210 | 1,814 |
| then | No change | follows your plan + 210 |

Eating 1,830 is now on target, and your goal date stays about 5 January.

**On your phone it can start sooner.** You already have weeks of meals. Once you weigh in most mornings, the first Monday that can act is the one where your weigh-ins span 14 days, with 8 or more of them: 16 or 23 November if you start weighing daily now.

**Why "2,000 to 1,500 after one weigh-in" can't happen.** Nothing changes except on a Monday. One weigh-in is one dot among at least 8. It needs 3 weeks of data first. A cut needs two Mondays. Each step is at most 5% (100 kcal for a 2,000 plan). And the total is at most 15%, so the lowest a 2,000 plan can ever go is **1,700**. The fastest path there is 1,900, 1,800, 1,700 on three Mondays in a row, after a first sign, with 6 weeks of consistent data behind it. A 500 kcal drop is beyond the limit, and the minimum stands under all of it.

## What you see

All copy follows the house rules: British English, sentence case, no "Please", no exclamation marks. Numbers are written as the app writes them elsewhere ("1670", no comma). Every Today line fits in two lines on a 360dp phone.

### Today

One muted line (12 px, like the "meals not counted" note) at the bottom of the target card (`_TodayCard`). It shows that week's Monday result from Monday to Sunday. It shows nothing for free users, while learning, or when switched off.

| When | Line |
|---|---|
| Lowered | Adjusted for you: −80 kcal. You burn a little less than your plan assumed. |
| Raised | Adjusted for you: +80 kcal. You burn a little more than your plan assumed. |
| First sign of a cut | You may burn a little less than your plan assumed. Checking again next Monday. |
| No change, adjusted before | Adjusted for you: −160 kcal. No change this week. |
| No change, never adjusted | No change this week: your weight matches what you eat. |
| At the minimum because of the adjustment | Your target is at your minimum, so your goal date is now 30 January. |
| Not enough weigh-ins | Not enough weigh-ins this week, so your target stays the same. |
| Not enough logging | Not enough days logged this week, so your target stays the same. |
| Unusual | Your numbers look unusual. Check your logging and weigh-ins. |
| Paused (any day, as soon as the last weigh-in is 10 days old) | Paused: no weigh-in for 10 days. Weigh in to keep it personal. |

The amount is the target minus the plan target, so it always matches Plan Settings. "You burn less" rather than "you're losing slower" keeps it about your body, not your eating, and works the same in maintain mode.

### Plan Settings

A new block under the pace cards, above the "Updated plan" preview: `SectionLabel('PERSONAL ADJUSTMENT')`, then a switch row.

- **Title:** Adaptive formula
- **Subtitle:** Learns from your weigh-ins and adjusts your target each Monday.
- **Free users:** the switch shows off, with the "+" mark plan 06 gives the photo button. Tapping the row opens the paywall (`showPlusPaywall(context)`, plan 07).
- **Subscribers:** on by default. It's part of the form, like Track protein, and is saved with Save plan.

Under it, for subscribers with it on:
- **The sum**, from the preview, so it follows the form as you edit:
  - "1670 from your plan − 80 adaptive = 1590 kcal"
  - at the minimum: "1642 from your plan − 142 adaptive = 1500 kcal, your minimum"
- **How well it knows you**, in plain stages, never a percentage:
  - "Learning: 11 weigh-ins, 13 days logged" (before it can act)
  - "Getting to know you: 21 weigh-ins and 21 days logged in 3 weeks" (confidence under 0.4)
  - "Knows you fairly well: …" (0.4 to 0.7)
  - "Knows you well: …" (0.7 or more)
  - "Paused: no weigh-in for 10 days."
- **When the form changes your details or activity:** "Saving starts it again from your new plan."
- **A "How it works" link** that opens the dialog below.

The preview card's info dialog (`_CalculationInfoDialog`) gets an "Adaptive" line, for example "−80 kcal/day", and the Target line includes it.

### How it works (once, after subscribing; again from the link)

A dialog with icon rows, like Day off's (`confirmDayOff`). Title: **How the Adaptive formula works**.
- (insights icon) Learns what you really burn from your weigh-ins and meals.
- (calendar icon) Changes your target on Mondays only, in small steps.
- (scale icon) Weigh in at least 3 times a week, daily is best, at the same time each morning.

Buttons: **Got it**, and **Remind me each morning** on phones when the weigh-in reminder isn't already daily. That sets the weigh-in reminder to every day at 07:30. Afterwards a snackbar says: "Weigh-in reminder on for 07:30 every day. Change it under Notifications in the menu."

### Notifications

The weekly weigh-in reminder becomes **Weigh-in reminder**. Its day list gains **Every day** at the top, and its subtitle reads "Every day at 07:30" or "Saturdays at 20:00". The free default stays Saturday 20:00.

### When YumSum Star ends

- The adjustment stays frozen for **2 weeks** from `Entitlement.endedAt` (plan 07: set when YumSum Star switches off, cleared when it comes back, and falling back to `expiresAt` once that has passed). No Monday steps run meanwhile.
- Play's grace period for failed payments keeps YumSum Star on, and with it the formula.
- Today shows a one-time dialog (only if the adjustment isn't 0), titled **Your YumSum Star has ended**: "Your target goes back to your standard plan on 15 November." Button: Got it.
- On that date the adjustment goes to 0 and the target returns to the formula. The switch shows off with the "+".
- Your own switch setting is kept, so subscribing again turns it back on, starting fresh.

### Paywall (plan 07 writes the screen)

Plan 07's draft line says the target adjusts "after 2 weeks of weigh-ins" and leaves the exact rule to this plan. By the rules above, it's 3 weeks. Suggested line: "Adaptive formula: learns what you really burn and adjusts your target each Monday. It starts after about 3 weeks of weigh-ins."

### Weight & Progress (free)

- The trend line becomes the chart's green line.
- The weigh-ins are the dots: hollow when set aside.
- A caption under the chart: "The line is your trend: your weight without the daily ups and downs."

## What gets built

Kept minimal, in the code's own style. In order, each tried on your phone before the next.

### 1. Trend line (free, ships alone)

- **New `lib/helpers/weight_trend.dart`:** `weightTrend(List<WeightEntry> entries)` returns, for each entry, the trend after it and whether it was set aside. It contains the smoothing and typo rules of step 3, with the constants `trendSmoothing = 0.9` and `setAsideShare = 0.03`.
- **`_WeightChartCard` in `lib/screens/progress/progress_screen.dart`:** today it draws the raw weigh-ins as one curved line. It becomes two `LineChartBarData`: the weigh-ins as dots with no line (hollow when set aside), and the trend as the green line with its wash, without dots. The caption goes underneath. The axis range includes both.

### 2. The profile and the plan

**`lib/models/user_profile.dart`:** six fields. `fromFirestore` reads each null-safely, because the plan numbers there are required and old profiles won't have these:

| Field | Type, default | Meaning |
|---|---|---|
| `adaptiveOn` | bool, `true` | your switch (it only acts with YumSum Star) |
| `adaptiveKcal` | int, `0` | the adjustment |
| `adaptiveWeek` | String?, yyyy-MM-dd | the Monday last processed |
| `adaptiveNote` | String? | that Monday's result: `learning`, `paused`, `few_weigh_ins`, `few_days`, `unusual`, `steady`, `first_sign`, `lowered`, `raised`, `off` |
| `adaptiveFrom` | String?, yyyy-MM-dd | learn nothing from before this day |
| `adaptiveChanges` | list of up to 6 `{week, from, to}`, `[]` | the last changes: the Monday and the target before and after. The AI weekly review reads the one made on the week it reviews (`09-ai-weekly-review.md`) |

- `toFirestore` writes the nullable ones only when set.
- `copyWith` uses `??`, so it can't set a field to null. The plan never needs to: switching off writes `adaptiveNote: 'off'` (which also breaks the two-Monday chain), and `adaptiveWeek` and `adaptiveFrom` only move forward. If clearing is ever needed, build the `UserProfile` directly.
- The pending "first Monday of a cut" needs no field of its own: it's `adaptiveNote == 'first_sign'` with `adaptiveWeek` one week back.

**`lib/helpers/health_calculator.dart`:**
- `calculatePlan` gains `double adaptiveKcal = 0` and applies it to the burn before the target and the minimum (step 9). `dailyCalorieTargetFromPace` and `effectivePaceKgPerWeek` get the adjusted burn.
- For maintain, a negative adjustment can't go below `calorieFloor`.
- `HealthPlanCalculation` gains `adaptiveKcal` and `planCalorieTarget` (the target without the adjustment, for the sum line). `tdee` stays the formula's.
- With 0, every result is identical to today's, so `currentPlanCalculationVersion` doesn't change.

**The writers.** Each one that recalculates passes `adaptiveKcal: profile.adaptiveKcal`; `copyWith` keeps the stored fields:
- `WeightLogService._replan` (logging, and deleting the newest weigh-in)
- `_migrateProfile` in `activityScaleMigrationProvider`
- `PlanSettingsScreen._preview`

Onboarding passes nothing.

**`ProfileController.saveProfile`** gains `adaptiveOn`:
- **Switched off:** adjustment 0, note `off`.
- **Movement, training, age, height or gender changed:** adjustment 0, `adaptiveFrom` today, note `learning`.
- **Otherwise:** keeps the adjustment.

**`firestore.rules`**, in the profile's `create, update`, which has no `hasOnly`:
```
&& request.resource.data.get('adaptiveOn', true) is bool
&& request.resource.data.get('adaptiveKcal', 0) is number
&& optionalDateKey(request.resource.data.get('adaptiveWeek', null))
&& optionalDateKey(request.resource.data.get('adaptiveFrom', null))
&& optionalText(request.resource.data.get('adaptiveNote', null), 20)
&& request.resource.data.get('adaptiveChanges', []) is list
&& request.resource.data.get('adaptiveChanges', []).size() <= 6
```
- Add `function optionalDateKey(value) { return value == null || dateKey(value); }`.
- Update the comment above the profile rule, which says only free-text fields are checked.
- Deploy with `firebase deploy --only firestore:rules` before the app that writes the fields.

### 3. The calculator

New **`lib/helpers/adaptive_formula.dart`**. It's pure: no Firebase, takes `now`, and holds every constant from "The numbers in one place".
- `AdaptiveNote` enum with `value` and `fromString`, like the model enums.
- `AdaptiveFormula.measure(...)`: given the profile, all weigh-ins, the window's summaries and the last day, it returns the counts, L, gap, confidence and stage (Paused, Learning or a confidence stage). Plan Settings uses it mid-week.
- `AdaptiveFormula.monday(...)`: runs `measure` for the finished week, then step 8. It returns the note, the new adjustment and the aim.

### 4. The Monday run

New **`lib/providers/adaptive_formula_provider.dart`**:

**`adaptiveMondayProvider`** is a `FutureProvider.autoDispose<void>`, watched in `LeanStreakApp.build` beside `activityScaleMigrationProvider` and following its pattern. On each run:
1. It returns early without a user or profile.
2. It awaits `plusProvider.future`, so a still-loading subscription is never read as "free".
3. **Not subscribed:** if `adaptiveKcal` isn't 0 and 14 days have passed since `Entitlement.endedAt` (awaited from `entitlementProvider`; or there's no end date), it re-plans with 0 and note `off`. Otherwise it does nothing (frozen).
4. **Subscribed with the switch off:** it does nothing.
5. **Already done:** if `adaptiveWeek` is this Monday, it returns. That makes it once a week, and safe across phones.
6. **Never run** (`adaptiveWeek` null, i.e. just subscribed or switched on): it records this Monday as `learning` and changes nothing, so the first change is always on a Monday.
7. Otherwise it reads the weigh-ins once (`watchEntries(uid).first`) and the summaries from Monday − 42 to Sunday (`fetchSummariesInRange`), and runs `AdaptiveFormula.monday`.
8. It recalculates the plan with the new adjustment, writes the profile with `createProfile` (plan fields, `adaptiveKcal`, `adaptiveWeek`, `adaptiveNote`, and, when the target moved, the change added to `adaptiveChanges`, keeping the newest 6) and calls `recomputeForDate` for today, as the migration does.
9. It prints one debug line, like the "AI tokens" one: `Adaptive: 2026-11-30 lowered, gap -226, confidence 0.60, aim -130, step -80, adjustment -80, target 1568 (28 weigh-ins, 28 days)`. In debug builds it also prints the window's data as JSON for the replay test (Tests, below).

It runs the first time the app opens on or after Monday. An app left open overnight runs it when the profile next changes, for example at the Monday weigh-in.

**Two more providers in the same file:**
- `adaptiveProgressProvider` (`FutureProvider.autoDispose`): `measure` up to yesterday, for Plan Settings.
- `adaptiveTodayLineProvider` (`Provider.autoDispose<String?>`): the Today line, from the profile, `plusProvider` and `latestWeightEntryProvider`.

### 5. Screens

- **`PlanSettingsScreen`:** the switch row and the lines under it.
  - `_seedForm` seeds `_adaptiveOn`, and `_submit` passes it.
  - For free users the switch only displays off, and the form passes the stored value back unchanged. So saving during the 2-week freeze doesn't end it early, and your setting survives a lapse.
  - `_preview` passes `adaptiveKcal`: 0 when switched off or when details or activity differ from the profile.
- **`HealthPlanPreviewCard`:** the "Adaptive" info line.
- **`DashboardScreen`:**
  - `_DashboardContent` passes the line to `_TodayCard`.
  - Two `listenManual` hooks show the How it works dialog (once, prefs `adaptive.intro_shown`, when `plusProvider` first becomes true) and the lapse dialog (once per end date, prefs `adaptive.lapse_notice`), as `_maybeOfferCreatine` does.
  - The dialogs live in `lib/screens/dashboard/helpers/adaptive_dialogs.dart`.

### 6. Reminders

- **`ReminderSettings.weeklyDay`** gains an "every day" value (0, as `ReminderSettings.everyDay`).
- **`NotificationService.scheduleWeeklyWeightReminder`** takes a `daily` flag:
  - daily uses `DateTimeComponents.time`, with the body "Log today's weight to keep your plan accurate."
  - weekly keeps `dayOfWeekAndTime`
- **`reminderSyncProvider`** passes it through, and the Notifications page shows the new option.
- **Creatine hook:** when `ReminderSettingsNotifier.setCreatine(true)` succeeds, it sets the profile's `adaptiveFrom` to 28 days later, unless that's already later (`copyWith` and `createProfile`). One place covers both the Today offer and the Notifications switch.

### 7. Resets

- **`AccountController.resetAllData`** and **`WeightLogController.resetHistory`** also re-plan with adjustment 0 and note `off`.
- After building, add an Adaptive formula bullet to CLAUDE.md's Key Domain Logic, and the new prefs keys to Device settings.

**Needs from plan 07, part A** (it can all be built and tried with a manual grant before billing exists):
- `plusProvider` and `entitlementProvider` with `Entitlement.endedAt`, in `lib/providers/plus_provider.dart`
- `showPlusPaywall(context)` in `lib/screens/plus/plus_screen.dart`

The "+" mark comes from plan 06.

## Tests

Tests never touch Firebase, as the house rule says. The calculator tests use a small seeded simulator in **`test/adaptive_fixtures.dart`**. It turns a scenario (true burn, intake, logging habit, weigh-in days, water events, seed) into `WeightEntry` and `DailySummary` lists day by day. It runs Mondays through `AdaptiveFormula.monday` and `calculatePlan`, and feeds each new target back into intake for people who eat to target. This is the simulation this plan was checked with, rewritten in Dart.

### `test/weight_trend_test.dart`

- Daily weigh-ins move the trend 10% a day.
- A 3-day gap moves it 1 − 0.9³ = 27.1%.
- 97.8 among 79.x is set aside, and the trend ignores it.
- 83.0 then 83.1 after 79.9 both count.
- A set-aside last weigh-in waits.

### `test/adaptive_formula_test.dart`

- **Your plan**, noiseless, daily weigh-ins at 1,830:
  - (a) always `steady`, adjustment 0
  - (b) learning, learning, `first_sign`, then −80, −160, −220; target 1,568 on 30 Nov, 1,500 from 7 Dec; goal date later than the same plan with 0
  - (c) +80, +130, steady, +210
- **Noisy daily weights**, formula right, 50 seeds, 10 weeks: the median adjustment is within ±40, and none passes 15%.
- **Logging 10% low, eating to target:** noiseless, the real loss over the last 4 of 14 weeks is within 0.05 kg a week of the plan; noisy, over 20 seeds, within 0.1. Logging honestly, the adjustment stays within ±50.
- **Forgotten-meal days:**
  - a day at 40% of target is left out (gap unchanged within 10 kcal)
  - a day at 65% counts
  - the 4/7 and 4-in-the-week minimums give `few_days`
- **Creatine:**
  - 1 kg over 4 weeks without the hook: never past −15%, back within ±60 of 0 within 8 weeks of the water settling
  - with `adaptiveFrom` set: no change at all
- **Typo:** 97.8 gives the same result as without it. A confirmed jump is used.
- **Holiday:** 14 unlogged, unweighed days at +1,000 kcal give no change. With breaks switched off in the test, it cuts, which proves the rule matters.
- **Weigh-in habits:**
  - daily gives more confidence than 3 a week at the same week
  - weekly gives `few_weigh_ins` every Monday
  - fewer than 2 in the finished week gives `few_weigh_ins`
- **Two Mondays:**
  - a first cut gives `first_sign` with no change
  - the next Monday gives `lowered`
  - a `steady` Monday in between, or a missed Monday, starts the chain again
  - raises happen at once
- **Limits:**
  - a step never exceeds 5% of the plan
  - the total never exceeds 15%
  - an aim over 20% gives `unusual` with no change
  - the dead band holds at 49 and moves at 50
- **Minimum and goal date:**
  - the target is never below `calorieFloor` for each gender
  - when the adjustment takes it there, the goal date is later than with 0
  - away from the minimum, the goal date equals the plain plan's
- **Windows:**
  - under 21 days gives `learning`
  - a new account's first 14 days aren't used
  - nothing older than 42 days is used (changing a 43-day-old weigh-in changes nothing)
  - `adaptiveFrom` is respected
- **Paused:** the last weigh-in 10 days ago gives `paused` with the adjustment unchanged.
- **Lapse:** with plus false and an end date of 1 November, on 10 November it's frozen with no Monday step, and on 15 November the adjustment is 0.

### `test/health_calculator_test.dart`

- With `adaptiveKcal: 0`, every existing case gives the same result.
- −80 lowers the target by 80 and keeps the goal date.
- At the minimum it's clamped and the date is later.
- In maintain mode, −100 never goes below the minimum.

### `test/weight_log_service_test.dart`

`_replan` keeps `adaptiveKcal` and applies it.

### Profile round trip

A `Fake implements DocumentSnapshot<Map<String, dynamic>>` with `data()` checks:
- an old profile without the fields gives the defaults
- `toFirestore` → `fromFirestore` keeps them

### Widget tests

These override `plusProvider` both ways and `entitlementProvider` with a ready-made `Entitlement` (as plan 07 describes), plus the providers the existing tests override.
- **Today:** each line in the table, at 360×640 with nothing overflowing; nothing for free users or while learning.
- **Plan Settings:**
  - a free user sees the switch off with "+", and tapping opens the paywall
  - a subscriber sees the sum and the learning line
  - switching off and saving passes `adaptiveOn: false`
  - changing training shows "Saving starts it again from your new plan."
- **Weight & Progress:** a free user sees two line series (dots and trend) and the caption.
- **Dialogs:** How it works shows once; "Remind me each morning" sets the daily reminder. The lapse dialog shows once.

### `test/adaptive_replay_test.dart`

Skipped unless `config/adaptive_replay.json` exists (add it to `.gitignore`). It feeds your real weigh-ins and days, copied from the debug log, through the calculator and prints what each past Monday would have done. That's how the starting values get tuned on your data.

## Trying it on yourself

**Before you start:**
- Grant yourself YumSum Star (plan 07's manual grant). The switch is on by default.
- Take "Remind me each morning" in the dialog.
- Weigh in every morning after the toilet, before eating, and log everything as usual.

**What to watch, week by week:**

| When | Expect | Check |
|---|---|---|
| Days 1–14 | Plan Settings: "Learning: N weigh-ins, M days logged", counting up each day. Today: no line, or "Not enough weigh-ins this week" if you skip. | The counts match your History and Weight & Progress. |
| First Monday that can act (16 or 23 Nov) | One line on Today. The debug log shows the gap and confidence. | By hand: (your average logged kcal + your kg lost a week × 1,100) − 2,495 should be close to the logged gap. |
| Weeks 4–6 | Changes of at most 80 a week. A cut always follows a "Checking again next Monday" week. At 1,500, the goal date moves. | The Plan Settings sum adds up. Today's number matches it. |
| Any time | Try the bad cases on purpose: type a wrong weight then delete it, skip logging a day, take a day off, delete a weigh-in. | Nothing jumps. Monday's result explains itself. |

**Signs something is wrong:**
- a change on any day but the first open on or after a Monday
- a change bigger than 80 kcal
- a cut without a first sign the Monday before
- a target under 1,500
- a sum that doesn't add up

Copy the debug log's JSON into the replay file and run it to see why.

**For the closed test:** in 14 days your testers will only see "Learning". That's honest, and the paywall line says it starts after about 3 weeks.

## Risks

- **It wanders a little even when the formula is right:** about ±80 kcal (0.07 kg a week) in simulation, because weigh-ins bounce. That's well inside the formula's own error for most people (Mifflin-St Jeor is within 10% of measured resting burn for most adults, not all).
- **It settles short of the full gap on purpose.** It aims for gap × confidence, and with real scatter confidence tops out around 0.85, so it corrects about 70–85% of the gap. Stepping by gap × confidence every week instead would in theory reach 100%. But it passes more of each week's noise through, and the raw gap crosses the limits more often. In simulation it ended further from the truth, both when the formula was right and when it was 225 off.
- **Creatine started without the reminder** cuts for a few weeks and then reverses (see the table).
- **Logging habits change.** If you start logging more fully, it reads that as a higher burn and raises within a week or two. A raise needs only one Monday.
- **People who weigh weekly never get it.** The paywall and the How it works dialog say weigh-ins are the fuel. Plan 06 already counts subscribers' weigh-ins as a health check.
- **A cut can feel like being told off.** The copy talks about your burn, never your eating.
- **Health.** It never goes below the minimum. Very low days are left out, which errs towards eating more. The medical note in Plan Settings still applies.

## Later

- **Re-plan from the trend weight, not the raw weigh-in.** A typo would then stop moving the plan's own target, and daily weigh-ins would stop nudging the target and the "New target" snackbar by a few kcal each day.
- **Show the trend weight** as "Current" on Weight & Progress.
- **Plan 09's AI weekly review** mentions Monday's change when there was one, as plan 06 says.
- **Judge half-logged days against your usual day** (the median of your logged days) instead of the target, if the replay shows forgotten dinners slipping through for people who eat well over target.
- **A server-side run** (a Cloud Function on Blaze), if two-phone or offline cases ever cause trouble.

## Decisions for you

These go beyond what we agreed on 1–2 November, or change it slightly:

1. **"Unusual" at 20%, limit at 15%.** You said past 15% it doesn't believe the data. In simulation, for someone whose real gap was −225 (your case (b)), a 15% trigger said "unusual" on about 1 Monday in 8 after the learning weeks; at 20%, about 1 in 30. So the adjustment stops at 15%, and only an aim past 20% is called unusual.
2. **It aims for gap × confidence**, re-measured each Monday, rather than stepping by gap × confidence each week. The first move is the same; later it stays steadier.
3. **Changing details or activity in Plan Settings restarts learning**, rather than keeping the adjustment. Otherwise the old correction double-counts, or fights a real change such as starting to train.
4. **The first 14 days of a new account are left out**, and **28 days after turning on the creatine reminder**. A brand-new subscriber's first change is then about 5 weeks in. Plan 06's trial section says it "only starts changing your target after two weeks", and plan 07's paywall draft says "after 2 weeks of weigh-ins". Both should say about 3 weeks of weigh-ins, and 5 for a new account.
5. **Reset progress and Reset all data put the adjustment back to 0.**
6. **The lapse notice is a one-time dialog**, as "Today says once" suggests, rather than a line for the 2 weeks.
7. **Today's wording is "You burn a little less than your plan assumed"**, not "You're losing a little slower than your plan expects". It's adherence-neutral and works in maintain mode.

## Checklist

- [ ] (you) Agree the decisions above, or change them
- [ ] (Claude) Step 1, the trend line (built 2 November); (you) try it on the phone
- [ ] (Claude) Steps 2–3 with their tests; deploy the rules
- [ ] (Claude) Steps 4–7 and the widget tests
- [ ] (you) Grant yourself YumSum Star, switch on the morning reminder, weigh in daily for 6 weeks
- [ ] (you) Each Monday, check the line, the sum and the debug log; copy the JSON into the replay file once a fortnight
- [ ] (Claude) Tune the starting values from the replay, then update this plan and CLAUDE.md

## Sources

- Harvard Health, "Calorie counting made easy" (minimums of 1,200 for women and 1,500 for men): <https://www.health.harvard.edu/staying-healthy/calorie-counting-made-easy>
- Frankenfield, Roth-Yousey and Compher, "Comparison of predictive equations for resting metabolic rate in healthy nonobese and obese adults: a systematic review", J Am Diet Assoc, 2005 (Mifflin-St Jeor is the most reliable, but individual errors are noteworthy): <https://pubmed.ncbi.nlm.nih.gov/15883556/>
- John Walker, The Hacker's Diet, "Signal and Noise" (the exponentially smoothed trend, constant 0.9): <https://www.fourmilab.ch/hackdiet/e4/signalnoise.html>
- Kreitzman, Coxon and Szaz, "Glycogen storage: illusions of easy weight loss…", Am J Clin Nutr, 1992 (glycogen is stored with three to four parts water): <https://pubmed.ncbi.nlm.nih.gov/1615908/>
- Hall and others, "Quantification of the effect of energy imbalance on bodyweight", Lancet, 2011 (why simple kcal-per-kg rules are approximate): <https://pubmed.ncbi.nlm.nih.gov/21872751/>
- Kreider and others, ISSN position stand on creatine, J Int Soc Sports Nutr, 2017 (loading retains about 0.5–1 litre of water; weight gain is the one consistent side effect): <https://pubmed.ncbi.nlm.nih.gov/28615996/>
- Hultman and others, "Muscle creatine loading in men", J Appl Physiol, 1996 (3 g a day reaches the same level as loading over 28 days): <https://pubmed.ncbi.nlm.nih.gov/8828669/>
- Lichtman and others, "Discrepancy between self-reported and actual caloric intake and exercise in obese subjects", N Engl J Med, 1992 (under-logging is common): <https://pubmed.ncbi.nlm.nih.gov/1454084/>
