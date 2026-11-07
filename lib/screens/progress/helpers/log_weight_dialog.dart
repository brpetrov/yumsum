import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/providers/units_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/providers/weight_log_controller.dart';
import 'package:lean_streak/services/weight_log_service.dart';
import 'package:lean_streak/widgets/measure_field.dart';

/// Opens the ad-hoc "log your weight" dialog. Resolves with the recalculation
/// result when a weight is saved, or null if the user cancels.
Future<WeightLogResult?> showLogWeightDialog(BuildContext context) {
  return showDialog<WeightLogResult>(
    context: context,
    builder: (context) => const _LogWeightDialog(),
  );
}

/// The dialog, then a snackbar saying how it went: for Today and the
/// Adaptive formula's "Log weight now".
Future<void> logWeightWithFeedback(BuildContext context) async {
  final result = await showLogWeightDialog(context);
  if (!context.mounted || result == null) return;
  final message = result.targetChanged
      ? 'Weight saved. New target: ${result.newCalorieTarget} kcal.'
      : 'Weight saved.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _LogWeightDialog extends ConsumerStatefulWidget {
  const _LogWeightDialog();

  @override
  ConsumerState<_LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends ConsumerState<_LogWeightDialog> {
  late final WeightUnit _unit;
  late final WeightInput _weight;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userProfileProvider).valueOrNull?.currentWeightKg;
    _unit = ref.read(weightUnitProvider);
    _weight = WeightInput(_unit)..show(current);
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = _weight.value;
    if (weight == null || weight < 25 || weight > 400) {
      setState(
        () => _error =
            'Enter a weight between '
            '${weightRange(25, 400, _unit, between: ' and ')}.',
      );
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
          MeasureField(
            input: _weight,
            label: 'Current weight',
            autofocus: true,
            error: _error,
            textInputAction: TextInputAction.done,
            onSubmitted: isSaving ? null : _save,
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
