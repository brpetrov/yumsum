import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

class ProfileLoadErrorScreen extends ConsumerWidget {
  const ProfileLoadErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ResponsivePage(
            maxWidth: 460,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 42,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Could not load your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: isSigningOut
                      ? null
                      : () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    isSigningOut ? 'Signing out...' : 'Back to sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
