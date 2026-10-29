import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/feedback_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
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
    ).showSnackBar(SnackBar(content: Text('Feedback sent. Thank you.')));
  }
}

/// Per device and day: plenty for anyone with something to say, and one
/// person can't use up the form's 50 a month.
const _dailyLimit = 3;
const _sentDayKey = 'feedback.sent_day';
const _sentCountKey = 'feedback.sent_count';

enum _Kind {
  problem('Problem', 'What happened, and what did you expect?'),
  idea('Idea', 'What would make YumSum better for you?'),
  other('Other', 'Anything at all');

  const _Kind(this.label, this.hint);
  final String label;
  final String hint;
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
      final user = ref.read(authStateProvider).valueOrNull!;
      await ref
          .read(feedbackRepositoryProvider)
          .send(
            uid: user.uid,
            email: user.email!,
            kind: _kind.label,
            text: _textCtrl.text.trim(),
          );
      final sent = _sentToday();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_sentDayKey, _today);
      await prefs.setInt(_sentCountKey, sent + 1);
      if (mounted) Navigator.of(context).pop(true);
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
    final email = ref.watch(authStateProvider).valueOrNull?.email;
    final limitReached = _sentToday() >= _dailyLimit;
    final canSend =
        !limitReached && !_sending && _textCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Send feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillToggle<_Kind>(
            options: [for (final kind in _Kind.values) (kind, kind.label)],
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
            decoration: InputDecoration(hintText: _kind.hint),
          ),
          if (email != null) ...[
            SizedBox(height: 12),
            Text(
              'Replies go to $email.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (limitReached) ...[
            SizedBox(height: 12),
            Text(
              "You've sent $_dailyLimit today. You can send more tomorrow.",
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (_failed) ...[
            SizedBox(height: 12),
            Text(
              'Could not send. Try again.',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSend ? _send : null,
          child: Text(_sending ? 'Sending…' : 'Send'),
        ),
      ],
    );
  }
}
