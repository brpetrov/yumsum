import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// When the YumSum Star card on Today was hidden until, in milliseconds.
const plusPromptHiddenKey = 'plus.prompt_hidden_until';

/// Today's card for people without YumSum Star: what it adds, opening its page.
/// Its cross hides it for two weeks. It brings the gap below it, so nothing
/// is left behind when it's hidden.
class PlusPromptCard extends ConsumerStatefulWidget {
  const PlusPromptCard({super.key});

  @override
  ConsumerState<PlusPromptCard> createState() => _PlusPromptCardState();
}

class _PlusPromptCardState extends ConsumerState<PlusPromptCard> {
  bool _hidden = false;

  void _hide() {
    setState(() => _hidden = true);
    final until = DateTime.now().add(const Duration(days: 14));
    ref
        .read(sharedPreferencesProvider)
        .setInt(plusPromptHiddenKey, until.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementProvider);
    final until = ref
        .watch(sharedPreferencesProvider)
        .getInt(plusPromptHiddenKey);
    final hidden =
        _hidden ||
        (until != null && DateTime.now().millisecondsSinceEpoch < until);
    // Not until the account is known, so a subscriber never sees it flash.
    if (hidden || !entitlement.hasValue || ref.watch(plusProvider)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 6, 16),
        onTap: () => showPlusPaywall(context),
        child: Row(
          children: [
            const PlusHero(size: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PlusMark(size: 19),
                  const SizedBox(height: 4),
                  Text(
                    'Photo logging, a target that learns from your '
                    'weigh-ins, full macros and a weekly review.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hide for now',
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: _hide,
            ),
          ],
        ),
      ),
    );
  }
}
