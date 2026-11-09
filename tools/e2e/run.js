// The website, signed in as the test account, in one browser: every check
// prints ok or FAIL (with a screenshot in shots/). Writes real data to the
// test account and clears it at the end with Settings > Reset all data.
// AI estimates are skipped: App Check's reCAPTCHA refuses robot browsers.
//
// Usage: YUMSUM_TEST_EMAIL=… YUMSUM_TEST_PASSWORD=… node run.js chromium|firefox|webkit [device]
// e.g. node run.js webkit "iPhone 13"; BASE= for another site; KEEP=1 skips
// the reset; WRONG=1 tries a wrong password first. Firebase allows only so
// many sign-ins an hour ("Too many attempts"), so run a few at a time.
const fs = require("fs");
const { open, names, tap, type, sees } = require("./lib");

const [engine = "chromium", device] = process.argv.slice(2);
const email = process.env.YUMSUM_TEST_EMAIL;
const password = process.env.YUMSUM_TEST_PASSWORD;
if (!email || !password) throw new Error("Set YUMSUM_TEST_EMAIL and YUMSUM_TEST_PASSWORD.");
const tag = `${engine}${device ? "-" + device.replace(/\s+/g, "") : ""}`;
const meal = `E2E toast ${engine}`;

(async () => {
  fs.mkdirSync("shots", { recursive: true });
  const { browser, page, problems } = await open(engine, device);
  const results = [];
  const check = async (name, body) => {
    const start = Date.now();
    const seen = problems.length;
    try {
      await body();
      results.push(`ok    ${name} (${((Date.now() - start) / 1000).toFixed(1)}s)`);
    } catch (error) {
      const file = `shots/${tag}-${results.length}.png`;
      await page.screenshot({ path: file }).catch(() => {});
      results.push(`FAIL  ${name}: ${error.message.split("\n")[0]} [${file}]`);
      const on = (await names(page).catch(() => [])).slice(0, 12).join(" | ");
      results.push(`      on screen: ${on}`);
    }
    for (const problem of problems.slice(seen))
      problems[problems.indexOf(problem)] = `${problem} (during: ${name})`;
  };
  const expect = async (text, what, timeout) => {
    if (!(await sees(page, text, timeout))) throw new Error(`no "${what ?? text}"`);
  };
  const expectGone = async (text, timeout = 6000) => {
    const deadline = Date.now() + timeout;
    while (Date.now() < deadline) {
      if (!(await names(page)).some((n) => n.includes(text))) return;
      await page.waitForTimeout(300);
    }
    throw new Error(`"${text}" still there`);
  };
  // Today's meals as the card counts them.
  const logged = async () => {
    const card = (await names(page)).find((n) => n.includes("Today's meals")) ?? "";
    return +(card.match(/(\d+) logged/)?.[1] ?? 0);
  };
  const expectLogged = async (count) => {
    const deadline = Date.now() + 8000;
    while (Date.now() < deadline) {
      if ((await logged()) === count) return;
      await page.waitForTimeout(300);
    }
    throw new Error(`${await logged()} logged, not ${count}`);
  };
  let before = 0;
  const menu = async (page_) => {
    await tap(page, "Open navigation menu");
    // A robot's tap on the menu button doesn't always land in Firefox.
    if (!(await sees(page, "Log out", 2000))) await tap(page, "Open navigation menu");
    await tap(page, page_);
    await page.waitForTimeout(1200);
  };

  await type(page, "Email", email);
  if (process.env.WRONG) {
    await check("a wrong password says so, and the box takes typing again", async () => {
      await type(page, "Password", "Wrong-password-1");
      await tap(page, "Sign in", { last: true });
      await expect("Incorrect email or password");
      await type(page, "Password", password);
      const value = await page.locator('flt-semantics input[aria-label="Password"]').inputValue();
      if (value !== password) throw new Error(`the box holds ${value.length} characters`);
    });
  } else {
    await type(page, "Password", password);
  }

  await check("Forgot password opens its own box, which says nothing until sent", async () => {
    await tap(page, "Forgot password?");
    await expect("Reset your password");
    await expect("Send link");
    await tap(page, "Cancel");
    await expectGone("Reset your password");
  });

  await check("signing in opens Home, or onboarding for a new account", async () => {
    await tap(page, "Sign in", { last: true });
    await page.waitForURL(/#\/(dashboard|onboarding)/, { timeout: 30000 });
  });

  if (page.url().includes("onboarding")) {
    await check("onboarding, start to finish", async () => {
      await type(page, "Name", "Tester");
      await tap(page, "Next");
      await tap(page, "Male");
      await tap(page, "Next");
      await type(page, "Age", "34");
      await tap(page, "Next");
      await type(page, "Height", "178");
      await tap(page, "Next");
      await type(page, "Current weight", "84");
      await tap(page, "Next");
      await tap(page, "Lose weight");
      await tap(page, "Next");
      await type(page, "Target weight", "76");
      await tap(page, "Next");
      await tap(page, "Light daily movement");
      await tap(page, "Next");
      await tap(page, "3 to 4 sessions/week");
      await tap(page, "Next");
      await tap(page, "Next");
      await expect("Your plan is ready!");
      await tap(page, "Start");
      await page.waitForURL(/#\/dashboard/, { timeout: 20000 });
    });
  }

  await check("Home shows the day's calories", () => expect(/kcal left/, "kcal left", 15000));

  await check("typing a meal with calories logs it", async () => {
    before = await logged();
    await type(page, "Type a meal", meal);
    await type(page, "kcal", "250");
    await type(page, "protein (g)", "8", { enter: true });
    await expectLogged(before + 1);
    await expect(meal);
    // The bar empties once it's saved.
    const kcal = page.locator('flt-semantics input[aria-label="kcal"]');
    const deadline = Date.now() + 10000;
    while ((await kcal.count()) && (await kcal.inputValue()) !== "" && Date.now() < deadline) {
      await page.waitForTimeout(300);
    }
    // The bar sets itself up again after a save.
    await page.waitForTimeout(3000);
  });

  await check("a meal logged before comes back as a chip while typing", async () => {
    await type(page, "Type a meal", "E2E");
    await expect(`${meal} · 250 kcal`);
    await tap(page, "Clear");
  });

  await check("Log again adds a copy to today", async () => {
    await tap(page, "Meal options");
    await tap(page, "Log again");
    await expect("Added to today.");
    await expectLogged(before + 2);
  });

  await check("Edit changes a meal's calories", async () => {
    await tap(page, "Meal options");
    await tap(page, "Edit");
    await expect("Edit meal");
    await type(page, "Calories", "300");
    await tap(page, "Save changes");
    await expectGone("Edit meal");
    await expect("300 kcal");
  });

  await check("Delete removes a meal", async () => {
    await tap(page, "Meal options");
    await tap(page, "Delete");
    await tap(page, "Delete", { last: true });
    await expectLogged(before + 1);
  });

  await check("the targets dialog explains the rings' colours", async () => {
    await tap(page, "About your targets");
    await expect("Your targets");
    await expect("Colours:");
    await tap(page, "OK");
    await expectGone("Your targets");
  });

  await check("Recipes lists and searches recipes", async () => {
    await menu("Recipes");
    await expect("Greek yoghurt berry bowl");
    await type(page, "Search recipes or ingredients", "salmon");
    await expect(/salmon/i, "a salmon recipe");
  });

  await check("History opens today's meals", async () => {
    await menu("History");
    await expect("November");
    await tap(page, `${new Date().getDate()}`);
    await expect(meal, `${meal} in the day sheet`);
    // Tapping outside closes it, on a phone as on a computer.
    await tap(page, "Dismiss", { last: true }).catch(() => page.keyboard.press("Escape"));
    await expectGone("Add meal");
  });

  await check("Weight & Progress logs a weigh-in", async () => {
    await menu("Weight & Progress");
    await tap(page, "Log weight");
    await expect("Log your weight");
    await type(page, "Current weight", "83.6");
    await tap(page, "Save");
    await expectGone("Log your weight");
    await expect(/83[.,]6/, "83.6");
  });

  await check("AI Coach offers YumSum Star", async () => {
    await menu("AI Coach");
    await expect("Your AI Coach");
  });

  await check("Plan Settings shows the plan", async () => {
    await menu("Plan Settings");
    await expect("Update your health plan");
    await expect("Save plan");
  });

  await check("the YumSum Star page opens and closes", async () => {
    await menu("YumSum Star");
    await expect("Shine bright with these smart perks.");
    await tap(page, "Close");
    await expectGone("Shine bright");
  });

  await check("Settings switches to Bulgarian and back", async () => {
    await menu("Settings");
    await tap(page, "Български");
    await expect("ЕЗИК", "the Bulgarian Settings");
    await tap(page, "English");
    await expect("LANGUAGE");
  });

  await check("dark mode, then back to the system's", async () => {
    await tap(page, "Dark");
    await page.waitForTimeout(600);
    await tap(page, "System");
  });

  if (!process.env.KEEP) {
    await check("Reset all data clears the test's meals and weigh-ins", async () => {
      await tap(page, "Reset all data");
      await expect("Reset all data?");
      await type(page, "Password", password);
      await tap(page, "Reset all data", { last: true });
      await expect("All logged data deleted.", "All logged data deleted.", 15000);
    });
  }

  await check("Log out returns to sign-in", async () => {
    await tap(page, "Open navigation menu");
    if (!(await sees(page, "Log out", 2000))) await tap(page, "Open navigation menu");
    await tap(page, "Log out");
    await page.waitForTimeout(1000);
    const confirm = (await names(page)).filter((n) => n.includes("Log out")).length > 0;
    if (confirm) await tap(page, "Log out", { last: true }).catch(() => {});
    await page.waitForURL(/#\/auth/, { timeout: 20000 });
  });

  console.log(`\n== ${tag}`);
  console.log(results.join("\n"));
  const failed = results.filter((r) => r.startsWith("FAIL")).length;
  const browserProblems = [...new Set(problems)].filter(
    // App Check refusing robots, and the wrong password on purpose.
    (p) => !/firebaseappcheck|recaptcha|signInWithPassword/.test(p),
  );
  if (browserProblems.length) console.log(`browser errors:\n  ${browserProblems.join("\n  ")}`);
  console.log(`${results.filter((r) => r.startsWith("ok")).length} ok, ${failed} failed`);
  await browser.close();
  process.exit(failed ? 1 : 0);
})();
