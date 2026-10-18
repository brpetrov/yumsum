import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/widgets/app_frame.dart';
import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/reminder_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/widgets/legal_links.dart';
import 'package:lean_streak/widgets/password_confirm_dialog.dart';
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
      ).showSnackBar(SnackBar(content: Text('Account updated.')));
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: 'Could not update your account.');
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await ref
          .read(accountControllerProvider.notifier)
          .sendPasswordResetEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password reset email sent.')));
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: 'Could not send reset email.');
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
        SnackBar(content: Text('Check your new email to confirm the change.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: 'Could not start email change.');
    }
  }

  Future<void> _confirmAndResetAllData() async {
    final password = await showPasswordConfirmDialog(
      context,
      title: 'Reset all data?',
      description:
          'This deletes every meal, daily summary, weigh-in and AI usage '
          'record. Your account, profile and plan stay.',
      confirmLabel: 'Reset all data',
      destructive: true,
    );

    if (password == null || !mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .resetAllData(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('All logged data deleted.')));
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: 'Could not reset your data.');
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final password = await showPasswordConfirmDialog(
      context,
      title: 'Delete account?',
      description:
          'This deletes your profile, all logged data, and your login. This cannot be undone.',
      confirmLabel: 'Delete account',
      destructive: true,
    );

    if (password == null || !mounted) return;

    try {
      await ref
          .read(accountControllerProvider.notifier)
          .deleteAccount(password: password);
    } catch (error) {
      if (!mounted) return;
      _showAccountError(error, fallback: 'Could not delete your account.');
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
    final profileAsync = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final accountState = ref.watch(accountControllerProvider);
    final isWorking = accountState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text('Account Settings')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Could not load your account right now.',
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
                        'Manage your account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Update your name, change your email, or manage account security.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 28),
                      const _AccountSectionLabel('ACCOUNT'),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14),
                      TextFormField(
                        initialValue: authUser?.email ?? profile.email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isWorking ? null : _changeEmail,
                        icon: Icon(Icons.mark_email_read_outlined),
                        label: Text('Change email'),
                      ),
                      SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: isWorking ? null : _saveName,
                        child: isWorking
                            ? const _SmallButtonSpinner()
                            : Text('Save Account'),
                      ),
                      SizedBox(height: 28),
                      const _AccountSectionLabel('REMINDERS'),
                      const _ReminderSwitches(),
                      SizedBox(height: 28),
                      const _AccountSectionLabel('PASSWORD'),
                      OutlinedButton.icon(
                        onPressed: isWorking ? null : _sendPasswordReset,
                        icon: Icon(Icons.lock_reset_rounded),
                        label: Text('Send password reset email'),
                      ),
                      SizedBox(height: 28),
                      const _AccountSectionLabel('LEGAL'),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Privacy policy'),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => openLegalPage(LegalLinks.privacyPolicy),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Terms of use'),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => openLegalPage(LegalLinks.terms),
                      ),
                      SizedBox(height: 28),
                      const _AccountSectionLabel('DANGER ZONE'),
                      OutlinedButton.icon(
                        onPressed: isWorking ? null : _confirmAndResetAllData,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                        icon: Icon(Icons.restart_alt_rounded),
                        label: Text('Reset all data'),
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
                        label: Text('Delete Account'),
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
            'Could not load your account right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// The two notification switches, plus the weigh-in day and time. Turning a
/// switch on asks the system for permission; if that is refused it stays off.
class _ReminderSwitches extends ConsumerWidget {
  const _ReminderSwitches();

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _clock(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    Future<void> apply(Future<bool> Function() change) async {
      final ok = await change();
      if (ok || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow notifications for LeanStreak in system settings.',
          ),
        ),
      );
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: settings.weeklyTime,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked != null) {
        await notifier.setWeeklySchedule(day: settings.weeklyDay, time: picked);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily meal reminder'),
          subtitle: const Text('Every evening at 20:30'),
          value: settings.dailyMeal,
          onChanged: (on) => apply(() => notifier.setDailyMeal(on)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Weekly weigh-in reminder'),
          subtitle: Text(
            '${_dayNames[settings.weeklyDay]}s at ${_clock(settings.weeklyTime)}',
          ),
          value: settings.weeklyWeight,
          onChanged: (on) => apply(() => notifier.setWeeklyWeight(on)),
        ),
        if (settings.weeklyWeight)
          Row(
            children: [
              DropdownButton<int>(
                value: settings.weeklyDay,
                underline: const SizedBox.shrink(),
                items: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    DropdownMenuItem(value: day, child: Text(_dayNames[day])),
                ],
                onChanged: (day) {
                  if (day != null) {
                    notifier.setWeeklySchedule(
                      day: day,
                      time: settings.weeklyTime,
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(_clock(settings.weeklyTime)),
              ),
            ],
          ),
      ],
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
    return AlertDialog(
      title: Text('Change email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your new email and current password. We will send a verification link before changing your login email.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Please enter your new email.';
                final emailRe = RegExp(
                  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                );
                if (!emailRe.hasMatch(email)) {
                  return 'Please enter a valid email.';
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
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
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
                  return 'Please enter your current password.';
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
          child: Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text('Send verification')),
      ],
    );
  }
}
