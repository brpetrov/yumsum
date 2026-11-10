// Play Store screenshots from the website (YumSum Star's page says to subscribe
// in the Android app there, so take that one on the phone), signed in as the test account:
// logs a few recipe portions and a weigh-in, captures the main screens at a 9:16
// phone size (1080 × 1920), then clears the data with Reset all data.
// Usage: YUMSUM_TEST_EMAIL=… YUMSUM_TEST_PASSWORD=… node screenshots.js [en|bg]
const fs = require("fs");
const pw = require("playwright");
const { open, tap, type, sees } = require("./lib");

const language = process.argv[2] || "en";
const phone = {
  ...pw.devices["Pixel 7"],
  viewport: { width: 412, height: 732 },
  screen: { width: 412, height: 732 },
  deviceScaleFactor: 1080 / 412,
};
// Recipes carry full macros, so the rings on the home screen fill up
// (a typed meal has calories and protein only).
const recipes = [
  "Greek yoghurt berry bowl",
  "Chicken souvlaki wrap",
  "Berry protein smoothie",
  "Salmon with dill potatoes",
];

(async () => {
  fs.mkdirSync("store", { recursive: true });
  const { browser, page } = await open("chromium", phone);
  const shot = async (name) => {
    await page.waitForTimeout(1500);
    await page.screenshot({ path: `store/${language}-${name}.png` });
    console.log(`store/${language}-${name}.png`);
  };
  const reset = async () => {
    await menu("Settings");
    await tap(page, "Reset all data");
    await type(page, "Password", process.env.YUMSUM_TEST_PASSWORD);
    await tap(page, "Reset all data", { last: true });
    await page.waitForTimeout(3000);
    await menu("Home");
  };
  const menu = async (name) => {
    await tap(page, "Open navigation menu");
    if (!(await sees(page, "Log out", 2000))) await tap(page, "Open navigation menu");
    await tap(page, name);
    await page.waitForTimeout(1500);
  };

  await type(page, "Email", process.env.YUMSUM_TEST_EMAIL);
  await type(page, "Password", process.env.YUMSUM_TEST_PASSWORD);
  await tap(page, "Sign in", { last: true });
  await page.waitForURL(/#\/dashboard/, { timeout: 30000 });
  await page.waitForTimeout(3000);
  // One-off offers on a fresh browser: the Adaptive formula's intro (an
  // account new to YumSum Star) and the creatine reminder.
  for (const later of ["Maybe later", "No thanks"]) {
    if (await sees(page, later, 8000)) {
      await tap(page, later);
      await page.waitForTimeout(1500);
    }
  }
  // Start from an empty day, after a run that stopped early.
  if (await sees(page, "logged", 2000)) await reset();

  for (const name of recipes) {
    await menu("Recipes");
    await type(page, "Search recipes or ingredients", name);
    // The search leaves one card; its button opens the recipe, whose own
    // Log a portion opens the "How many portions?" sheet.
    await tap(page, "Log a portion");
    await tap(page, "Log a portion");
    await tap(page, "Log", { last: true });
    await page.waitForTimeout(3000);
    // The recipe stays open after logging, and the list keeps the search.
    await tap(page, "Back");
    await tap(page, "Clear");
  }
  await menu("Home");
  await shot("1-home");

  await type(page, "Type a meal", "Chick");
  await page.waitForTimeout(1200);
  await shot("2-quick-log");
  await tap(page, "Clear").catch(() => {});

  await tap(page, "About your targets");
  await shot("3-targets");
  await tap(page, "OK");

  await menu("Recipes");
  await shot("4-recipes");

  await menu("Weight & Progress");
  await tap(page, "Log weight");
  await type(page, "Current weight", "83.6");
  await tap(page, "Save");
  // After the "Weight saved" note has gone.
  await page.waitForTimeout(5000);
  await shot("5-progress");

  await menu("History");
  await shot("6-history");


  if (!process.env.KEEP) await reset();
  await browser.close();
})();
