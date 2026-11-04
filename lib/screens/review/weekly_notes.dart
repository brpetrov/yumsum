import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/weekly_review_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// A number and its unit on the same line: "14 g", never "14" then "g".
String _keepUnits(String note) => note.replaceAllMapped(
  RegExp(r'(\d) (g|kcal)\b'),
  (match) => '${match[1]}\u00A0${match[2]}',
);

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
          'Protein, fibre, salt and sugar, against the UK\u00A0guides.',
        ),
        (
          Icons.lightbulb_outline_rounded,
          'One easy tip',
          'From your own meals or our\u00A0recipes.',
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
/// there are none. Without: [CoachPrompt], when the week has enough logged
/// for notes. [judgedDays] are the logged days that weren't
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
      return judgedDays < 4 ? const SizedBox.shrink() : const CoachPrompt();
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
                          _keepUnits(point),
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

/// For people without YumSum Star, on History's weeks and months: the
/// shining AI Coach button and a line on what it does, both opening the
/// dialog.
class CoachPrompt extends StatelessWidget {
  const CoachPrompt({super.key});

  @override
  Widget build(BuildContext context) {
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
              'See what\'s working, what\'s holding you back, and one easy '
              'fix for next week.',
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
