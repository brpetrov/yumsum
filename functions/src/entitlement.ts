import { createHash } from "node:crypto";
import type { androidpublisher_v3 } from "@googleapis/androidpublisher";

/** Play's answer from `purchases.subscriptionsv2.get`. */
export type Subscription = androidpublisher_v3.Schema$SubscriptionPurchaseV2;

/** A Firestore Timestamp as read back, or a Date as written. */
type When = Date | { toDate(): Date };

/** `entitlements/{uid}` as stored, as far as the functions care. */
export interface Stored {
  active?: boolean;
  source?: string;
  startedAt?: When | null;
  expiresAt?: When | null;
  endedAt?: When | null;
  purchaseId?: string;
  admin?: boolean;
  dev?: boolean;
  /** The account's email, for the console's list only; nothing reads it. */
  email?: string | null;
}

/**
 * The fields a Play write sets, merged into the document so the owner's
 * `admin` and `dev` stay. A null removes the field.
 */
export interface PlayFields {
  active: boolean;
  state: string;
  inTrial: boolean;
  productId: string;
  basePlan: string | null;
  startedAt: Date | null;
  expiresAt: Date | null;
  endedAt: Date | null;
  source: "play";
  updatedAt: Date;
}

// Play's subscriptionState: whether YumSum Star is on, and the document's
// state. Cancelled stays on until expiryTime, which entitlementFrom checks.
const states: Record<string, [boolean, string]> = {
  SUBSCRIPTION_STATE_ACTIVE: [true, "active"],
  SUBSCRIPTION_STATE_IN_GRACE_PERIOD: [true, "grace"],
  SUBSCRIPTION_STATE_CANCELED: [true, "cancelled"],
  SUBSCRIPTION_STATE_ON_HOLD: [false, "hold"],
  SUBSCRIPTION_STATE_PAUSED: [false, "paused"],
  SUBSCRIPTION_STATE_EXPIRED: [false, "expired"],
  SUBSCRIPTION_STATE_PENDING: [false, "pending"],
  SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED: [false, "expired"],
};

/**
 * The entitlement's fields from Play's answer, or null when a live manual
 * grant is there, which a purchase never replaces.
 */
export function entitlementFrom(
  subscription: Subscription,
  previous: Stored | undefined,
  now: Date,
): PlayFields | null {
  if (previous && isLiveManualGrant(previous, now)) return null;

  const item = subscription.lineItems?.[0];
  const expiresAt = item?.expiryTime ? new Date(item.expiryTime) : null;
  // A state Play adds later counts as off until it's mapped here.
  const [on, state] = states[subscription.subscriptionState ?? ""] ?? [
    false,
    "expired",
  ];
  const active = state === "cancelled" ? !!expiresAt && expiresAt > now : on;

  return {
    active,
    state,
    inTrial: active && !!item?.offerPhase?.freeTrial,
    productId: item?.productId ?? "",
    basePlan: item?.offerDetails?.basePlanId ?? null,
    startedAt: active ? startedAt(previous, now) : null,
    expiresAt,
    endedAt: active ? null : endedAt(previous, now),
    source: "play",
    updatedAt: now,
  };
}

/**
 * When YumSum Star switched on: kept while it stays on, otherwise now (a
 * first purchase, or back after a lapse). AI Coach writes notes only on
 * weeks from then.
 */
function startedAt(previous: Stored | undefined, now: Date): Date {
  return (previous?.active === true && dateOf(previous.startedAt)) || now;
}

/**
 * When YumSum Star last switched off. Going from on to off it's now, or the
 * old expiry if that passed first (a late notification); otherwise whatever
 * was stored.
 */
function endedAt(previous: Stored | undefined, now: Date): Date | null {
  if (previous?.active !== true) return dateOf(previous?.endedAt);
  const expired = dateOf(previous.expiresAt);
  return expired && expired < now ? expired : now;
}

/** The same check as the app's `Entitlement.isPlusAt`. */
export function isPlusAt(entitlement: Stored | undefined, now: Date): boolean {
  if (!entitlement) return false;
  return entitlement.admin === true || entitlement.dev === true ||
    isActiveAt(entitlement, now);
}

function isActiveAt(entitlement: Stored, now: Date): boolean {
  const expiresAt = dateOf(entitlement.expiresAt);
  return entitlement.active === true && (!expiresAt || expiresAt > now);
}

// The app reads a missing source as manual, so this does too.
function isLiveManualGrant(previous: Stored, now: Date): boolean {
  return (previous.source ?? "manual") === "manual" &&
    isActiveAt(previous, now);
}

/** The purchases this one replaced: a plan change, or resubscribing in Play. */
export function replacedTokens(subscription: Subscription): string[] {
  return [
    subscription.linkedPurchaseToken,
    subscription.outOfAppPurchaseContext?.expiredPurchaseToken,
  ].filter((token): token is string => !!token);
}

/**
 * Whether a notification about this purchase may write the account's
 * entitlement: it's the current purchase, it replaced the current one, or
 * there's none. A late "expired" for a replaced purchase is left alone.
 */
export function isCurrentOrNewer(
  subscription: Subscription,
  purchaseId: string,
  current: string | undefined,
): boolean {
  if (!current || current === purchaseId) return true;
  return replacedTokens(subscription).some(
    (token) => purchaseIdFor(token) === current,
  );
}

/**
 * Whether a purchase may be linked to [uid]. The app buys with the
 * account's SHA-256 as Play's obfuscated account ID, so a purchase with
 * another ID belongs to another account. One with none was bought outside
 * the app, and goes to the first account that checks it.
 */
export function boughtFor(subscription: Subscription, uid: string): boolean {
  const account =
    subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  return !account || account === createHash("sha256").update(uid).digest("hex");
}

/** The document ID for a purchase: the raw token is never stored. */
export function purchaseIdFor(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

function dateOf(when: When | null | undefined): Date | null {
  if (!when) return null;
  return when instanceof Date ? when : when.toDate();
}
