import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';

/// The home shell: app bar with the menu, the page body, and an optional bar
/// pinned to the bottom (kept above the keyboard).
class AppFrame extends ConsumerWidget {
  const AppFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: subtitle == null
            ? Text(title)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
        actions: actions,
      ),
      drawer: const AppDrawer(),
      // The bottom bar lives in the body so it rides above the keyboard;
      // Scaffold.bottomNavigationBar would stay hidden behind it.
      body: bottom == null
          ? body
          : Column(
              children: [
                Expanded(child: body),
                bottom!,
              ],
            ),
    );
  }
}

/// The menu, shown on every page: Today first, then the other pages,
/// appearance and log out.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _pages = [
    (route: AppRoutes.dashboard, icon: Icons.today_outlined, label: 'Today'),
    (
      route: AppRoutes.review,
      icon: Icons.calendar_month_outlined,
      label: 'History',
    ),
    (
      route: AppRoutes.progress,
      icon: Icons.monitor_weight_outlined,
      label: 'Weight & Progress',
    ),
    (
      route: AppRoutes.planSettings,
      icon: Icons.assignment_outlined,
      label: 'Plan Settings',
    ),
    (
      route: AppRoutes.notifications,
      icon: Icons.notifications_outlined,
      label: 'Notifications',
    ),
    (
      route: AppRoutes.profile,
      icon: Icons.manage_accounts_outlined,
      label: 'Account Settings',
    ),
  ];

  /// Today is the root and every other page sits one level above it, so
  /// moving between pages swaps the top one and Back always lands on Today.
  void _open(BuildContext context, String route) {
    Navigator.of(context).pop();
    final router = GoRouter.of(context);
    if (router.state.uri.path == route) return;
    if (route == AppRoutes.dashboard) {
      router.go(route);
    } else if (router.canPop()) {
      router.pushReplacement(route);
    } else {
      router.push(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isWorking = authState.isLoading;
    final current = GoRouter.maybeOf(context)?.state.uri.path;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const AppLogoMark(size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'YumSum',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            for (final page in _pages)
              ListTile(
                leading: Icon(page.icon),
                title: Text(page.label),
                selected: page.route == current,
                onTap: () => _open(context, page.route),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {ref.watch(themeControllerProvider)},
                onSelectionChanged: (selection) => ref
                    .read(themeControllerProvider.notifier)
                    .setMode(selection.first),
              ),
            ),
            const Spacer(),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout_rounded),
              title: Text(authState.isLoading ? 'Signing out...' : 'Log out'),
              enabled: !isWorking,
              onTap: isWorking
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
