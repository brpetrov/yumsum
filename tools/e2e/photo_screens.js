// Two real screens of Smart Snap for the Play Store, from the website signed
// in as the test account (which has YumSum Star): the camera page with a
// plate in the preview, and the AI's result in the bar. The "camera" is
// Chromium's fake one playing a recipe photo of the app's own, so no
// stock photo and nothing invented. One AI call per photo (about 0.1p).
// Usage: YUMSUM_TEST_EMAIL=… YUMSUM_TEST_PASSWORD=… node photo_screens.js [recipe…]
//   recipe: a file in ../hosting/recipes without .webp (default: chicken-curry salmon-dill-potatoes)
const fs = require("fs");
const os = require("os");
const path = require("path");
const pw = require("playwright");
const { semantics, names, tap, sees, type, BASE } = require("./lib");

const recipes = process.argv.slice(2);
if (!recipes.length) recipes.push("chicken-curry", "salmon-dill-potatoes");
const phone = {
  ...pw.devices["Pixel 7"],
  viewport: { width: 412, height: 732 },
  screen: { width: 412, height: 732 },
  deviceScaleFactor: 1080 / 412,
};

/** The recipe's photo as one portrait JPEG frame (a one-frame .mjpeg), cover-cropped. */
async function frame(recipe) {
  const browser = await pw.chromium.launch();
  const page = await browser.newPage();
  const webp = fs.readFileSync(path.join(__dirname, "..", "hosting", "recipes", `${recipe}.webp`));
  const jpeg = await page.evaluate(async (src) => {
    const img = new Image();
    img.src = `data:image/webp;base64,${src}`;
    await img.decode();
    const W = 720, H = 1280;
    const canvas = document.createElement("canvas");
    canvas.width = W;
    canvas.height = H;
    // A plate from above is still one turned a quarter: a landscape photo
    // turned portrait keeps most of the plate in a phone's frame.
    const ctx = canvas.getContext("2d");
    ctx.translate(W / 2, H / 2);
    ctx.rotate(Math.PI / 2);
    const s = Math.max(H / img.width, W / img.height);
    const w = img.width * s, h = img.height * s;
    ctx.drawImage(img, -w / 2, -h / 2, w, h);
    return canvas.toDataURL("image/jpeg", 0.92).split(",")[1];
  }, webp.toString("base64"));
  await browser.close();
  const file = path.join(os.tmpdir(), `yumsum-${recipe}.mjpeg`);
  fs.writeFileSync(file, Buffer.from(jpeg, "base64"));
  return file;
}

(async () => {
  fs.mkdirSync(path.join(__dirname, "store"), { recursive: true });
  for (const recipe of recipes) {
    const browser = await pw.chromium.launch({
      args: [
        "--use-fake-device-for-media-stream",
        "--use-fake-ui-for-media-stream",
        `--use-file-for-fake-video-capture=${await frame(recipe)}`,
      ],
    });
    const context = await browser.newContext({ ...phone, locale: "en-GB", permissions: ["camera"] });
    const page = await context.newPage();
    const shot = async (name) => {
      await page.waitForTimeout(1500);
      const file = path.join(__dirname, "store", `${name}-${recipe}.png`);
      await page.screenshot({ path: file });
      console.log(path.relative(process.cwd(), file));
    };

    await page.goto(BASE, { waitUntil: "load" });
    await page.waitForFunction(() => document.querySelector("flt-semantics-placeholder"), null, { timeout: 60000 });
    await page.waitForTimeout(1500);
    await semantics(page);
    await type(page, "Email", process.env.YUMSUM_TEST_EMAIL);
    await type(page, "Password", process.env.YUMSUM_TEST_PASSWORD);
    await tap(page, "Sign in", { last: true });
    await page.waitForURL(/#\/dashboard/, { timeout: 30000 });
    await page.waitForTimeout(3000);
    for (const later of ["Maybe later", "No thanks"]) {
      if (await sees(page, later, 5000)) {
        await tap(page, later);
        await page.waitForTimeout(1000);
      }
    }

    // The camera page, with the plate in the preview and the shutter.
    await tap(page, "Take a photo");
    if (!(await sees(page, "Take photo", 15000))) throw new Error("the camera page didn't open");
    await page.waitForTimeout(2000);
    await shot("en-7-camera");

    // The photo goes to the AI; the bar fills with the result.
    await tap(page, "Take photo");
    if (!(await sees(page, "Save", 60000))) {
      await shot("debug-after-shutter");
      console.log((await names(page)).join("\n"));
      throw new Error("no estimate came back");
    }
    await shot("en-8-photo-result");

    // Nothing is logged.
    await tap(page, "Clear").catch(() => {});
    await browser.close();
  }
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
