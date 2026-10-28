import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';

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
                      fontWeight: FontWeight.w600,
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
            // Scrolls on a short screen or with large text, so Log out
            // always keeps its place at the bottom.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 20, 14),
                    child: Row(
                      children: [
                        const AppLogoMark(size: 38),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'YumSum',
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.display.copyWith(
                              fontSize: 27,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final page in _pages)
                    _MenuItem(
                      icon: page.icon,
                      label: page.label,
                      selected: page.route == current,
                      onTap: () => _open(context, page.route),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 20, 8),
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
                    child: PillToggle<ThemeMode>(
                      options: const [
                        (ThemeMode.system, 'System'),
                        (ThemeMode.light, 'Light'),
                        (ThemeMode.dark, 'Dark'),
                      ],
                      selected: ref.watch(themeControllerProvider),
                      onChanged: (mode) => ref
                          .read(themeControllerProvider.notifier)
                          .setMode(mode),
                    ),
                  ),
                ],
              ),
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: authState.isLoading ? 'Signing out...' : 'Log out',
              onTap: isWorking
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// One menu entry: a soft pill, tinted when it is the open page, with its
/// icon in a bubble.
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      // The same height on phones as in browsers, so the menu fits short
      // screens.
      child: ListTile(
        shape: const StadiumBorder(),
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.only(left: 6, right: 12),
        horizontalTitleGap: 14,
        selected: selected,
        selectedTileColor: AppColors.primaryContainer,
        selectedColor: AppColors.onPrimaryContainer,
        enabled: onTap != null,
        leading: IconBubble(
          icon,
          size: 36,
          background: selected ? AppColors.surface : AppColors.surfaceVariant,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
