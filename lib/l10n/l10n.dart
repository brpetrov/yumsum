import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/l10n/app_localizations.dart';

export 'package:lean_streak/l10n/app_localizations.dart';

final _english = lookupAppLocalizations(const Locale('en'));

/// The app's texts in the current language: `context.l10n.someKey`.
extension L10nContext on BuildContext {
  /// English where the tree has no app localisations, as in widget tests
  /// that pump a bare MaterialApp.
  AppLocalizations get l10n => AppLocalizations.of(this) ?? _english;
}

/// Dates and numbers in the language of these texts, so "7 November" reads
/// "7 ноември" and 1.5 reads "1,5" in Bulgarian. Reached from widgets as
/// `context.l10n.dayMonth(date)`, elsewhere through `l10nProvider`.
///
/// Bulgarian day and month names are lower case: [capitalised] when one
/// starts a line.
extension AppFormats on AppLocalizations {
  /// [date] in an intl [pattern] such as 'EEE, d MMM'. Prefer the named
  /// formats below, which keep the app's day-month order.
  String date(DateTime date, String pattern) {
    _loadDateData();
    return DateFormat(pattern, localeName).format(date);
  }

  /// "Saturday, 7 November", "събота, 7 ноември".
  String weekdayDayMonth(DateTime d) => date(d, 'EEEE, d MMMM');

  /// "Sat, 7 Nov", "сб, 7 ное".
  String shortWeekdayDayMonth(DateTime d) => date(d, 'EEE, d MMM');

  /// "7 November", "7 ноември".
  String dayMonth(DateTime d) => date(d, 'd MMMM');

  /// "7 Nov", "7 ное".
  String shortDayMonth(DateTime d) => date(d, 'd MMM');

  /// "7 Nov 2026", "7 ное 2026".
  String shortDayMonthYear(DateTime d) => date(d, 'd MMM yyyy');

  /// "November 2026", "ноември 2026".
  String monthYear(DateTime d) => date(d, 'LLLL yyyy');

  /// "November", "ноември", standing alone.
  String month(DateTime d) => date(d, 'LLLL');

  /// "20:30" in both.
  String time(DateTime d) => date(d, 'HH:mm');

  /// [value] with [digits] decimals and the language's decimal mark, like
  /// `toStringAsFixed`: "1.5", "1,5". No thousands separator.
  String decimal(num value, [int digits = 1]) => NumberFormat(
    digits == 0 ? '0' : '0.${'0' * digits}',
    localeName,
  ).format(value);
}

/// [text] with its first letter in capitals: "Събота, 7 ноември".
String capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// A number the user typed, with either a comma or a point for decimals.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

var _dateDataLoaded = false;

/// intl's day and month names for every locale. Loads at once (the Future
/// is already complete), so it can be called from a synchronous format.
void _loadDateData() {
  if (_dateDataLoaded) return;
  _dateDataLoaded = true;
  initializeDateFormatting();
}
