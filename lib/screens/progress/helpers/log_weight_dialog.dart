import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/services/weight_log_service.dart';

/// Opens the ad-hoc "log your weight" dialog. Resolves with the recalculation
/// result when a weight is saved, or null if the user cancels.
Future<WeightLogResult?> showLogWeightDialog(BuildContext context) {
  return showDialog<WeightLogResult>(
    context: context,
    builder: (context) => const _LogWeightDialog(),
  );
}

class _LogWeightDialog extends ConsumerStatefulWidget {
  const _LogWeightDialog();

  @override
  ConsumerState<_LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends ConsumerState<_LogWeightDialog> {
  late final TextEditingController _weightCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider).valueOrNull?.currentWeightKg;
    _weightCtrl = TextEditingController(
      text: current != null ? current.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    if (weight == null || weight < 25 || weight > 400) {
      setState(() => _error = 'Enter a weight between 25 and 400 kg.');
      return;
    }
    setState(() => _error = null);

    final result = await ref
        .read(weightLogControllerProvider.notifier)
        .logWeight(weightKg: weight);

    if (!mounted) return;
    if (result == null) {
      setState(() => _error = 'Could not save your weight. Try again.');
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(weightLogControllerProvider).isLoading;

    return AlertDialog(
      title: const Text('Log your weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your plan adjusts to match.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current weight',
              suffixText: 'kg',
              errorText: _error,
            ),
            onSubmitted: (_) => isSaving ? null : _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
