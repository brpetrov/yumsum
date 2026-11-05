import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { countToday, signedIn } from "./account";

// The app's shared Open Food Facts account, which only the server holds
// (`firebase functions:secrets:set OFF_USER_ID`, then OFF_PASSWORD).
const userId = defineSecret("OFF_USER_ID");
const password = defineSecret("OFF_PASSWORD");

const host = "https://world.openfoodfacts.org";

/** The contact address in the User-Agent: the app's `supportEmail`. */
const supportEmail = "help.yumsum@gmail.com";

/**
 * Contributions a day per account. A contribution needs an AI reading of
 * the label, so a few a day is a lot; every try counts, retries included.
 */
export const dailyLimit = 10;

/** What the app sends: a product's form fields and its photos. */
export interface Contribution {
  appUuid: string;
  appVersion: string;
  fields: Record<string, string>;
  /** In order; [field] is the picture it becomes, e.g. front_en. */
  photos: { field: string; jpeg: Buffer }[];
}

interface Account {
  user_id: string;
  password: string;
}

/**
 * Sends a new product, or the nutrition for a listed one, to Open Food
 * Facts through the app's shared account, the same requests the app used
 * to make itself.
 */
export const contributeProduct = onCall(
  { enforceAppCheck: true, secrets: [userId, password], timeoutSeconds: 120 },
  async (request) => {
    const uid = signedIn(request.auth);
    const contribution = contributionFrom(request.data);
    await countToday(uid, "contribution_usage", dailyLimit);
    await contribute(contribution, {
      user_id: userId.value(),
      password: password.value(),
    });
    return {};
  },
);

// Only the fields the app's productFields and nutritionFields write, so the
// account can't be used for anything else.
const fieldName = new RegExp(
  "^(code|lc|lang|cc|add_brands|quantity|serving_size|add_countries|" +
    "nutrition_data_per|product_name_[a-z]{2,3}|nutriment_[a-z-]+(_unit)?)$",
);
const photoField = /^(front|nutrition)_([a-z]{2,3})$/;
// About 6 MB a photo; the camera's are well under 1 MB.
const maxPhoto = 8_000_000;

/** The app's request, checked; anything else is refused. */
export function contributionFrom(data: unknown): Contribution {
  const { appUuid, appVersion, fields, photos } = (data ?? {}) as Record<
    string,
    unknown
  >;
  if (
    typeof appUuid !== "string" || !/^[0-9a-f]{32}$/.test(appUuid) ||
    typeof appVersion !== "string" || !/^[\w.+-]{1,20}$/.test(appVersion) ||
    !isFields(fields) || !/^\d{1,20}$/.test(fields.code ?? "") ||
    !Array.isArray(photos) || photos.length > 2 || !photos.every(isPhoto)
  ) {
    throw new HttpsError("invalid-argument", "Not a contribution.");
  }
  return {
    appUuid,
    appVersion,
    fields,
    photos: photos.map(({ field, jpeg }) => ({
      field,
      jpeg: Buffer.from(jpeg, "base64"),
    })),
  };
}

function isFields(fields: unknown): fields is Record<string, string> {
  return typeof fields === "object" && fields !== null &&
    !Array.isArray(fields) &&
    Object.entries(fields).every(
      ([name, value]) =>
        fieldName.test(name) && typeof value === "string" &&
        value.length <= 1000,
    );
}

function isPhoto(photo: unknown): photo is { field: string; jpeg: string } {
  const { field, jpeg } = (photo ?? {}) as Record<string, unknown>;
  return typeof field === "string" && photoField.test(field) &&
    typeof jpeg === "string" && jpeg.length > 0 && jpeg.length <= maxPhoto;
}

/**
 * Saves the details, then each photo in order: only a photo sent as the
 * front becomes the product's front picture.
 */
export async function contribute(
  contribution: Contribution,
  account: Account,
  post: typeof fetch = fetch,
): Promise<void> {
  const { appUuid, appVersion, fields, photos } = contribution;
  const shared = {
    ...account,
    app_name: "YumSum",
    app_version: appVersion,
    app_uuid: appUuid,
  };

  async function send(
    path: string,
    body: URLSearchParams | FormData,
    saved: (reply: Reply) => boolean,
  ) {
    let response: Response;
    let text: string;
    try {
      response = await post(host + path, {
        method: "POST",
        headers: { "User-Agent": `YumSum/${appVersion} (${supportEmail})` },
        body,
        signal: AbortSignal.timeout(30_000),
      });
      text = await response.text();
    } catch (error) {
      logger.warn(`Could not reach Open Food Facts: ${path}`, error);
      throw new HttpsError("unavailable", "Could not reach Open Food Facts.");
    }
    // A wrong account password comes back as an HTML page, so it fails
    // [saved] too.
    if (response.status !== 200 || !saved(json(text))) {
      logger.warn(`Open Food Facts said ${response.status}: ${path}`, {
        reply: text.slice(0, 500),
      });
      throw new HttpsError("aborted", "Open Food Facts didn't accept it.");
    }
  }

  await send(
    "/cgi/product_jqm2.pl",
    new URLSearchParams({
      ...shared,
      ...fields,
      // Open Food Facts asks for "user agent + user id", nothing personal.
      comment: `YumSum ${appVersion} user ${appUuid}`,
    }),
    (reply) => reply?.status === 1,
  );
  for (const { field, jpeg } of photos) {
    const form = new FormData();
    const upload = {
      ...shared,
      code: fields.code,
      lc: field.replace(photoField, "$2"),
      imagefield: field,
    };
    for (const [name, value] of Object.entries(upload)) form.append(name, value);
    form.append(`imgupload_${field}`, new Blob([new Uint8Array(jpeg)]), `${field}.jpg`);
    // A photo sent before (a retry after a dropped connection) comes back
    // as "already exists" with its id, which is just as good.
    await send(
      "/cgi/product_image_upload.pl",
      form,
      (reply) => reply?.status === "status ok" || reply?.imgid != null,
    );
  }
}

type Reply = Record<string, unknown> | null;

function json(body: string): Reply {
  try {
    const reply: unknown = JSON.parse(body);
    return typeof reply === "object" && reply !== null
      ? (reply as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}
