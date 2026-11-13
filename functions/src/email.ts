import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { createTransport } from "nodemailer";
import { countToday, signedIn } from "./account";
import { type Language, languageOf } from "./prompts";

/**
 * help.yumsum's Gmail app password, in Secret Manager. Firebase's own
 * confirmation email can't be restyled and comes from
 * lean-streak-project.firebaseapp.com, so the app's sign-up sent ours
 * instead, through Gmail, from 7 to 13 November 2026. The app no longer
 * calls these: Outlook held ours for an hour and junked it, as a new free
 * Gmail address sending HTML looks like phishing. They stay for when
 * there's a domain of our own with an email service behind it.
 */
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");
const sender = "help.yumsum@gmail.com";

/** The logo at the top of the email, from the website. */
const logoUrl = "https://yumsum.app/app/icons/Icon-192.png";

/**
 * Confirmation and password reset emails a day per account, together: room
 * to ask again, not to spam.
 */
export const dailyLimit = 5;

/**
 * Emails the caller the link that confirms their email address, styled as
 * YumSum, from help.yumsum@gmail.com. Nothing is sent to an account that's
 * already confirmed. The app falls back to Firebase's own plain email when
 * this fails. Written in the app's `language` ('en' or 'bg', English for
 * anything else or none), as is the page the link opens.
 */
export const sendVerificationEmail = onCall(
  { enforceAppCheck: true, secrets: [gmailAppPassword] },
  async (request) => {
    const uid = signedIn(request.auth);
    const language = languageOf((request.data as { language?: unknown } | null)?.language);
    const user = await getAuth().getUser(uid);
    if (!user.email) throw new HttpsError("failed-precondition", "No email.");
    if (user.emailVerified) return { sent: false };

    const counter = await countToday(uid, "email_usage", dailyLimit);
    try {
      const link = await getAuth().generateEmailVerificationLink(user.email);
      const email = verificationEmail(inLanguage(link, language), language);
      await createTransport({
        service: "gmail",
        auth: { user: sender, pass: gmailAppPassword.value() },
      }).sendMail({ from: `"YumSum" <${sender}>`, to: user.email, ...email });
    } catch (error) {
      logger.warn("Could not send the confirmation email", error);
      // Only what's sent counts.
      await counter.update({ count: FieldValue.increment(-1) });
      throw new HttpsError("unavailable", "Could not send the email.");
    }
    return { sent: true };
  },
);

/**
 * Emails the link to choose a new password to `email`, styled as YumSum,
 * from help.yumsum@gmail.com, in the app's `language`: Firebase's own reset
 * email is plain and comes from lean-streak-project.firebaseapp.com. Asked
 * before signing in, so it answers the same whether or not there's an
 * account, and once the day's emails are used up, so the form can't be used
 * to probe addresses. The app falls back to Firebase's email when this fails.
 */
export const sendPasswordResetEmail = onCall(
  { enforceAppCheck: true, secrets: [gmailAppPassword] },
  async (request) => {
    const data = (request.data ?? {}) as { email?: unknown; language?: unknown };
    const language = languageOf(data.language);
    const email = typeof data.email === "string" ? data.email.trim() : "";
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new HttpsError("invalid-argument", "Not an email address.");
    }
    const same = { sent: true };
    let uid: string;
    try {
      const user = await getAuth().getUserByEmail(email);
      if (user.disabled) return same;
      uid = user.uid;
    } catch (error) {
      if ((error as { code?: string }).code === "auth/user-not-found") return same;
      throw error;
    }

    let counter;
    try {
      counter = await countToday(uid, "email_usage", dailyLimit);
    } catch (error) {
      if (error instanceof HttpsError && error.code === "resource-exhausted") return same;
      throw error;
    }
    try {
      const link = await getAuth().generatePasswordResetLink(email);
      const message = resetEmail(inLanguage(link, language), language);
      await createTransport({
        service: "gmail",
        auth: { user: sender, pass: gmailAppPassword.value() },
      }).sendMail({ from: `"YumSum" <${sender}>`, to: email, ...message });
    } catch (error) {
      logger.warn("Could not send the password reset email", error);
      await counter.update({ count: FieldValue.increment(-1) });
      throw new HttpsError("unavailable", "Could not send the email.");
    }
    return same;
  },
);

/**
 * [link] opening Firebase's confirmation or reset page in [language]: the
 * link comes with `lang=en`.
 */
export function inLanguage(link: string, language: Language): string {
  if (language === "en") return link;
  const url = new URL(link);
  url.searchParams.set("lang", language);
  return url.toString();
}

/** Each email's words in each language. */
const copy: Record<"verify" | "reset", Record<Language, Record<string, string>>> = {
  verify: { en: {
    subject: "Confirm your email for YumSum",
    title: "Confirm your email",
    preheader: "One tap to confirm your email and start using YumSum.",
    intro: "You're one tap away from tracking your meals with YumSum. " +
      "Confirm this is your email address to finish setting up your account.",
    button: "Confirm my email",
    fallback: "The button not working? Copy this link into your browser:",
    ignore: "If you didn't create a YumSum account, you can ignore this email.",
    tagline: "Stay consistent. Stay lean.",
  },
  // "ти", and no words that show the reader's gender ("създал/създала").
  bg: {
    subject: "Потвърди имейла си за YumSum",
    title: "Потвърди имейла си",
    preheader: "Потвърди имейла си, за да започнеш с YumSum.",
    intro: "Остава само да потвърдиш имейл адреса си, за да завършиш " +
      "регистрацията и да започнеш да записваш храненията си с YumSum.",
    button: "Потвърди имейла",
    fallback: "Бутонът не работи? Копирай този линк в браузъра си:",
    ignore: "Ако регистрацията в YumSum не е по твоя заявка, можеш да " +
      "пренебрегнеш този имейл.",
    tagline: "Постоянство всеки ден. Винаги във форма.",
  } },
  // Firebase's reset links work once, for an hour.
  reset: { en: {
    subject: "Reset your YumSum password",
    title: "Reset your password",
    preheader: "Choose a new password for your YumSum account.",
    intro: "Tap the button to choose a new password for your YumSum " +
      "account. The link works once, for an hour.",
    button: "Choose a new password",
    fallback: "The button not working? Copy this link into your browser:",
    ignore: "If you didn't ask to reset your password, you can ignore this " +
      "email. Your password stays as it is.",
    tagline: "Stay consistent. Stay lean.",
  },
  bg: {
    subject: "Нова парола за YumSum",
    title: "Смени паролата си",
    preheader: "Избери нова парола за профила си в YumSum.",
    intro: "Натисни бутона, за да избереш нова парола за профила си в " +
      "YumSum. Линкът работи веднъж, до един час.",
    button: "Избери нова парола",
    fallback: "Бутонът не работи? Копирай този линк в браузъра си:",
    ignore: "Ако смяната на паролата не е по твоя заявка, можеш да " +
      "пренебрегнеш този имейл. Паролата ти остава същата.",
    tagline: "Постоянство всеки ден. Винаги във форма.",
  } },
};

/**
 * The confirmation email for [link] in [language]: its subject, HTML and
 * plain text.
 */
export function verificationEmail(link: string, language: Language = "en") {
  return styledEmail(copy.verify[language], link, language);
}

/** The password reset email for [link] in [language], in the same design. */
export function resetEmail(link: string, language: Language = "en") {
  return styledEmail(copy.reset[language], link, language);
}

function styledEmail(words: Record<string, string>, link: string, language: Language) {
  const href = escapeHtml(link);
  const font =
    "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";
  const { subject, title, preheader, intro, button, fallback, ignore, tagline } = words;
  // Tables and inline styles, as email clients need.
  const html = `<!DOCTYPE html>
<html lang="${language}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>${title}</title>
</head>
<body style="margin:0;padding:0;background:#FBF0E4;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">${preheader}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#FBF0E4;">
<tr><td align="center" style="padding:40px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">
<tr><td align="center" style="padding-bottom:20px;">
<img src="${logoUrl}" width="72" height="72" alt="YumSum" style="display:block;width:72px;height:72px;border:0;border-radius:20px;">
</td></tr>
<tr><td style="background:#FFFBF5;border-radius:24px;padding:40px 36px;box-shadow:0 12px 30px rgba(201,77,26,0.10);font-family:${font};color:#2B1F18;">
<h1 style="margin:0 0 12px;font-size:26px;line-height:1.25;font-weight:700;color:#2B1F18;text-align:center;">${title}</h1>
<p style="margin:0 0 28px;font-size:16px;line-height:1.55;color:#6F5F53;text-align:center;">${intro}</p>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center"><tr>
<td align="center" style="border-radius:999px;background:#C94D1A;">
<a href="${href}" style="display:inline-block;padding:15px 36px;font-size:16px;font-weight:700;color:#FFFFFF;text-decoration:none;border-radius:999px;">${button}</a>
</td></tr></table>
<p style="margin:28px 0 0;font-size:13px;line-height:1.5;color:#6F5F53;text-align:center;">${fallback}<br>
<a href="${href}" style="color:#C94D1A;word-break:break-all;">${href}</a></p>
</td></tr>
<tr><td style="padding:24px 12px 0;font-family:${font};font-size:12.5px;line-height:1.55;color:#8A7A6E;text-align:center;">
${ignore}<br>YumSum · ${tagline}
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
  const text = `${title}\n\n${intro}\n\n${link}\n\n${ignore}\n\nYumSum`;
  return { subject, html, text };
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}
