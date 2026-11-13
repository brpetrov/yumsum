import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { inLanguage, resetEmail, verificationEmail } from "../src/email";

describe("verificationEmail", () => {
  const link =
    "https://lean-streak-project.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=abc&lang=en";

  test("has the link, escaped, in the button and as text, and the logo", () => {
    const email = verificationEmail(link);
    assert.equal(email.subject, "Confirm your email for YumSum");
    const escaped = link.replace(/&/g, "&amp;");
    assert.equal(email.html.split(`href="${escaped}"`).length - 1, 2);
    assert.ok(email.html.includes(">Confirm my email</a>"));
    assert.ok(email.html.includes("https://yumsum.app/app/icons/Icon-192.png"));
    assert.ok(email.text.includes(link));
  });

  test("a link can't break out of its attribute", () => {
    const email = verificationEmail('https://x.test/?a="><script>');
    assert.ok(!email.html.includes("<script>"));
    assert.ok(email.html.includes("&quot;&gt;&lt;script&gt;"));
  });

  test("keeps to the app's copy rules, in English and in Bulgarian", () => {
    for (const language of ["en", "bg"] as const) {
      const { html, text, subject } = verificationEmail(link, language);
      // The doctype's "!" isn't wording.
      for (const words of [html.replace("<!DOCTYPE html>", ""), text, subject]) {
        assert.ok(!words.includes("!"), `no exclamation marks (${language})`);
        assert.ok(!/please|моля/i.test(words), `no please (${language})`);
        // No \b: it only knows Latin letters.
        assert.ok(
          !/(^|[^а-я])(вие|вас|ваш[а-я]*|ви)(?![а-я])/i.test(words),
          `"ти", not "Вие" (${language})`,
        );
      }
    }
  });

  test("in Bulgarian: the same design, with the words and the page in Bulgarian", () => {
    const english = verificationEmail(link);
    const bulgarian = verificationEmail(inLanguage(link, "bg"), "bg");
    assert.equal(bulgarian.subject, "Потвърди имейла си за YumSum");
    assert.ok(bulgarian.html.includes('<html lang="bg">'));
    assert.ok(bulgarian.html.includes(">Потвърди имейла</a>"));
    assert.ok(bulgarian.html.includes("Постоянство всеки ден. Винаги във форма."));
    assert.ok(bulgarian.text.startsWith("Потвърди имейла си\n\n"));
    for (const word of ["Confirm", "tap", "ignore", "Stay lean"]) {
      assert.ok(!bulgarian.html.includes(word), word);
      assert.ok(!bulgarian.text.includes(word), word);
    }
    // Only the words differ: the same tags, styles and logo.
    const tags = (html: string) => html.match(/<[^>]*>/g)?.filter((tag) => !tag.startsWith("<a "));
    assert.deepEqual(tags(bulgarian.html), tags(english.html)?.map((tag) =>
      tag === '<html lang="en">' ? '<html lang="bg">' : tag));
    assert.ok(bulgarian.text.includes("&lang=bg"));
  });

  test("the reset email: the same design, its own words, both languages", () => {
    const reset = "https://lean-streak-project.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=abc&lang=en";
    const english = resetEmail(reset);
    assert.equal(english.subject, "Reset your YumSum password");
    assert.ok(english.html.includes(">Choose a new password</a>"));
    assert.equal(english.html.split(`href="${reset.replace(/&/g, "&amp;")}"`).length - 1, 2);
    const bulgarian = resetEmail(inLanguage(reset, "bg"), "bg");
    assert.equal(bulgarian.subject, "Нова парола за YumSum");
    assert.ok(bulgarian.html.includes(">Избери нова парола</a>"));
    assert.ok(!/Confirm|password/.test(bulgarian.text));
    const tags = (html: string) => html.match(/<[^>]*>/g)?.filter((tag) => !tag.startsWith("<a "));
    assert.deepEqual(tags(english.html), tags(verificationEmail(link).html));
    for (const { html, text, subject } of [english, bulgarian]) {
      for (const words of [html.replace("<!DOCTYPE html>", ""), text, subject]) {
        assert.ok(!words.includes("!"));
        assert.ok(!/please|моля/i.test(words));
        assert.ok(!/(^|[^а-я])(вие|вас|ваш[а-я]*|ви)(?![а-я])/i.test(words));
      }
    }
  });

  test("Firebase's page opens in the email's language", () => {
    assert.equal(inLanguage(link, "en"), link);
    assert.equal(inLanguage(link, "bg"), link.replace("lang=en", "lang=bg"));
    assert.ok(inLanguage("https://x.test/a?oobCode=1", "bg").endsWith("?oobCode=1&lang=bg"));
  });
});
