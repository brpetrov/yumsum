import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

/// Opens the YumSum+ page over the current one, so Back returns to it.
Future<void> showPlusPaywall(BuildContext context) =>
    context.push(AppRoutes.plus);

/// Where a subscriber manages or cancels YumSum+.
final managePlusInPlay = Uri.parse(
  'https://play.google.com/store/account/subscriptions'
  '?sku=yumsum_plus&package=com.bpetrov.yumsum',
);

/// Whether a tap on the account's YumSum+ row belongs in Google Play: a
/// Play subscription that is on, or off until a payment is fixed.
bool managedInPlay(Entitlement? entitlement, DateTime now) =>
    entitlement?.source == EntitlementSource.play &&
    (entitlement!.isPlusAt(now) || entitlement.state == 'hold');

/// The account's YumSum+ in one line: "Renews on 3 December", "Free trial
/// until 9 November", or what it adds for someone without it.
String plusStatusLine(Entitlement? entitlement, DateTime now) {
  final e = entitlement;
  if (e == null || !e.isPlusAt(now)) {
    return e?.state == 'hold' && e?.source == EntitlementSource.play
        ? 'Off until the payment problem is fixed in Google Play'
        : 'Photo logging, 30 AI estimates a day and more';
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
    'grace' => 'Payment problem. Fix it in Google Play to keep YumSum+.',
    _ => 'Renews on $until',
  };
}

/// What YumSum+ adds, and the account's YumSum+ once it has it. It isn't
/// on sale yet: the plans and the subscribe button come with Play billing
/// (docs/plans/07-billing.md).
class PlusScreen extends ConsumerWidget {
  const PlusScreen({super.key});

  static const _features = [
    (Icons.photo_camera_rounded, 'Log a meal from a photo of your plate'),
    (Icons.auto_awesome_rounded, '30 AI estimates a day, instead of 10'),
    (
      Icons.tune_rounded,
      'Adaptive formula: your target adjusts each Monday to how your weight '
          'really moves, after about 3 weeks of regular weigh-ins',
    ),
    (Icons.insights_rounded, 'A weekly review in History, written by the AI'),
    (
      Icons.pie_chart_outline_rounded,
      'Full macros: fat, saturates, carbs, sugars, fibre and salt for your '
          'meals',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider).valueOrNull;
    final now = DateTime.now();
    final plus = entitlement?.isPlusAt(now) ?? false;
    final body = TextStyle(
      fontSize: 15.5,
      height: 1.4,
      color: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('YumSum+')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePage(
            maxWidth: 560,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Center(child: PlusHero(size: 168)),
                const SizedBox(height: 14),
                const Center(child: PlusMark(size: 30)),
                const SizedBox(height: 8),
                Text(
                  'Logging stays free. YumSum+ adds:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                for (final (icon, line) in _features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBubble(icon, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(line, style: body),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                AppCard(
                  child: plus
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your YumSum+',
                              style: body.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              plusStatusLine(entitlement, now),
                              style: body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : Text('YumSum+ isn\'t on sale yet.', style: body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
