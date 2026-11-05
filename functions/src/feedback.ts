import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { countToday, signedIn } from "./account";

/** The help.yumsum Formspree form, which emails help.yumsum@gmail.com. */
const form = "https://formspree.io/f/mqppllqo";

/**
 * Messages a day per account: plenty for anyone with something to say, and
 * one person can't use up the form's 50 a month. The app says so too.
 */
export const dailyLimit = 3;

const kinds = ["Problem", "Idea", "Other"];

/**
 * Emails the caller's feedback through Formspree, with the uid and email
 * they signed in with, so neither can be made up.
 */
export const sendFeedback = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = signedIn(request.auth);
  const body = formspreeBody(request.data, uid, request.auth?.token.email);
  const counter = await countToday(uid, "feedback_usage", dailyLimit);
  try {
    await deliver(body);
  } catch (error) {
    // Only what's sent counts, as on the phone.
    await counter.update({ count: FieldValue.increment(-1) });
    throw error;
  }
  return {};
});

/** Formspree's JSON for the app's `{kind, text, app}`. */
export function formspreeBody(data: unknown, uid: string, email: unknown) {
  const { kind, text, app } = (data ?? {}) as Record<string, unknown>;
  if (
    typeof kind !== "string" || !kinds.includes(kind) ||
    typeof text !== "string" || !text.trim() || text.length > 4000 ||
    typeof app !== "string" || app.length > 60
  ) {
    throw new HttpsError("invalid-argument", "Not feedback.");
  }
  if (typeof email !== "string" || !email) {
    throw new HttpsError("failed-precondition", "No email to reply to.");
  }
  return { _subject: `YumSum feedback: ${kind}`, email, message: text, user: uid, app };
}

export async function deliver(body: object, post: typeof fetch = fetch) {
  let response: Response;
  try {
    response = await post(form, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(30_000),
    });
  } catch (error) {
    logger.warn("Could not reach Formspree", error);
    throw new HttpsError("unavailable", "Could not reach Formspree.");
  }
  if (response.status !== 200) {
    logger.warn(`Formspree said ${response.status}`);
    throw new HttpsError("unavailable", "Formspree didn't take it.");
  }
}
