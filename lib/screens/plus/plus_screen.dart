import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/plus_purchase_controller.dart';
import 'package:lean_streak/services/billing_service.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// Opens the YumSum Star page over the current one, so Back returns to it.
Future<void> showPlusPaywall(BuildContext context) =>
    context.push(AppRoutes.plus);

/// Where a subscriber manages or cancels YumSum Star.
final managePlusInPlay = Uri.parse(
  'https://play.google.com/store/account/subscriptions'
  '?sku=yumsum_plus&package=com.bpetrov.yumsum',
);

/// Whether a tap on the account's YumSum Star row belongs in Google Play: a
/// Play subscription that is on, or off until a payment is fixed.
bool managedInPlay(Entitlement? entitlement, DateTime now) =>
    entitlement?.source == EntitlementSource.play &&
    (entitlement!.isPlusAt(now) || entitlement.state == 'hold');

/// The account's YumSum Star in one line: "Renews on 3 December", "Free
/// trial until 9 November", or what it adds for someone without it. In
/// [l10n]'s language, English when not given.
String plusStatusLine(
  Entitlement? entitlement,
  DateTime now, {
  AppLocalizations? l10n,
}) {
  final t = l10n ?? lookupAppLocalizations(const Locale('en'));
  final e = entitlement;
  if (e == null || !e.isPlusAt(now)) {
    return e?.state == 'hold' && e?.source == EntitlementSource.play
        ? t.starStatusHold
        : t.starStatusPitch;
  }
  if (e.admin) return t.starStatusAdmin;
  final until = e.expiresAt == null ? null : t.dayMonth(e.expiresAt!);
  if (until == null) return t.starStatusOn;
  if (e.source == EntitlementSource.manual) return t.starStatusOnUntil(until);
  if (e.inTrial) return t.starStatusTrial(until);
  return switch (e.state) {
    'cancelled' => t.starStatusEnds(until),
    'grace' => t.starStatusGrace,
    _ => t.starStatusRenews(until),
  };
}

/// Whether a Play subscription will keep renewing, so deleting the account
/// must warn that it doesn't cancel it.
bool renewsInPlay(Entitlement? entitlement) =>
    entitlement?.source == EntitlementSource.play &&
    entitlement!.state != 'cancelled' &&
    entitlement.state != 'expired';

/// The YumSum Star page: what it adds, then the yearly and monthly plans at
/// Play's own prices, with the free trial when Play offers one to this
/// Google account, all on one phone screen. Buying and restoring go through
/// [plusPurchaseControllerProvider]; the page closes once YumSum Star is on.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key});

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  bool _yearly = true;

  /// A purchase or restore started here, so YumSum Star switching on is its
  /// result (and not just the record loading).
  bool _started = false;

  static List<(IconData, String, String)> _features(AppLocalizations l10n) => [
    (
      Icons.photo_camera_rounded,
      l10n.starFeatureSnapTitle,
      l10n.starFeatureSnapBody,
    ),
    (
      Icons.auto_awesome_rounded,
      l10n.starFeatureEstimatesTitle,
      l10n.starFeatureEstimatesBody,
    ),
    (
      Icons.tune_rounded,
      l10n.starFeatureAdaptiveTitle,
      l10n.starFeatureAdaptiveBody,
    ),
    (
      Icons.insights_rounded,
      l10n.starFeatureCoachTitle,
      l10n.starFeatureCoachBody,
    ),
    (
      Icons.pie_chart_outline_rounded,
      l10n.starFeatureMacrosTitle,
      l10n.starFeatureMacrosBody,
    ),
  ];

  void _buy(StarPlan plan) {
    _started = true;
    ref.read(plusPurchaseControllerProvider.notifier).buy(plan);
  }

  void _restore() {
    _started = true;
    ref.read(plusPurchaseControllerProvider.notifier).restore();
  }

  /// The yearly and monthly tiles, the button and the terms under it.
  Widget _plans(List<StarPlan> plans, PlusPurchase purchase, TextStyle muted) {
    final l10n = context.l10n;
    final [yearly, monthly] = plans;
    final chosen = _yearly ? yearly : monthly;
    final saving = (100 * (1 - yearly.micros / (12 * monthly.micros))).round();
    final trial = chosen.trialDays;
    final terms = switch ((trial, _yearly)) {
      (null, true) => l10n.starTermsYearly(chosen.price),
      (null, false) => l10n.starTermsMonthly(chosen.price),
      (final days?, true) => l10n.starTrialTermsYearly(days, chosen.price),
      (final days?, false) => l10n.starTrialTermsMonthly(days, chosen.price),
    };
    final perMonth = NumberFormat.simpleCurrency(
      locale: l10n.localeName,
      name: yearly.currency,
    ).format(yearly.micros / 12e6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Both tiles as tall as the taller one.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PlanTile(
                  title: l10n.starYearly,
                  price: yearly.price,
                  per: l10n.starPerYear,
                  note: l10n.starMonthlyEquivalent(perMonth),
                  badge: saving > 0 ? l10n.starSave(saving) : null,
                  selected: _yearly,
                  onTap: () => setState(() => _yearly = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanTile(
                  title: l10n.starMonthly,
                  price: monthly.price,
                  per: l10n.starPerMonth,
                  selected: !_yearly,
                  onTap: () => setState(() => _yearly = false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StartButton(
          label: purchase.checking
              ? l10n.starChecking
              : trial == null
              ? l10n.starSubscribe
              : l10n.starStartTrial(trial),
          onPressed: purchase.checking ? null : () => _buy(chosen),
        ),
        const SizedBox(height: 8),
        Text(terms, textAlign: TextAlign.center, style: muted),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(plusPurchaseControllerProvider, (_, next) {
      if (next.message case final message?) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(message.text(l10n)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.starOk),
              ),
            ],
          ),
        );
      }
    });
    // Bought or restored: back to where the person came from, which now
    // has YumSum Star.
    ref.listen(plusProvider, (_, plus) {
      if (!plus || !_started) return;
      _started = false;
      final e = ref.read(entitlementProvider).valueOrNull;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).maybePop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e != null && e.inTrial && e.expiresAt != null
                ? l10n.starOnTrial(l10n.dayMonth(e.expiresAt!))
                : l10n.starOn,
          ),
        ),
      );
    });

    final entitlement = ref.watch(entitlementProvider).valueOrNull;
    final now = DateTime.now();
    final plus = entitlement?.isPlusAt(now) ?? false;
    final muted = TextStyle(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    );

    final Widget offer;
    if (plus) {
      final status = plusStatusLine(entitlement, now, l10n: l10n);
      offer = AppCard(
        child: Row(
          children: [
            const PlusStar(size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.starAlreadyTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(l10n.starThanks, style: muted.copyWith(fontSize: 14)),
                  // A plain "On" adds nothing to the line above.
                  if (status != l10n.starStatusOn) Text(status, style: muted),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (kIsWeb) {
      offer = AppCard(
        child: Text(
          l10n.starWeb,
          textAlign: TextAlign.center,
          style: muted.copyWith(fontSize: 15),
        ),
      );
    } else if (!playBilling) {
      // Apple's rules don't let the iPhone app point to another way to pay.
      offer = AppCard(
        child: Text(
          l10n.starNoIphone,
          textAlign: TextAlign.center,
          style: muted.copyWith(fontSize: 15),
        ),
      );
    } else {
      final purchase = ref.watch(plusPurchaseControllerProvider);
      offer = ref
          .watch(starPlansProvider)
          .when(
            data: (plans) => _plans(plans, purchase, muted),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => AppCard(
              child: Column(
                children: [
                  Text(
                    l10n.starErrorPlay,
                    textAlign: TextAlign.center,
                    style: muted.copyWith(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(starPlansProvider),
                    child: Text(l10n.starTryAgain),
                  ),
                ],
              ),
            ),
          );
    }

    final link = TextButton.styleFrom(visualDensity: VisualDensity.compact);
    const linkSize = TextStyle(fontSize: 13.5);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.heroStart, AppColors.background],
            stops: const [0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Center(
            // The width is set here, outside the scroll view, so the page
            // is measured at the width it is laid out at.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              // Fills one screen, and scrolls only when the screen is too
              // short for it all.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 800;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 4,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              compact: compact,
                              line: plus
                                  ? l10n.starHeaderMember
                                  : l10n.starHeaderPitch,
                              onClose: () => Navigator.of(context).maybePop(),
                            ),
                            for (final (icon, name, line) in _features(l10n))
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: compact ? 8 : 14,
                                ),
                                child: Row(
                                  children: [
                                    IconBubble(icon, size: compact ? 34 : 38),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              height: 1.2,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            line,
                                            style: muted.copyWith(height: 1.25),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            const SizedBox(height: 12),
                            offer,
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                if (!plus && playBilling)
                                  TextButton(
                                    style: link,
                                    onPressed: _restore,
                                    child: Text(
                                      l10n.starRestore,
                                      style: linkSize,
                                    ),
                                  ),
                                TextButton(
                                  style: link,
                                  onPressed: () => openLegalPage(
                                    LegalLinks.terms(
                                      ref.read(languageCodeProvider),
                                    ),
                                  ),
                                  child: Text(l10n.starTerms, style: linkSize),
                                ),
                                TextButton(
                                  style: link,
                                  onPressed: () => openLegalPage(
                                    LegalLinks.privacyPolicy(
                                      ref.read(languageCodeProvider),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.starPrivacy,
                                    style: linkSize,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of the page: the bowl with its star on a warm glow, the
/// wordmark and one [line], with a close button. [compact] makes the bowl
/// smaller, for short screens.
class _Header extends StatelessWidget {
  const _Header({
    required this.compact,
    required this.line,
    required this.onClose,
  });

  final bool compact;
  final String line;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8, bottom: compact ? 12 : 20),
          child: Column(
            children: [
              PlusHero(size: compact ? 104 : 150),
              const SizedBox(height: 4),
              const PlusMark(size: 34),
              const SizedBox(height: 6),
              Text(
                line,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          left: -16,
          child: IconButton(
            tooltip: context.l10n.starClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

/// One plan to pick: its name, the price as the big number, and, for the
/// yearly plan, a badge.
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.per,
    required this.selected,
    required this.onTap,
    this.note,
    this.badge,
  });

  final String title;
  final String price;
  final String per;
  final String? note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Semantics(
      selected: selected,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          Material(
            color: selected ? AppColors.primaryContainer : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: AppTheme.display.copyWith(
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      per,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Both tiles keep the same height.
                    Text(
                      note ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge case final badge?)
            Positioned(
              top: -11,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The big orange "Start 7 days free" pill, glowing like the mic button.
/// It keeps its look while a purchase is checked ([onPressed] null).
class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(56),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
