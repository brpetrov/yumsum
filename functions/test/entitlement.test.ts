import assert from "node:assert/strict";
import { describe, test } from "node:test";
import {
  boughtFor,
  entitlementFrom,
  isCurrentOrNewer,
  isPlusAt,
  purchaseIdFor,
  Stored,
  Subscription,
} from "../src/entitlement";

const now = new Date("2026-11-04T12:00:00.000Z");
const future = "2026-12-04T12:00:00.000Z";
const past = "2026-11-01T12:00:00.000Z";

// Google's example answer for a new purchase in its free trial, from
// https://developer.android.com/google/play/billing/lifecycle/subscriptions
// with YumSum's product, base plan and offer, and dates for its placeholders.
const newPurchase: Subscription = {
  kind: "androidpublisher#subscriptionPurchaseV2",
  startTime: "2026-11-04T11:58:00.000Z",
  regionCode: "GB",
  subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
  acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
  lineItems: [
    {
      productId: "yumsum_plus",
      expiryTime: "2026-11-11T11:58:00.000Z",
      autoRenewingPlan: { autoRenewEnabled: true },
      offerDetails: { basePlanId: "monthly", offerId: "monthly-trial" },
      offerPhase: { freeTrial: {} },
      latestSuccessfulOrderId: "GPA.3333-4137-0319-36762",
    },
  ],
};

/** The same purchase later on, like the guide's other examples. */
function later(
  subscriptionState: string,
  expiryTime?: string,
  offerPhase: object = { basePrice: {} },
): Subscription {
  return {
    ...newPurchase,
    subscriptionState,
    acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
    lineItems: [{ ...newPurchase.lineItems![0], expiryTime, offerPhase }],
  };
}

/** A date as Firestore hands it back. */
const stamp = (iso: string) => ({ toDate: () => new Date(iso) });

describe("entitlementFrom", () => {
  test("a new purchase in its free trial", () => {
    assert.deepEqual(entitlementFrom(newPurchase, undefined, now), {
      active: true,
      state: "active",
      inTrial: true,
      productId: "yumsum_plus",
      basePlan: "monthly",
      expiresAt: new Date("2026-11-11T11:58:00.000Z"),
      endedAt: null,
      source: "play",
      updatedAt: now,
    });
  });

  test("the first renewal is at the base price, so not in trial", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_ACTIVE", future),
      undefined,
      now,
    );
    assert.equal(fields?.inTrial, false);
  });

  test("cancelled in the trial: still on and in trial until it ends", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_CANCELED", future, { freeTrial: {} }),
      undefined,
      now,
    );
    assert.equal(fields?.active, true);
    assert.equal(fields?.inTrial, true);
  });

  test("a trial that has ended isn't in trial", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_EXPIRED", past, { freeTrial: {} }),
      undefined,
      now,
    );
    assert.equal(fields?.inTrial, false);
  });

  test("the yearly base plan", () => {
    const annual: Subscription = {
      ...newPurchase,
      lineItems: [
        {
          ...newPurchase.lineItems![0],
          offerDetails: { basePlanId: "annual", offerId: "annual-trial" },
        },
      ],
    };
    assert.equal(entitlementFrom(annual, undefined, now)?.basePlan, "annual");
  });

  // [what, Play's subscriptionState, expiryTime, active, state]
  const states: [string, string, string | undefined, boolean, string][] = [
    ["renewed", "SUBSCRIPTION_STATE_ACTIVE", future, true, "active"],
    ["in grace", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", future, true, "grace"],
    ["cancelled", "SUBSCRIPTION_STATE_CANCELED", future, true, "cancelled"],
    ["cancelled on hold", "SUBSCRIPTION_STATE_CANCELED", past, false, "cancelled"],
    ["on hold", "SUBSCRIPTION_STATE_ON_HOLD", past, false, "hold"],
    ["paused", "SUBSCRIPTION_STATE_PAUSED", past, false, "paused"],
    ["expired", "SUBSCRIPTION_STATE_EXPIRED", past, false, "expired"],
    ["revoked", "SUBSCRIPTION_STATE_EXPIRED", future, false, "expired"],
    ["pending", "SUBSCRIPTION_STATE_PENDING", undefined, false, "pending"],
    [
      "pending, then cancelled",
      "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED",
      undefined,
      false,
      "expired",
    ],
    ["a state Play adds later", "SUBSCRIPTION_STATE_UNSPECIFIED", future, false, "expired"],
  ];
  for (const [what, playState, expiryTime, active, state] of states) {
    test(`${what}: ${state}, ${active ? "on" : "off"}`, () => {
      const fields = entitlementFrom(later(playState, expiryTime), undefined, now);
      assert.equal(fields?.active, active);
      assert.equal(fields?.state, state);
      assert.deepEqual(fields?.expiresAt, expiryTime ? new Date(expiryTime) : null);
    });
  }
});

describe("endedAt", () => {
  const wasOn: Stored = { active: true, source: "play", expiresAt: stamp(future) };

  test("set to now when YumSum Star switches off", () => {
    const fields = entitlementFrom(later("SUBSCRIPTION_STATE_EXPIRED", future), wasOn, now);
    assert.deepEqual(fields?.endedAt, now);
  });

  test("set to the old expiry when that passed before the notification", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_EXPIRED", past),
      { ...wasOn, expiresAt: stamp(past) },
      now,
    );
    assert.deepEqual(fields?.endedAt, new Date(past));
  });

  test("kept while it stays off", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_ON_HOLD", past),
      { active: false, source: "play", endedAt: stamp(past) },
      now,
    );
    assert.deepEqual(fields?.endedAt, new Date(past));
  });

  test("cleared when it comes back", () => {
    const fields = entitlementFrom(
      later("SUBSCRIPTION_STATE_ACTIVE", future),
      { active: false, source: "play", endedAt: stamp(past) },
      now,
    );
    assert.equal(fields?.endedAt, null);
  });

  test("not set for a purchase that was never on", () => {
    const fields = entitlementFrom(later("SUBSCRIPTION_STATE_PENDING"), undefined, now);
    assert.equal(fields?.endedAt, null);
  });
});

describe("manual grants and the owner's fields", () => {
  const play = later("SUBSCRIPTION_STATE_ACTIVE", future);

  test("a live manual grant is never replaced", () => {
    const grant = { active: true, source: "manual", expiresAt: stamp(future) };
    assert.equal(entitlementFrom(play, grant, now), null);
  });

  test("nor one with no end", () => {
    assert.equal(entitlementFrom(play, { active: true, source: "manual" }, now), null);
  });

  test("a grant with no source counts as manual, as in the app", () => {
    assert.equal(entitlementFrom(play, { active: true }, now), null);
  });

  test("an expired grant is replaced, and ended at its expiry", () => {
    const grant = { active: true, source: "manual", expiresAt: stamp(past) };
    const fields = entitlementFrom(later("SUBSCRIPTION_STATE_PENDING"), grant, now);
    assert.equal(fields?.source, "play");
    assert.deepEqual(fields?.endedAt, new Date(past));
  });

  test("a grant switched off is replaced", () => {
    const fields = entitlementFrom(play, { active: false, source: "manual" }, now);
    assert.equal(fields?.active, true);
  });

  test("admin and dev are left to the merge, and keep YumSum Star on", () => {
    const owner: Stored = { admin: true, dev: true };
    const fields = entitlementFrom(later("SUBSCRIPTION_STATE_EXPIRED", past), owner, now);
    assert.ok(fields);
    assert.ok(!("admin" in fields) && !("dev" in fields));
    assert.equal(isPlusAt({ ...owner, ...fields }, now), true);
  });
});

describe("isPlusAt, as the app's Entitlement.isPlusAt", () => {
  test("no document", () => assert.equal(isPlusAt(undefined, now), false));
  test("admin", () => assert.equal(isPlusAt({ admin: true }, now), true));
  test("dev", () => assert.equal(isPlusAt({ dev: true }, now), true));
  test("active with no end", () => assert.equal(isPlusAt({ active: true }, now), true));
  test("active but expired", () => {
    assert.equal(isPlusAt({ active: true, expiresAt: stamp(past) }, now), false);
  });
  test("off", () => {
    assert.equal(isPlusAt({ active: false, expiresAt: stamp(future) }, now), false);
  });
});

describe("isCurrentOrNewer", () => {
  const current = purchaseIdFor("token-a");
  const tokenB = purchaseIdFor("token-b");

  test("the current purchase", () => {
    assert.equal(isCurrentOrNewer(newPurchase, current, current), true);
  });

  test("no current purchase", () => {
    assert.equal(isCurrentOrNewer(newPurchase, tokenB, undefined), true);
  });

  test("a plan change from the current purchase", () => {
    const changed = { ...newPurchase, linkedPurchaseToken: "token-a" };
    assert.equal(isCurrentOrNewer(changed, tokenB, current), true);
  });

  test("resubscribing in the Play Store after it expired", () => {
    const resubscribed = {
      ...newPurchase,
      outOfAppPurchaseContext: { expiredPurchaseToken: "token-a" },
    };
    assert.equal(isCurrentOrNewer(resubscribed, tokenB, current), true);
  });

  test("a late expiry for a purchase that was replaced", () => {
    const old = later("SUBSCRIPTION_STATE_EXPIRED", past);
    assert.equal(isCurrentOrNewer(old, purchaseIdFor("token-0"), current), false);
  });
});

describe("boughtFor", () => {
  // The app buys with sha256.convert(utf8.encode(uid)).toString(): for the
  // uid "abc", the standard SHA-256 test vector.
  const boughtByAbc: Subscription = {
    ...newPurchase,
    externalAccountIdentifiers: {
      obfuscatedExternalAccountId:
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
    },
  };

  test("the account the app bought it for", () => {
    assert.equal(boughtFor(boughtByAbc, "abc"), true);
  });

  test("another account on the same phone is refused", () => {
    assert.equal(boughtFor(boughtByAbc, "abd"), false);
  });

  test("bought outside the app, with no ID: the first to check it", () => {
    assert.equal(boughtFor(newPurchase, "abd"), true);
  });
});

test("purchaseIdFor is the token's SHA-256 in hex", () => {
  // The standard SHA-256 test vector.
  assert.equal(
    purchaseIdFor("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});
