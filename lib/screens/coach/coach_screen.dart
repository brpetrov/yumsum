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
import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/widgets/feature_intro.dart';
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

/// AI Coach in one line, under its name on the page and in the dialog.
const coachSubtitle =
    'Reads your week every Monday and tells you what\'s working and what '
    'to change.';

/// The coach illustration (assets/coach.webp, trimmed and shrunk to 720 px
/// for the web) at [width].
class _CoachImage extends StatelessWidget {
  const _CoachImage({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/coach.webp',
    width: width,
    filterQuality: FilterQuality.medium,
  );
}

/// What AI Coach does, from the page's info button, with Close only.
Future<void> showCoachIntro(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => FeatureIntroDialog(
    title: 'AI Coach',
    subtitle: coachSubtitle,
    image: const _CoachImage(width: 52),
    promises: coachPromises,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  ),
);

/// The AI Coach page, `/coach`: the week's name over the notes the AI wrote
/// on it, paging back through the finished weeks since YumSum Star began.
/// Only the latest finished week is ever written; the others show what was
/// saved. Someone whose YumSum Star has ended keeps their notes; anyone
/// else without it gets what it does and Enable. [week] is a Monday as
/// `yyyy-MM-dd`; anything else, or a week still going, opens the latest
/// finished week.
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
    // Notes written earlier stay readable once YumSum Star has ended.
    final kept =
        !plus && (ref.watch(hasWeeklyReviewsProvider).valueOrNull ?? false);
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
            child: plus || kept ? _weeks(plus) : const _CoachPitch(),
          ),
        ],
      ),
    );
  }

  Widget _weeks(bool plus) {
    final now = DateTime.now();
    final latest = latestFinishedWeek(now);
    final firstWeek = firstCoachWeek(
      ref.watch(entitlementProvider).valueOrNull,
    );
    if (plus && firstWeek != null && firstWeek.isAfter(latest)) {
      return _FirstNotes(now: now);
    }
    final firstDay = ref.watch(firstLoggedDayProvider).valueOrNull;
    var first = firstDay == null
        ? _monday
        : DateTime(
            firstDay.year,
            firstDay.month,
            firstDay.day - firstDay.weekday + 1,
          );
    if (firstWeek != null && firstWeek.isAfter(first)) first = firstWeek;
    DateTime shift(int weeks) =>
        DateTime(_monday.year, _monday.month, _monday.day + 7 * weeks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekHeader(
          monday: _monday,
          latest: latest,
          onPrevious: _monday.isAfter(first)
              ? () => setState(() => _monday = shift(-1))
              : null,
          onNext: _monday.isBefore(latest)
              ? () => setState(() => _monday = shift(1))
              : null,
        ),
        const SizedBox(height: 18),
        if (!plus) ...[const _Ended(), const SizedBox(height: 18)],
        _WeekNotes(monday: _monday, plus: plus),
      ],
    );
  }
}

/// The week's name beside the coach, with Previous and Next: "Last week"
/// over its dates for the latest finished week, or just the dates for an
/// earlier one (with the year once it isn't this one).
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.monday,
    required this.latest,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime monday;
  final DateTime latest;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final last = monday == latest;
    final dates = weekLabel(
      monday,
      year:
          DateTime(monday.year, monday.month, monday.day + 6).year !=
          DateTime.now().year,
    );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 2, 10),
      child: Row(
        children: [
          const _CoachImage(width: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last ? 'Last week' : dates,
                  style: AppTheme.display.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (last)
                  Text(
                    dates,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Previous',
            onPressed: onPrevious,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// For a new subscriber, until a week finished with YumSum Star is in:
/// when the first notes come, and what the coach is doing meanwhile.
class _FirstNotes extends StatelessWidget {
  const _FirstNotes({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = 8 - now.weekday;
    final monday = DateTime(now.year, now.month, now.day + days);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CoachImage(width: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your first notes come on Monday',
                      style: AppTheme.display.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days == 1 ? '1 day to go' : '$days days to go',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'AI Coach reads a whole week at a time, so it\'s going over this '
            'one as you log it. On Monday ${DateFormat('d MMMM').format(monday)} '
            'it\'ll tell you what went well, what held you back and what to '
            'try next week.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Once YumSum Star has ended: the notes stay, and Enable brings new ones.
class _Ended extends StatelessWidget {
  const _Ended();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YumSum Star has ended, so no new notes are written. The ones '
            'you have stay.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: () => showPlusPaywall(context),
              icon: const PlusStar(size: 22),
              label: const Text('Enable'),
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 4),
        // Small enough for Enable to be on screen on a phone.
        const Center(child: _CoachImage(width: 156)),
        const SizedBox(height: 16),
        Text(
          'AI Coach',
          textAlign: TextAlign.center,
          style: AppTheme.display.copyWith(
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          coachSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        const AppCard(child: FeaturePromises(coachPromises)),
        const SizedBox(height: 18),
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
/// off) or a week it never wrote, a spinner, or a failure with Try again.
class _WeekNotes extends ConsumerWidget {
  const _WeekNotes({required this.monday, required this.plus});

  final DateTime monday;
  final bool plus;

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
        ? const AsyncLoading<List<ReviewPoint>?>()
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
        if (points == null) {
          return AppCard(
            child: Text(
              plus
                  ? 'No notes on this week. AI Coach writes them during the '
                        'week after, when you open this page.'
                  : 'No notes on this week.',
              style: muted,
            ),
          );
        }
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
