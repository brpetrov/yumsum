import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/feedback_provider.dart';

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

class _FeedbackDialog extends ConsumerStatefulWidget {
  const _FeedbackDialog();

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  final _textCtrl = TextEditingController();
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
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
          .send(uid: user.uid, email: user.email!, text: _textCtrl.text.trim());
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
    final canSend = !_sending && _textCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Send feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email != null)
            Text(
              'Replies go to $email.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
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
            decoration: InputDecoration(hintText: 'Ideas, problems, anything'),
          ),
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
