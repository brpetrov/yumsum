import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

String _weekKey(DateTime monday) => DateFormat('yyyy-MM-dd').format(monday);

/// What AI Coach does (plan 09): from the card's info button, and from the
/// free users' button, where Enable opens the YumSum Star page.
Future<void> showCoachIntro(BuildContext context, {bool plus = true}) async {
  final enable = await showDialog<bool>(
    context: context,
    builder: (context) => FeatureIntroDialog(
      title: 'AI Coach',
      subtitle: 'Your week, read for you',
      promises: const [
        (
          Icons.query_stats_rounded,
          'Spots your patterns',
          'Like weekends running higher, or a light breakfast.',
        ),
        (
          Icons.eco_rounded,
          'Looks past calories',
          'Protein, fibre, salt and sugar, against the UK guides.',
        ),
        (
          Icons.lightbulb_outline_rounded,
          'One easy tip',
          'From your own meals or our recipes.',
        ),
        (
          Icons.event_available_rounded,
          'Ready every Monday',
          '3 short notes on the week just gone.',
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        if (!plus)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const PlusStar(size: 24),
            label: const Text('Enable'),
          ),
      ],
    ),
  );
  if (enable == true && context.mounted) await showPlusPaywall(context);
}

/// AI Coach on a finished week in History, above the week's review. With
/// YumSum Star: up to 3 notes the AI wrote from the week's facts, or why
/// there are none. Without: the shining AI Coach button, when the week has
/// enough logged for notes. [judgedDays] are the logged days that weren't
/// days off; notes need 4.
class WeeklyNotesCard extends ConsumerWidget {
  const WeeklyNotesCard({
    super.key,
    required this.monday,
    required this.judgedDays,
  });

  final DateTime monday;
  final int judgedDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusProvider);
    if (!plus) {
      if (judgedDays < 4) return const SizedBox.shrink();
      void open() => showCoachIntro(context, plus: false);
      return _Spaced(
        AppCard(
          onTap: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TryButton(label: 'AI Coach', onTap: open),
              const SizedBox(height: 12),
              Text(
                'Notes on your week every Monday: your patterns, your salt '
                'and fibre, and one easy tip.',
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

    final muted = TextStyle(
      fontSize: 13.5,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    if (judgedDays < 4) {
      return _Spaced(
        _CoachCard(
          child: Text(
            'Not enough logged this week for notes. They need 4 days '
            'logged, not counting days off.',
            style: muted,
          ),
        ),
      );
    }

    final notes = ref.watch(weeklyReviewProvider(monday));
    return _Spaced(
      _CoachCard(
        child: notes.when(
          loading: () => Row(
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Looking over your week', style: muted)),
            ],
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not get this week\'s notes. Try again.',
                style: muted,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => ref.invalidate(weeklyReviewProvider(monday)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (points) {
            if (points.isEmpty) return const SizedBox.shrink();
            // Shown, so Today's line can go.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ref
                    .read(weeklyReviewSeenProvider.notifier)
                    .markSeen(_weekKey(monday));
              }
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, point) in points.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Written by AI from what you logged.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The card with its title, the sparkle and the info button.
class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 14, 10, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(Icons.auto_awesome_rounded, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Coach',
                  style: AppTheme.display.copyWith(
                    fontSize: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'How it works',
                onPressed: () => showCoachIntro(context),
                icon: const Icon(Icons.info_outline_rounded),
                iconSize: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.only(right: 12), child: child),
        ],
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

/// On Today, for YumSum Star: a slim line to last week's notes, from the
/// Monday until they've been read in History. Last week needs 4 judged
/// days, as the notes do.
class WeeklyNotesLine extends ConsumerWidget {
  const WeeklyNotesLine({super.key, required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(plusProvider)) return const SizedBox.shrink();
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday) - 7,
    );
    final summaries = ref
        .watch(
          reviewSummariesProvider(
            ReviewRange(
              startDate: monday,
              endDate: DateTime(monday.year, monday.month, monday.day + 6),
            ),
          ),
        )
        .valueOrNull;
    final judged = summaries?.values.where(isJudgedDay).length ?? 0;
    if (judged < 4 || ref.watch(weeklyReviewSeenProvider) == _weekKey(monday)) {
      return const SizedBox.shrink();
    }

    return _Spaced(
      AppCard(
        onTap: () => context.push(AppRoutes.review, extra: monday),
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(
          children: [
            const IconBubble(Icons.auto_awesome_rounded, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Coach',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your notes on last week',
                    style: TextStyle(
                      fontSize: 13.5,
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
