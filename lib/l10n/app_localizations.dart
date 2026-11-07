import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bg.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bg'),
  ];

  /// First-launch language screen: its heading, shown in English and in Bulgarian at once.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageChoose;

  /// The English option, always written in English, in both files.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// The Bulgarian option, always written in Bulgarian, in both files.
  ///
  /// In en, this message translates to:
  /// **'Български'**
  String get languageBulgarian;

  /// Menu: the heading over the English / Български switch.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// Evening reminder notification: title.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s meals'**
  String get reminderMealTitle;

  /// Evening reminder notification: text.
  ///
  /// In en, this message translates to:
  /// **'Add what you ate before the day ends.'**
  String get reminderMealBody;

  /// Android's notification settings: the evening reminder's name.
  ///
  /// In en, this message translates to:
  /// **'Daily Log Reminder'**
  String get reminderMealChannel;

  /// Android's notification settings: what the evening reminder is for.
  ///
  /// In en, this message translates to:
  /// **'Reminds you each evening to log your meals.'**
  String get reminderMealChannelDescription;

  /// Weigh-in reminder notification: title.
  ///
  /// In en, this message translates to:
  /// **'Time to weigh in'**
  String get reminderWeightTitle;

  /// Weigh-in reminder notification: text when it comes every day.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s weight to keep your plan accurate.'**
  String get reminderWeightBodyDaily;

  /// Weigh-in reminder notification: text when it comes once a week.
  ///
  /// In en, this message translates to:
  /// **'Log this week\'s weight to keep your plan accurate.'**
  String get reminderWeightBodyWeekly;

  /// Android's notification settings: the weigh-in reminder's name.
  ///
  /// In en, this message translates to:
  /// **'Weekly Weight Reminder'**
  String get reminderWeightChannel;

  /// Android's notification settings: what the weigh-in reminder is for.
  ///
  /// In en, this message translates to:
  /// **'Reminds you once a week to log your weight.'**
  String get reminderWeightChannelDescription;

  /// Creatine reminder notification: title.
  ///
  /// In en, this message translates to:
  /// **'Creatine time'**
  String get reminderCreatineTitle;

  /// Creatine reminder notification: text.
  ///
  /// In en, this message translates to:
  /// **'Take today\'s creatine.'**
  String get reminderCreatineBody;

  /// Android's notification settings: the creatine reminder's name.
  ///
  /// In en, this message translates to:
  /// **'Creatine Reminder'**
  String get reminderCreatineChannel;

  /// Android's notification settings: what the creatine reminder is for.
  ///
  /// In en, this message translates to:
  /// **'Reminds you once a day to take creatine.'**
  String get reminderCreatineChannelDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bg', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bg':
      return AppLocalizationsBg();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
