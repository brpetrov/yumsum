// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get languageChoose => 'Изберете език';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBulgarian => 'Български';

  @override
  String get languageSetting => 'Език';

  @override
  String get reminderMealTitle => 'Запишете днешните хранения';

  @override
  String get reminderMealBody =>
      'Добавете какво сте яли, преди денят да свърши.';

  @override
  String get reminderMealChannel => 'Дневно напомняне за храненията';

  @override
  String get reminderMealChannelDescription =>
      'Напомня ви всяка вечер да запишете храненията си.';

  @override
  String get reminderWeightTitle => 'Време е за претегляне';

  @override
  String get reminderWeightBodyDaily =>
      'Запишете днешното си тегло, за да остане планът ви точен.';

  @override
  String get reminderWeightBodyWeekly =>
      'Запишете теглото си за тази седмица, за да остане планът ви точен.';

  @override
  String get reminderWeightChannel => 'Седмично напомняне за теглото';

  @override
  String get reminderWeightChannelDescription =>
      'Напомня ви веднъж седмично да запишете теглото си.';

  @override
  String get reminderCreatineTitle => 'Време за креатин';

  @override
  String get reminderCreatineBody => 'Вземете днешния си креатин.';

  @override
  String get reminderCreatineChannel => 'Напомняне за креатин';

  @override
  String get reminderCreatineChannelDescription =>
      'Напомня ви веднъж дневно да вземете креатин.';
}
