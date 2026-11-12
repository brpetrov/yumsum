import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/widgets/app_logo_mark.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/responsive_page.dart';
import 'package:lean_streak/widgets/clickable.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignIn) {
      final success = await controller.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (success) {
        TextInput.finishAutofillContext(shouldSave: true);
      }
    } else {
      await controller.signUp(_emailController.text, _passwordController.text);
      if (!ref.read(authControllerProvider).hasError) {
        TextInput.finishAutofillContext(shouldSave: true);
      }
    }
  }

  Future<void> _resendVerification() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .resendVerification(_emailController.text, _passwordController.text);
  }

  Future<void> _signInWithGoogle() =>
      ref.read(authControllerProvider.notifier).signInWithGoogle();

  String _parseError(Object error) {
    final l10n = context.l10n;
    if (error is EmailNotVerifiedException) {
      return l10n.authErrorVerifyEmail;
    }
    if (error is GoogleSignInException) {
      return l10n.authErrorGoogle;
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return l10n.authErrorUsePassword;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return l10n.authErrorWrongCredentials;
        case 'email-already-in-use':
          return l10n.authErrorEmailInUse;
        case 'weak-password':
          return l10n.authPasswordTooShort;
        case 'invalid-email':
          return l10n.commonEnterValidEmailAddress;
        case 'too-many-requests':
          return l10n.commonErrorTooManyAttempts;
        case 'network-request-failed':
          return l10n.authErrorNoInternet;
        default:
          return l10n.authErrorGeneric;
      }
    }
    return l10n.authErrorGeneric;
  }

  static final _emailRe = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  bool _isValidEmail(String email) => _emailRe.hasMatch(email);

  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ResetPasswordDialog(email: _emailController.text.trim()),
    );
  }

  void _switchMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // When sign up completes, auto-switch to Sign In tab.
    ref.listen<AsyncValue<AuthStatus>>(authControllerProvider, (_, next) {
      if (next.valueOrNull == AuthStatus.verificationSent) {
        setState(() => _isSignIn = true);
      }
    });

    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final email = _emailController.text.trim();
    final (bannerTitle, bannerBody) = switch (authState.valueOrNull) {
      AuthStatus.verificationSent => (
        l10n.authVerificationSentTitle,
        l10n.authVerificationSentBody(email),
      ),
      _ => (null, null),
    };
    final errorMessage = authState.hasError
        ? _parseError(authState.error!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePage(
            maxWidth: 560,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 32),

                    // Logo, glowing like the tile it sits on
                    Center(
                      child: Container(
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
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'YumSum',
                        style: AppTheme.display.copyWith(
                          fontSize: 38,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 36),

                    // Sign In / Sign Up toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _TabButton(
                            label: l10n.authSignInTab,
                            selected: _isSignIn,
                            onTap: _isSignIn ? null : _switchMode,
                          ),
                          _TabButton(
                            label: l10n.authSignUpTab,
                            selected: !_isSignIn,
                            onTap: !_isSignIn ? null : _switchMode,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Verification / reset sent banner
                    if (bannerTitle != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bannerTitle,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    bannerBody!,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Error banner
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // The confirmation email may not have come (or be in
                      // junk), so it can be sent again.
                      if (authState.error is EmailNotVerifiedException)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : _resendVerification,
                            child: Text(l10n.authResendVerification),
                          ),
                        ),
                      SizedBox(height: 16),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: l10n.commonEmail,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.authEnterEmail;
                        }
                        if (!_isValidEmail(v.trim())) {
                          return l10n.commonEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      // No hint while the password is shown: on the web, a
                      // shown password with one lost its input after a
                      // failed sign-in, so typing went nowhere (Firefox,
                      // 9 November 2026).
                      autofillHints: !_obscurePassword
                          ? null
                          : _isSignIn
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) {
                        if (!isLoading) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: l10n.commonPassword,
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? l10n.accountShowPassword
                              : l10n.accountHidePassword,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.commonEnterPassword;
                        }
                        if (!_isSignIn && v.length < 6) {
                          return l10n.authPasswordTooShort;
                        }
                        return null;
                      },
                    ),
                    if (_isSignIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _forgotPassword,
                          child: Text(l10n.authForgotPassword),
                        ),
                      ),
                    SizedBox(height: _isSignIn ? 12 : 28),

                    // Submit
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Text(
                                _isSignIn
                                    ? l10n.authSignInButton
                                    : l10n.authCreateAccountButton,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.authOr,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: const _GoogleMark(),
                      label: Text(l10n.authContinueWithGoogle),
                    ),
                    SizedBox(height: 28),
                    const LegalFooter(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain "G" in Google blue, so the button needs no image asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}

// Private tab toggle button

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Clickable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // In dark mode the card colour is darker than the track, so the
            // chosen side is lifted with the outline colour instead.
            color: !selected
                ? Colors.transparent
                : AppColors.isDark
                ? AppColors.outline
                : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.display.copyWith(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Forgot password: asks for the email to send the link to (the sign-in
/// box's to start with), then says a link went if an account uses it. The
/// answer is the same either way, so it never tells who has an account.
class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.email});

  final String email;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  late final _email = TextEditingController(text: widget.email);
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    final failed = ref.read(authControllerProvider).hasError;
    setState(() {
      _sending = false;
      if (failed) {
        _error = context.l10n.authResetError;
      } else {
        _sentTo = email;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = TextStyle(fontSize: 14.5, color: AppColors.textSecondary);
    if (_sentTo case final email?) {
      return AlertDialog(
        title: Text(l10n.authResetSentTitle),
        content: Text(l10n.authResetSentBody(email), style: body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(l10n.authResetTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.authResetIntro, style: body),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) => _send(),
              decoration: InputDecoration(
                labelText: l10n.commonEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  _AuthScreenState._emailRe.hasMatch(v?.trim() ?? '')
                  ? null
                  : l10n.commonEnterValidEmail,
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authResetSend),
        ),
      ],
    );
  }
}
