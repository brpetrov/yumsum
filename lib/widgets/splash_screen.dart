import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:lean_streak/helpers/page_reload.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'app_logo_mark.dart';

/// The logo while the app starts. Still up after 15 seconds, it says so,
/// with Reload on the web, the way out of a connection that stalled.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: 15),
      () => setState(() => _slow = true),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Logo(),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            if (_slow) ...[
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  context.l10n.splashSlow,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              if (kIsWeb) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: reloadPage,
                  child: Text(context.l10n.splashReload),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const AppLogoMark(size: 96),
        ),
        SizedBox(height: 20),
        Text(
          'YumSum',
          style: AppTheme.display.copyWith(
            color: AppColors.textPrimary,
            fontSize: 38,
          ),
        ),
        SizedBox(height: 6),
        Text(
          context.l10n.splashTagline,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
