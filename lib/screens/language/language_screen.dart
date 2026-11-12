import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';

/// Asked once, before sign-in, on a device in Bulgaria or Malta or set to
/// Bulgarian (languagePromptProvider). The heading reads in both languages;
/// choosing saves the setting and the router moves on to sign-in. Debug
/// tools' onboarding preview starts here too (previewOnboarding).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = lookupAppLocalizations(const Locale('en'));
    final bulgarian = lookupAppLocalizations(const Locale('bg'));
    Future<void> choose(String code) async {
      await ref.read(languageControllerProvider.notifier).setLanguage(code);
      // In Debug tools' preview, on to onboarding in that language, and back
      // to Debug tools from there.
      if (!context.mounted || !ref.read(onboardingPreviewProvider)) return;
      await context.push(AppRoutes.onboarding);
      if (context.mounted) context.pop();
    }

    final heading = AppTheme.display.copyWith(
      fontSize: 26,
      color: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogoMark(size: 72)),
                  const SizedBox(height: 28),
                  Text(
                    english.languageChoose,
                    textAlign: TextAlign.center,
                    style: heading,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bulgarian.languageChoose,
                    textAlign: TextAlign.center,
                    style: heading.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => choose('en'),
                    child: Text(context.l10n.languageEnglish),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => choose('bg'),
                    child: Text(context.l10n.languageBulgarian),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
