import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/language_provider.dart';

Future<void> openLegalPage(Uri page) =>
    launchUrl(page, mode: LaunchMode.externalApplication);

/// [text] with each of [links]' texts in it made a tappable link, in the
/// order the language puts them.
List<InlineSpan> _linked(
  String text,
  List<(String, Uri)> links,
  TextStyle style,
) {
  final found = [
    for (final (label, page) in links)
      if (text.indexOf(label) case final at when at >= 0) (at, label, page),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final spans = <InlineSpan>[];
  var from = 0;
  for (final (at, label, page) in found) {
    spans
      ..add(TextSpan(text: text.substring(from, at)))
      ..add(
        TextSpan(
          text: label,
          style: style,
          recognizer: TapGestureRecognizer()..onTap = () => openLegalPage(page),
        ),
      );
    from = at + label.length;
  }
  return spans..add(TextSpan(text: text.substring(from)));
}

/// "By continuing you agree to..." with tappable Terms and Privacy links.
class LegalFooter extends ConsumerWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(languageCodeProvider);
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final link = TextStyle(
      fontSize: 13,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    final agreement = Text.rich(
      TextSpan(
        style: muted,
        children: _linked(
          l10n.legalAgreement(l10n.legalTermsOfUse, l10n.legalPrivacyPolicy),
          [
            (l10n.legalTermsOfUse, LegalLinks.terms(language)),
            (l10n.legalPrivacyPolicy, LegalLinks.privacyPolicy(language)),
          ],
          link,
        ),
      ),
      textAlign: TextAlign.center,
    );
    if (!kIsWeb) return agreement;
    // Google's terms ask for this line wherever the reCAPTCHA badge is hidden.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        agreement,
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: muted,
            children: _linked(
              l10n.legalRecaptcha(
                l10n.legalGooglePrivacy,
                l10n.legalGoogleTerms,
              ),
              [
                (
                  l10n.legalGooglePrivacy,
                  Uri.parse('https://policies.google.com/privacy'),
                ),
                (
                  l10n.legalGoogleTerms,
                  Uri.parse('https://policies.google.com/terms'),
                ),
              ],
              link,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// The one-line health disclaimer shown wherever a calorie target is set.
class MedicalNote extends StatelessWidget {
  const MedicalNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.legalMedicalNote,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }
}
