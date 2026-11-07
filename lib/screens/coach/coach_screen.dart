import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/helpers/week_facts.dart';
import 'package:lean_streak/l10n/l10n.dart';
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
import 'package:lean_streak/widgets/recipe_photo.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// What AI Coach does (plan 09): on the page for free users, and in the
/// dialog behind the info button, under [AppLocalizations.coachIntroTitle]
/// and [AppLocalizations.coachSubtitle].
List<(IconData, String, String)> coachPromises(AppLocalizations l10n) => [
  (
    Icons.query_stats_rounded,
    l10n.coachPromiseHoldingBackTitle,
    l10n.coachPromiseHoldingBackBody,
  ),
  (
    Icons.eco_rounded,
    l10n.coachPromiseBalanceTitle,
    l10n.coachPromiseBalanceBody,
  ),
  (
    Icons.lightbulb_outline_rounded,
    l10n.coachPromiseAdviceTitle,
    l10n.coachPromiseAdviceBody,
  ),
  (
    Icons.event_available_rounded,
    l10n.coachPromiseWeeklyTitle,
    l10n.coachPromiseWeeklyBody,
  ),
];

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
    title: context.l10n.coachIntroTitle,
    subtitle: context.l10n.coachSubtitle,
    image: const _CoachImage(width: 52),
    promises: coachPromises(context.l10n),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.coachClose),
      ),
    ],
  ),
);

/// The AI Coach page, `/coach`: the week's name over the notes the AI wrote
/// on it, paging back through the finished weeks since YumSum Star began.
/// Only the latest finished week is ever written; the others show what was
/// saved. Someone whose YumSum Star has ended keeps their notes; anyone
/// else without it gets what it does and Become a Star. [week] is a Monday as
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

  /// Where a sideways swipe began, to measure a slow one.
  double _swipeFrom = 0;

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                context.l10n.coachTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const PlusStar(size: 24),
          ],
        ),
        actions: [
          if (plus)
            IconButton(
              tooltip: context.l10n.coachHowItWorks,
              onPressed: () => showCoachIntro(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: plus || kept ? _weeks(plus) : _page(const _CoachPitch()),
    );
  }

  /// The page's scrolling column with [child]. A swipe sideways, by touch
  /// or mouse, does what the arrows do: to the left [onNext], to the right
  /// [onPrevious]. A fling counts, or a slower drag (a mouse's, often) of
  /// 80 px.
  Widget _page(Widget child, {VoidCallback? onPrevious, VoidCallback? onNext}) {
    return RawGestureDetector(
      gestures: {
        _SwipeRecognizer:
            GestureRecognizerFactoryWithHandlers<_SwipeRecognizer>(
              _SwipeRecognizer.new,
              (swipe) => swipe
                ..onStart = ((start) => _swipeFrom = start.globalPosition.dx)
                ..onEnd = (end) {
                  final velocity = end.primaryVelocity ?? 0;
                  final dragged = end.globalPosition.dx - _swipeFrom;
                  final way = velocity != 0
                      ? velocity
                      : (dragged.abs() >= 80 ? dragged : 0);
                  if (way < 0) onNext?.call();
                  if (way > 0) onPrevious?.call();
                },
            ),
      },
      child: ListView(
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
            child: child,
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
      return _page(_FirstNotes(now: now));
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
    final onPrevious = _monday.isAfter(first)
        ? () => setState(() => _monday = shift(-1))
        : null;
    final onNext = _monday.isBefore(latest)
        ? () => setState(() => _monday = shift(1))
        : null;
    return _page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekHeader(
            monday: _monday,
            latest: latest,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
          const SizedBox(height: 18),
          if (!plus) ...[const _Ended(), const SizedBox(height: 18)],
          _WeekNotes(monday: _monday, plus: plus),
        ],
      ),
      onPrevious: onPrevious,
      onNext: onNext,
    );
  }
}

/// A sideways drag that waits for a finger's slop (18 px) from a mouse too,
/// where Flutter would start it after 1 px, so a click on a note or a recipe
/// that drifts a little still taps.
class _SwipeRecognizer extends HorizontalDragGestureRecognizer {
  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => super.hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind.touch,
    deviceTouchSlop,
  );
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
    final l10n = context.l10n;
    final last = monday == latest;
    final dates = weekLabel(
      l10n,
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
                  last ? l10n.coachLastWeek : dates,
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
            tooltip: l10n.coachPrevious,
            onPressed: onPrevious,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: l10n.coachNext,
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
    final l10n = context.l10n;
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
                      l10n.coachFirstNotesTitle,
                      style: AppTheme.display.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.coachDaysToGo(days),
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
            l10n.coachFirstNotesBody(l10n.dayMonth(monday)),
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

/// Once YumSum Star has ended: the notes stay, and Become a Star brings new
/// ones.
class _Ended extends StatelessWidget {
  const _Ended();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.coachEnded,
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
              label: Text(context.l10n.starBecome),
            ),
          ),
        ],
      ),
    );
  }
}

/// For people without YumSum Star: what AI Coach does, and Become a Star.
class _CoachPitch extends StatelessWidget {
  const _CoachPitch();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        // Small enough for Become a Star to be on screen on a phone.
        const Center(child: _CoachImage(width: 156)),
        const SizedBox(height: 16),
        Text(
          l10n.coachIntroTitle,
          textAlign: TextAlign.center,
          style: AppTheme.display.copyWith(
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.coachSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        AppCard(child: FeaturePromises(coachPromises(l10n))),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: () => showPlusPaywall(context),
            icon: const PlusStar(size: 24),
            label: Text(l10n.starBecome),
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
    final l10n = context.l10n;
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
      return AppCard(child: Text(l10n.coachNotEnough, style: muted));
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
            Expanded(child: Text(l10n.coachLooking, style: muted)),
          ],
        ),
      ),
      error: (_, _) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.coachErrorLoad, style: muted),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => ref.invalidate(weeklyReviewProvider(monday)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.coachTryAgain),
            ),
          ],
        ),
      ),
      data: (points) {
        if (points == null) {
          return AppCard(
            child: Text(
              plus ? l10n.coachNoNotesPlus : l10n.coachNoNotes,
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
/// display font, and under it what the facts show, with library recipes as
/// links; then, for a note written in pieces, why it matters in a quieter
/// line, the tips under "Try this" (or "Keep going" for a good one), and
/// the recipes that fit as chips with their photos.
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
    final found = [
      for (final name in point.recipes)
        for (final recipe in recipes)
          if (recipe.isNamed(name)) recipe,
    ];
    final rest = [
      if (point.why.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            point.why,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      if (point.tips.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _Tips(point.tips, good: point.good),
        ),
      if (found.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final recipe in found) _RecipeChip(recipe)],
          ),
        ),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dot,
              const SizedBox(width: 12),
              Expanded(
                child: point.title.isEmpty
                    ? text
                    : Text(
                        point.title,
                        style: AppTheme.display.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (point.title.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8), child: text),
                ...rest,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A note's tips, one short line each behind an arrow, under a small
/// heading.
class _Tips extends StatelessWidget {
  const _Tips(this.tips, {required this.good});

  final List<String> tips;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          good ? context.l10n.coachKeepGoing : context.l10n.coachTryThis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: good ? AppColors.veryGood : AppColors.primary,
          ),
        ),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: good ? AppColors.veryGood : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _keepUnits(tip),
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A recipe the note recommends: its photo in a small round and its name on
/// a pill, which opens the recipe.
class _RecipeChip extends StatelessWidget {
  const _RecipeChip(this.recipe);

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.recipePath(recipe.id), extra: recipe),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 26,
                  child: RecipePhoto(recipe),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  recipe.nameIn(context.l10n.localeName),
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display.copyWith(
                    fontSize: 13.5,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A number and its unit on the same line: "14 g", never "14" then "g";
/// "14 г" and "300 ккал" in Bulgarian.
String _keepUnits(String note) => note.replaceAllMapped(
  RegExp(r'(\d) (g|kcal|г|ккал)(?![\p{L}\p{N}_])', unicode: true),
  (match) => '${match[1]} ${match[2]}',
);

/// Finds the library's recipe names in a note, in English or Bulgarian,
/// with any quotes the AI puts round them. Longer names first, so one that
/// contains another wins. Built once per library; null when it has no
/// recipes.
final _recipeNamesProvider = Provider<RegExp?>((ref) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const [];
  if (recipes.isEmpty) return null;
  final names = [
    for (final recipe in recipes) ...[recipe.name, ?recipe.bg?.name],
  ]..sort((a, b) => b.length.compareTo(a.length));
  return RegExp(
    '["“”]?(${names.map(RegExp.escape).join('|')})["“”]?',
    caseSensitive: false,
  );
});

/// A note's text, with every library recipe it names a link that opens it,
/// named in the app's language and shedding the quotes the AI puts round
/// names. It's split once per text, and the links' recognizers are disposed
/// with it.
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
  /// The note in pieces: its text, and the recipe and a recognizer on each
  /// recipe name.
  var _pieces = <(String, Recipe?, TapGestureRecognizer?)>[];

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
    final pieces = <(String, Recipe?, TapGestureRecognizer?)>[];
    var at = 0;
    for (final match
        in widget.names?.allMatches(note) ?? const <RegExpMatch>[]) {
      final name = match[1]!;
      final recipe = widget.recipes.firstWhere(
        (recipe) => recipe.isNamed(name),
      );
      pieces.add((note.substring(at, match.start), null, null));
      pieces.add((
        name,
        recipe,
        TapGestureRecognizer()
          ..onTap = () =>
              context.push(AppRoutes.recipePath(recipe.id), extra: recipe),
      ));
      at = match.end;
    }
    pieces.add((note.substring(at), null, null));
    _pieces = pieces;
  }

  void _disposeRecognizers() {
    for (final (_, _, recognizer) in _pieces) {
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
    // A recipe the note names in another language takes the app's name.
    String shown(String text, Recipe? recipe) {
      final name = recipe?.nameIn(context.l10n.localeName);
      return name == null || name.toLowerCase() == text.toLowerCase()
          ? text
          : name;
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        children: [
          for (final (text, recipe, recognizer) in _pieces)
            TextSpan(
              text: shown(text, recipe),
              style: recognizer == null ? null : link,
              recognizer: recognizer,
            ),
        ],
      ),
    );
  }
}
