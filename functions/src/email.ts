import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { createTransport } from "nodemailer";
import { countToday, signedIn } from "./account";

/**
 * help.yumsum's Gmail app password, in Secret Manager. Firebase's own
 * confirmation email can't be restyled and comes from
 * lean-streak-project.firebaseapp.com, so the app's sign-up sends ours
 * instead, through Gmail.
 */
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");
const sender = "help.yumsum@gmail.com";

/** The logo at the top of the email, from the website. */
const logoUrl = "https://yumsum.web.app/app/icons/Icon-192.png";

/** Confirmation emails a day per account: room to ask again, not to spam. */
export const dailyLimit = 5;

/**
 * Emails the caller the link that confirms their email address, styled as
 * YumSum, from help.yumsum@gmail.com. Nothing is sent to an account that's
 * already confirmed. The app falls back to Firebase's own plain email when
 * this fails.
 */
export const sendVerificationEmail = onCall(
  { enforceAppCheck: true, secrets: [gmailAppPassword] },
  async (request) => {
    const uid = signedIn(request.auth);
    const user = await getAuth().getUser(uid);
    if (!user.email) throw new HttpsError("failed-precondition", "No email.");
    if (user.emailVerified) return { sent: false };

    const counter = await countToday(uid, "email_usage", dailyLimit);
    try {
      const link = await getAuth().generateEmailVerificationLink(user.email);
      const email = verificationEmail(link);
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

/** The confirmation email for [link]: its subject, HTML and plain text. */
export function verificationEmail(link: string) {
  const href = escapeHtml(link);
  const font =
    "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";
  const intro = "You're one tap away from tracking your meals with YumSum. " +
    "Confirm this is your email address to finish setting up your account.";
  const ignore = "If you didn't create a YumSum account, you can ignore this email.";
  // Tables and inline styles, as email clients need.
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>Confirm your email</title>
</head>
<body style="margin:0;padding:0;background:#FBF0E4;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">One tap to confirm your email and start using YumSum.</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#FBF0E4;">
<tr><td align="center" style="padding:40px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">
<tr><td align="center" style="padding-bottom:20px;">
<img src="${logoUrl}" width="72" height="72" alt="YumSum" style="display:block;width:72px;height:72px;border:0;border-radius:20px;">
</td></tr>
<tr><td style="background:#FFFBF5;border-radius:24px;padding:40px 36px;box-shadow:0 12px 30px rgba(201,77,26,0.10);font-family:${font};color:#2B1F18;">
<h1 style="margin:0 0 12px;font-size:26px;line-height:1.25;font-weight:700;color:#2B1F18;text-align:center;">Confirm your email</h1>
<p style="margin:0 0 28px;font-size:16px;line-height:1.55;color:#6F5F53;text-align:center;">${intro}</p>
<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center"><tr>
<td align="center" style="border-radius:999px;background:#C94D1A;">
<a href="${href}" style="display:inline-block;padding:15px 36px;font-size:16px;font-weight:700;color:#FFFFFF;text-decoration:none;border-radius:999px;">Confirm my email</a>
</td></tr></table>
<p style="margin:28px 0 0;font-size:13px;line-height:1.5;color:#6F5F53;text-align:center;">The button not working? Copy this link into your browser:<br>
<a href="${href}" style="color:#C94D1A;word-break:break-all;">${href}</a></p>
</td></tr>
<tr><td style="padding:24px 12px 0;font-family:${font};font-size:12.5px;line-height:1.55;color:#8A7A6E;text-align:center;">
${ignore}<br>YumSum · Stay consistent. Stay lean.
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
  const text = `Confirm your email\n\n${intro}\n\n${link}\n\n${ignore}\n\nYumSum`;
  return { subject: "Confirm your email for YumSum", html, text };
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}
