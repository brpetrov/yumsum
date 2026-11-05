import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { dayKey } from "../src/account";
import { deliver, formspreeBody } from "../src/feedback";

const fromApp = { kind: "Idea", text: "Love it", app: "0.1.0, android" };

describe("formspreeBody", () => {
  test("the uid and email are the account's, not the app's", () => {
    const data = { ...fromApp, user: "someone-else", email: "forged@example.com" };
    assert.deepEqual(formspreeBody(data, "u1", "a@b.com"), {
      _subject: "YumSum feedback: Idea",
      email: "a@b.com",
      message: "Love it",
      user: "u1",
      app: "0.1.0, android",
    });
  });

  test("refuses what the app wouldn't send", () => {
    for (const data of [
      null,
      { ...fromApp, kind: "Spam" },
      { ...fromApp, text: "   " },
      { ...fromApp, text: "x".repeat(4001) },
      { ...fromApp, app: 1 },
    ]) {
      assert.throws(() => formspreeBody(data, "u1", "a@b.com"), {
        code: "invalid-argument",
      });
    }
  });

  test("an account with no email has no one to reply to", () => {
    assert.throws(() => formspreeBody(fromApp, "u1", undefined), {
      code: "failed-precondition",
    });
  });
});

describe("deliver", () => {
  test("posts the message to the Formspree form as JSON", async () => {
    let sent: { url: string; init: RequestInit } | undefined;
    const post = (async (url: string, init: RequestInit) => {
      sent = { url, init };
      return new Response('{"ok":true}');
    }) as typeof fetch;
    const body = formspreeBody(fromApp, "u1", "a@b.com");
    await deliver(body, post);

    assert.equal(sent?.url, "https://formspree.io/f/mqppllqo");
    assert.equal(sent?.init.method, "POST");
    assert.deepEqual(sent?.init.headers, {
      Accept: "application/json",
      "Content-Type": "application/json",
    });
    assert.deepEqual(JSON.parse(sent?.init.body as string), body);
  });

  test("fails when Formspree refuses it", async () => {
    const post = (async () =>
      new Response('{"errors":[]}', { status: 422 })) as typeof fetch;
    await assert.rejects(deliver({}, post), { code: "unavailable" });
  });
});

test("the daily limits count UTC days", () => {
  assert.equal(dayKey(new Date("2026-11-05T23:59:59.000Z")), "2026-11-05");
  assert.equal(dayKey(new Date("2026-11-06T00:30:00.000+02:00")), "2026-11-05");
});
