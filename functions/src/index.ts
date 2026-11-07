import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  type DocumentReference,
  FieldValue,
  getFirestore,
  type Transaction,
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { setGlobalOptions } from "firebase-functions/options";
import { onMessagePublished } from "firebase-functions/pubsub";
import {
  boughtFor,
  entitlementFrom,
  isCurrentOrNewer,
  isPlusAt,
  purchaseIdFor,
  replacedTokens,
  type Stored,
  type Subscription,
} from "./entitlement";
import {
  acknowledge,
  getSubscription,
  isUnknownToken,
  packageName,
  productId,
} from "./play";

export { aiEstimate, aiWeeklyReview } from "./ai";

setGlobalOptions({ region: "europe-west10", maxInstances: 10 });
initializeApp();
const db = getFirestore();

// After setGlobalOptions: onCall reads the region as each is defined.
export { deleteAccount } from "./account";
export { sendVerificationEmail } from "./email";
export { sendFeedback } from "./feedback";
export { contributeProduct } from "./off";

/**
 * Checks a purchase with Play, links it to the caller's account and writes
 * their entitlement. Returns whether YumSum Star is on afterwards.
 */
export const verifyPurchase = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = signedIn(request.auth);
  const token = (request.data as { purchaseToken?: unknown } | null)?.purchaseToken;
  if (typeof token !== "string" || !token) {
    throw new HttpsError("invalid-argument", "No purchase token.");
  }

  let subscription: Subscription;
  try {
    subscription = await getSubscription(token);
  } catch (error) {
    logger.warn("Could not read the purchase from Play", error);
    if (isUnknownToken(error)) {
      throw new HttpsError("not-found", "Google Play doesn't know it.");
    }
    throw new HttpsError("unavailable", "Could not reach Google Play.");
  }
  if (subscription.lineItems?.[0]?.productId !== productId) {
    throw new HttpsError("invalid-argument", "Not YumSum Star.");
  }
  if (!boughtFor(subscription, uid)) {
    throw new HttpsError("already-exists", "Bought for another account.");
  }

  const purchaseId = purchaseIdFor(token);
  const linkRef = db.doc(`playPurchases/${purchaseId}`);
  const entitlementRef = db.doc(`entitlements/${uid}`);
  const plus = await db.runTransaction(async (tx) => {
    const [link, entitlement] = await tx.getAll(linkRef, entitlementRef);
    const owner = link.get("uid") as string | undefined;
    if (owner !== uid) {
      // A purchase stays with the first account, unless it was deleted.
      if (owner && (await accountExists(owner))) {
        throw new HttpsError("already-exists", "Linked to another account.");
      }
      tx.set(linkRef, linkFor(uid, subscription));
    }
    const previous = entitlement.data() as Stored | undefined;
    return writeEntitlement(tx, entitlementRef, purchaseId, subscription, previous);
  });

  // The app's completePurchase acknowledges too, and so does the
  // notification, so a failure here doesn't fail the check.
  try {
    await acknowledgeIfPending(token, subscription);
  } catch (error) {
    logger.error(`Could not acknowledge ${purchaseId}`, error);
  }
  return { plus };
});

/**
 * Play's real-time notifications. Whatever the type, it reads the purchase
 * again, as Google advises. Anything permanent returns normally, so Pub/Sub
 * retries only what might work later.
 */
export const playNotifications = onMessagePublished(
  { topic: "play-billing", retry: true },
  async (event) => {
    let notice: PlayNotice;
    try {
      notice = event.data.message.json;
    } catch {
      logger.warn("Not a Play notification");
      return;
    }
    if (notice.packageName !== packageName) {
      logger.warn("Notification for another app", notice.packageName);
      return;
    }
    if (notice.testNotification) {
      logger.info("Play test notification", notice);
      return;
    }
    if (notice.pendingRefundReviewNotification) {
      logger.warn("Chargeback to review within 24 hours", {
        orderId: notice.pendingRefundReviewNotification.orderId,
      });
      return;
    }

    const voided = notice.voidedPurchaseNotification;
    const token = notice.subscriptionNotification?.purchaseToken ??
      (voided?.productType === 1 ? voided.purchaseToken : undefined);
    if (!token) return;

    let subscription: Subscription;
    try {
      subscription = await getSubscription(token);
    } catch (error) {
      if (!isUnknownToken(error)) throw error;
      logger.warn("Google Play doesn't know this purchase", error);
      return;
    }
    if (subscription.lineItems?.[0]?.productId !== productId) return;

    const purchaseId = purchaseIdFor(token);
    const uid = await accountFor(purchaseId, subscription);
    if (!uid) {
      logger.info("Purchase not linked yet; the app links it", { purchaseId });
      return;
    }

    const linkRef = db.doc(`playPurchases/${purchaseId}`);
    const entitlementRef = db.doc(`entitlements/${uid}`);
    await db.runTransaction(async (tx) => {
      const [link, entitlement] = await tx.getAll(linkRef, entitlementRef);
      const previous = entitlement.data() as Stored | undefined;
      // Found through the purchase it replaced: link it directly, because
      // Play drops expiredPurchaseToken once it's acknowledged.
      if (!link.exists) tx.set(linkRef, linkFor(uid, subscription));
      if (!isCurrentOrNewer(subscription, purchaseId, previous?.purchaseId)) {
        logger.info("Older purchase, left alone", { purchaseId });
        return;
      }
      writeEntitlement(tx, entitlementRef, purchaseId, subscription, previous);
    });
    await acknowledgeIfPending(token, subscription);
  },
);

/**
 * Deletes the caller's entitlement and purchase links, before their account
 * goes. It doesn't cancel the Play subscription.
 */
export const deleteBillingData = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = signedIn(request.auth);
  const links = await db.collection("playPurchases").where("uid", "==", uid).get();
  const batch = db.batch();
  batch.delete(db.doc(`entitlements/${uid}`));
  links.forEach((link) => batch.delete(link.ref));
  await batch.commit();
  return {};
});

/** What Play publishes: developer.android.com/google/play/billing/rtdn-reference */
interface PlayNotice {
  packageName?: string;
  subscriptionNotification?: { purchaseToken?: string };
  voidedPurchaseNotification?: { purchaseToken?: string; productType?: number };
  pendingRefundReviewNotification?: { orderId?: string };
  testNotification?: object;
}

function signedIn(auth: { uid: string } | undefined): string {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return auth.uid;
}

async function accountExists(uid: string): Promise<boolean> {
  try {
    await getAuth().getUser(uid);
    return true;
  } catch (error) {
    if ((error as { code?: string }).code === "auth/user-not-found") return false;
    throw error;
  }
}

/** The account a purchase belongs to, or the purchase it replaced. */
async function accountFor(purchaseId: string, subscription: Subscription) {
  const ids = [purchaseId, ...replacedTokens(subscription).map(purchaseIdFor)];
  for (const id of ids) {
    const link = await db.doc(`playPurchases/${id}`).get();
    if (link.exists) return link.get("uid") as string;
  }
  return undefined;
}

function linkFor(uid: string, subscription: Subscription) {
  const orderId = subscription.lineItems?.[0]?.latestSuccessfulOrderId ?? null;
  return { uid, linkedAt: new Date(), orderId };
}

/** Returns whether YumSum Star is on once the transaction commits. */
function writeEntitlement(
  tx: Transaction,
  ref: DocumentReference,
  purchaseId: string,
  subscription: Subscription,
  previous: Stored | undefined,
): boolean {
  const now = new Date();
  const fields = entitlementFrom(subscription, previous, now);
  if (!fields) return isPlusAt(previous, now);

  // Merged, so the owner's admin and dev stay; a null removes the field.
  const update = Object.fromEntries(
    Object.entries({ ...fields, purchaseId }).map(([key, value]) => [
      key,
      value ?? FieldValue.delete(),
    ]),
  );
  tx.set(ref, update, { merge: true });
  return isPlusAt({ ...previous, ...fields }, now);
}

async function acknowledgeIfPending(token: string, subscription: Subscription) {
  if (!needsAcknowledging(subscription)) return;
  try {
    await acknowledge(token);
  } catch (error) {
    // Play doesn't say what it answers when the app or the other function
    // got there first (two at once is a 409), so look again.
    if (needsAcknowledging(await getSubscription(token))) throw error;
  }
}

function needsAcknowledging(subscription: Subscription): boolean {
  const state = subscription.subscriptionState;
  return subscription.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING" &&
    (state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD");
}
