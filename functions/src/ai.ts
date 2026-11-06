import {
  type ContentListUnion,
  type GenerateContentConfig,
  GoogleGenAI,
  type Part,
} from "@google/genai";
import { type Firestore, getFirestore } from "firebase-admin/firestore";
import {
  type CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { isPlusAt, type Stored } from "./entitlement";
import {
  aiModelId,
  jsonReply,
  labelPrompt,
  mealConfig,
  mealPrompt,
  nutrientsPrompt,
  photoPrompt,
  type Profile,
  voicePrompt,
  weeklyReviewConfig,
} from "./prompts";

// Every Gemini call goes through these two functions: the app sends what the
// user gave (text, audio, photos, a week's facts) and never a prompt. The
// account's allowance and YumSum Star are checked here, before Gemini is
// asked.

/**
 * The Gemini Developer API key, in Secret Manager. Not Vertex AI: the Gemini
 * API's prepaid credit, with auto-reload off, caps what AI can ever cost
 * (plan 03), and Vertex AI is billed on the normal Cloud cycle with no cap.
 */
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// The region and instances of setGlobalOptions, set here as well because
// index.ts imports this file before it calls setGlobalOptions.
const options = {
  region: "europe-west10",
  maxInstances: 10,
  enforceAppCheck: true,
  secrets: [geminiApiKey],
};

/** What a call counts against, in `users/{uid}/ai_usage/{date}`. */
export type Use = "estimate" | "nutrients" | "coach";

/**
 * Each use's field in the day's document and its limit. `count` is the daily
 * allowance the app shows (`AiUsageRepository.dailyLimit`). The save-time
 * fill-in and AI Coach don't use it, as before; their caps are only there so
 * they can't be scripted. The owner's admin account has no limit.
 */
export const limits: Record<Use, { field: string; perDay: number }> = {
  estimate: { field: "count", perDay: 20 },
  nutrients: { field: "nutrients", perDay: 50 },
  coach: { field: "coach", perDay: 10 },
};

/** One call to Gemini, and what it needs before it's made. */
export interface Ask {
  use: Use;
  /** Whether it needs YumSum Star: macros, a photo (Smart Snap), or AI Coach. */
  star: boolean;
  contents: ContentListUnion;
  config: GenerateContentConfig;
}

/** Sends an [Ask] to Gemini and returns the reply's text. */
export type Generate = (ask: Ask) => Promise<string | undefined>;

/**
 * An estimate, by `kind`:
 * - `meal`: `text`, the meal as typed;
 * - `voice`: `audio`, a WAV voice note in base64;
 * - `photo`: `photo`, a JPEG in base64;
 * - `label`: `label`, the nutrition table, and optionally `front`, the front
 *   of the pack, JPEGs in base64, for a contribution;
 * - `nutrients`: `name` and `kcal`, the fill-in when a named meal is saved.
 * All take `dateKey` (the phone's date, yyyy-MM-dd), and all but `label`
 * take `country`, `usualFood` and `macros` (true for YumSum Star). Returns
 * the model's JSON reply as it is, which the app reads.
 */
export const aiEstimate = onCall(options, (request) => {
  const uid = signedIn(request);
  const ask = estimateAsk(request.data);
  return respond(getFirestore(), gemini, uid, dataOf(request.data).dateKey, ask, new Date());
});

/**
 * AI Coach's notes on a week, for YumSum Star: `facts`, the week as the app
 * worked it out, and `dateKey`. Returns `{points: [{text, good}]}`.
 */
export const aiWeeklyReview = onCall(options, (request) => {
  const uid = signedIn(request);
  const ask = weeklyReviewAsk(request.data);
  return respond(getFirestore(), gemini, uid, dataOf(request.data).dateKey, ask, new Date());
});

// Room for a 30-second voice note at 16 kHz and a phone photo.
const maxAudioBytes = 2_000_000;
const maxPhotoBytes = 5_000_000;

/** The call an estimate makes, from what the app sent. */
export function estimateAsk(raw: unknown): Ask {
  const data = dataOf(raw);
  const profile: Profile = {
    country: text(data.country, 100) || "United Kingdom",
    usualFood: text(data.usualFood, 500),
  };
  const macros = data.macros === true;
  const estimate = (contents: ContentListUnion): Ask => ({
    use: "estimate",
    star: macros,
    contents,
    config: jsonReply,
  });

  switch (data.kind) {
    case "meal":
      return {
        ...estimate(mealPrompt(profile, macros, filled(text(data.text, 1000).trim()))),
        config: mealConfig(macros),
      };
    case "voice":
      return estimate(
        withMedia(voicePrompt(profile, macros), [media(data.audio, "audio/wav", maxAudioBytes)]),
      );
    case "photo":
      return {
        ...estimate(
          withMedia(photoPrompt(profile, macros), [media(data.photo, "image/jpeg", maxPhotoBytes)]),
        ),
        // Smart Snap is YumSum Star only, whatever the app says about macros.
        star: true,
      };
    case "label": {
      const front = data.front == null
        ? []
        : [media(data.front, "image/jpeg", maxPhotoBytes)];
      const label = media(data.label, "image/jpeg", maxPhotoBytes);
      return {
        use: "estimate",
        star: false,
        contents: withMedia(labelPrompt(front.length > 0), [...front, label]),
        config: jsonReply,
      };
    }
    case "nutrients": {
      const kcal = data.kcal;
      if (typeof kcal !== "number" || !Number.isFinite(kcal) || kcal < 0 || kcal > 100_000) {
        throw new HttpsError("invalid-argument", "No calories.");
      }
      return {
        use: "nutrients",
        star: macros,
        contents: nutrientsPrompt(
          profile,
          macros,
          filled(text(data.name, 500).trim()),
          Math.round(kcal),
        ),
        config: jsonReply,
      };
    }
    default:
      throw new HttpsError("invalid-argument", "Unknown estimate.");
  }
}

/** AI Coach's call, from the week's facts. */
export function weeklyReviewAsk(raw: unknown): Ask {
  return {
    use: "coach",
    star: true,
    contents: filled(text(dataOf(raw).facts, 16000)),
    config: weeklyReviewConfig,
  };
}

/** Counts the call, then asks Gemini and returns its JSON reply. */
export async function respond(
  db: Firestore,
  generate: Generate,
  uid: string,
  dateKey: unknown,
  ask: Ask,
  now: Date,
): Promise<Record<string, unknown>> {
  await reserve(db, uid, todayFrom(dateKey, now), ask, now);
  return parseReply(await withRetries(() => generate(ask)));
}

/**
 * Counts the call in the day's document before Gemini is asked, in a
 * transaction, so calls made at the same time are all counted, and a failed
 * call or a "no food" answer counts too. Throws `permission-denied` when it
 * needs YumSum Star and the account hasn't got it, and `resource-exhausted`
 * once the day's limit is used up.
 */
export async function reserve(
  db: Firestore,
  uid: string,
  dateKey: string,
  ask: Ask,
  now: Date,
): Promise<void> {
  const usageRef = db.doc(`users/${uid}/ai_usage/${dateKey}`);
  const entitlementRef = db.doc(`entitlements/${uid}`);
  const { field, perDay } = limits[ask.use];
  await db.runTransaction(async (tx) => {
    const [usage, record] = await tx.getAll(usageRef, entitlementRef);
    const entitlement = record.data() as Stored | undefined;
    if (ask.star && !isPlusAt(entitlement, now)) {
      throw new HttpsError("permission-denied", "That needs YumSum Star.");
    }
    const stored: unknown = usage.get(field);
    const used = typeof stored === "number" ? stored : 0;
    if (entitlement?.admin !== true && used >= perDay) {
      throw new HttpsError("resource-exhausted", "Today's limit is used up.");
    }
    tx.set(usageRef, { [field]: used + 1 }, { merge: true });
  });
}

/**
 * The phone's date, accepted only while it is today somewhere on Earth
 * (UTC−12 to UTC+14), so changing the phone's date can't start a new day.
 */
export function todayFrom(dateKey: unknown, now: Date): string {
  const dayAt = (hours: number) =>
    new Date(now.getTime() + hours * 3_600_000).toISOString().slice(0, 10);
  if (
    typeof dateKey === "string" &&
    /^\d{4}-\d{2}-\d{2}$/.test(dateKey) &&
    isRealDate(dateKey) &&
    dateKey >= dayAt(-12) &&
    dateKey <= dayAt(14)
  ) {
    return dateKey;
  }
  throw new HttpsError("invalid-argument", "Not today's date.");
}

function isRealDate(dateKey: string): boolean {
  const date = new Date(`${dateKey}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(dateKey);
}

/** The model's JSON reply as an object; code fences are stripped just in case. */
export function parseReply(reply: string | undefined): Record<string, unknown> {
  const json = (reply ?? "")
    .replace(/```(?:json)?\s*/g, "")
    .replace(/```/g, "")
    .trim();
  try {
    const value: unknown = JSON.parse(json);
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }
  } catch {
    // Not JSON: the same failure as no reply.
  }
  logger.warn("No usable answer from the AI");
  throw new HttpsError("internal", "No usable answer from the AI.");
}

/**
 * The callable's error for a failed Gemini call, told apart by its status
 * and wording as the app did: `failed-precondition` when the AI isn't
 * switched on or is paused (an empty prepaid balance is a 402), and
 * `unavailable` when it's busy (a per-minute quota, 429) or has a passing
 * server error. `details.reason` says which.
 */
export function geminiError(error: unknown): HttpsError {
  const { status, message } = (error ?? {}) as { status?: unknown; message?: unknown };
  const said = `${status ?? ""} ${message ?? ""}`.toLowerCase();
  if (/has not been used|is disabled|not enabled|api key not valid|unregistered callers/.test(said)) {
    return new HttpsError("failed-precondition", "The AI isn't switched on.", { reason: "off" });
  }
  if (/402|payment|prepay|credit|billing/.test(said)) {
    return new HttpsError("failed-precondition", "The AI is paused.", { reason: "paused" });
  }
  if (/quota|429|resource_exhausted/.test(said)) {
    return new HttpsError("unavailable", "The AI is busy.", { reason: "busy" });
  }
  if (isTransient(said)) {
    return new HttpsError("unavailable", "The AI is busy.", { reason: "transient" });
  }
  return new HttpsError("internal", "The AI call failed.");
}

function isTransient(said: string): boolean {
  return /503|500|unavailable|high demand|overloaded|timed out|fetch failed/.test(said);
}

const maxAttempts = 3;

/**
 * Asks Gemini with up to 3 attempts on passing server errors. A busy minute
 * isn't retried: a per-minute limit doesn't clear in a few seconds.
 */
async function withRetries(call: () => Promise<string | undefined>) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await call();
    } catch (error) {
      const failure = geminiError(error);
      const reason = (failure.details as { reason?: string } | undefined)?.reason;
      if (reason !== "transient" || attempt === maxAttempts) {
        logger.warn("Gemini call failed", { error: String(error) });
        throw failure;
      }
      await new Promise((resolve) => setTimeout(resolve, 700 * attempt));
    }
  }
}

let client: GoogleGenAI | undefined;

/** Asks Gemini, and logs the tokens the call used, which is what it costs. */
const gemini: Generate = async ({ use, contents, config }) => {
  client ??= new GoogleGenAI({ vertexai: false, apiKey: geminiApiKey.value() });
  const response = await client.models.generateContent({
    model: aiModelId,
    contents,
    config,
  });
  const usage = response.usageMetadata;
  logger.info("AI tokens", {
    use,
    in: usage?.promptTokenCount,
    out: usage?.candidatesTokenCount,
    thinking: usage?.thoughtsTokenCount,
  });
  return response.text;
};

function signedIn(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return request.auth.uid;
}

function dataOf(raw: unknown): Record<string, unknown> {
  return raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
}

/** [value] as text, "" when it's missing; refused when it's longer than [max]. */
function text(value: unknown, max: number): string {
  if (value == null) return "";
  if (typeof value !== "string" || value.length > max) {
    throw new HttpsError("invalid-argument", `Not text of at most ${max} characters.`);
  }
  return value;
}

function filled(value: string): string {
  if (!value) throw new HttpsError("invalid-argument", "Nothing to ask about.");
  return value;
}

/** A base64 file of at most [maxBytes], as Gemini takes it. */
function media(value: unknown, mimeType: string, maxBytes: number): Part {
  if (
    typeof value !== "string" ||
    value.length > Math.ceil(maxBytes / 3) * 4 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value)
  ) {
    throw new HttpsError("invalid-argument", `No usable ${mimeType}.`);
  }
  return { inlineData: { mimeType, data: value } };
}

function withMedia(prompt: string, files: Part[]): ContentListUnion {
  return [{ role: "user", parts: [{ text: prompt }, ...files] }];
}
