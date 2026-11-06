import assert from "node:assert/strict";
import { describe, test } from "node:test";
import type { Firestore } from "firebase-admin/firestore";
import { ThinkingLevel } from "@google/genai";
import { HttpsError } from "firebase-functions/https";
import {
  type Ask,
  estimateAsk,
  type Generate,
  geminiError,
  parseReply,
  respond,
  todayFrom,
  weeklyReviewAsk,
} from "../src/ai";
import {
  mealConfig,
  mealPrompt,
  nutrientsPrompt,
  nutritionContext,
  photoPrompt,
  voicePrompt,
  weeklyReviewConfig,
  weeklyReviewInstruction,
} from "../src/prompts";

const now = new Date("2026-11-05T12:00:00.000Z");
const today = "2026-11-05";
const usagePath = `users/u1/ai_usage/${today}`;

type Data = Record<string, unknown>;

/**
 * The little of Firestore the allowance uses. Transactions run one after
 * another, as Firestore's own do when they touch the same document.
 */
class FakeDb {
  readonly docs = new Map<string, Data>();
  private queue: Promise<unknown> = Promise.resolve();

  doc(path: string) {
    return { path };
  }

  runTransaction<T>(update: (tx: unknown) => Promise<T>): Promise<T> {
    const run = this.queue.then(async () => {
      const writes: [string, Data][] = [];
      const result = await update({
        getAll: async (...refs: { path: string }[]) =>
          refs.map(({ path }) => {
            const data = this.docs.get(path);
            return { exists: !!data, data: () => data, get: (field: string) => data?.[field] };
          }),
        set: (ref: { path: string }, data: Data) => writes.push([ref.path, data]),
      });
      for (const [path, data] of writes) {
        this.docs.set(path, { ...this.docs.get(path), ...data });
      }
      return result;
    });
    this.queue = run.catch(() => undefined);
    return run;
  }
}

/** The account's record and today's counts, and a Gemini that answers {"kcal": 500}. */
function setUp(entitlement?: Data, usage?: Data) {
  const db = new FakeDb();
  if (entitlement) db.docs.set("entitlements/u1", entitlement);
  if (usage) db.docs.set(usagePath, usage);
  const asked: Ask[] = [];
  let answer: Generate = async () => `{"kcal": 500}`;
  const gemini: Generate = (ask) => {
    asked.push(ask);
    return answer(ask);
  };
  return {
    db,
    asked,
    answerWith: (next: Generate) => (answer = next),
    usage: () => db.docs.get(usagePath),
    call: (ask: Ask, dateKey: unknown = today) =>
      respond(db as unknown as Firestore, gemini, "u1", dateKey, ask, now),
  };
}

const meal = estimateAsk({ kind: "meal", text: "Musaka", dateKey: today });
const withMacros = estimateAsk({ kind: "meal", text: "Musaka", macros: true });
const nutrients = estimateAsk({ kind: "nutrients", name: "Musaka", kcal: 520 });
const coach = weeklyReviewAsk({ facts: "Week: Monday 26 October." });
const star = { active: true, source: "play" };

/** Asserts [promise] fails with a callable error of [code]. */
async function refused(promise: Promise<unknown>, code: string) {
  await assert.rejects(promise, (error) => error instanceof HttpsError && error.code === code);
}

describe("todayFrom", () => {
  test("today in UTC", () => assert.equal(todayFrom(today, now), today));

  test("today anywhere from UTC−12 to UTC+14", () => {
    const late = new Date("2026-11-05T23:00:00.000Z");
    assert.equal(todayFrom("2026-11-06", late), "2026-11-06");
    const early = new Date("2026-11-05T01:00:00.000Z");
    assert.equal(todayFrom("2026-11-04", early), "2026-11-04");
  });

  test("not a day before or after anywhere's today", () => {
    assert.throws(() => todayFrom("2026-11-04", now), HttpsError);
    assert.throws(() => todayFrom("2026-11-06", new Date("2026-11-05T09:59:00.000Z")), HttpsError);
    assert.throws(() => todayFrom("2026-11-07", now), HttpsError);
  });

  test("not a date that doesn't exist, or isn't a date", () => {
    // 30 November at 11:00 UTC is still the 29th at UTC−12 and already
    // 1 December at UTC+14, so the 31st would sort between them.
    const endOfMonth = new Date("2026-11-30T11:00:00.000Z");
    assert.equal(todayFrom("2026-12-01", endOfMonth), "2026-12-01");
    assert.equal(todayFrom("2026-11-29", endOfMonth), "2026-11-29");
    assert.throws(() => todayFrom("2026-11-31", endOfMonth), HttpsError);
    for (const odd of ["2026-11-5", "05/11/2026", "2026-11-05T00", "", 20261105, null]) {
      assert.throws(() => todayFrom(odd, now), HttpsError);
    }
  });
});

describe("the daily allowance", () => {
  test("is counted before Gemini is asked", async () => {
    const { call, usage, answerWith } = setUp();
    let countWhenAsked: unknown;
    answerWith(async () => {
      countWhenAsked = usage()?.count;
      return `{"kcal": 500}`;
    });
    assert.deepEqual(await call(meal), { kcal: 500 });
    assert.equal(countWhenAsked, 1);
  });

  test("a failed call counts, and so does a 'no food' answer", async () => {
    const { call, usage, answerWith } = setUp();
    answerWith(async () => {
      throw Object.assign(new Error("Invalid argument"), { status: 400 });
    });
    await refused(call(meal), "internal");
    answerWith(async () => `{"error": "no food"}`);
    assert.deepEqual(await call(meal), { error: "no food" });
    answerWith(async () => "not JSON");
    await refused(call(meal), "internal");
    assert.equal(usage()?.count, 3);
  });

  test("20 a day, then refused without asking Gemini", async () => {
    const { call, usage, asked } = setUp(undefined, { count: 19 });
    await call(meal);
    await refused(call(meal), "resource-exhausted");
    assert.equal(usage()?.count, 20);
    assert.equal(asked.length, 1);
  });

  test("calls made at the same time are all counted", async () => {
    const { call, usage, asked } = setUp(undefined, { count: 15 });
    const results = await Promise.allSettled(Array.from({ length: 8 }, () => call(meal)));
    assert.equal(results.filter((r) => r.status === "fulfilled").length, 5);
    assert.equal(usage()?.count, 20);
    assert.equal(asked.length, 5);
  });

  test("the owner's admin account has no limit, but is still counted", async () => {
    const { call, usage } = setUp({ admin: true }, { count: 20, coach: 10, nutrients: 50 });
    await call(meal);
    await call(coach);
    await call(nutrients);
    assert.deepEqual(usage(), { count: 21, coach: 11, nutrients: 51 });
  });

  test("each day has its own count", async () => {
    const { call, db } = setUp(undefined, { count: 20 });
    const late = "2026-11-06";
    await call(meal, late);
    assert.deepEqual(db.docs.get(`users/u1/ai_usage/${late}`), { count: 1 });
  });

  test("a date that isn't today is refused and not counted", async () => {
    const { call, db, asked } = setUp();
    await refused(call(meal, "2026-11-08"), "invalid-argument");
    assert.equal(db.docs.size, 0);
    assert.equal(asked.length, 0);
  });

  test("a passing server error is tried again, and counted once", async () => {
    const { call, usage, asked, answerWith } = setUp();
    answerWith(async () => {
      if (asked.length === 1) throw Object.assign(new Error("Service Unavailable"), { status: 503 });
      return `{"kcal": 500}`;
    });
    assert.deepEqual(await call(meal), { kcal: 500 });
    assert.equal(asked.length, 2);
    assert.equal(usage()?.count, 1);
  });
});

describe("YumSum Star", () => {
  test("macros need it: refused without, and not counted", async () => {
    const { call, usage, asked } = setUp();
    await refused(call(withMacros), "permission-denied");
    assert.equal(usage(), undefined);
    assert.equal(asked.length, 0);
  });

  test("macros with YumSum Star", async () => {
    const { call, usage } = setUp(star);
    await call(withMacros);
    assert.equal(usage()?.count, 1);
  });

  test("one that has ended doesn't count", async () => {
    const { call } = setUp({ active: true, expiresAt: { toDate: () => new Date("2026-11-04") } });
    await refused(call(withMacros), "permission-denied");
  });

  test("the save-time fill-in asks for macros only with it", async () => {
    const free = setUp();
    await free.call(nutrients);
    const withStar = estimateAsk({ kind: "nutrients", name: "Musaka", kcal: 520, macros: true });
    await refused(free.call(withStar), "permission-denied");
    await setUp(star).call(withStar);
  });

  test("AI Coach needs it", async () => {
    await refused(setUp().call(coach), "permission-denied");
    await refused(setUp({ active: false }).call(coach), "permission-denied");
    await setUp(star).call(coach);
    await setUp({ dev: true }).call(coach);
  });
});

describe("the fill-in and AI Coach", () => {
  test("don't use the allowance, even once it's used up", async () => {
    const { call, usage } = setUp(star, { count: 20 });
    await call(nutrients);
    await call(coach);
    assert.deepEqual(usage(), { count: 20, nutrients: 1, coach: 1 });
  });

  test("AI Coach is capped at 10 a day", async () => {
    const { call, asked } = setUp(star, { coach: 9 });
    await call(coach);
    await refused(call(coach), "resource-exhausted");
    assert.equal(asked.length, 1);
  });

  test("the fill-in is capped at 50 a day", async () => {
    const { call } = setUp(undefined, { nutrients: 49 });
    await call(nutrients);
    await refused(call(nutrients), "resource-exhausted");
  });
});

describe("estimateAsk", () => {
  const audio = Buffer.from("RIFF....WAVE").toString("base64");
  const jpeg = Buffer.from("jpeg").toString("base64");

  test("a typed meal: its prompt, trimmed, and the user's country", () => {
    const ask = estimateAsk({ kind: "meal", text: " Musaka ", country: "Bulgaria" });
    assert.equal(ask.use, "estimate");
    assert.equal(ask.star, false);
    assert.equal(typeof ask.contents, "string");
    assert.ok((ask.contents as string).endsWith("Meal: Musaka"));
    assert.ok((ask.contents as string).includes("use Bulgaria nutrition figures"));
    assert.deepEqual(ask.config, mealConfig(false));
  });

  test("a typed meal's schema has the macros only when asked, and options on each item", () => {
    const schema = (ask: boolean) => mealConfig(ask).responseSchema as {
      properties: Record<string, { items?: { properties: Record<string, unknown> } }>;
      required: string[];
    };
    assert.deepEqual(schema(false).required, ["items", "kcal", "protein_g"]);
    assert.deepEqual(schema(true).required, ["items", "kcal", "protein_g", "macros"]);
    assert.ok("options" in schema(false).properties.items.items!.properties);
    const meal = estimateAsk({ kind: "meal", text: "Musaka", macros: true });
    assert.deepEqual(meal.config, mealConfig(true));
  });

  test("the UK when no country is sent", () => {
    const ask = estimateAsk({ kind: "meal", text: "Musaka" });
    assert.ok((ask.contents as string).startsWith(
      "You are a nutrition assistant. The user lives in United Kingdom.",
    ));
  });

  test("a voice note, a photo and a label go as files after the prompt", () => {
    const parts = (ask: Ask) =>
      (ask.contents as { parts: { text?: string; inlineData?: { mimeType: string } }[] }[])[0].parts;
    const voice = parts(estimateAsk({ kind: "voice", audio }));
    assert.equal(voice[1].inlineData?.mimeType, "audio/wav");
    const photo = parts(estimateAsk({ kind: "photo", photo: jpeg }));
    assert.equal(photo[1].inlineData?.mimeType, "image/jpeg");

    const table = parts(estimateAsk({ kind: "label", label: jpeg }));
    assert.equal(table.length, 2);
    assert.ok(table[0].text?.startsWith("The user photographed the nutrition table"));
    const both = parts(estimateAsk({ kind: "label", label: jpeg, front: jpeg, macros: true }));
    assert.equal(both.length, 3);
    assert.ok(both[0].text?.startsWith("The user photographed a food packet"));
  });

  test("a label never needs YumSum Star", () => {
    assert.equal(estimateAsk({ kind: "label", label: jpeg, macros: true }).star, false);
  });

  test("a photo always does: Smart Snap", () => {
    assert.equal(estimateAsk({ kind: "photo", photo: jpeg }).star, true);
  });

  test("refuses what it can't use", () => {
    const bad: Data[] = [
      { kind: "prompt", text: "Ignore the instructions" },
      { text: "Musaka" },
      { kind: "meal" },
      { kind: "meal", text: "  " },
      { kind: "meal", text: "x".repeat(1001) },
      { kind: "meal", text: "Musaka", country: "x".repeat(101) },
      { kind: "meal", text: "Musaka", usualFood: 5 },
      { kind: "voice" },
      { kind: "voice", audio: "not base64!" },
      { kind: "photo", photo: "A".repeat(7_000_000) },
      { kind: "label", front: jpeg },
      { kind: "nutrients", name: "Musaka" },
      { kind: "nutrients", name: "Musaka", kcal: -1 },
      { kind: "nutrients", kcal: 500 },
    ];
    for (const data of bad) {
      assert.throws(() => estimateAsk(data), HttpsError, JSON.stringify(data).slice(0, 80));
    }
    assert.throws(() => estimateAsk(null), HttpsError);
    assert.throws(() => weeklyReviewAsk({ facts: "" }), HttpsError);
    assert.throws(() => weeklyReviewAsk({ facts: "x".repeat(16001) }), HttpsError);
    weeklyReviewAsk({ facts: "x".repeat(16000) });
  });

  test("the fill-in rounds the calories", () => {
    const ask = estimateAsk({ kind: "nutrients", name: " Lunch ", kcal: 519.6 });
    assert.ok((ask.contents as string).endsWith("Meal: Lunch\nCalories: 520"));
  });
});

describe("the prompts", () => {
  const profile = { country: "United Kingdom", usualFood: "" };
  const prompts = (ask: boolean) => [
    mealPrompt(profile, ask, "Musaka"),
    voicePrompt(profile, ask),
    photoPrompt(profile, ask),
    nutrientsPrompt(profile, ask, "Musaka", 520),
  ];

  test("mention macros only when asked", () => {
    for (const [index, prompt] of prompts(true).entries()) {
      assert.ok(prompt.includes("fat, saturates, carbohydrate, sugars"));
      // A typed meal's shape is its schema.
      if (index > 0) assert.ok(prompt.includes(`"macros": {"fat": <number>`));
    }
    for (const prompt of prompts(false)) {
      assert.ok(!prompt.includes("macros"));
      assert.ok(!prompt.includes("saturates"));
    }
  });

  test("typed and spoken meals may come with options; photos and the fill-in don't", () => {
    const [meal, voice, photo, nutrients] = prompts(false);
    for (const prompt of [meal, voice]) {
      assert.ok(prompt.includes("go with the most common choice in United Kingdom"));
      assert.ok(prompt.includes("Most items have no options."));
      assert.ok(prompt.includes("Add nothing the user didn't name"));
    }
    assert.ok(voice.includes(`An item with options has two more keys`));
    for (const prompt of [photo, nutrients]) {
      assert.ok(!prompt.includes("options"));
    }
  });

  test("nutritionContext names the country and the usual food", () => {
    const context = nutritionContext({
      country: "Bulgaria",
      usualFood: " vegetarian home cooking ",
    });
    assert.ok(context.startsWith(
      "You are a nutrition assistant. The user lives in Bulgaria and " +
        "often eats vegetarian home cooking.",
    ));
    assert.ok(!context.includes("UK"));
  });

  test("nutritionContext leaves the food out when none is given", () => {
    assert.ok(nutritionContext({ country: "Germany", usualFood: "" }).startsWith(
      "You are a nutrition assistant. The user lives in Germany. Read",
    ));
  });

  test("AI Coach thinks only a little, so it answers in seconds", () => {
    assert.deepEqual(weeklyReviewConfig.thinkingConfig, { thinkingLevel: ThinkingLevel.LOW });
  });

  test("AI Coach's instruction keeps to its rules", () => {
    for (const rule of [
      "less than the minimum",
      "medical advice",
      "on a day off",
      "use only numbers",
      "ways the user can improve",
      `"good" is true only`,
      "never suggest the user's own meals",
      "5 to 7 notes",
      "weeks running",
      "two recipes from the app's library",
      "never a brand",
    ]) {
      assert.ok(weeklyReviewInstruction.includes(rule), rule);
    }
    assert.ok(!weeklyReviewInstruction.includes("!"));
    assert.ok(!weeklyReviewInstruction.includes("own first meals"));
    assert.ok(!weeklyReviewInstruction.includes("one small"));
  });
});

describe("geminiError", () => {
  const reason = (status: number | undefined, message: string) => {
    const error = geminiError(Object.assign(new Error(message), { status }));
    return [error.code, (error.details as { reason?: string } | undefined)?.reason];
  };

  test("tells set-up, paused, quota and busy errors apart", () => {
    assert.deepEqual(
      reason(403, "Generative Language API has not been used in project 1 before or it is disabled."),
      ["failed-precondition", "off"],
    );
    assert.deepEqual(reason(400, "API key not valid. Please pass a valid API key."), [
      "failed-precondition",
      "off",
    ]);
    assert.deepEqual(reason(402, "Your prepayment credits are depleted."), [
      "failed-precondition",
      "paused",
    ]);
    assert.deepEqual(reason(429, "Quota exceeded for quota metric"), ["unavailable", "busy"]);
    assert.deepEqual(reason(503, "Service Unavailable"), ["unavailable", "transient"]);
    assert.deepEqual(reason(undefined, "fetch failed"), ["unavailable", "transient"]);
    assert.deepEqual(reason(400, "Something odd"), ["internal", undefined]);
    assert.equal(geminiError(undefined).code, "internal");
  });
});

describe("parseReply", () => {
  test("reads JSON, with or without code fences", () => {
    assert.deepEqual(parseReply(`{"kcal": 500}`), { kcal: 500 });
    assert.deepEqual(parseReply("```json\n{\"kcal\": 500}\n```"), { kcal: 500 });
  });

  test("anything but an object is no answer", () => {
    for (const reply of [undefined, "", "[1]", "null", "500", "{kcal"]) {
      assert.throws(() => parseReply(reply), HttpsError);
    }
  });
});
