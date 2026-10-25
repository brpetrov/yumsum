import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

/// Asks for the password before [confirmLabel]. Without [askPassword]
/// (a Google account, which confirms with Google next) it's a plain
/// confirmation that resolves to an empty string.
Future<String?> showPasswordConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  bool destructive = false,
  bool askPassword = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return _PasswordConfirmDialog(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        destructive: destructive,
        askPassword: askPassword,
      );
    },
  );
}

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.destructive,
    required this.askPassword,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final bool destructive;
  final bool askPassword;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        !widget.askPassword || _passwordCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          if (widget.askPassword) ...[
            SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              autofocus: true,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_passwordCtrl.text.trim())
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: widget.destructive
                ? AppColors.error
                : AppColors.primary,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
