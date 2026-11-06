import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/screens/dashboard/helpers/plus_prompt_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

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
                  'The questions a new account answers before Home. Nothing '
                  'you enter is saved.',
                  style: muted,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(onboardingPreviewProvider.notifier).state = true;
                    context.push(AppRoutes.onboarding);
                  },
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
