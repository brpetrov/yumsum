import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { contribute, contributionFrom } from "../src/off";

const uuid = "0123456789abcdef0123456789abcdef";
const jpeg = Buffer.from([0xff, 0xd8, 1, 2]).toString("base64");

/** What the app sends for a new product (productFields), with both photos. */
const fromApp = {
  appUuid: uuid,
  appVersion: "0.1.0",
  fields: {
    code: "3800000000017",
    lc: "bg",
    lang: "bg",
    cc: "bg",
    product_name_bg: "Лютеница",
    add_brands: "Първа преса",
    quantity: "260 g",
    add_countries: "en:bulgaria",
    nutrition_data_per: "100g",
    "nutriment_energy-kcal": "95",
    "nutriment_energy-kcal_unit": "kcal",
    "nutriment_saturated-fat": "0.4",
    "nutriment_saturated-fat_unit": "g",
  },
  photos: [
    { field: "front_bg", jpeg },
    { field: "nutrition_bg", jpeg },
  ],
};

const refused = (data: unknown) =>
  assert.throws(() => contributionFrom(data), { code: "invalid-argument" });

describe("contributionFrom", () => {
  test("takes what the app sends", () => {
    const contribution = contributionFrom(fromApp);
    assert.deepEqual(contribution.fields, fromApp.fields);
    assert.deepEqual(
      contribution.photos.map((photo) => photo.field),
      ["front_bg", "nutrition_bg"],
    );
    assert.deepEqual([...contribution.photos[0].jpeg], [0xff, 0xd8, 1, 2]);
  });

  test("and a nutrition-only one with no photo", () => {
    const nutrition = {
      ...fromApp,
      fields: { code: "3800000000024", nutrition_data_per: "100g" },
      photos: [],
    };
    assert.equal(contributionFrom(nutrition).photos.length, 0);
  });

  test("refuses fields the app never writes, so the account does nothing else", () => {
    for (const name of ["user_id", "password", "app_uuid", "comment", "delete", "nutriment_x_y"]) {
      refused({ ...fromApp, fields: { ...fromApp.fields, [name]: "x" } });
    }
  });

  test("refuses anything else that isn't the app's", () => {
    refused(null);
    refused({ ...fromApp, appUuid: "install-1" });
    refused({ ...fromApp, appVersion: "0.1.0 (evil)" });
    refused({ ...fromApp, fields: { ...fromApp.fields, code: "abc" } });
    refused({ ...fromApp, fields: { lc: "en" } });
    refused({ ...fromApp, fields: { ...fromApp.fields, quantity: 260 } });
    refused({ ...fromApp, photos: [{ field: "packaging_bg", jpeg }] });
    refused({ ...fromApp, photos: [{ field: "front_bg", jpeg: "" }] });
    refused({ ...fromApp, photos: [...fromApp.photos, fromApp.photos[0]] });
  });
});

describe("contribute", () => {
  const account = { user_id: "yumsum-app", password: "secret" };

  /** Answers like Open Food Facts and keeps each request. */
  function openFoodFacts(details = '{"status": 1}') {
    const sent: { url: string; init: RequestInit }[] = [];
    const post = (async (url: string, init: RequestInit) => {
      sent.push({ url, init });
      return new Response(
        url.endsWith("jqm2.pl") ? details : '{"status": "status ok", "imgid": 1}',
      );
    }) as typeof fetch;
    return { sent, post };
  }

  test("the details first, then the front and nutrition photos", async () => {
    const { sent, post } = openFoodFacts();
    await contribute(contributionFrom(fromApp), account, post);

    assert.deepEqual(sent.map((request) => request.url), [
      "https://world.openfoodfacts.org/cgi/product_jqm2.pl",
      "https://world.openfoodfacts.org/cgi/product_image_upload.pl",
      "https://world.openfoodfacts.org/cgi/product_image_upload.pl",
    ]);
    for (const { init } of sent) {
      assert.deepEqual(init.headers, {
        "User-Agent": "YumSum/0.1.0 (help.yumsum@gmail.com)",
      });
    }

    const details = Object.fromEntries(sent[0].init.body as URLSearchParams);
    assert.deepEqual(details, {
      user_id: "yumsum-app",
      password: "secret",
      app_name: "YumSum",
      app_version: "0.1.0",
      app_uuid: uuid,
      ...fromApp.fields,
      comment: `YumSum 0.1.0 user ${uuid}`,
    });

    const front = sent[1].init.body as FormData;
    assert.equal(front.get("user_id"), "yumsum-app");
    assert.equal(front.get("app_uuid"), uuid);
    assert.equal(front.get("code"), "3800000000017");
    assert.equal(front.get("lc"), "bg");
    assert.equal(front.get("imagefield"), "front_bg");
    const photo = front.get("imgupload_front_bg") as File;
    assert.equal(photo.name, "front_bg.jpg");
    assert.deepEqual([...new Uint8Array(await photo.arrayBuffer())], [0xff, 0xd8, 1, 2]);
    assert.equal((sent[2].init.body as FormData).get("imagefield"), "nutrition_bg");
  });

  test("a refusal stops before the photos", async () => {
    const { sent, post } = openFoodFacts('{"status": 0}');
    await assert.rejects(contribute(contributionFrom(fromApp), account, post), {
      code: "aborted",
    });
    assert.equal(sent.length, 1);
  });

  test("a wrong password, an HTML page, is a refusal too", async () => {
    const post = (async () =>
      new Response("<html>Incorrect user name</html>", { status: 403 })) as typeof fetch;
    await assert.rejects(contribute(contributionFrom(fromApp), account, post), {
      code: "aborted",
    });
  });

  test("a dropped connection says it couldn't reach them", async () => {
    const post = (async () => {
      throw new TypeError("fetch failed");
    }) as typeof fetch;
    await assert.rejects(contribute(contributionFrom(fromApp), account, post), {
      code: "unavailable",
    });
  });
});
