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

  /// Button that closes a dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Button or menu item that deletes something, such as a meal.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Menu item that opens something, such as a meal, for editing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Save button, e.g. the tick beside the quick-log bar's box.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Button that confirms and closes a sheet, e.g. the portion sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Button that closes an information dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Tooltip of a close (X) button, e.g. on the camera page.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Button that retries something that failed, e.g. starting the camera.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Button that turns down an offer for now, in the YumSum Star feature dialogs.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get commonMaybeLater;

  /// Button that closes a notice once read.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Button with a star icon that opens the YumSum Star page; Star is the paid tier's name.
  ///
  /// In en, this message translates to:
  /// **'Become a Star'**
  String get commonBecomeStar;

  /// An amount of calories, e.g. on a meal row or an option in the which-did-you-have dialog.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String commonKcal(int kcal);

  /// The calorie unit on its own: the hint and suffix of calorie boxes.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get commonKcalUnit;

  /// The gram unit on its own: the suffix of weight boxes.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get commonGramsUnit;

  /// An amount in grams, e.g. a food's weight or a macro ring's figure. grams is already formatted, maybe with a decimal.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String commonGrams(String grams);

  /// Calories and protein of a portion of a packaged food.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {protein} g protein'**
  String commonKcalProtein(int kcal, int protein);

  /// Home: the page title while the user's first name hasn't loaded.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Home: shown instead of the page when the profile doesn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get homeErrorProfile;

  /// Home: shown instead of the page when today's meals don't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your meals.'**
  String get homeErrorMeals;

  /// Home: in the month card when its days don't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this month.'**
  String get homeErrorMonth;

  /// Home: title of the dialog confirming a meal's deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get homeDeleteMealTitle;

  /// Home: text of the dialog confirming a meal's deletion.
  ///
  /// In en, this message translates to:
  /// **'Remove this meal from today?'**
  String get homeDeleteMealBody;

  /// Home: snack bar when deleting a meal failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the meal. Try again.'**
  String get homeErrorDelete;

  /// Home: the pill on today's card, and the umbrella button's tooltip, when today is a day off.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get homeDayOff;

  /// Home: tooltip of the umbrella button at the top right, which takes today off.
  ///
  /// In en, this message translates to:
  /// **'Take the day off'**
  String get homeDayOffTake;

  /// Home: snack bar when taking the day off, or undoing it, failed.
  ///
  /// In en, this message translates to:
  /// **'Could not change your day off. Try again.'**
  String get homeErrorDayOff;

  /// Home: green pill on today's card when the calories so far are on target.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get homeOnTrack;

  /// Home: amber or red pill on today's card when today's calories are over the target.
  ///
  /// In en, this message translates to:
  /// **'Over target'**
  String get homeOverTarget;

  /// Home: after the big number of calories still to eat today ("1250 kcal left"), in smaller type.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get homeKcalLeft;

  /// Home: after the big number of calories eaten over today's target ("200 kcal over"), in smaller type.
  ///
  /// In en, this message translates to:
  /// **'kcal over'**
  String get homeKcalOver;

  /// Home: under the big number, today's calories so far against the target.
  ///
  /// In en, this message translates to:
  /// **'{eaten} of {target} kcal eaten'**
  String homeKcalEaten(int eaten, int target);

  /// Home: tooltip of the info button on today's card, which explains the targets.
  ///
  /// In en, this message translates to:
  /// **'About your targets'**
  String get homeTargetsTooltip;

  /// Home: heading of the card listing today's meals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meals'**
  String get homeMealsTitle;

  /// Home: pill beside Today's meals with how many meals are logged today.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} logged}}'**
  String homeMealsLogged(int count);

  /// Home: in the meals card while nothing is logged today; the quick-log bar with its mic is below.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet. Type or tap the mic below.'**
  String get homeNothingLogged;

  /// Home: the month card's button that opens History.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// Home: in the month card when no day this month has meals.
  ///
  /// In en, this message translates to:
  /// **'No logged days yet this month.'**
  String get homeNoDaysThisMonth;

  /// Home: in the month card, how many days this month have meals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} days logged}}'**
  String homeDaysLogged(int count);

  /// Home: heading of the weight card, which opens Weight & Progress.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get homeWeight;

  /// Home: in the weight card before any weight is logged.
  ///
  /// In en, this message translates to:
  /// **'Log your weight to track progress'**
  String get homeWeightEmpty;

  /// Home: in the weight card, the latest weight, formatted in the user's unit ("82.4 kg", "12 st 4 lb").
  ///
  /// In en, this message translates to:
  /// **'Latest: {weight}'**
  String homeWeightLatest(String weight);

  /// Home: in the weight card, the latest weight when it is over a week old, formatted in the user's unit.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{Latest: {weight} · {days} days ago}}'**
  String homeWeightLatestAgo(String weight, int days);

  /// Home: the weight card's button that opens the weigh-in dialog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeWeightLog;

  /// Home: the YumSum Star card for free accounts, under the YumSum Star logo: what it adds. Smart Snap is a name; AI Coach is AI треньор in Bulgarian.
  ///
  /// In en, this message translates to:
  /// **'Smart Snap, the Adaptive Formula, an AI Assisted Coach and Detailed Macros.'**
  String get homeStarPitch;

  /// Home: tooltip of the YumSum Star card's close button, which hides it for two weeks.
  ///
  /// In en, this message translates to:
  /// **'Hide for now'**
  String get homeStarHide;

  /// Home: title of the dialog offering the daily creatine reminder, once in the first week.
  ///
  /// In en, this message translates to:
  /// **'Take creatine?'**
  String get homeCreatineTitle;

  /// Home: text of the creatine reminder offer. time is e.g. 09:00.
  ///
  /// In en, this message translates to:
  /// **'Get a daily reminder at {time}. You can change the time later.'**
  String homeCreatineBody(String time);

  /// Home: button turning down the creatine reminder.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get homeCreatineNo;

  /// Home: button turning on the creatine reminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get homeCreatineYes;

  /// Home: snack bar once the creatine reminder is on. time is e.g. 09:00; Notifications is the menu page.
  ///
  /// In en, this message translates to:
  /// **'Creatine reminder on for {time}. Change it under Notifications in the menu.'**
  String homeCreatineOn(String time);

  /// Home: snack bar when the creatine reminder was wanted but notifications are blocked.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your phone\'s Settings, then turn it on under Notifications in the menu.'**
  String get homeCreatineBlocked;

  /// Home: snack bar when the creatine reminder was turned down.
  ///
  /// In en, this message translates to:
  /// **'You can turn it on any time under Notifications in the menu.'**
  String get homeCreatineLater;

  /// Day off dialog: title when today is already a day off.
  ///
  /// In en, this message translates to:
  /// **'Back on plan?'**
  String get homeDayOffBackTitle;

  /// Day off dialog: title when taking today off.
  ///
  /// In en, this message translates to:
  /// **'Take today off?'**
  String get homeDayOffTakeTitle;

  /// Day off dialog: text when going back on plan.
  ///
  /// In en, this message translates to:
  /// **'Today will be measured against your target again.'**
  String get homeDayOffBackBody;

  /// Day off dialog: first line, what a day off is for.
  ///
  /// In en, this message translates to:
  /// **'For holidays and nights out.'**
  String get homeDayOffIntro;

  /// Day off dialog: a line beside a plate icon.
  ///
  /// In en, this message translates to:
  /// **'Log your meals as usual.'**
  String get homeDayOffLog;

  /// Day off dialog: a line saying the day gets no on-track colour.
  ///
  /// In en, this message translates to:
  /// **'No green, yellow or red today.'**
  String get homeDayOffNoColours;

  /// Day off dialog: a line saying History's counts leave the day out. History is the page.
  ///
  /// In en, this message translates to:
  /// **'Left out of History scores.'**
  String get homeDayOffHistory;

  /// Day off dialog: a line saying the umbrella button undoes it.
  ///
  /// In en, this message translates to:
  /// **'Tap the umbrella to undo.'**
  String get homeDayOffUndo;

  /// Day off dialog: button ending the day off.
  ///
  /// In en, this message translates to:
  /// **'Back on plan'**
  String get homeDayOffBackButton;

  /// Day off dialog: button taking today off.
  ///
  /// In en, this message translates to:
  /// **'Take day off'**
  String get homeDayOffTakeButton;

  /// Adaptive formula dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Your calories, personalised'**
  String get adaptiveIntroTitle;

  /// Adaptive formula dialog: the line under the title.
  ///
  /// In en, this message translates to:
  /// **'Feel more confident about how much to eat, with a smart formula that adapts to you every week.'**
  String get adaptiveIntroSubtitle;

  /// Adaptive formula dialog: first promise, bold.
  ///
  /// In en, this message translates to:
  /// **'Understand what you burn'**
  String get adaptiveIntroBurnTitle;

  /// Adaptive formula dialog: first promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Your food logs and weight trends help estimate your daily calorie burn, taking the guesswork out of your target.'**
  String get adaptiveIntroBurnBody;

  /// Adaptive formula dialog: second promise, bold.
  ///
  /// In en, this message translates to:
  /// **'Built around your body'**
  String get adaptiveIntroBodyTitle;

  /// Adaptive formula dialog: second promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Get a target shaped by how your body actually responds, helping you find what works for you.'**
  String get adaptiveIntroBodyBody;

  /// Adaptive formula dialog: third promise, bold.
  ///
  /// In en, this message translates to:
  /// **'Stay on track as you change'**
  String get adaptiveIntroChangeTitle;

  /// Adaptive formula dialog: third promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Your calorie needs can change as you lose weight. Your target adjusts to help you keep making progress.'**
  String get adaptiveIntroChangeBody;

  /// Adaptive formula dialog: fourth promise, bold.
  ///
  /// In en, this message translates to:
  /// **'Make every weigh-in count'**
  String get adaptiveIntroWeighTitle;

  /// Adaptive formula dialog: fourth promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Each weigh-in adds to the picture. Consistent logging helps fine-tune your target over time.'**
  String get adaptiveIntroWeighBody;

  /// Adaptive formula dialog: button for YumSum Star members, opening the weigh-in dialog.
  ///
  /// In en, this message translates to:
  /// **'Log my weight'**
  String get adaptiveIntroLogWeight;

  /// Notice once YumSum Star ends while the Adaptive formula had changed the target: title.
  ///
  /// In en, this message translates to:
  /// **'Your YumSum Star has ended'**
  String get adaptiveLapseTitle;

  /// Notice once YumSum Star ends: when the target returns to the plan's. date is e.g. 7 November.
  ///
  /// In en, this message translates to:
  /// **'Your target goes back to your standard plan on {date}.'**
  String adaptiveLapseBody(String date);

  /// Quick-log bar: error when the day's AI estimates are used up.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {limit} AI estimates are used up. Type the calories yourself.'**
  String quickLogLimit(int limit);

  /// Quick-log bar: error when saving a meal failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save meal. Try again.'**
  String get quickLogErrorSave;

  /// Quick-log bar: error when the microphone isn't allowed.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to log by voice.'**
  String get quickLogAllowMic;

  /// Quick-log bar: error when the recording didn't start.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. Try again.'**
  String get quickLogErrorRecord;

  /// Quick-log bar: error after a recording too short to be a meal.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Tap the mic and try again.'**
  String get quickLogMisTap;

  /// Quick-log bar: a scanned product is listed without calories, and contributing wasn't taken up.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts has no calories for this product yet. Take a photo of the packet instead.'**
  String get quickLogNoCalories;

  /// Quick-log bar: a scanned product isn't listed, and contributing wasn't taken up.
  ///
  /// In en, this message translates to:
  /// **'This product isn\'t on Open Food Facts. Take a photo of the packet instead.'**
  String get quickLogNotListed;

  /// Quick-log bar: quiet line above the box once half of the day's AI estimates are used.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No AI estimates left today} =1{1 AI estimate left today} other{{count} AI estimates left today}}'**
  String quickLogAiLeft(int count);

  /// Quick-log bar: hint in the box where a meal is typed.
  ///
  /// In en, this message translates to:
  /// **'Type a meal'**
  String get quickLogHint;

  /// Quick-log bar: tooltip of the button that empties the boxes.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get quickLogClear;

  /// Quick-log bar: hint in the protein box, half the bar's width.
  ///
  /// In en, this message translates to:
  /// **'protein (g)'**
  String get quickLogProteinHint;

  /// Quick-log bar: after the number in the protein box.
  ///
  /// In en, this message translates to:
  /// **'g protein'**
  String get quickLogProteinUnit;

  /// Quick-log bar: chip that searches packaged foods for what's typed.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get quickLogSearchFoods;

  /// Quick-log bar: a chip offering a recent meal or a recipe portion.
  ///
  /// In en, this message translates to:
  /// **'{name} · {kcal} kcal'**
  String quickLogChip(String name, int kcal);

  /// Quick-log bar: tooltip of the button that stops the recording.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get quickLogStop;

  /// Quick-log bar: tooltip of the camera button (Smart Snap).
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get quickLogPhoto;

  /// Quick-log bar: tooltip of the barcode button.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get quickLogBarcode;

  /// Quick-log bar: tooltip of the mic button.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get quickLogSpeak;

  /// Quick-log bar: tooltip of the sparkle button, which has the AI estimate the typed meal.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get quickLogEstimate;

  /// Quick-log bar: status line while recording.
  ///
  /// In en, this message translates to:
  /// **'Listening... tap stop when you\'re done.'**
  String get quickLogListening;

  /// Quick-log bar: status line while the AI or the food database is busy.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get quickLogWorking;

  /// AI error: the AI isn't switched on on the server.
  ///
  /// In en, this message translates to:
  /// **'AI estimates aren\'t switched on yet.'**
  String get mealAiOff;

  /// AI error: the AI is overloaded.
  ///
  /// In en, this message translates to:
  /// **'The AI is busy right now. Try again in a minute.'**
  String get mealAiBusy;

  /// AI error: the AI is paused on the server.
  ///
  /// In en, this message translates to:
  /// **'AI estimates are paused for now. You can still type the calories yourself.'**
  String get mealAiPaused;

  /// AI error: a brief hiccup.
  ///
  /// In en, this message translates to:
  /// **'The AI is busy. Try again in a few seconds.'**
  String get mealAiBusyShort;

  /// AI error: the server doesn't see YumSum Star on the account.
  ///
  /// In en, this message translates to:
  /// **'YumSum Star isn\'t on for this account. Try again.'**
  String get mealAiNoStar;

  /// AI error: estimating a typed meal failed.
  ///
  /// In en, this message translates to:
  /// **'Could not estimate calories. Try again.'**
  String get mealAiErrorEstimate;

  /// AI error: the recording had no meal in it.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t hear a meal in that. Tap the mic and try again.'**
  String get mealAiNoMeal;

  /// AI error: reading the recording failed.
  ///
  /// In en, this message translates to:
  /// **'Could not understand the recording. Try again.'**
  String get mealAiErrorVoice;

  /// AI error: the Smart Snap photo had no food in it.
  ///
  /// In en, this message translates to:
  /// **'No food found in that photo. Try again with the plate in view.'**
  String get mealAiNoFood;

  /// AI error: reading the Smart Snap photo failed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that photo. Try again.'**
  String get mealAiErrorPhoto;

  /// AI error, on the contribute form: the packet photos show no label.
  ///
  /// In en, this message translates to:
  /// **'Those photos don\'t show a label. Fill in the details yourself.'**
  String get mealAiNoLabel;

  /// Meal form: error when the day's AI estimates are used up.
  ///
  /// In en, this message translates to:
  /// **'Daily AI limit reached. Enter the calories yourself.'**
  String get mealAiLimit;

  /// Meal form and quick-log bar: error when the AI couldn't be reached.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the AI. Try again.'**
  String get mealErrorAi;

  /// Meal form: error on saving without calories.
  ///
  /// In en, this message translates to:
  /// **'Enter the calories, or estimate them.'**
  String get mealErrorNoCalories;

  /// Meal form: error when this month's changes to past days are used up.
  ///
  /// In en, this message translates to:
  /// **'No past-day changes left this month.'**
  String get mealErrorEditLimit;

  /// Meal form: error when saving failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the meal. Try again.'**
  String get mealErrorSave;

  /// Meal form: title when editing a meal.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get mealEditTitle;

  /// Meal form: title when adding a meal.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get mealAddTitle;

  /// Meal form: label of the name box.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealName;

  /// Meal form: example in the name box; local dishes in Bulgarian.
  ///
  /// In en, this message translates to:
  /// **'e.g. Musaka, chicken wrap'**
  String get mealNameHint;

  /// Meal form: label of the calories box, half width.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get mealCalories;

  /// Meal form: label of the protein box, half width.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get mealProtein;

  /// Meal form: note under the protein box.
  ///
  /// In en, this message translates to:
  /// **'Leave protein blank to estimate it from the name.'**
  String get mealProteinNote;

  /// Meal form: button that has the AI estimate the calories from the name.
  ///
  /// In en, this message translates to:
  /// **'Estimate from name'**
  String get mealEstimateFromName;

  /// Meal form: save button when editing.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get mealSaveChanges;

  /// Meal form: save button when adding.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get mealSave;

  /// Meal row: a meal logged with calories only.
  ///
  /// In en, this message translates to:
  /// **'Unnamed meal'**
  String get mealUnnamed;

  /// Meal row: small link beside the time that opens the meal's macros.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get mealNutrition;

  /// Meal row: the meal's protein, under its calories.
  ///
  /// In en, this message translates to:
  /// **'{grams} g protein'**
  String mealProteinGrams(int grams);

  /// Meal row: tooltip of the menu with Edit and Delete.
  ///
  /// In en, this message translates to:
  /// **'Meal options'**
  String get mealOptions;

  /// AI breakdown: note under the items, whose weights can be tapped.
  ///
  /// In en, this message translates to:
  /// **'Tap a weight to change it.'**
  String get mealTapWeight;

  /// AI breakdown: label of the box for an item's weight in grams.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get mealWeight;

  /// AI breakdown: button that applies the weight typed.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get mealUseWeight;

  /// AI breakdown: an item's calories and protein grams.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {grams} g'**
  String mealKcalGrams(int kcal, int grams);

  /// Dialog asking which version of an item the user had (size, milk, homemade or takeaway).
  ///
  /// In en, this message translates to:
  /// **'Which did you have?'**
  String get mealChoiceTitle;

  /// Which-did-you-have dialog: the first option, ticked, is the AI's guess.
  ///
  /// In en, this message translates to:
  /// **'We went with the first.'**
  String get mealChoiceNote;

  /// Camera page: the device has no camera.
  ///
  /// In en, this message translates to:
  /// **'No camera found.'**
  String get cameraNotFound;

  /// Camera page: the camera failed to open.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start.'**
  String get cameraCouldNotStart;

  /// Camera page in a browser: camera access was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in your browser to scan barcodes and take photos.'**
  String get cameraAllowWeb;

  /// Camera page in the app: camera access was refused.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to scan barcodes and take photos. If you said no before, turn it on in your phone\'s Settings.'**
  String get cameraAllowApp;

  /// Camera page in a browser: the barcode reader didn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not start the barcode reader. Try again.'**
  String get cameraErrorReader;

  /// Camera page: snack bar when taking the photo failed.
  ///
  /// In en, this message translates to:
  /// **'Could not take the photo. Try again.'**
  String get cameraErrorPhoto;

  /// Camera page in a browser: button picking a photo file instead.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo instead'**
  String get cameraChoosePhoto;

  /// Camera page: what screen readers say for the shutter button.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraTakePhoto;

  /// Camera page: which photo of several this is.
  ///
  /// In en, this message translates to:
  /// **'Step {number} of {total}'**
  String cameraStep(int number, int total);

  /// Camera page, scanning: what to do.
  ///
  /// In en, this message translates to:
  /// **'Point at the barcode'**
  String get cameraBarcodeTitle;

  /// Camera page, scanning: the tip under it; the box is drawn on the camera picture.
  ///
  /// In en, this message translates to:
  /// **'Hold it inside the box and it\'s read by itself.'**
  String get cameraBarcodeTip;

  /// Camera page, Smart Snap: what to photograph.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your meal'**
  String get cameraMealTitle;

  /// Camera page, Smart Snap: how to take it.
  ///
  /// In en, this message translates to:
  /// **'From above, with the whole plate in.'**
  String get cameraMealTip;

  /// Camera page, contributing a product: the first photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the front of the pack'**
  String get cameraFrontTitle;

  /// Camera page, contributing a product: how to take the first photo.
  ///
  /// In en, this message translates to:
  /// **'Get the whole front in, name and all.'**
  String get cameraFrontTip;

  /// Camera page, contributing a product: the nutrition table photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the nutrition table'**
  String get cameraTableTitle;

  /// Camera page, contributing a product: how to take the nutrition table photo.
  ///
  /// In en, this message translates to:
  /// **'Fill the frame with the table, flat and sharp, so every number can be read.'**
  String get cameraTableTip;

  /// Smart Snap's name, the YumSum Star photo logging; a name, kept in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'Smart Snap'**
  String get cameraSmartSnap;

  /// Smart Snap dialog for free accounts: the line under its name.
  ///
  /// In en, this message translates to:
  /// **'Make food logging as easy as taking a photo.'**
  String get cameraSmartSnapSubtitle;

  /// Smart Snap dialog: first promise, bold.
  ///
  /// In en, this message translates to:
  /// **'Skip the manual entry'**
  String get cameraSmartSnapSkipTitle;

  /// Smart Snap dialog: first promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Snap your meal and let AI identify the food, with estimated calories and macros for each item.'**
  String get cameraSmartSnapSkipBody;

  /// Smart Snap dialog: second promise, bold.
  ///
  /// In en, this message translates to:
  /// **'You\'re always in control'**
  String get cameraSmartSnapControlTitle;

  /// Smart Snap dialog: second promise, its line.
  ///
  /// In en, this message translates to:
  /// **'Review your meal, make any changes and save when you\'re happy.'**
  String get cameraSmartSnapControlBody;

  /// Food search sheet: under the words searched for.
  ///
  /// In en, this message translates to:
  /// **'Packaged foods · Open Food Facts'**
  String get foodSearchSource;

  /// Food search sheet: the search failed.
  ///
  /// In en, this message translates to:
  /// **'Could not search right now.'**
  String get foodSearchError;

  /// Food search sheet: no results.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try other words, or let the AI estimate it.'**
  String get foodSearchEmpty;

  /// Food search sheet: a product's calories, after its brand.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per 100 g'**
  String foodPer100g(int kcal);

  /// Portion sheet: the product's figures per 100 g. amounts is e.g. 215 kcal · 9 g protein.
  ///
  /// In en, this message translates to:
  /// **'{amounts} per 100 g · Open Food Facts'**
  String foodPortionSource(String amounts);

  /// Portion sheet: label of the grams box.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get foodPortionAmount;

  /// Barcode lookup or food search: Open Food Facts answered with an error.
  ///
  /// In en, this message translates to:
  /// **'The food database is not answering right now.'**
  String get foodErrorNotAnswering;

  /// Barcode lookup or food search: no connection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the food database. Check your connection.'**
  String get foodErrorOffline;

  /// Contribute invitation: title when the product is listed without its nutrition.
  ///
  /// In en, this message translates to:
  /// **'Add its nutrition'**
  String get contributeAddNutritionTitle;

  /// Contribute invitation: title when the product isn't listed.
  ///
  /// In en, this message translates to:
  /// **'Be the first to add this'**
  String get contributeAddProductTitle;

  /// Contribute invitation: text when the product is listed without its nutrition.
  ///
  /// In en, this message translates to:
  /// **'This product is in the database, but its nutrition isn\'t yet. Add it with one photo of the nutrition table and it\'ll be there for you and everyone who scans it next.'**
  String get contributeAddNutritionBody;

  /// Contribute invitation: text when the product isn't listed.
  ///
  /// In en, this message translates to:
  /// **'This product isn\'t in the database yet. Add it with two photos and it\'ll be there for you and everyone who scans it next.'**
  String get contributeAddProductBody;

  /// Contribute invitation: small line under the text.
  ///
  /// In en, this message translates to:
  /// **'It takes 30 seconds and helps everyone, forever ♥'**
  String get contributeTakesSeconds;

  /// Contribute invitation and form: the button that adds the product to Open Food Facts.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contributeButton;

  /// Contribute invitation: button turning it down.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get contributeNotNow;

  /// Contribute form: note once the AI has filled the form from the packet photos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The AI read these from your photo. Check them against the packet: they will be public.} other{The AI read these from your photos. Check them against the packet: they will be public.}}'**
  String contributeAiRead(int count);

  /// Contribute form: the AI couldn't read the photos, the day's AI use being up.
  ///
  /// In en, this message translates to:
  /// **'Daily AI limit reached. Copy the details from the packet yourself.'**
  String get contributeAiLimit;

  /// Contribute form: reading the packet photos failed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the label. Fill in the details yourself.'**
  String get contributeErrorRead;

  /// Contribute form: the account was signed out.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get contributeNotSignedIn;

  /// Contribute form: error when the name or calories are missing.
  ///
  /// In en, this message translates to:
  /// **'Add the product name and energy (kcal).'**
  String get contributeErrorMissing;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Energy (kcal)'**
  String get contributeEnergy;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get contributeProtein;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get contributeFat;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'of which saturates (g)'**
  String get contributeSaturates;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrate (g)'**
  String get contributeCarbs;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'of which sugars (g)'**
  String get contributeSugars;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Fibre (g)'**
  String get contributeFibre;

  /// Contribute form: label of a half-width box, as on a nutrition label.
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get contributeSalt;

  /// Contribute: heading once the product is sent; one of the two places with an exclamation mark.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get contributeThanks;

  /// Contribute: thank-you text after adding a new product.
  ///
  /// In en, this message translates to:
  /// **'{product} is now on Open Food Facts for everyone who scans it next.'**
  String contributeThanksProduct(String product);

  /// Contribute: thank-you text after adding a listed product's nutrition.
  ///
  /// In en, this message translates to:
  /// **'{product} now has its nutrition on Open Food Facts for everyone who scans it next.'**
  String contributeThanksNutrition(String product);

  /// Contribute: after the thank-you text, from the second product on.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{That\'s {count} products you\'ve added.}}'**
  String contributeThanksCount(int count);

  /// Contribute: button that goes on to log the product just added.
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get contributeLogIt;

  /// Contribute form: title for a new product.
  ///
  /// In en, this message translates to:
  /// **'Check the details'**
  String get contributeCheckDetails;

  /// Contribute form: title for a listed product's nutrition.
  ///
  /// In en, this message translates to:
  /// **'Check the nutrition'**
  String get contributeCheckNutrition;

  /// Contribute form: under the title.
  ///
  /// In en, this message translates to:
  /// **'Barcode {barcode}'**
  String contributeBarcode(String barcode);

  /// Contribute form: while the AI reads the packet photos.
  ///
  /// In en, this message translates to:
  /// **'Reading the label...'**
  String get contributeReading;

  /// Contribute form: label of the name box.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get contributeProductName;

  /// Contribute form: label of the brand box.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get contributeBrand;

  /// Contribute form: label of a half-width box; what is typed goes to Open Food Facts, so keep the example's unit as g.
  ///
  /// In en, this message translates to:
  /// **'Pack size, e.g. 400 g'**
  String get contributePackSize;

  /// Contribute form: label of a half-width box; what is typed goes to Open Food Facts, so keep the example's unit as g.
  ///
  /// In en, this message translates to:
  /// **'Serving, e.g. 30 g'**
  String get contributeServing;

  /// Contribute form: small capitals over the nutrition boxes.
  ///
  /// In en, this message translates to:
  /// **'PER 100 G (OR 100 ML)'**
  String get contributePer100;

  /// Contribute form: what gets published, for a new product.
  ///
  /// In en, this message translates to:
  /// **'Your photos and these details will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.'**
  String get contributePublishNew;

  /// Contribute form: what gets published, for nutrition alone.
  ///
  /// In en, this message translates to:
  /// **'These figures will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.'**
  String get contributePublishFigures;

  /// Contribute form: what gets published, for nutrition with its photo.
  ///
  /// In en, this message translates to:
  /// **'Your photo and these figures will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.'**
  String get contributePublishPhoto;

  /// Contribute form: the day's contributions are used up.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent all you can today. You can send more tomorrow.'**
  String get contributeErrorLimit;

  /// Contribute form: Open Food Facts refused it.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts didn\'t accept it. Try again in a moment.'**
  String get contributeErrorRejected;

  /// Contribute form: sending failed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Open Food Facts. Check your connection and try again.'**
  String get contributeErrorOffline;

  /// Protein: a macro ring's label, a macro guide heading, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// Carbohydrates: a macro guide heading, a cell of the day's totals, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// Fat: a macro ring's label, a macro guide heading, a totals cell, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// Fibre: a macro ring's label, a macro guide heading, a totals cell, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get macroFibre;

  /// Sugars: a macro ring's label, a macro guide heading, a totals cell, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Sugars'**
  String get macroSugars;

  /// Saturated fat: a macro guide heading, a totals cell, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Saturates'**
  String get macroSaturates;

  /// Salt: a macro ring's label, a macro guide heading, a totals cell, and in a meal's macro line.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get macroSalt;

  /// Carbohydrates under a macro ring, 72 px wide: abbreviate if needed.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroRingCarbs;

  /// Saturated fat under a macro ring, 72 px wide: abbreviate if needed.
  ///
  /// In en, this message translates to:
  /// **'Saturates'**
  String get macroRingSaturates;

  /// Under a macro ring with a limit (sugars, saturates, salt): the most for the day.
  ///
  /// In en, this message translates to:
  /// **'max {grams} g'**
  String macroRingMax(int grams);

  /// Under a macro ring with a target: the day's target.
  ///
  /// In en, this message translates to:
  /// **'of {grams} g'**
  String macroRingOf(int grams);

  /// Under the macro rings: meals whose protein isn't known.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 meal not counted (no protein info)} other{{count} meals not counted (no protein info)}}'**
  String macroNotCountedProtein(int count);

  /// Under the macro rings or the day's totals: meals whose macros aren't known.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 meal not counted (no macro info)} other{{count} meals not counted (no macro info)}}'**
  String macroNotCountedMacros(int count);

  /// What screen readers say for the dimmed macro rings of a free account.
  ///
  /// In en, this message translates to:
  /// **'Unlock full macros with YumSum Star'**
  String get macroUnlockLabel;

  /// Chip over the dimmed macro rings of a free account, beside a star; about 140 px wide at most.
  ///
  /// In en, this message translates to:
  /// **'Unlock full macros'**
  String get macroUnlock;

  /// The day's macro totals when no meal has macros.
  ///
  /// In en, this message translates to:
  /// **'No macro info for today\'s meals'**
  String get macroNoneToday;

  /// Tooltip of the info button by the day's macro totals.
  ///
  /// In en, this message translates to:
  /// **'About macros'**
  String get macroAbout;

  /// The day's macro totals: where some meals don't give the figure. grams is e.g. 12 g.
  ///
  /// In en, this message translates to:
  /// **'at least {grams}'**
  String macroAtLeast(String grams);

  /// Macro guide dialog: title when opened from Home's calorie card.
  ///
  /// In en, this message translates to:
  /// **'Your targets'**
  String get macroGuideTargets;

  /// Macro guide dialog: title when opened from the rings or totals.
  ///
  /// In en, this message translates to:
  /// **'Your macros'**
  String get macroGuideMacros;

  /// Macro guide dialog: first line.
  ///
  /// In en, this message translates to:
  /// **'Your targets come from your plan, so they change with it.'**
  String get macroGuideIntro;

  /// Macro guide dialog: the calories heading.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get macroGuideCalories;

  /// Macro guide dialog: what calories are.
  ///
  /// In en, this message translates to:
  /// **'The energy in food. Eat less than you burn and you lose weight.'**
  String get macroGuideCaloriesWhy;

  /// Macro guide dialog: how the calorie target is set, after Target:.
  ///
  /// In en, this message translates to:
  /// **'What you burn in a day, from your age, height, weight and activity, with a little taken off if you\'re losing weight.'**
  String get macroGuideCaloriesTarget;

  /// Macro guide dialog: group heading over protein and fibre, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Aim for'**
  String get macroGuideAimFor;

  /// Macro guide dialog: group heading over carbs and fat, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Keep in balance'**
  String get macroGuideBalance;

  /// Macro guide dialog: group heading over sugars, saturates and salt, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Keep under'**
  String get macroGuideKeepUnder;

  /// Macro guide dialog: under the Keep under heading.
  ///
  /// In en, this message translates to:
  /// **'Keep these under the amounts shown. Going over day after day is what harms your teeth, heart and blood pressure.'**
  String get macroGuideKeepUnderNote;

  /// Macro guide dialog: what protein does.
  ///
  /// In en, this message translates to:
  /// **'Keeps you full and protects your muscle while you lose fat.'**
  String get macroGuideProteinWhy;

  /// Macro guide dialog: protein's target, after Target:.
  ///
  /// In en, this message translates to:
  /// **'1.2 to 2 g per kg of your goal weight, more the more you train.'**
  String get macroGuideProteinTarget;

  /// Macro guide dialog: what fibre does.
  ///
  /// In en, this message translates to:
  /// **'Keeps you full and your gut healthy.'**
  String get macroGuideFibreWhy;

  /// Macro guide dialog: fibre's target, after Target:.
  ///
  /// In en, this message translates to:
  /// **'At least 30 g a day.'**
  String get macroGuideFibreTarget;

  /// Macro guide dialog: what carbs do.
  ///
  /// In en, this message translates to:
  /// **'Your main fuel: bread, rice, pasta, potatoes and fruit.'**
  String get macroGuideCarbsWhy;

  /// Macro guide dialog: carbs' target, after Target:.
  ///
  /// In en, this message translates to:
  /// **'What\'s left after protein and fat.'**
  String get macroGuideCarbsTarget;

  /// Macro guide dialog: what fat does.
  ///
  /// In en, this message translates to:
  /// **'Energy, and it helps you absorb vitamins.'**
  String get macroGuideFatWhy;

  /// Macro guide dialog: fat's target, after Target:.
  ///
  /// In en, this message translates to:
  /// **'About 30% of your calories.'**
  String get macroGuideFatTarget;

  /// Macro guide dialog: why to limit sugars.
  ///
  /// In en, this message translates to:
  /// **'Calories that don\'t fill you up, and bad for your teeth.'**
  String get macroGuideSugarsWhy;

  /// Macro guide dialog: sugars' limit, after Target:.
  ///
  /// In en, this message translates to:
  /// **'Under 18% of your calories.'**
  String get macroGuideSugarsTarget;

  /// Macro guide dialog: why to limit saturated fat.
  ///
  /// In en, this message translates to:
  /// **'Raises your cholesterol: butter, cheese, fatty meat and cakes.'**
  String get macroGuideSaturatesWhy;

  /// Macro guide dialog: saturated fat's limit, after Target:.
  ///
  /// In en, this message translates to:
  /// **'Under 10% of your calories.'**
  String get macroGuideSaturatesTarget;

  /// Macro guide dialog: why to limit salt.
  ///
  /// In en, this message translates to:
  /// **'Raises your blood pressure. Most is hidden in bread, cheese and ready meals.'**
  String get macroGuideSaltWhy;

  /// Macro guide dialog: salt's limit, after Target:.
  ///
  /// In en, this message translates to:
  /// **'Under 6 g a day, about a teaspoon.'**
  String get macroGuideSaltTarget;

  /// Macro guide dialog: bold, before each target; keep the space at the end.
  ///
  /// In en, this message translates to:
  /// **'Target: '**
  String get macroGuideTarget;

  /// Macro guide dialog: small last line.
  ///
  /// In en, this message translates to:
  /// **'General guidance for adults, not medical advice.'**
  String get macroGuideDisclaimer;

  /// Badge on a recipe high in fibre: its tooltip on the photo, and a pill on the recipe page.
  ///
  /// In en, this message translates to:
  /// **'Rich in fibre'**
  String get macroFibreBadge;
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
