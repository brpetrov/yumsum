// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageChoose => 'Choose your language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBulgarian => 'Български';

  @override
  String get languageSetting => 'Language';

  @override
  String get reminderMealTitle => 'Log today\'s meals';

  @override
  String get reminderMealBody => 'Add what you ate before the day ends.';

  @override
  String get reminderMealChannel => 'Daily Log Reminder';

  @override
  String get reminderMealChannelDescription =>
      'Reminds you each evening to log your meals.';

  @override
  String get reminderWeightTitle => 'Time to weigh in';

  @override
  String get reminderWeightBodyDaily =>
      'Log today\'s weight to keep your plan accurate.';

  @override
  String get reminderWeightBodyWeekly =>
      'Log this week\'s weight to keep your plan accurate.';

  @override
  String get reminderWeightChannel => 'Weekly Weight Reminder';

  @override
  String get reminderWeightChannelDescription =>
      'Reminds you once a week to log your weight.';

  @override
  String get reminderCreatineTitle => 'Creatine time';

  @override
  String get reminderCreatineBody => 'Take today\'s creatine.';

  @override
  String get reminderCreatineChannel => 'Creatine Reminder';

  @override
  String get reminderCreatineChannelDescription =>
      'Reminds you once a day to take creatine.';
}
