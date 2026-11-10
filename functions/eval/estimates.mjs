// The typed-estimate test set: runs each meal of a set through the real
// meal prompt a few times and reports how often the total lands in range,
// how far the same words move between runs, and how often the app would ask
// (after the same option filter as parseEstimateItems and
// offerEstimateChoices in the app). Run it before and after any prompt
// change:
//
//   npm run eval                      meals.json, 3 runs a meal, the model's temperature
//   npm run eval -- --runs 5 --temperature 0.3
//   npm run eval:foods                foods.json, the large set
//
// Flags:
//   --file <name>        the set in eval/ (default meals.json)
//   --runs N             runs a meal (default 3)
//   --concurrency N      requests in flight at once (default 8); 429, 5xx and
//                        network errors are retried 3 times, after 2, 4, 8 s
//   --group a,b          only these groups (an entry without one is "legacy")
//   --lang en,bg         only these languages; "bg" asks with the
//                        Bulgarian profile, the app's language and country
//   --temperature T      override the model's temperature
//   --tag name           suffix on the outputs, so two halves of a set can run
//                        side by side without overwriting each other
//   --report-only        no calls: rebuild report-<set>.md from every
//                        results-<set>*.json already there
//
// Outputs (all gitignored), in eval/:
//   last-run.txt         every run, as printed (not for held-back foods)
//   results-<set>.json   one object per food with its fields and tries: the
//                        model's raw parsed reply, the kcal total, the
//                        questions after the app's filter, latency, any error
//   report-<set>.md      for a reviewing AI: summary tables by group and
//                        language, then failure sections with the raw items.
//                        Entries marked holdout are only in the last line.
//
// About a penny a run of meals.json. The Gemini key comes from
// GEMINI_API_KEY, or else from the Functions secret through the Firebase
// CLI; it is never printed.

import { execSync } from "node:child_process";
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { GoogleGenAI } = require("@google/genai");
const { aiModelId, mealConfig, mealPrompt } = require("../lib/src/prompts.js");

const arg = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > 0 ? Number(process.argv[at + 1]) : fallback;
};
const text = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > 0 ? process.argv[at + 1] : fallback;
};
const list = (name) => text(name, "").split(",").filter(Boolean);
const runs = arg("runs", 3);
const concurrency = arg("concurrency", 8);
const temperature = arg("temperature", undefined);
const file = text("file", "meals.json");
const set = file.replace(/\.json$/, "");
const tag = text("tag", "");
const suffix = tag ? `-${tag}` : "";
const reportOnly = process.argv.includes("--report-only");
const here = new URL(".", import.meta.url);
const groups = list("group");
const langs = list("lang");
// Entries without a group are "legacy" and without a language "en"; the
// set's own list is "meals" in meals.json and "foods" in foods.json.
const entries = JSON.parse(readFileSync(new URL(file, here), "utf8"));
const meals = (entries.foods ?? entries.meals)
  .map((food) => ({ ...food, group: food.group ?? "legacy", lang: food.lang ?? "en" }))
  .filter((food) => !groups.length || groups.includes(food.group))
  .filter((food) => !langs.length || langs.includes(food.lang));

const apiKey = reportOnly
  ? "unused"
  : process.env.GEMINI_API_KEY ||
    execSync("firebase functions:secrets:access GEMINI_API_KEY", {
      stdio: ["ignore", "pipe", "ignore"],
    })
      .toString()
      .trim();
const ai = new GoogleGenAI({ apiKey, apiVersion: "v1beta" });
const profiles = {
  en: { country: "United Kingdom" },
  bg: { country: "Bulgaria", language: "bg" },
};
const config = { ...mealConfig(false), ...(temperature === undefined ? {} : { temperature }) };

// The app's filter (parseEstimateItems): other amounts, by grams, and
// other kinds, as complete items, each at least 30 kcal from the item and
// each other, at most 3 of each; kinds under new names that keep every
// word of the item's name the user typed; at most 6 chips counting the
// ticked one of each row, kinds dropped first; questions for at most 2
// items a meal, the widest spread first.
const words = (text) =>
  new Set(text.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((word) => word.length > 2));
// The words of an amount that say how much, beside its numbers (the app's
// _sizeWords): amounts that repeat one the user said aren't asked.
const sizes = new Set([
  "small", "medium", "regular", "large", "big", "half", "quarter", "whole",
  "double", "single", "pint", "pints", "short", "tall", "grande", "venti",
  "малка", "малък", "средна", "среден", "средно", "голяма", "голям", "голямо",
  "половин", "половинка", "цяла", "цял", "цяло", "двойна", "двоен", "двойно",
]);
const tokens = (text, sizesOnly = false) =>
  text
    .toLowerCase()
    .split(/[^\p{L}\p{N}]+/u)
    .filter((t) => /^\p{N}+$/u.test(t) || (sizesOnly ? sizes.has(t) : t.length > 2));
function amountsOf(item, said) {
  const amount = typeof item.amount === "string" ? item.amount.trim() : "";
  const raw = Array.isArray(item.amounts) ? item.amounts : [];
  if (!(item.grams > 0)) return [];
  // An amount the user said ("5 meatballs", "a pint", "large") isn't asked.
  const heard = new Set(tokens(said));
  const theirs = [amount, ...raw.map((other) => (typeof other?.amount === "string" ? other.amount : ""))];
  if (tokens(theirs.join(" "), true).some((t) => heard.has(t))) return [];
  // "a fried egg" is one egg (the app's _oneArticle / _oneAssumed).
  if (
    /(^|\s)(a|an|един|една|едно)\s/i.test(said) &&
    /^(1|one|един|една|едно)\b(?!\s*(bowl|plate|handful|portion|serving|cup|glass|купа|купичка|чиния|шепа|порция|чаша))/i.test(amount)
  ) {
    return [];
  }
  const labels = new Set([amount.toLowerCase()]);
  const calories = [item.kcal];
  const amounts = [];
  for (const other of raw) {
    const label = typeof other?.amount === "string" ? other.amount.trim() : "";
    if (!label || !(other.grams > 0) || Math.round(other.grams) === item.grams) continue;
    const kcal = Math.round((item.kcal * other.grams) / item.grams);
    if (calories.some((each) => Math.abs(kcal - each) < 30)) continue;
    if (labels.has(label.toLowerCase())) continue;
    labels.add(label.toLowerCase());
    calories.push(kcal);
    amounts.push({ amount: label, grams: Math.round(other.grams), kcal });
    if (amounts.length === 3) break;
  }
  return worthAsking(item.kcal, calories) ? amounts : [];
}
// The app's askBarFor: a row must be able to move the item by a third and
// at least 80 kcal, or it isn't asked.
const bar = (kcal) => Math.max(80, Math.round(kcal * 0.3));
const worthAsking = (kcal, calories) => calories.some((other) => Math.abs(other - kcal) >= bar(kcal));
function asked(item, meal) {
  const said = words(meal);
  const kept = [...words(item.item)].filter((word) => said.has(word));
  const names = new Set([item.item.toLowerCase()]);
  const calories = [item.kcal];
  const options = [];
  for (const option of Array.isArray(item.options) ? item.options : []) {
    if (typeof option?.item !== "string" || typeof option.kcal !== "number") continue;
    if (calories.some((kcal) => Math.abs(option.kcal - kcal) < 30)) continue;
    if (names.has(option.item.toLowerCase())) continue;
    if (!kept.every((word) => words(option.item).has(word))) continue;
    names.add(option.item.toLowerCase());
    calories.push(option.kcal);
    options.push(option);
    if (options.length === 3) break;
  }
  if (!worthAsking(item.kcal, calories)) options.length = 0;
  const amounts = amountsOf(item, meal);
  const chips = () =>
    (amounts.length ? amounts.length + 1 : 0) + (options.length ? options.length + 1 : 0);
  while (chips() > 6) options.pop();
  const spread = Math.max(
    0,
    ...[...amounts, ...options].map((other) => Math.abs(other.kcal - item.kcal)),
  );
  return { amounts, options, spread };
}

async function estimate(meal, lang) {
  const started = Date.now();
  const reply = await ai.models.generateContent({
    model: aiModelId,
    contents: mealPrompt(profiles[lang] ?? profiles.en, false, meal),
    config,
  });
  const ms = Date.now() - started;
  let json;
  try {
    json = JSON.parse(reply.text);
  } catch (error) {
    // Kept whole, so the report can show what the model wrote.
    const failure = new Error(`malformed reply: ${String(reply.text).slice(0, 300)}`);
    failure.malformed = true;
    throw failure;
  }
  const items = Array.isArray(json.items) ? json.items : [];
  const questions = items
    .map((item) => ({ item, ...asked(item, meal) }))
    .filter(({ amounts, options }) => amounts.length + options.length > 0)
    .sort((a, b) => b.spread - a.spread)
    .slice(0, 2);
  return {
    kcal: items.reduce((sum, item) => sum + item.kcal, 0),
    items,
    questions,
    raw: json,
    ms,
  };
}

// A rate limit, a server error or a dropped connection is tried again, 3
// times, after 2, 4 and 8 seconds; anything else (a malformed reply, a
// refusal) is the model's and counts as the run's error.
const transient = (error) =>
  !error.malformed &&
  (error.status === 429 ||
    error.status >= 500 ||
    /\b(429|5\d\d)\b|fetch failed|network|ECONN|ETIMEDOUT|ENOTFOUND|EAI_AGAIN|socket|overloaded|UNAVAILABLE|RESOURCE_EXHAUSTED/i.test(
      String(error.message ?? error),
    ));
async function attempt(meal, lang) {
  for (let retry = 0; ; retry++) {
    try {
      return { ...(await estimate(meal, lang)), retries: retry };
    } catch (error) {
      if (retry === 3 || !transient(error)) throw error;
      await new Promise((done) => setTimeout(done, 2000 * 2 ** retry));
    }
  }
}

const median = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
};

// At most [concurrency] requests in flight, from one list of (meal, run).
async function runAll() {
  const results = meals.map((case_) => ({ ...case_, tries: new Array(runs) }));
  const jobs = results.flatMap((result) => Array.from({ length: runs }, (_, run) => [result, run]));
  let next = 0;
  let done = 0;
  const worker = async () => {
    while (next < jobs.length) {
      const [result, run] = jobs[next++];
      try {
        result.tries[run] = await attempt(result.meal, result.lang);
      } catch (error) {
        result.tries[run] = { error: String(error.message ?? error).slice(0, 400) };
      }
      if (++done % 50 === 0) console.error(`${done}/${jobs.length} runs`);
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, concurrency) }, worker));
  return results;
}

// The numbers of one food: used by the console summary and the report.
function statsOf({ min, max, specific, pieces, single, tries }) {
  const good = tries.filter((t) => !t.error);
  const kcals = good.map((t) => t.kcal);
  const hits = kcals.filter((kcal) => kcal >= min && kcal <= max).length;
  const spread = kcals.length ? (Math.max(...kcals) - Math.min(...kcals)) / Math.max(median(kcals), 1) : 0;
  const asks = good.filter((t) => t.questions.length > 0).length;
  const countAsks = pieces
    ? good.filter((t) => t.questions.some((q) => q.amounts.length > 0)).length
    : 0;
  // A single item (a sandwich) asked how much: the amount is one.
  const sizeAsks = single
    ? good.filter((t) => t.questions.some((q) => q.amounts.length > 0)).length
    : 0;
  // Amounts given with no amount on the item: the app can't say what the
  // item's own portion is.
  const noLabel = good.filter((t) =>
    t.items.some(
      (item) =>
        Array.isArray(item.amounts) &&
        item.amounts.length > 0 &&
        !(typeof item.amount === "string" && item.amount.trim()),
    ),
  ).length;
  return { good, kcals, hits, spread, asks, countAsks, sizeAsks, noLabel };
}

// The report, for a reviewing AI.
const clip = (line, length = 200) => (line.length > length ? `${line.slice(0, length - 1)}…` : line);
const itemLine = (item) => {
  const extra = [];
  const amounts = Array.isArray(item.amounts)
    ? item.amounts.map((a) => `${a?.amount} ${a?.grams}g`).join(", ")
    : "";
  if (item.amount !== undefined || amounts) {
    extra.push(`amount: ${item.amount ?? "(none)"}${amounts ? `; amounts: ${amounts}` : ""}`);
  }
  const options = Array.isArray(item.options)
    ? item.options.map((o) => `${o?.item} ${o?.kcal}`).join(", ")
    : "";
  if (options) extra.push(`options: ${options}`);
  return clip(`${item.item} ${item.grams ?? "?"}g ${item.kcal}${extra.map((e) => ` [${e}]`).join("")}`);
};
function entryBlock(result) {
  const { meal, min, max, group, lang, basis, tries } = result;
  const { kcals } = statsOf(result);
  const out = [
    `#### ${meal}`,
    `Range ${min}-${max} kcal; group ${group}, ${lang}; basis: ${basis ?? "(none given)"}`,
    `Totals: ${tries.map((t) => (t.error ? "error" : t.kcal)).join(" / ")}` +
      (kcals.length ? ` (spread ${Math.round(statsOf(result).spread * 100)}%)` : ""),
  ];
  tries.forEach((t, at) => {
    if (t.error) {
      out.push(`- run ${at + 1}: error: ${clip(t.error)}`);
      return;
    }
    out.push(`- run ${at + 1}: ${t.kcal} kcal${t.questions.length ? `; asks about ${t.questions.map((q) => q.item.item).join(", ")}` : ""}`);
    for (const item of t.items) out.push(`  - ${itemLine(item)}`);
  });
  return out.join("\n");
}
function report(results) {
  const shown = results.filter((r) => !r.holdout);
  const held = results.filter((r) => r.holdout);
  const count = Math.max(...results.map((r) => r.tries.length));
  const rows = (name, items) => {
    const stats = items.map(statsOf);
    const sum = (pick) => stats.reduce((total, s) => total + pick(s), 0);
    const attempts = sum((s) => s.good.length);
    const hits = sum((s) => s.hits);
    const specificRuns = items.reduce((n, r) => n + (r.specific ? r.tries.filter((t) => !t.error).length : 0), 0);
    const vagueRuns = attempts - specificRuns;
    const needlessRuns = items.reduce((n, r, at) => n + (r.specific ? stats[at].asks : 0), 0);
    const vagueAsked = items.reduce((n, r, at) => n + (r.specific ? 0 : stats[at].asks), 0);
    const pieceItems = items.filter((r) => r.pieces);
    const pieceRuns = pieceItems.reduce((n, r) => n + r.tries.filter((t) => !t.error).length, 0);
    const singleItems = items.filter((r) => r.single);
    const singleRuns = singleItems.reduce((n, r) => n + r.tries.filter((t) => !t.error).length, 0);
    const pct = (a, b) => (b ? `${a}/${b} (${Math.round((100 * a) / b)}%)` : "-");
    const spreads = stats.filter((s) => s.good.length > 1).map((s) => s.spread);
    return (
      `| ${name} | ${items.length} | ${pct(hits, items.reduce((n, r) => n + r.tries.length, 0))} ` +
      `| ${spreads.length ? `${Math.round(median(spreads) * 100)}%` : "-"} ` +
      `| ${pct(needlessRuns, specificRuns)} | ${pct(vagueAsked, vagueRuns)} ` +
      `| ${pct(pieceItems.reduce((n, r) => n + statsOf(r).countAsks, 0), pieceRuns)} ` +
      `| ${pct(singleItems.reduce((n, r) => n + statsOf(r).sizeAsks, 0), singleRuns)} ` +
      `| ${sum((s) => s.noLabel)} |`
    );
  };
  const table = (title, key) => {
    const names = [...new Set(shown.map((r) => r[key]))].sort();
    return [
      `| ${title} | Foods | In range (runs) | Median spread | Needless questions (runs of specific foods) | Vague foods asked (runs) | Piece foods asked the count (runs) | Single items asked how much (runs) | Runs with amounts but no amount |`,
      "|---|---|---|---|---|---|---|---|---|",
      ...(key === "all" ? [rows("All", shown)] : names.map((n) => rows(n, shown.filter((r) => r[key] === n)))),
    ].join("\n");
  };

  const sections = [
    ["Too high", "Every successful run above the maximum; the largest overshoot first.",
      (r, s) => s.good.length > 0 && s.kcals.every((k) => k > r.max),
      (r, s) => -(Math.min(...s.kcals) - r.max) / Math.max(r.max, 1)],
    ["Too low", "Every successful run below the minimum; the largest shortfall first.",
      (r, s) => s.good.length > 0 && s.kcals.every((k) => k < r.min),
      (r, s) => -(r.min - Math.max(...s.kcals)) / Math.max(r.min, 1)],
    ["Mixed", "Some runs out of range, but not all on the same side of it (includes runs in range beside runs out); fewest hits first.",
      (r, s) =>
        s.hits < s.good.length &&
        !s.kcals.every((k) => k > r.max) &&
        !s.kcals.every((k) => k < r.min),
      (r, s) => s.hits - s.good.length],
    ["Wobbly", "Spread of 25% or more between runs, in range or not; widest first.",
      (r, s) => s.spread >= 0.25, (r, s) => -s.spread],
    ["Needless questions", "Foods marked specific that the app would have asked about; most runs asked first.",
      (r, s) => r.specific && s.asks > 0, (r, s) => -s.asks],
    ["Missing count", "Foods marked pieces where no run offered amounts (so the app would not ask how many).",
      (r, s) => r.pieces && s.good.length > 0 && s.countAsks === 0, () => 0],
    ["Missing amount label", "Runs where an item has amounts but no amount of its own; most runs first.",
      (r, s) => s.noLabel > 0, (r, s) => -s.noLabel],
    ["Malformed or errored", "Runs that gave no usable reply, after the retries; most failed runs first.",
      (r, s) => r.tries.some((t) => t.error), (r) => -r.tries.filter((t) => t.error).length],
  ];

  const out = [
    `# YumSum typed-estimate report: ${set}${tag ? ` (${tag})` : ""}`,
    "",
    `- Model: ${aiModelId}`,
    `- Temperature: ${temperature ?? "default"}`,
    `- Runs per food: ${count}`,
    `- Foods: ${results.length} (${shown.length} shown, ${held.length} held back)`,
    `- Date: ${new Date().toISOString().slice(0, 10)}`,
    `- Median latency: ${median(results.flatMap((r) => r.tries.filter((t) => !t.error).map((t) => t.ms))) ?? "-"} ms`,
    "",
    "A food can appear in more than one failure section below (for example Too low and Wobbly). " +
      "Each section lists its foods worst first. The raw items of every run are shown as " +
      "`item grams kcal [amount: x; amounts: a, b] [options: ...]`, the model's own reply before the app's filter. " +
      "Foods marked holdout are left out of every section and table; their one summary is the last line.",
    "",
    "## Summary",
    "",
    table("All", "all"),
    "",
    table("Group", "group"),
    "",
    table("Language", "lang"),
  ];
  for (const [title, about, test, rank] of sections) {
    const hit = shown
      .map((r) => ({ r, s: statsOf(r) }))
      .filter(({ r, s }) => test(r, s))
      .sort((a, b) => rank(a.r, a.s) - rank(b.r, b.s));
    out.push("", `## ${title} (${hit.length})`, "", about);
    for (const { r } of hit) out.push("", entryBlock(r));
  }
  if (held.length) {
    const stats = held.map(statsOf);
    const total = held.reduce((n, r) => n + r.tries.length, 0);
    const specificHeld = held.filter((r) => r.specific);
    out.push(
      "",
      "---",
      "",
      `Held-back set: in range ${stats.reduce((n, s) => n + s.hits, 0)}/${total}, ` +
        `median spread ${Math.round(median(stats.map((s) => s.spread)) * 100)}%, ` +
        `needless questions ${specificHeld.reduce((n, r) => n + statsOf(r).asks, 0)}/` +
        `${specificHeld.reduce((n, r) => n + statsOf(r).good.length, 0)} runs of specific foods, ` +
        `${held.length} foods.`,
    );
  }
  return out.join("\n") + "\n";
}

let results;
if (reportOnly) {
  // Every results file of the set, a tagged half or the whole.
  const seen = new Map();
  for (const name of readdirSync(here).filter((n) => new RegExp(`^results-${set}(-[^.]+)?\\.json$`).test(n))) {
    for (const result of JSON.parse(readFileSync(new URL(name, here), "utf8"))) seen.set(result.meal, result);
  }
  results = [...seen.values()];
  writeFileSync(new URL(`report-${set}.md`, here), report(results));
  console.log(`report-${set}.md from ${results.length} foods`);
  process.exit(0);
}
results = await runAll();
writeFileSync(new URL(`results-${set}${suffix}.json`, here), JSON.stringify(results, null, 1));
writeFileSync(new URL(`report-${set}${suffix}.md`, here), report(results));

const lines = [];
let inRange = 0;
let total = 0;
let needless = 0;
let vagueAsked = 0;
let vagueRuns = 0;
let piecesAsked = 0;
let piecesRuns = 0;
let imperialRuns = 0;
const spreads = [];
for (const result of results) {
  const { meal, min, max, specific, pieces, tries, holdout } = result;
  const { good, kcals, hits, spread, asks, countAsks } = statsOf(result);
  inRange += hits;
  // Ounces or cups in an amount: the user is in a metric country.
  for (const t of good) {
    const labels = t.items.flatMap((item) => [item.amount, ...(Array.isArray(item.amounts) ? item.amounts.map((a) => a?.amount) : [])]);
    if (labels.some((label) => typeof label === "string" && /\b(oz|ounces?|cups?)\b/i.test(label))) imperialRuns++;
  }
  total += tries.length;
  spreads.push(spread);
  if (specific) needless += asks;
  else {
    vagueAsked += asks;
    vagueRuns += good.length;
  }
  if (pieces) {
    piecesAsked += countAsks;
    piecesRuns += good.length;
  }
  // Held-back foods count in the totals but are never listed.
  if (holdout) continue;
  const flag = hits < tries.length ? " <- out of range" : "";
  const asking = specific && asks ? " <- asked" : "";
  lines.push(
    `${meal} [${min}-${max}]: ${kcals.join(", ")}${tries.length > good.length ? ", error" : ""}` +
      ` (spread ${Math.round(spread * 100)}%)${flag}${asking}`,
  );
  for (const t of tries) {
    if (t.error) {
      lines.push(`   error: ${t.error.slice(0, 120)}`);
      continue;
    }
    lines.push(`   ${t.items.map((item) => `${item.item} ${item.kcal}`).join(" + ")}`);
    for (const { item, amounts, options } of t.questions) {
      const rows = [
        amounts.length
          ? `amounts: ${item.amount} ${item.kcal}, ${amounts.map((a) => `${a.amount} ${a.kcal}`).join(", ")}`
          : "",
        options.length ? `kinds: ${options.map((o) => `${o.item} ${o.kcal}`).join(", ")}` : "",
      ].filter(Boolean);
      lines.push(`      asks: ${item.item} / ${rows.join(" / ")}`);
    }
  }
}

const specificRuns = results.filter((r) => r.specific).length * runs;
const summary = [
  `${aiModelId}, temperature ${temperature ?? "default"}, ${runs} runs of ${meals.length} meals`,
  `In range:           ${inRange}/${total} (${Math.round((100 * inRange) / total)}%)`,
  `Median spread:      ${Math.round(median(spreads) * 100)}% between runs of the same meal`,
  `Needless questions: ${needless}/${specificRuns} runs of specific meals`,
  `Vague meals asked:  ${vagueAsked}/${vagueRuns} runs`,
  `Piece foods asked the count: ${piecesAsked}/${piecesRuns} runs`,
  `Imperial amounts (oz, cups): ${imperialRuns} runs`,
];
writeFileSync(new URL("last-run.txt", here), [...summary, "", ...lines].join("\n"));
console.log([...lines.filter((line) => !line.startsWith("   ")), "", ...summary].join("\n"));
