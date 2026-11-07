import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/feedback_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/repositories/feedback_repository.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';

/// Lets the user write to the developer without leaving the app; a thank-you
/// snackbar follows once it's sent.
Future<void> showFeedbackDialog(BuildContext context) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (context) => const _FeedbackDialog(),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.feedbackSent)));
  }
}

/// A day: plenty for anyone with something to say, and one person can't use
/// up the form's 50 a month. The server holds each account to it; this
/// device's count only says so before anything is sent.
const _dailyLimit = 3;
const _sentDayKey = 'feedback.sent_day';
const _sentCountKey = 'feedback.sent_count';

enum _Kind {
  problem('Problem'),
  idea('Idea'),
  other('Other');

  const _Kind(this.sent);

  /// What the message is sent as: English, for the developer's inbox.
  final String sent;

  String label(AppLocalizations l10n) => switch (this) {
    problem => l10n.feedbackKindProblem,
    idea => l10n.feedbackKindIdea,
    other => l10n.feedbackKindOther,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    problem => l10n.feedbackHintProblem,
    idea => l10n.feedbackHintIdea,
    other => l10n.feedbackHintOther,
  };
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  const _FeedbackDialog();

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  final _textCtrl = TextEditingController();
  var _kind = _Kind.problem;
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int _sentToday() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getString(_sentDayKey) != _today) return 0;
    return prefs.getInt(_sentCountKey) ?? 0;
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .send(kind: _kind.sent, text: _textCtrl.text.trim());
      final sent = _sentToday();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_sentDayKey, _today);
      await prefs.setInt(_sentCountKey, sent + 1);
      if (mounted) Navigator.of(context).pop(true);
    } on FeedbackLimitReached {
      // Sent from another device, or this phone's day began before the
      // server's UTC one: shown as if they were all sent from here.
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_sentDayKey, _today);
      await prefs.setInt(_sentCountKey, _dailyLimit);
      if (mounted) setState(() => _sending = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = ref.watch(authStateProvider).valueOrNull?.email;
    final limitReached = _sentToday() >= _dailyLimit;
    final canSend =
        !limitReached && !_sending && _textCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.feedbackTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillToggle<_Kind>(
            options: [
              for (final kind in _Kind.values) (kind, kind.label(l10n)),
            ],
            selected: _kind,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          SizedBox(height: 16),
          TextField(
            key: const Key('feedback-text'),
            controller: _textCtrl,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            inputFormatters: [LengthLimitingTextInputFormatter(4000)],
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: _kind.hint(l10n)),
          ),
          if (email != null) ...[
            SizedBox(height: 12),
            Text(
              l10n.feedbackRepliesTo(email),
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (limitReached) ...[
            SizedBox(height: 12),
            Text(
              l10n.feedbackLimitReached(_dailyLimit),
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (_failed) ...[
            SizedBox(height: 12),
            Text(
              l10n.feedbackErrorSend,
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: canSend ? _send : null,
          child: Text(_sending ? l10n.feedbackSending : l10n.feedbackSend),
        ),
      ],
    );
  }
}
