import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';

/// Asks a time on two wheels, hours and minutes in 24 hours, in a sheet
/// under [title]; resolves to the time on Done, or null if the sheet was
/// dismissed. In place of Material's dial, too big and busy for a time of
/// day (12 November 2026).
Future<TimeOfDay?> showTimeWheels(
  BuildContext context, {
  required TimeOfDay initial,
  required String title,
}) {
  var time = initial;
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.display.copyWith(
              fontSize: 19,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: AppColors.isDark
                    ? Brightness.dark
                    : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: AppTheme.display.copyWith(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  initial.hour,
                  initial.minute,
                ),
                onDateTimeChanged: (value) =>
                    time = TimeOfDay.fromDateTime(value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('time-wheels-done'),
            onPressed: () => Navigator.of(context).pop(time),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(context.l10n.commonDone),
          ),
        ],
      ),
    ),
  );
}
