import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/meal.dart';
import 'package:lean_streak/models/nutrients.dart';
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

  // An estimate's macros, kept with its calories and scaled to the
  // calories saved, as the quick-log bar does.
  Nutrients? _macros;
  int? _macrosKcal;

  // The time eaten, once picked; until then an edit keeps the meal's own
  // and a new meal gets the time it is saved. The day is always the meal's.
  TimeOfDay? _time;

  bool get _isEditing => widget.existingMeal != null;

  TimeOfDay get _shownTime =>
      _time ??
      TimeOfDay.fromDateTime(widget.existingMeal?.timestamp ?? DateTime.now());

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
      _macros = result.macros;
      _macrosKcal = result.kcal;
    } on DailyLimitExceededException {
      if (mounted) _error = context.l10n.mealAiLimit;
    } on CalorieEstimateException catch (error) {
      _error = error.message;
    } catch (_) {
      if (mounted) _error = context.l10n.mealErrorAi;
    }

    if (!mounted) return;
    setState(() => _estimating = false);
  }

  /// A weight corrected or a version picked: the boxes follow the items.
  void _itemsChanged(List<EstimateItem> items) {
    final total = totalOf(items);
    _caloriesController.text = '${total.kcal}';
    if (total.protein != null) {
      _proteinController.text = '${total.protein}';
    }
    setState(() => _estimateItems = items);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _shownTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final calories = parseDecimal(_caloriesController.text);
    if (calories == null || calories <= 0) {
      setState(() => _error = context.l10n.mealErrorNoCalories);
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
          proteinGrams: parseDecimal(_proteinController.text),
          macros: switch ((_macros, _macrosKcal)) {
            (final macros?, final from?) when from > 0 => macros.scaled(
              calories / from,
            ),
            _ => null,
          },
          time: _time,
        );

    if (!mounted) return;
    final result = ref.read(logMealControllerProvider);
    if (result.hasError) {
      setState(
        () => _error = result.error is EditLimitExceededException
            ? context.l10n.mealErrorEditLimit
            : context.l10n.mealErrorSave,
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(logMealControllerProvider).isLoading;
    final showProtein = ref.watch(trackProteinProvider);
    final l10n = context.l10n;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateLabel = _date == today
        ? null
        : capitalised(l10n.weekdayDayMonth(DateTime.parse(_date)));

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
              _isEditing ? l10n.mealEditTitle : l10n.mealAddTitle,
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
              // An estimate's macros belong to the food it was for.
              onChanged: (_) => setState(() => _macros = null),
              decoration: InputDecoration(
                labelText: l10n.mealName,
                hintText: l10n.mealNameHint,
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
                    decoration: InputDecoration(
                      labelText: l10n.mealCalories,
                      suffixText: l10n.commonKcalUnit,
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
                      decoration: InputDecoration(
                        labelText: l10n.mealProtein,
                        suffixText: l10n.commonGramsUnit,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (showProtein) ...[
              const SizedBox(height: 6),
              Text(
                l10n.mealProteinNote,
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
                label: Text(l10n.mealEstimateFromName),
              ),
            ),
            if (_estimateItems.isNotEmpty)
              EstimateBreakdown(
                items: _estimateItems,
                showProtein: showProtein,
                onChanged: _itemsChanged,
              ),
            const SizedBox(height: 12),
            InkWell(
              key: const ValueKey('meal-time'),
              onTap: saving ? null : _pickTime,
              borderRadius: BorderRadius.circular(AppTheme.inputRadius),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.mealTime,
                  suffixIcon: const Icon(Icons.schedule_rounded),
                ),
                child: Text(
                  l10n.time(
                    DateTime(2000, 1, 1, _shownTime.hour, _shownTime.minute),
                  ),
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
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
                  : Text(_isEditing ? l10n.mealSaveChanges : l10n.mealSave),
            ),
          ],
        ),
      ),
    );
  }
}
