// Play Store screenshots from the website (YumSum Star's page says to subscribe
// in the Android app there, so take that one on the phone), signed in as the test account:
// logs a few meals and a weigh-in, captures the main screens at a 9:16
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
const meals = [
  ["Greek yoghurt with berries and honey", "240", "18"],
  ["Chicken and avocado wrap", "460", "34"],
  ["Apple", "80", "0"],
  ["Salmon, rice and green beans", "610", "42"],
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
  // Start from an empty day, after a run that stopped early.
  if (await sees(page, "logged", 2000)) await reset();

  for (const [name, kcal, protein] of meals) {
    await type(page, "Type a meal", name);
    await type(page, "kcal", kcal);
    await type(page, "protein (g)", protein, { enter: true });
    await page.waitForTimeout(3500);
  }
  await page.keyboard.press("Escape");
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
