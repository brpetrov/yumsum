import { androidpublisher, auth } from "@googleapis/androidpublisher";
import type { Subscription } from "./entitlement";

export const packageName = "com.bpetrov.yumsum";
export const productId = "yumsum_plus";

// The functions run as the project's default service account, which is
// invited in Play Console, so there's no key file.
const play = androidpublisher({
  version: "v3",
  auth: new auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  }),
});

/** Play's current answer for a purchase. */
export function getSubscription(token: string): Promise<Subscription> {
  return call(play.purchases.subscriptionsv2.get({ packageName, token }));
}

/** Acknowledges a new purchase, which Play refunds if it isn't within 3 days. */
export async function acknowledge(token: string): Promise<void> {
  await call(
    play.purchases.subscriptions.acknowledge({
      packageName,
      subscriptionId: productId,
      token,
    }),
  );
}

/** Play's status and message, without the request, whose URL holds the token. */
export class PlayError extends Error {
  constructor(
    readonly status: number | undefined,
    message = "No answer from Google Play",
  ) {
    super(message);
  }
}

async function call<T>(request: Promise<{ data: T }>): Promise<T> {
  try {
    return (await request).data;
  } catch (error) {
    const { status, message } = error as { status?: number; message?: string };
    throw new PlayError(status, status ? `${status} ${message}` : undefined);
  }
}

/**
 * Whether Play's error means it doesn't know the token: 400 for a malformed
 * or unknown one, 404, or 410 once it's 60 days past expiry. Anything else
 * (no access yet, Play down, no network) is worth trying again.
 */
export function isUnknownToken(error: unknown): boolean {
  const status = error instanceof PlayError ? error.status : undefined;
  return status === 400 || status === 404 || status === 410;
}
