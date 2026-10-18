import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/constants/legal_links.dart';

Future<void> openLegalPage(Uri page) =>
    launchUrl(page, mode: LaunchMode.externalApplication);

/// "By continuing you agree to..." with tappable Terms and Privacy links.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final link = TextStyle(
      fontSize: 13,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: muted,
        children: [
          const TextSpan(text: 'By continuing you agree to the '),
          TextSpan(
            text: 'Terms of Use',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => openLegalPage(LegalLinks.terms),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => openLegalPage(LegalLinks.privacyPolicy),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// The one-line health disclaimer shown wherever a calorie target is set.
class MedicalNote extends StatelessWidget {
  const MedicalNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'LeanStreak gives general estimates, not medical advice. Talk to a '
      'doctor or dietitian before changing your diet, especially if you have '
      'a health condition.',
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }
}
