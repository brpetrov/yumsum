// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get languageChoose => 'Избери език';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBulgarian => 'Български';

  @override
  String get languageSetting => 'Език';

  @override
  String get reminderMealTitle => 'Запиши днешните хранения';

  @override
  String get reminderMealBody => 'Добави храненията си, преди денят да свърши.';

  @override
  String get reminderMealChannel => 'Дневно напомняне за храненията';

  @override
  String get reminderMealChannelDescription =>
      'Напомня ти всяка вечер да запишеш храненията си.';

  @override
  String get reminderWeightTitle => 'Време е за претегляне';

  @override
  String get reminderWeightBodyDaily =>
      'Запиши днешното си тегло, за да остане планът ти точен.';

  @override
  String get reminderWeightBodyWeekly =>
      'Запиши теглото си за тази седмица, за да остане планът ти точен.';

  @override
  String get reminderWeightChannel => 'Седмично напомняне за теглото';

  @override
  String get reminderWeightChannelDescription =>
      'Напомня ти веднъж седмично да запишеш теглото си.';

  @override
  String get reminderCreatineTitle => 'Време за креатин';

  @override
  String get reminderCreatineBody => 'Вземи днешния си креатин.';

  @override
  String get reminderCreatineChannel => 'Напомняне за креатин';

  @override
  String get reminderCreatineChannelDescription =>
      'Напомня ти веднъж дневно да вземеш креатин.';
}
