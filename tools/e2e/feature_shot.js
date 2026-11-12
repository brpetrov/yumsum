// Renders store/feature.html to the 1024 × 500 Play feature graphic.
const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");
const { chromium } = require("playwright");
const dir = path.join(__dirname, "store");

async function renderFeatureGraphic(page) {
  await page.setViewportSize({ width: 1024, height: 500 });
  const sources = Object.fromEntries(["phone-home-light-matched.png", "phone-ai-estimate.png"]
    .map(name => [name, "data:image/png;base64," + fs.readFileSync(path.join(dir, name)).toString("base64")]));
  await page.addInitScript(value => { window.featureSources = value; }, sources);
  await page.goto(pathToFileURL(path.join(dir, "feature.html")).href);
  await page.evaluate(() => window.ready);
  await page.evaluate(() => {
    if (!document.fonts.check("600 54px Fredoka") || !document.fonts.check("700 20px Nunito")) throw Error("Brand fonts did not load");
    for (const selector of [".copy", ".phone", ".estimate"]) {
      const bounds = document.querySelector(selector).getBoundingClientRect();
      if (bounds.left < 0 || bounds.top < 0 || bounds.right > 1024 || bounds.bottom > 500) throw Error(selector + " is clipped");
    }
    const plate = document.querySelector(".meal").getBoundingClientRect();
    const pill = document.querySelector(".fact").getBoundingClientRect();
    const phone = document.querySelector(".phone").getBoundingClientRect();
    const estimate = document.querySelector(".estimate").getBoundingClientRect();
    if (Math.abs(plate.width - 220) > .1 || Math.abs(plate.height - 220) > .1 || Math.abs(plate.left + 73) > .1 || Math.abs(plate.bottom - 573) > .1) throw Error("Plate crop changed");
    if (plate.top - pill.bottom < 24) throw Error("Claim pill must clear the plate by at least 24 px; measured " + (plate.top - pill.bottom).toFixed(1) + " px");
    if (estimate.left - plate.right < 300 || phone.left - plate.right < 300) throw Error("Plate is too close to the phone or AI card");
    if (getComputedStyle(document.body).backgroundColor !== "rgb(250, 242, 231)") throw Error("Feature background must be #FAF2E7");
    const canvas = document.getElementById("home");
    const screen = document.querySelector(".screen");
    if (canvas.width !== 430 || canvas.height !== 850 || Math.abs(screen.clientWidth / screen.clientHeight - 430 / 850) > .002) throw Error("Full phone capture is distorted");
  });
  const output = path.join(dir, "feature-graphic.png");
  await page.screenshot({ path: output });
  const bytes = fs.readFileSync(output);
  if (bytes.readUInt32BE(16) !== 1024 || bytes.readUInt32BE(20) !== 500 || bytes[25] !== 2) throw Error("Expected 1024 x 500 RGB PNG");
  console.log("feature-graphic.png: 1024 x 500 RGB, " + Math.round(bytes.length / 1024) + " KB; full phone and layout checked");
}

async function main() {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
    await renderFeatureGraphic(page);
  } finally {
    await browser.close();
  }
}
if (require.main === module) main().catch(error => { console.error(error); process.exitCode = 1; });
module.exports = { renderFeatureGraphic };
