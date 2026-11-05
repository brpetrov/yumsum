import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lean_streak/app/router.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/icon_bubble.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/plus_mark.dart';

/// The home shell: app bar with the menu, the page body, and an optional bar
/// pinned to the bottom (kept above the keyboard).
class AppFrame extends ConsumerWidget {
  const AppFrame({
    super.key,
    required this.title,
    this.titleBadge,
    this.subtitle,
    this.actions,
    required this.body,
    this.bottom,
  });

  final String title;

  /// Shown right after the title, like Home's YumSum Star badge.
  final Widget? titleBadge;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = titleBadge == null
        ? Text(title)
        : Row(
            children: [
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              titleBadge!,
            ],
          );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: subtitle == null
            ? heading
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
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

/// Opens one of the menu's pages ([route], with any query) from anywhere.
/// Home is the root and every other page sits one level above it, so
/// moving between pages swaps the top one and Back always lands on Home.
void openPage(BuildContext context, String route) {
  final router = GoRouter.of(context);
  if (router.state.uri.toString() == route) return;
  if (route == AppRoutes.dashboard) {
    router.go(route);
  } else if (router.canPop()) {
    router.pushReplacement(route);
  } else {
    router.push(route);
  }
}

/// The menu, shown on every page: Home first, then the other pages,
/// appearance and log out.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _pages = [
    (route: AppRoutes.dashboard, icon: Icons.home_outlined, label: 'Home'),
    (
      route: AppRoutes.review,
      icon: Icons.calendar_month_outlined,
      label: 'History',
    ),
    (
      route: AppRoutes.coach,
      icon: Icons.auto_awesome_outlined,
      label: 'AI Coach',
    ),
    (
      route: AppRoutes.recipes,
      icon: Icons.menu_book_outlined,
      label: 'Recipes',
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

  void _open(BuildContext context, String route) {
    Navigator.of(context).pop();
    openPage(context, route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isWorking = authState.isLoading;
    final current = GoRouter.maybeOf(context)?.state.uri.path;

    // Over the current page, like everywhere it opens from.
    void openPlus() {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(AppRoutes.plus);
    }

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
                          // The badge drops under the name when the menu
                          // is too narrow for both.
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'YumSum',
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.display.copyWith(
                                  fontSize: 27,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StarBadge(onTap: openPlus),
                            ],
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
                  _PlusMenuItem(onTap: openPlus),
                  if (ref.watch(debugToolsProvider))
                    _MenuItem(
                      icon: Icons.bug_report_outlined,
                      label: 'Debug tools',
                      selected: current == AppRoutes.debug,
                      onTap: () => _open(context, AppRoutes.debug),
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

/// YumSum Star in the menu: its smiling star beside the wordmark, so it
/// stands out from the plain pages.
class _PlusMenuItem extends StatelessWidget {
  const _PlusMenuItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: const StadiumBorder(),
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.only(left: 6, right: 12),
        horizontalTitleGap: 14,
        leading: const PlusStar(),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: PlusMark(size: 18),
        ),
        onTap: onTap,
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
