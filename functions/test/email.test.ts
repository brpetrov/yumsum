import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { verificationEmail } from "../src/email";

describe("verificationEmail", () => {
  const link =
    "https://lean-streak-project.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=abc&lang=en";

  test("has the link, escaped, in the button and as text, and the logo", () => {
    const email = verificationEmail(link);
    assert.equal(email.subject, "Confirm your email for YumSum");
    const escaped = link.replace(/&/g, "&amp;");
    assert.equal(email.html.split(`href="${escaped}"`).length - 1, 2);
    assert.ok(email.html.includes(">Confirm my email</a>"));
    assert.ok(email.html.includes("https://yumsum.web.app/app/icons/Icon-192.png"));
    assert.ok(email.text.includes(link));
  });

  test("a link can't break out of its attribute", () => {
    const email = verificationEmail('https://x.test/?a="><script>');
    assert.ok(!email.html.includes("<script>"));
    assert.ok(email.html.includes("&quot;&gt;&lt;script&gt;"));
  });

  test("keeps to the app's copy rules", () => {
    const { html, text, subject } = verificationEmail(link);
    // The doctype's "!" isn't wording.
    for (const words of [html.replace("<!DOCTYPE html>", ""), text, subject]) {
      assert.ok(!words.includes("!"), "no exclamation marks");
      assert.ok(!/please/i.test(words), "no please");
    }
  });
});
