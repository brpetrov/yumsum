// Renders store/feature.html to the 1024 × 500 Play feature graphic.
const path = require("path");
const { chromium } = require("playwright");
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  await page.goto("file://" + path.resolve("store/feature.html"));
  await page.waitForTimeout(800);
  await page.screenshot({ path: "store/feature-graphic.png" });
  await browser.close();
})();
