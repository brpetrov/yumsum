import { getAuth } from "firebase-admin/auth";
import { type DocumentReference, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";

/**
 * The counters under `users/{uid}`: the app's AI allowance and past-day
 * edits, and the functions' own daily limits. The app can't delete any of
 * them, so only a new account starts them again.
 */
export const counters = [
  "ai_usage",
  "day_edits",
  "contribution_usage",
  "feedback_usage",
];

/**
 * Deletes the caller's counters, then their sign-in account. The app has
 * deleted the rest of their data by then.
 */
export const deleteAccount = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = signedIn(request.auth);
  const db = getFirestore();
  for (const name of counters) {
    await db.recursiveDelete(db.collection(`users/${uid}/${name}`));
  }
  await getAuth().deleteUser(uid);
  return {};
});

export function signedIn(auth: { uid: string } | undefined): string {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return auth.uid;
}

/** The day a daily limit counts, yyyy-MM-dd in UTC. */
export function dayKey(now: Date): string {
  return now.toISOString().slice(0, 10);
}

/**
 * Counts one more use of a daily limit in `users/{uid}/{collection}/{day}`,
 * or refuses with resource-exhausted once [limit] are used. Returns the
 * counter, so a use that didn't happen can be given back.
 */
export async function countToday(
  uid: string,
  collection: string,
  limit: number,
): Promise<DocumentReference> {
  const db = getFirestore();
  const ref = db.doc(`users/${uid}/${collection}/${dayKey(new Date())}`);
  await db.runTransaction(async (tx) => {
    const count = ((await tx.get(ref)).get("count") as number | undefined) ?? 0;
    if (count >= limit) {
      throw new HttpsError("resource-exhausted", "That's all for today.");
    }
    tx.set(ref, { count: count + 1 });
  });
  return ref;
}
