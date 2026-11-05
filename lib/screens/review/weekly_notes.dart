import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/models/recipe.dart';
import 'package:lean_streak/models/weekly_review.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/recipe_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
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

/// Finds the library's recipe names in a note, with any quotes the AI puts
/// round them. Longer names first, so one that contains another wins. Built
/// once per library; null when it has no recipes.
final _recipeNamesProvider = Provider<RegExp?>((ref) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const [];
  if (recipes.isEmpty) return null;
  final names = recipes.map((recipe) => recipe.name).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  return RegExp(
    '["\u201C\u201D]?(${names.map(RegExp.escape).join('|')})["\u201C\u201D]?',
    caseSensitive: false,
  );
});

/// A note, with every library recipe it names a link that opens it,
/// shedding the quotes the AI puts round names. It's split once per text,
/// and the links' recognizers are disposed with it.
class _NoteText extends StatefulWidget {
  const _NoteText(this.text, {required this.recipes, required this.names});

  final String text;
  final List<Recipe> recipes;

  /// From [_recipeNamesProvider].
  final RegExp? names;

  @override
  State<_NoteText> createState() => _NoteTextState();
}

class _NoteTextState extends State<_NoteText> {
  /// The note in pieces: its text, and a recognizer on each recipe name.
  var _pieces = <(String, TapGestureRecognizer?)>[];

  @override
  void initState() {
    super.initState();
    _split();
  }

  @override
  void didUpdateWidget(_NoteText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.names != oldWidget.names) {
      _disposeRecognizers();
      _split();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _split() {
    final note = _keepUnits(widget.text);
    final pieces = <(String, TapGestureRecognizer?)>[];
    var at = 0;
    for (final match
        in widget.names?.allMatches(note) ?? const <RegExpMatch>[]) {
      final name = match[1]!;
      final recipe = widget.recipes.firstWhere(
        (recipe) => recipe.name.toLowerCase() == name.toLowerCase(),
      );
      pieces.add((note.substring(at, match.start), null));
      pieces.add((
        name,
        TapGestureRecognizer()
          ..onTap = () =>
              context.push(AppRoutes.recipePath(recipe.id), extra: recipe),
      ));
      at = match.end;
    }
    pieces.add((note.substring(at), null));
    _pieces = pieces;
  }

  void _disposeRecognizers() {
    for (final (_, recognizer) in _pieces) {
      recognizer?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        children: [
          for (final (text, recognizer) in _pieces)
            TextSpan(
              text: text,
              style: recognizer == null ? null : link,
              recognizer: recognizer,
            ),
        ],
      ),
    );
  }
}

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
          'Detects your patterns',
          'Finds what\'s quietly holding you back, so you can fix\u00A0it.',
        ),
        (
          Icons.eco_rounded,
          'Looks past calories',
          'Checks your protein, fibre, salt and sugar against the recommended '
              'amounts, not just your\u00A0calories.',
        ),
        (
          Icons.lightbulb_outline_rounded,
          'Tips written for you',
          'Personal advice based on your own meals, with fixes and recipes '
              'that\u00A0help.',
        ),
        (
          Icons.event_available_rounded,
          'Fresh every Monday',
          'A new review every week, so you keep getting\u00A0better.',
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

/// AI Coach in History, under the calendar in both views, on the week
/// starting [monday]. With YumSum Star: the notes the AI wrote from the
/// week's facts (a green dot on one about something that went well), or why
/// there are none yet; notes need the week over and 4 judged days (logged,
/// not days off). Without: [CoachPrompt]. [named] adds the week's date, for
/// the month view.
class WeeklyNotesCard extends ConsumerWidget {
  const WeeklyNotesCard({super.key, required this.monday, this.named = false});

  final DateTime monday;
  final bool named;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(plusProvider)) return const CoachPrompt();

    final week = named
        ? 'Week of ${DateFormat('d MMMM').format(monday)}'
        : null;
    final muted = TextStyle(
      fontSize: 13.5,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final now = DateTime.now();
    if (!sunday.isBefore(DateTime(now.year, now.month, now.day))) {
      return _Spaced(
        _CoachCard(
          week: week,
          child: Text('Your notes on this week come on Monday.', style: muted),
        ),
      );
    }

    final summaries = ref
        .watch(
          reviewSummariesProvider(
            ReviewRange(startDate: monday, endDate: sunday),
          ),
        )
        .valueOrNull;
    if (summaries != null && summaries.values.where(isJudgedDay).length < 4) {
      return _Spaced(
        _CoachCard(
          week: week,
          child: Text(
            'Not enough logged this week for notes. They need 4 days '
            'logged, not counting days off.',
            style: muted,
          ),
        ),
      );
    }

    final notes = summaries == null
        ? const AsyncLoading<List<ReviewPoint>>()
        : ref.watch(weeklyReviewProvider(monday));
    return _Spaced(
      _CoachCard(
        week: week,
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
            final recipes = ref.watch(recipesProvider).valueOrNull ?? const [];
            final names = ref.watch(_recipeNamesProvider);
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
                          color: point.good
                              ? AppColors.veryGood
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NoteText(
                          point.text,
                          recipes: recipes,
                          names: names,
                        ),
                      ),
                    ],
                  ),
                ],
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
              'See what\'s working, what\'s holding you back, and get '
              'personal tips on how to improve.',
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

/// The card with its title, the sparkle and the info button, and the
/// [week] under the title when given.
class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.child, this.week});

  final Widget child;
  final String? week;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach',
                      style: AppTheme.display.copyWith(
                        fontSize: 19,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (week case final week?)
                      Text(
                        week,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
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
