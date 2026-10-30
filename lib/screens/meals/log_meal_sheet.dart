import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/log_meal_controller.dart';
import 'package:lean_streak/providers/past_day_edit_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/widgets/estimate_breakdown.dart';

/// Opens the meal form: edits [existingMeal], or adds a meal on [date]
/// (yyyy-MM-dd, today by default). Resolves to true when the meal was saved.
Future<bool?> showLogMealSheet(
  BuildContext context, {
  Meal? existingMeal,
  String? date,
  String? initialName,
  int? initialCalories,
  int? initialProtein,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LogMealSheet(
      existingMeal: existingMeal,
      date: date,
      initialName: initialName,
      initialCalories: initialCalories,
      initialProtein: initialProtein,
    ),
  );
}

class _LogMealSheet extends ConsumerStatefulWidget {
  const _LogMealSheet({
    this.existingMeal,
    this.date,
    this.initialName,
    this.initialCalories,
    this.initialProtein,
  });

  final Meal? existingMeal;
  final String? date;
  final String? initialName;
  final int? initialCalories;
  final int? initialProtein;

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();

  bool _estimating = false;
  List<EstimateItem> _estimateItems = const [];
  String? _error;

  bool get _isEditing => widget.existingMeal != null;

  String get _date =>
      widget.existingMeal?.date ??
      widget.date ??
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    final meal = widget.existingMeal;
    _nameController.text = meal?.name ?? widget.initialName ?? '';
    final calories = meal?.calories.round() ?? widget.initialCalories;
    if (calories != null) _caloriesController.text = '$calories';
    final protein = meal?.proteinGrams?.round() ?? widget.initialProtein;
    if (protein != null) _proteinController.text = '$protein';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    final name = _nameController.text.trim();
    final uid = ref.read(currentUidProvider);
    if (name.isEmpty || uid == null) return;

    setState(() {
      _estimating = true;
      _estimateItems = const [];
      _error = null;
    });

    try {
      final result = await ref
          .read(calorieEstimateServiceProvider)
          .estimate(uid, name);
      if (!mounted) return;
      _caloriesController.text = '${result.kcal}';
      if (result.protein != null) {
        _proteinController.text = '${result.protein}';
      }
      _estimateItems = result.items;
    } on DailyLimitExceededException {
      _error = 'Daily AI limit reached. Enter the calories yourself.';
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Could not reach the AI. Try again.';
    }

    if (mounted) setState(() => _estimating = false);
  }

  Future<void> _submit() async {
    final calories = double.tryParse(_caloriesController.text.trim());
    if (calories == null || calories <= 0) {
      setState(() => _error = 'Enter the calories, or estimate them.');
      return;
    }
    setState(() => _error = null);

    await ref
        .read(logMealControllerProvider.notifier)
        .submit(
          existingMeal: widget.existingMeal,
          date: _date,
          name: _nameController.text,
          calories: calories,
          proteinGrams: double.tryParse(_proteinController.text.trim()),
        );

    if (!mounted) return;
    final result = ref.read(logMealControllerProvider);
    if (result.hasError) {
      setState(
        () => _error = result.error is EditLimitExceededException
            ? 'No past-day changes left this month.'
            : 'Could not save the meal. Try again.',
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(logMealControllerProvider).isLoading;
    final showProtein = ref.watch(trackProteinProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateLabel = _date == today
        ? null
        : DateFormat('EEEE, d MMMM').format(DateTime.parse(_date));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        // useSafeArea only guards the top of a sheet. padding.bottom is the
        // navigation bar and drops to 0 while the keyboard covers it.
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit meal' : 'Add meal',
              style: AppTheme.display.copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Meal',
                hintText: 'e.g. Musaka, chicken wrap',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: showProtein
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: showProtein ? null : (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      suffixText: 'kcal',
                    ),
                  ),
                ),
                if (showProtein) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (showProtein) ...[
              const SizedBox(height: 6),
              Text(
                'Leave protein blank to estimate it from the name.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _nameController.text.trim().isEmpty || _estimating
                    ? null
                    : _estimate,
                icon: _estimating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Estimate from name'),
              ),
            ),
            if (_estimateItems.isNotEmpty)
              EstimateBreakdown(
                items: _estimateItems,
                showProtein: showProtein,
                onChanged: (items) {
                  final total = totalOf(items);
                  _caloriesController.text = '${total.kcal}';
                  if (total.protein != null) {
                    _proteinController.text = '${total.protein}';
                  }
                  setState(() => _estimateItems = items);
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saving || _estimating ? null : _submit,
              child: saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save meal'),
            ),
          ],
        ),
      ),
    );
  }
}
