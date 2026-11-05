import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/period_bar.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// What AI Coach does (plan 09): on the page for free users, and in the
/// dialog behind the info button.
const coachPromises = <(IconData, String, String)>[
  (
    Icons.query_stats_rounded,
    'Detects your patterns',
    'Finds what\'s quietly holding you back, so you can fix it.',
  ),
  (
    Icons.eco_rounded,
    'Looks past calories',
    'Checks your protein, fibre, salt and sugar against the recommended '
        'amounts, not just your calories.',
  ),
  (
    Icons.lightbulb_outline_rounded,
    'Tips written for you',
    'Personal advice based on your own meals, with fixes and recipes '
        'that help.',
  ),
  (
    Icons.event_available_rounded,
    'Fresh every Monday',
    'A new review every week, so you keep getting better.',
  ),
];

/// The Monday of the latest finished week: a week finishes on its Sunday,
/// so last week's.
DateTime latestFinishedWeek(DateTime today) =>
    DateTime(today.year, today.month, today.day - today.weekday - 6);

/// What AI Coach does, from the page's info button, with Close only.
Future<void> showCoachIntro(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => FeatureIntroDialog(
    title: 'AI Coach',
    subtitle: 'Your week, read for you',
    promises: coachPromises,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  ),
);

/// The AI Coach page, `/coach`: a week bar over the notes the AI wrote on
/// each finished week, back to the first logged one. Free users get what
/// it does and Enable. [week] is a Monday as `yyyy-MM-dd`; anything else,
/// or a week still going, opens the latest finished week.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key, this.week});

  final String? week;

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  late DateTime _monday;

  @override
  void initState() {
    super.initState();
    final latest = latestFinishedWeek(DateTime.now());
    final asked = DateTime.tryParse(widget.week ?? '');
    _monday =
        asked != null &&
            asked.weekday == DateTime.monday &&
            !asked.isAfter(latest)
        ? DateTime(asked.year, asked.month, asked.day)
        : latest;
  }

  @override
  Widget build(BuildContext context) {
    final plus = ref.watch(plusProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          if (plus)
            IconButton(
              tooltip: 'How it works',
              onPressed: () => showCoachIntro(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ResponsivePage(
            maxWidth: 720,
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            child: plus ? _weeks() : const _CoachPitch(),
          ),
        ],
      ),
    );
  }

  Widget _weeks() {
    final latest = latestFinishedWeek(DateTime.now());
    final firstDay = ref.watch(firstLoggedDayProvider).valueOrNull;
    final first = firstDay == null
        ? _monday
        : DateTime(
            firstDay.year,
            firstDay.month,
            firstDay.day - firstDay.weekday + 1,
          );
    DateTime shift(int weeks) =>
        DateTime(_monday.year, _monday.month, _monday.day + 7 * weeks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodBar(
          label: weekLabel(_monday),
          onPrevious: _monday.isAfter(first)
              ? () => setState(() => _monday = shift(-1))
              : null,
          onNext: _monday.isBefore(latest)
              ? () => setState(() => _monday = shift(1))
              : null,
          onToday: _monday == latest
              ? null
              : () => setState(() => _monday = latest),
          todayLabel: 'Latest',
        ),
        const SizedBox(height: 18),
        _WeekNotes(monday: _monday),
      ],
    );
  }
}

/// For people without YumSum Star: what AI Coach does, and Enable.
class _CoachPitch extends StatelessWidget {
  const _CoachPitch();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // The coach illustration goes here once it's drawn.
        const Center(child: IconBubble(Icons.auto_awesome_rounded, size: 120)),
        const SizedBox(height: 22),
        Text(
          'AI Coach',
          textAlign: TextAlign.center,
          style: AppTheme.display.copyWith(
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your week, read for you',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        const AppCard(child: FeaturePromises(coachPromises)),
        const SizedBox(height: 22),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () => showPlusPaywall(context),
            icon: const PlusStar(size: 24),
            label: const Text('Enable'),
          ),
        ),
      ],
    );
  }
}

/// The notes on the week starting [monday]: the AI's notes, or why there
/// are none for a thin week (notes need 4 judged days: logged, not days
/// off), a spinner, or a failure with Try again.
class _WeekNotes extends ConsumerWidget {
  const _WeekNotes({required this.monday});

  final DateTime monday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = TextStyle(
      fontSize: 13.5,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final summaries = ref
        .watch(
          reviewSummariesProvider(
            ReviewRange(startDate: monday, endDate: sunday),
          ),
        )
        .valueOrNull;
    if (summaries != null && summaries.values.where(isJudgedDay).length < 4) {
      return AppCard(
        child: Text(
          'Not enough logged this week for notes. They need 4 days logged, '
          'not counting days off.',
          style: muted,
        ),
      );
    }

    final notes = summaries == null
        ? const AsyncLoading<List<ReviewPoint>>()
        : ref.watch(weeklyReviewProvider(monday));
    return notes.when(
      loading: () => AppCard(
        child: Row(
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
      ),
      error: (_, _) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not get this week\'s notes. Try again.', style: muted),
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
      ),
      data: (points) {
        final recipes = ref.watch(recipesProvider).valueOrNull ?? const [];
        final names = ref.watch(_recipeNamesProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, point) in points.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _NoteCard(point, recipes: recipes, names: names),
            ],
          ],
        );
      },
    );
  }
}

/// One note: a dot (green for something that went well), its title in the
/// display font, and the text under it, with library recipes as links.
class _NoteCard extends StatelessWidget {
  const _NoteCard(this.point, {required this.recipes, required this.names});

  final ReviewPoint point;
  final List<Recipe> recipes;
  final RegExp? names;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(
        color: point.good ? AppColors.veryGood : AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
    final text = _NoteText(point.text, recipes: recipes, names: names);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: point.title.isEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dot,
                const SizedBox(width: 12),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dot,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point.title,
                        style: AppTheme.display.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.only(left: 20), child: text),
              ],
            ),
    );
  }
}

/// A number and its unit on the same line: "14 g", never "14" then "g".
String _keepUnits(String note) => note.replaceAllMapped(
  RegExp(r'(\d) (g|kcal)\b'),
  (match) => '${match[1]} ${match[2]}',
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
    '["“”]?(${names.map(RegExp.escape).join('|')})["“”]?',
    caseSensitive: false,
  );
});

/// A note's text, with every library recipe it names a link that opens it,
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
          height: 1.45,
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
