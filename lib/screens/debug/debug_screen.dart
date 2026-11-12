import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/plus_prompt_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// "Go through onboarding again": from the language question, as a new
/// device in Bulgaria sees it, then onboarding in the language chosen.
/// However it's left, the preview ends once back here and this device's
/// own language is put back.
Future<void> previewOnboarding(BuildContext context, WidgetRef ref) async {
  final language = ref.read(languageControllerProvider);
  ref.read(onboardingPreviewProvider.notifier).state = true;
  await context.push(AppRoutes.language);
  if (!context.mounted) return;
  ref.read(onboardingPreviewProvider.notifier).state = false;
  if (ref.read(languageControllerProvider) != language) {
    await ref
        .read(languageControllerProvider.notifier)
        .setLanguage(language ?? 'en');
  }
}

/// Shortcuts for trying the app, in debug builds only (the menu and the
/// route exist only there). Nothing here reaches Firestore.
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final account = ref.watch(debugAccountProvider);
    final muted = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: AppColors.textSecondary,
    );

    void say(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Debug tools')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePage(
            maxWidth: 560,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In debug builds, and for dev accounts. What you pick here '
                  'is kept on this device, not in your account.',
                  style: muted,
                ),
                const SizedBox(height: 24),
                const _Label('YOUR ACCOUNT'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('User ID'),
                  subtitle: SelectableText(uid ?? 'Not signed in'),
                  trailing: IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: uid == null
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: uid));
                            say('User ID copied.');
                          },
                  ),
                ),
                Text(
                  'To give an account YumSum Star for real, add a document with '
                  'this ID under entitlements in the Firebase console.',
                  style: muted,
                ),
                const SizedBox(height: 24),
                const _Label('PRETEND TO BE'),
                RadioGroup<DebugAccount>(
                  groupValue: account,
                  onChanged: (pick) {
                    if (pick != null) {
                      ref.read(debugAccountProvider.notifier).set(pick);
                    }
                  },
                  child: Column(
                    children: [
                      for (final option in DebugAccount.values)
                        RadioListTile<DebugAccount>(
                          contentPadding: EdgeInsets.zero,
                          value: option,
                          title: Text(option.label),
                        ),
                    ],
                  ),
                ),
                Text(
                  'Admin also lifts the daily AI limit and the limit on '
                  'changing past days. Your real plan reacts to a pretend '
                  'account: Free, or an ended YumSum Star after 2 weeks, '
                  'switches the Adaptive formula off and drops its '
                  'adjustment.',
                  style: muted,
                ),
                const SizedBox(height: 24),
                const _Label('ONBOARDING'),
                Text(
                  'The questions a new account answers before Home, from '
                  'the language question a device in Bulgaria gets. Nothing '
                  'you enter is saved, and your language is put back after.',
                  style: muted,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => previewOnboarding(context, ref),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Go through onboarding again'),
                ),
                const SizedBox(height: 24),
                const _Label('ONE-TIME PROMPTS'),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(sharedPreferencesProvider)
                        .remove(plusPromptHiddenKey);
                    say('The YumSum Star card is back on Today.');
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Show the YumSum Star card again'),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 24),
                  const _Label('CRASH REPORTS'),
                  Text(
                    'Sends a test report to Firebase → Crashlytics, under '
                    'Non-fatals. It arrives when the app next starts. Debug '
                    "builds don't send reports; this turns them on for this "
                    'run.',
                    style: muted,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final crashlytics = FirebaseCrashlytics.instance;
                      await crashlytics.setCrashlyticsCollectionEnabled(true);
                      await crashlytics.recordError(
                        Exception('Test report from Debug tools'),
                        StackTrace.current,
                        reason: 'Debug tools test',
                      );
                      await crashlytics.sendUnsentReports();
                      say('Test report sent.');
                    },
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Send a test crash report'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
