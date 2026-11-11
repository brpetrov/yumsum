import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';

final _dateKey = DateFormat('yyyy-MM-dd');

/// AI Coach in History, under the calendar in both views, on the week
/// starting [monday]: a card that opens the AI Coach page on that week,
/// swapping History for it so Back still lands on Home. Nothing for a week
/// before YumSum Star began, which has no notes and never will. Without
/// YumSum Star: [CoachPrompt]. [named] adds the week's date, for the month
/// view.
class WeeklyNotesCard extends ConsumerWidget {
  const WeeklyNotesCard({super.key, required this.monday, this.named = false});

  final DateTime monday;
  final bool named;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(plusProvider)) return const CoachPrompt();
    final first = firstCoachWeek(ref.watch(entitlementProvider).valueOrNull);
    if (first != null && monday.isBefore(first)) return const SizedBox.shrink();

    final now = DateTime.now();
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final finished = sunday.isBefore(DateTime(now.year, now.month, now.day));
    final l10n = context.l10n;
    final line = !finished
        ? l10n.coachNotesComing
        : named
        ? l10n.coachNotesReadThat
        : l10n.coachNotesReadThis;
    return _Spaced(
      AppCard(
        padding: const EdgeInsets.fromLTRB(22, 14, 10, 16),
        onTap: () => openPage(
          context,
          finished
              ? '${AppRoutes.coach}?week=${_dateKey.format(monday)}'
              : AppRoutes.coach,
        ),
        child: Row(
          children: [
            const IconBubble(Icons.insights_rounded, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.coachTitle,
                    style: AppTheme.display.copyWith(
                      fontSize: 19,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (named)
                    Text(
                      l10n.coachWeekOf(l10n.dayMonth(monday)),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// For people without YumSum Star, on History's weeks and months: the
/// shining AI Coach button and a line on what it does, both opening the
/// AI Coach page.
class CoachPrompt extends StatelessWidget {
  const CoachPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    void open() => openPage(context, AppRoutes.coach);
    return _Spaced(
      AppCard(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TryButton(label: context.l10n.coachTitle, onTap: open),
            const SizedBox(height: 12),
            Text(
              context.l10n.coachPromptLine,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gap under the card, there only when the card is.
class _Spaced extends StatelessWidget {
  const _Spaced(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 18), child: child);
}
