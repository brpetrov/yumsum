// The typed-estimate test set: runs each meal in meals.json through the real
// meal prompt a few times and reports how often the total lands in range,
// how far the same words move between runs, and how often the app would ask
// (after the same option filter as parseEstimateItems and
// offerEstimateChoices in the app). Run it before and after any prompt
// change:
//
//   npm run eval                      3 runs a meal, the model's temperature
//   npm run eval -- --runs 5 --temperature 0.3
//
// Every run is printed to eval/last-run.txt (gitignored). About a penny a
// run of the whole set. The Gemini key comes from GEMINI_API_KEY, or else
// from the Functions secret through the Firebase CLI; it is never printed.

import { execSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { GoogleGenAI } = require("@google/genai");
const { aiModelId, mealConfig, mealPrompt } = require("../lib/src/prompts.js");

const arg = (name, fallback) => {
  const at = process.argv.indexOf(`--${name}`);
  return at > 0 ? Number(process.argv[at + 1]) : fallback;
};
const runs = arg("runs", 3);
const temperature = arg("temperature", undefined);
const here = new URL(".", import.meta.url);
const { meals } = JSON.parse(readFileSync(new URL("meals.json", here), "utf8"));

const apiKey =
  process.env.GEMINI_API_KEY ||
  execSync("firebase functions:secrets:access GEMINI_API_KEY", {
    stdio: ["ignore", "pipe", "ignore"],
  })
    .toString()
    .trim();
const ai = new GoogleGenAI({ apiKey });
const profile = { country: "United Kingdom", usualFood: "" };
const config = { ...mealConfig(false), ...(temperature === undefined ? {} : { temperature }) };

// The app's filter: options at least 30 kcal from the item and each other,
// under new names that keep every word of the item's name the user typed,
// at most 3; questions for at most 2 items a meal.
const words = (text) =>
  new Set(text.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((word) => word.length > 2));
function asked(item, said) {
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
  return options;
}

async function estimate(meal) {
  const reply = await ai.models.generateContent({
    model: aiModelId,
    contents: mealPrompt(profile, false, meal),
    config,
  });
  const json = JSON.parse(reply.text);
  const items = Array.isArray(json.items) ? json.items : [];
  const said = words(meal);
  const questions = items
    .map((item) => ({ item, options: asked(item, said) }))
    .filter(({ options }) => options.length > 0)
    .slice(0, 2);
  return {
    kcal: items.reduce((sum, item) => sum + item.kcal, 0),
    items,
    questions,
  };
}

const median = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
};

const results = await Promise.all(
  meals.map(async (case_) => {
    const tries = [];
    for (let run = 0; run < runs; run++) {
      try {
        tries.push(await estimate(case_.meal));
      } catch (error) {
        tries.push({ error: String(error.message ?? error).slice(0, 120) });
      }
    }
    return { ...case_, tries };
  }),
);

const lines = [];
let inRange = 0;
let total = 0;
let needless = 0;
let vagueAsked = 0;
let vagueRuns = 0;
const spreads = [];
for (const { meal, min, max, specific, tries } of results) {
  const good = tries.filter((t) => !t.error);
  const kcals = good.map((t) => t.kcal);
  const hits = kcals.filter((kcal) => kcal >= min && kcal <= max).length;
  const spread = kcals.length ? (Math.max(...kcals) - Math.min(...kcals)) / Math.max(median(kcals), 1) : 0;
  const asks = good.filter((t) => t.questions.length > 0).length;
  inRange += hits;
  total += tries.length;
  spreads.push(spread);
  if (specific) needless += asks;
  else {
    vagueAsked += asks;
    vagueRuns += good.length;
  }
  const flag = hits < tries.length ? " <- out of range" : "";
  const asking = specific && asks ? " <- asked" : "";
  lines.push(
    `${meal} [${min}-${max}]: ${kcals.join(", ")}${tries.length > good.length ? ", error" : ""}` +
      ` (spread ${Math.round(spread * 100)}%)${flag}${asking}`,
  );
  for (const t of tries) {
    if (t.error) {
      lines.push(`   error: ${t.error}`);
      continue;
    }
    lines.push(`   ${t.items.map((item) => `${item.item} ${item.kcal}`).join(" + ")}`);
    for (const { item, options } of t.questions) {
      lines.push(`      asks: ${item.item} / ${options.map((o) => `${o.item} ${o.kcal}`).join(" / ")}`);
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
];
writeFileSync(new URL("last-run.txt", here), [...summary, "", ...lines].join("\n"));
console.log([...lines.filter((line) => !line.startsWith("   ")), "", ...summary].join("\n"));
