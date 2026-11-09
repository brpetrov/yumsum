// Helpers for driving the YumSum website through Flutter's accessibility
// tree: buttons and fields found by their names, as a person reads them.
const pw = require("playwright");

const BASE = process.env.BASE || "https://yumsum.web.app/";

/** Opens the site in [engine] ("chromium", "firefox", "webkit") with [device]. */
async function open(engine, device) {
  const browser = await pw[engine].launch();
  // UK English: Settings offers Bulgarian only to some regions, the UK one.
  const context = await browser.newContext({
    ...(device ? pw.devices[device] : { viewport: { width: 1280, height: 800 } }),
    locale: process.env.LOCALE || "en-GB",
  });
  const page = await context.newPage();
  const problems = [];
  page.on("pageerror", (e) =>
    problems.push(
      `page error: ${e.message.slice(0, 200)} ${(e.stack || "").split(/\n/).slice(0, 4).join(" < ")}`,
    ),
  );
  page.on("console", (m) => {
    if (m.type() === "error" && !/status of \d+|requestStorageAccess/.test(m.text())) {
      problems.push(`console: ${m.text().slice(0, 200)}`);
    }
  });
  page.on("response", (r) => {
    if (r.status() >= 400) problems.push(`http ${r.status()}: ${r.url().slice(0, 140)}`);
  });
  await page.goto(BASE, { waitUntil: "load" });
  await page.waitForFunction(() => document.querySelector("flt-semantics-placeholder"), null, {
    timeout: 60000,
  });
  await page.waitForTimeout(1500);
  await semantics(page);
  return { browser, page, problems };
}

/** Turns on the accessibility tree (again after a reload). */
async function semantics(page) {
  await page.evaluate(() => document.querySelector("flt-semantics-placeholder")?.click());
  await page.waitForTimeout(800);
  // On a phone Flutter waits for a touch on it instead.
  if (!(await page.locator("flt-semantics [role], flt-semantics input").count())) {
    await page
      .locator("flt-semantics-placeholder")
      .tap({ force: true })
      .catch(() => {});
    await page.waitForTimeout(800);
  }
}

const NODES =
  "flt-semantics [role], flt-semantics input, flt-semantics textarea, flt-semantics span";

/** Every name the screen shows now, as "role: name". */
async function names(page) {
  return page.evaluate((selector) => {
    const out = [];
    for (const e of document.querySelectorAll(selector)) {
      const label = e.getAttribute("aria-label");
      const text = (e.childElementCount === 0 ? e.textContent : "") || "";
      const name = (label || text).trim().replace(/\s+/g, " ");
      if (!name) continue;
      const role =
        e.tagName === "INPUT" || e.tagName === "TEXTAREA"
          ? "field"
          : e.getAttribute("role") || "text";
      out.push(`${role}: ${name.slice(0, 600)}`);
    }
    return [...new Set(out)];
  }, NODES);
}

const escape = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** The [nth] element whose name is exactly [name] (or matches a RegExp). */
function named(page, name) {
  const pattern = name instanceof RegExp ? name : new RegExp(`^\\s*${escape(name)}\\s*$`);
  return page
    .locator(NODES)
    .filter({ hasText: pattern })
    .or(page.locator(`flt-semantics [aria-label="${name instanceof RegExp ? "" : name}"]`));
}

/**
 * Taps what's named [name], waiting up to [timeout] for it and scrolling
 * down once halfway, as a list builds only what's near the screen.
 */
async function tap(page, name, { nth = 0, last = false, timeout = 6000 } = {}) {
  const start = Date.now();
  let scrolled = false;
  let target;
  let count = 0;
  for (;;) {
    target = named(page, name);
    // A button's name may carry its subtitle: match its start then.
    if (!(await target.count()) && typeof name === "string") {
      target = named(page, new RegExp(`^\\s*${escape(name)}`));
    }
    count = await target.count();
    if (count || Date.now() - start > timeout) break;
    if (!scrolled && Date.now() - start > timeout / 2) {
      const size = page.viewportSize();
      await page.mouse.move(size.width / 2, size.height / 2);
      // Phones have no wheel: a list there builds enough to find it anyway.
      await page.mouse.wheel(0, 600).catch(() => {});
      scrolled = true;
    }
    await page.waitForTimeout(300);
  }
  if (!count) throw new Error(`nothing named "${name}" to tap`);
  await target.nth(last ? count - 1 : Math.min(nth, count - 1)).click();
  await page.waitForTimeout(800);
}

/** Types [text] into the field named [label], replacing what's there. */
async function type(page, label, text, { enter = false } = {}) {
  const field = page
    .locator(
      `flt-semantics input[aria-label="${label}"], flt-semantics textarea[aria-label="${label}"]`,
    )
    .first();
  if (!(await field.count())) throw new Error(`no field "${label}"`);
  const had = await field.inputValue().catch(() => "");
  await field.click();
  await page.waitForTimeout(250);
  // A folded bar can take a tap to unfold before its box takes focus.
  const focused = () =>
    page.evaluate(() => /INPUT|TEXTAREA/.test(document.activeElement?.tagName ?? ""));
  if (!(await focused()) && (await field.count())) {
    await field.click();
    await page.waitForTimeout(400);
  }
  // Only a box with text is cleared: Safari's engine swaps an empty box's
  // input on its first key, and a select-all there lost what followed.
  if (had) {
    await page.keyboard.press("Control+A");
    await page.keyboard.press("Backspace");
  }
  await page.keyboard.type(text, { delay: 15 });
  // On a phone the first key can go to the box Flutter is swapping out:
  // check what landed, and type it again if it isn't all there.
  await page.waitForTimeout(200);
  const landed = await page.evaluate(() => document.activeElement?.value ?? null);
  if (landed !== null && landed !== text) {
    await page.keyboard.press("Control+A");
    await page.keyboard.press("Backspace");
    await page.keyboard.type(text, { delay: 15 });
  }
  if (enter) await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
}

/** Waits up to [timeout] ms for a name containing [text]. */
async function sees(page, text, timeout = 8000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const all = await names(page);
    if (all.some((n) => (text instanceof RegExp ? text.test(n) : n.includes(text)))) return true;
    await page.waitForTimeout(300);
  }
  return false;
}

module.exports = { open, semantics, names, named, tap, type, sees, BASE };
