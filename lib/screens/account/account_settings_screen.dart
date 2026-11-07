import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/theme_controller.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/screens/account/notification_settings.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/app_card.dart';
import 'package:lean_streak/widgets/plus_mark.dart';
import 'package:lean_streak/widgets/feedback_dialog.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/password_confirm_dialog.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';
import 'package:lean_streak/widgets/responsive_page.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _loadedProfileUid;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// False for an account made with Google: it has no password to change
  /// or confirm with, and Google looks after its email.
  bool get _usesPassword {
    final user = ref.read(authStateProvider).valueOrNull;
    return user == null || hasPasswordLogin(user);
  }

  /// A Google user is asked to confirm with Google next.
  String _confirmNote(String description) => _usesPassword
      ? description
      : context.l10n.accountConfirmWithGoogle(description);

  void _seedName(String uid, String name) {
    if (_loadedProfileUid == uid) return;
    _loadedProfileUid = uid;
    _nameCtrl.text = name;
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .updateAccountName(name: _nameCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.accountNameSaved)));
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: context.l10n.accountErrorSaveName);
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await ref
          .read(accountControllerProvider.notifier)
          .sendPasswordResetEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountResetEmailSent)),
      );
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: context.l10n.accountErrorSendReset);
    }
  }

  Future<void> _changeEmail() async {
    final request = await showChangeEmailDialog(context);
    if (request == null || !mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .sendEmailChangeVerification(
            newEmail: request.newEmail,
            password: request.password,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountCheckNewEmail)),
      );
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: context.l10n.accountErrorChangeEmail);
    }
  }

  Future<void> _confirmAndResetAllData() async {
    final l10n = context.l10n;
    final password = await showPasswordConfirmDialog(
      context,
      title: l10n.accountResetTitle,
      description: _confirmNote(l10n.accountResetBody),
      confirmLabel: l10n.accountResetButton,
      destructive: true,
      askPassword: _usesPassword,
    );

    if (password == null || !mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .resetAllData(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountResetDone)));
    } catch (error) {
      if (!mounted || backedOutOfGoogle(error)) return;
      _showAccountError(error, fallback: l10n.accountErrorReset);
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final l10n = context.l10n;
    final password = await showPasswordConfirmDialog(
      context,
      title: l10n.accountDeleteTitle,
      description: _confirmNote(
        renewsInPlay(ref.read(entitlementProvider).valueOrNull)
            ? l10n.accountDeleteBodyStar
            : l10n.accountDeleteBody,
      ),
      confirmLabel: l10n.accountDeleteButton,
      destructive: true,
      askPassword: _usesPassword,
    );

    if (password == null || !mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .deleteAccount(password: password);
    } catch (error) {
      if (!mounted || backedOutOfGoogle(error)) return;
      _showAccountError(error, fallback: l10n.accountErrorDelete);
    }
  }

  void _showAccountError(Object error, {required String fallback}) {
    final message = error is AccountActionException ? error.message : fallback;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final accountState = ref.watch(accountControllerProvider);
    final isWorking = accountState.isLoading;
    final usesPassword = _usesPassword;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                l10n.accountErrorLoad,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          _seedName(profile.uid, profile.name);
          ref.read(accountControllerProvider.notifier).syncAuthEmailToProfile();

          return SafeArea(
            child: SingleChildScrollView(
              child: ResponsivePage(
                maxWidth: 560,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.accountHeading,
                        style: AppTheme.display.copyWith(
                          fontSize: 26,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        usesPassword
                            ? l10n.accountSubtitle
                            : l10n.accountSubtitleGoogle,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionAccount),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: InputDecoration(
                          labelText: l10n.accountName,
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.accountEnterName;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        initialValue: authUser?.email ?? profile.email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.commonEmail,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      if (usesPassword) ...[
                        SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isWorking ? null : _changeEmail,
                          icon: Icon(Icons.mark_email_read_outlined),
                          label: Text(l10n.accountChangeEmail),
                        ),
                      ],
                      SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: isWorking ? null : _saveName,
                        child: isWorking
                            ? const _SmallButtonSpinner()
                            : Text(l10n.accountSaveName),
                      ),
                      if (usesPassword) ...[
                        SizedBox(height: 28),
                        _AccountSectionLabel(l10n.accountSectionPassword),
                        OutlinedButton.icon(
                          onPressed: isWorking ? null : _sendPasswordReset,
                          icon: Icon(Icons.lock_reset_rounded),
                          label: Text(l10n.accountSendReset),
                        ),
                      ],
                      // Reminders are Android and iOS only.
                      if (!kIsWeb) ...[
                        SizedBox(height: 28),
                        _AccountSectionLabel(l10n.accountSectionNotifications),
                        const NotificationSettings(),
                      ],
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionAppearance),
                      PillToggle<ThemeMode>(
                        options: [
                          (ThemeMode.system, l10n.menuThemeSystem),
                          (ThemeMode.light, l10n.menuThemeLight),
                          (ThemeMode.dark, l10n.menuThemeDark),
                        ],
                        selected: ref.watch(themeControllerProvider),
                        onChanged: (mode) => ref
                            .read(themeControllerProvider.notifier)
                            .setMode(mode),
                      ),
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionLanguage),
                      PillToggle<String>(
                        options: [
                          ('en', l10n.languageEnglish),
                          ('bg', l10n.languageBulgarian),
                        ],
                        selected: ref.watch(languageCodeProvider),
                        onChanged: (code) => ref
                            .read(languageControllerProvider.notifier)
                            .setLanguage(code),
                      ),
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionStar),
                      const _PlusTile(),
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionHelp),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.accountSendFeedback),
                        subtitle: Text(l10n.accountSendFeedbackHint),
                        trailing: const Icon(
                          Icons.mail_outline_rounded,
                          size: 18,
                        ),
                        onTap: () => showFeedbackDialog(context),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.accountPrivacyPolicy),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => openLegalPage(
                          LegalLinks.privacyPolicy(
                            ref.read(languageCodeProvider),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.accountTerms),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => openLegalPage(
                          LegalLinks.terms(ref.read(languageCodeProvider)),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.accountOpenFoodFacts),
                        subtitle: Text(l10n.accountOpenFoodFactsHint),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => openLegalPage(LegalLinks.openFoodFacts),
                      ),
                      SizedBox(height: 28),
                      _AccountSectionLabel(l10n.accountSectionDanger),
                      OutlinedButton.icon(
                        onPressed: isWorking ? null : _confirmAndResetAllData,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        icon: Icon(Icons.restart_alt_rounded),
                        label: Text(l10n.accountResetButton),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isWorking ? null : _confirmAndDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        icon: Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.accountDeleteButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text(
            l10n.accountErrorLoad,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AccountSectionLabel extends StatelessWidget {
  const _AccountSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// The account's YumSum Star: what it adds (opening the YumSum Star page) until it
/// has it, then its state, managed in Google Play for a subscription.
class _PlusTile extends ConsumerWidget {
  const _PlusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider).valueOrNull;
    final now = DateTime.now();
    final plus = entitlement?.isPlusAt(now) ?? false;
    final manage = managedInPlay(entitlement, now);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      onTap: manage
          ? () => openLegalPage(managePlusInPlay)
          : plus
          ? null
          : () => showPlusPaywall(context),
      child: Row(
        children: [
          const PlusStar(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PlusMark(size: 19),
                const SizedBox(height: 3),
                Text(
                  plusStatusLine(entitlement, now, l10n: context.l10n),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (manage || !plus)
            Icon(
              manage ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              size: manage ? 18 : 24,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

class _SmallButtonSpinner extends StatelessWidget {
  const _SmallButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.onPrimary,
      ),
    );
  }
}

class ChangeEmailRequest {
  const ChangeEmailRequest({required this.newEmail, required this.password});

  final String newEmail;
  final String password;
}

Future<ChangeEmailRequest?> showChangeEmailDialog(BuildContext context) {
  return showDialog<ChangeEmailRequest>(
    context: context,
    builder: (context) => const _ChangeEmailDialog(),
  );
}

class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog();

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ChangeEmailRequest(
        newEmail: _emailCtrl.text,
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.accountChangeEmailTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountChangeEmailBody,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.accountNewEmail,
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return l10n.accountEnterNewEmail;
                final emailRe = RegExp(
                  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                );
                if (!emailRe.hasMatch(email)) {
                  return l10n.commonEnterValidEmail;
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.accountCurrentPassword,
                prefixIcon: Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? l10n.accountShowPassword
                      : l10n.accountHidePassword,
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.accountEnterCurrentPassword;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.accountSendLink)),
      ],
    );
  }
}
