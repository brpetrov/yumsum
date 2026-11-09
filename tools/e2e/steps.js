// Runs steps from the command line and prints the screen after each, for
// exploring a flow before it becomes a test. Steps: "tap:Name", "tap:Name#2"
// (the third match), "type:Label=text", "enter:Label=text", "wait:ms",
// "shot:file", "dump", "url", "key:Escape". Signs in first unless NO_LOGIN.
// Usage: node steps.js chromium [device] -- step step ...
const { open, names, tap, type } = require("./lib");

(async () => {
  const args = process.argv.slice(2);
  const split = args.indexOf("--");
  const [engine = "chromium", device] = args.slice(0, split < 0 ? args.length : split);
  const steps = split < 0 ? [] : args.slice(split + 1);
  const { browser, page, problems } = await open(engine, device);
  try {
    if (!process.env.NO_LOGIN) {
      await type(page, "Email", process.env.YUMSUM_TEST_EMAIL);
      await type(page, "Password", process.env.YUMSUM_TEST_PASSWORD);
      await tap(page, "Sign in", { last: true });
      await page.waitForTimeout(6000);
    }
    for (const [index, step] of steps.entries()) {
      const [kind, ...rest] = step.split(":");
      const arg = rest.join(":");
      if (kind === "tap") {
        const [name, nth] = arg.split("#");
        await tap(page, name, { nth: nth ? +nth : 0 });
      } else if (kind === "type" || kind === "enter") {
        const [label, ...text] = arg.split("=");
        await type(page, label, text.join("="), { enter: kind === "enter" });
      } else if (kind === "wait") await page.waitForTimeout(+arg);
      else if (kind === "key") await page.keyboard.press(arg);
      else if (kind === "shot") await page.screenshot({ path: `${arg}.png` });
      else if (kind === "url") console.log(`url: ${page.url()}`);
      else if (kind === "dump")
        console.log(`--- after step ${index}\n${(await names(page)).join("\n")}`);
    }
  } catch (error) {
    console.log(`FAILED: ${error.message}`);
    console.log((await names(page)).join("\n"));
    await page.screenshot({ path: "failed.png" });
  }
  if (problems.length) console.log(`problems:\n${problems.join("\n")}`);
  await browser.close();
})();
