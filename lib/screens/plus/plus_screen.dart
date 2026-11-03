import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
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
/// trial until 9 November", or what it adds for someone without it.
String plusStatusLine(Entitlement? entitlement, DateTime now) {
  final e = entitlement;
  if (e == null || !e.isPlusAt(now)) {
    return e?.state == 'hold' && e?.source == EntitlementSource.play
        ? 'Off until the payment problem is fixed in Google Play'
        : 'Smart Snap, 30 AI estimates a day and more';
  }
  if (e.admin) return 'Admin: everything on, no daily limits';
  final until = e.expiresAt == null
      ? null
      : DateFormat('d MMMM').format(e.expiresAt!);
  if (until == null) return 'On';
  if (e.source == EntitlementSource.manual) return 'On until $until';
  if (e.inTrial) return 'Free trial until $until';
  return switch (e.state) {
    'cancelled' => 'Ends on $until',
    'grace' => 'Payment problem. Fix it in Google Play to keep YumSum Star.',
    _ => 'Renews on $until',
  };
}

/// The YumSum Star promo: what it adds, the yearly and monthly plans and
/// the free week, on one phone screen. It isn't on sale yet, so the buttons
/// say so; Play billing (docs/plans/07-billing.md) will load the real
/// prices and start the purchase.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key});

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  bool _yearly = true;

  static const _features = [
    (
      Icons.photo_camera_rounded,
      'Smart Snap',
      'Capture your meal. The AI does the rest.',
    ),
    (
      Icons.auto_awesome_rounded,
      'Triple the AI estimates',
      '30 a day, so you never run out.',
    ),
    (
      Icons.tune_rounded,
      'Adaptive Formula',
      'After about 3 weeks of weigh-ins, your target adjusts to you.',
    ),
    (
      Icons.insights_rounded,
      'AI Assisted Coach',
      'Weekly and monthly reviews, with advice.',
    ),
    (
      Icons.pie_chart_outline_rounded,
      'Detailed Macros',
      'The full label: fat, carbs, sugars, fibre, salt.',
    ),
  ];

  Future<void> _comingSoon() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const PlusStar(size: 64),
      title: const Text('Coming soon'),
      content: const Text(
        'YumSum Star isn\'t on sale yet. You\'ll be able to start your free '
        'week here soon.',
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
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
      final status = plusStatusLine(entitlement, now);
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
                    'You\'re already a bright YumSum Star',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Thank you for helping YumSum grow.',
                    style: muted.copyWith(fontSize: 14),
                  ),
                  // A plain "On" adds nothing to the line above.
                  if (status != 'On') Text(status, style: muted),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (kIsWeb) {
      offer = AppCard(
        child: Text(
          'Subscribe in the YumSum app for Android. YumSum Star then works '
          'here too, when you sign in with the same account.',
          textAlign: TextAlign.center,
          style: muted.copyWith(fontSize: 15),
        ),
      );
    } else {
      offer = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Both tiles as tall as the taller one.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PlanTile(
                    title: 'Yearly',
                    price: '£17.99',
                    per: 'a year',
                    note: '£1.50 a month',
                    badge: 'Save 50%',
                    selected: _yearly,
                    onTap: () => setState(() => _yearly = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanTile(
                    title: 'Monthly',
                    price: '£2.99',
                    per: 'a month',
                    selected: !_yearly,
                    onTap: () => setState(() => _yearly = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StartButton(onPressed: _comingSoon),
          const SizedBox(height: 8),
          Text(
            _yearly
                ? '7 days free, then £17.99 a year. Renews every year until '
                      'you cancel. Cancel any time in Google Play.'
                : '7 days free, then £2.99 a month. Renews every month '
                      'until you cancel. Cancel any time in Google Play.',
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
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
                                  ? 'Everything here is yours.'
                                  : 'Shine bright with these smart perks.',
                              onClose: () => Navigator.of(context).maybePop(),
                            ),
                            for (final (icon, name, line) in _features)
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
                                if (!plus && !kIsWeb)
                                  TextButton(
                                    style: link,
                                    onPressed: _comingSoon,
                                    child: const Text(
                                      'Restore purchase',
                                      style: linkSize,
                                    ),
                                  ),
                                TextButton(
                                  style: link,
                                  onPressed: () =>
                                      openLegalPage(LegalLinks.terms),
                                  child: const Text('Terms', style: linkSize),
                                ),
                                TextButton(
                                  style: link,
                                  onPressed: () =>
                                      openLegalPage(LegalLinks.privacyPolicy),
                                  child: const Text('Privacy', style: linkSize),
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
            tooltip: 'Close',
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
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

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
          minimumSize: const Size.fromHeight(56),
        ),
        child: const Text('Start 7 days free', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
