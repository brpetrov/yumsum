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

  /// Home: the YumSum Star card for free accounts, under the YumSum Star logo: what it adds. Smart Snap is Запис със снимка and AI Coach is AI треньор in Bulgarian.
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
  /// **'Creatine reminder on for {time}. Change it under Notifications in Settings.'**
  String homeCreatineOn(String time);

  /// Home: snack bar when the creatine reminder was wanted but notifications are blocked.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your phone\'s settings, then turn it on under Notifications in Settings.'**
  String get homeCreatineBlocked;

  /// Home: snack bar when the creatine reminder was turned down.
  ///
  /// In en, this message translates to:
  /// **'You can turn it on any time under Notifications in Settings.'**
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
  /// **'Your calorie needs change as your weight does. Your target adjusts to help you keep making progress.'**
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

  /// Quick-log bar: the calories after a chip's meal or recipe name, which is cut short when long.
  ///
  /// In en, this message translates to:
  /// **'· {kcal} kcal'**
  String quickLogChipKcal(int kcal);

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

  /// Meal row's menu: logs the same meal again for today, now.
  ///
  /// In en, this message translates to:
  /// **'Log again'**
  String get mealLogAgain;

  /// Note after Log again from the meal row's menu.
  ///
  /// In en, this message translates to:
  /// **'Added to today.'**
  String get mealLoggedAgain;

  /// Meal row: tooltip of the menu with Edit and Delete.
  ///
  /// In en, this message translates to:
  /// **'Meal options'**
  String get mealOptions;

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

  /// Estimate breakdown: the chip for the amount the AI went with, when it didn't name it; beside chips such as small and large.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get mealChoiceRegular;

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

  /// The YumSum Star photo logging feature's name: Smart Snap in English, Запис със снимка in Bulgarian.
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

  /// Portion sheet: a chip that sets the grams to this many of the pack's servings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 serving} other{{count} servings}}'**
  String foodPortionServings(int count);

  /// Portion sheet: a chip that sets the grams to the whole pack.
  ///
  /// In en, this message translates to:
  /// **'Whole pack'**
  String get foodPortionWholePack;

  /// Portion sheet: what the pack calls a serving, as printed, e.g. 1 biscuit (12.5 g).
  ///
  /// In en, this message translates to:
  /// **'Serving: {label}'**
  String foodPortionServingIs(String label);

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

  /// Under a macro ring with a target to reach (protein, fibre): at least this, and more is fine.
  ///
  /// In en, this message translates to:
  /// **'{grams}+ g'**
  String macroRingAtLeast(int grams);

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
  /// **'The energy in food. Eat less than you burn to lose weight, more to gain it.'**
  String get macroGuideCaloriesWhy;

  /// Macro guide dialog: how the calorie target is set, after Target:.
  ///
  /// In en, this message translates to:
  /// **'What you burn in a day, from your age, height, weight and activity, with a little taken off to lose weight or added to gain it.'**
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
  /// **'Keeps you full and looks after your muscle.'**
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
  /// **'At least 25 g a day. More is better.'**
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

  /// Macro guide dialog: bold, before the ring's colours as coloured dots; keep the space at the end.
  ///
  /// In en, this message translates to:
  /// **'Colours: '**
  String get macroGuideColours;

  /// Macro guide dialog: beside a coloured dot, the ring is this colour under so many grams.
  ///
  /// In en, this message translates to:
  /// **'under {grams} g'**
  String macroGuideUnder(int grams);

  /// Macro guide dialog: beside a coloured dot, the ring is this colour from one amount to the next.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} g'**
  String macroGuideRange(int from, int to);

  /// Macro guide dialog: beside a coloured dot, the ring is this colour up to so many percent over the target.
  ///
  /// In en, this message translates to:
  /// **'up to {percent}% over'**
  String macroGuideOverUpTo(int percent);

  /// Macro guide dialog: beside a coloured dot, the ring is this colour between these percentages over the target.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}% over'**
  String macroGuideOverRange(int from, int to);

  /// Macro guide dialog: beside a coloured dot, the ring is this colour past so many percent over the target.
  ///
  /// In en, this message translates to:
  /// **'more than {percent}% over'**
  String macroGuideOverMore(int percent);

  /// Macro guide dialog: beside a green dot, the ring is green while under the limit.
  ///
  /// In en, this message translates to:
  /// **'within the limit'**
  String get macroGuideWithinLimit;

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

  /// History: the page title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// History: shown when the page doesn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your history.'**
  String get historyErrorLoad;

  /// History: the week option of the Week / Month switch.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get historyWeek;

  /// History: the month option of the Week / Month switch.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get historyMonth;

  /// History: tooltip on the arrow to the previous week or month.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get historyPrevious;

  /// History: tooltip on the arrow to the next week or month.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get historyNext;

  /// History: the button back to the current week or month.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// A day's status, on the calendar's key and a day's pill: calories within 10% of the target.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get historyStatusOnTrack;

  /// A day's status, on the calendar's key and a day's pill: calories within 20% of the target.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get historyStatusClose;

  /// A day's status, on the calendar's key and a day's pill: calories more than 20% from the target.
  ///
  /// In en, this message translates to:
  /// **'Off track'**
  String get historyStatusOffTrack;

  /// History: the calendar key's grey dot, a day with nothing logged.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get historyNotLogged;

  /// History: under the calendar on the first day of a week or month, before any day of it is finished.
  ///
  /// In en, this message translates to:
  /// **'Your review starts tomorrow, once today is over.'**
  String get historyReviewTomorrow;

  /// History: the review card when no day of the week or month has a log.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged in this period yet.'**
  String get historyNothingLogged;

  /// History: pill with the number of days on track.
  ///
  /// In en, this message translates to:
  /// **'{count} on track'**
  String historyOnTrackCount(int count);

  /// History: pill with the number of days close to the target.
  ///
  /// In en, this message translates to:
  /// **'{count} close'**
  String historyCloseCount(int count);

  /// History: pill with the number of days off track.
  ///
  /// In en, this message translates to:
  /// **'{count} off track'**
  String historyOffTrackCount(int count);

  /// History: pill with the number of days off.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day off} other{{count} days off}}'**
  String historyDaysOffCount(int count);

  /// History: under the big percentage, the share of logged days on track.
  ///
  /// In en, this message translates to:
  /// **'of logged days on track'**
  String get historyOnTrackShare;

  /// History: how many days of the week or month have a log.
  ///
  /// In en, this message translates to:
  /// **'{logged} of {days} days logged'**
  String historyDaysLogged(int logged, int days);

  /// History: the average calories of the logged days.
  ///
  /// In en, this message translates to:
  /// **'Average {kcal} kcal a day'**
  String historyAverageKcal(int kcal);

  /// History: review note when nothing was logged.
  ///
  /// In en, this message translates to:
  /// **'No meals logged in this period.'**
  String get historyGuidanceNoMeals;

  /// History: review note when 70% or more of the logged days were on track.
  ///
  /// In en, this message translates to:
  /// **'Most logged days stayed close to target.'**
  String get historyGuidanceMostClose;

  /// History: review note when 40-70% of the logged days were on track.
  ///
  /// In en, this message translates to:
  /// **'Some logged days stayed close to target; a few were well off.'**
  String get historyGuidanceSomeClose;

  /// History: review note when under 40% of the logged days were on track.
  ///
  /// In en, this message translates to:
  /// **'Most logged days were well above or below target.'**
  String get historyGuidanceMostOff;

  /// History: month review note when the judged days averaged over 100 kcal above target, for someone keeping or gaining weight.
  ///
  /// In en, this message translates to:
  /// **'You averaged {kcal} kcal a day over your target.'**
  String historyGuidanceOver(int kcal);

  /// History: month review note when the judged days averaged over 100 kcal above target, for someone losing weight.
  ///
  /// In en, this message translates to:
  /// **'You averaged {kcal} kcal a day over your target, so your goal date moves a little later.'**
  String historyGuidanceOverGoalDate(int kcal);

  /// History: month review note when the judged days averaged over 100 kcal below target, for someone gaining weight.
  ///
  /// In en, this message translates to:
  /// **'You averaged {kcal} kcal a day under your target, so your goal date moves a little later.'**
  String historyGuidanceUnderGoalDate(int kcal);

  /// History: review note when too few days were logged.
  ///
  /// In en, this message translates to:
  /// **'Some days weren\'t logged. Log more days for a clearer review.'**
  String get historyGuidanceLogMore;

  /// History: tooltip on a day's calorie bar with nothing logged. The date is like 7 Nov.
  ///
  /// In en, this message translates to:
  /// **'{date}: no calories logged'**
  String historyBarNoCalories(String date);

  /// History: tooltip on a day's calorie bar.
  ///
  /// In en, this message translates to:
  /// **'{date}: {kcal} kcal'**
  String historyBarKcal(String date, int kcal);

  /// History: tooltip on a day's calorie bar, with protein.
  ///
  /// In en, this message translates to:
  /// **'{date}: {kcal} kcal · {protein} g protein'**
  String historyBarKcalProtein(String date, int kcal, int protein);

  /// A day's meals (opened from History): under the date when the day has no log.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get historyDayNothingLogged;

  /// A day's meals: the day's calories against its target.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target} kcal'**
  String historyDayKcal(int total, int target);

  /// A day's meals: the day's calories against its target, and protein.
  ///
  /// In en, this message translates to:
  /// **'{total} of {target} kcal · {protein} g protein'**
  String historyDayKcalProtein(int total, int target, int protein);

  /// A day's meals: the pill on a day taken off.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get historyDayOff;

  /// A day's meals: in place of the macro totals when no meal has them.
  ///
  /// In en, this message translates to:
  /// **'No macro info for this day\'s meals'**
  String get historyDayNoMacros;

  /// A day's meals, on a past day: how many changes to past days are left this month.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, other{{left} of {limit} past-day changes left this month}}'**
  String historyChangesLeft(int left, int limit);

  /// A day's meals: error when the month's changes to past days are used up.
  ///
  /// In en, this message translates to:
  /// **'No past-day changes left this month.'**
  String get historyNoChangesLeft;

  /// A day's meals: the empty list.
  ///
  /// In en, this message translates to:
  /// **'No meals logged on this day.'**
  String get historyDayNoMeals;

  /// A day's meals: the button that adds a meal to that day.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get historyAddMeal;

  /// A day's meals: the delete confirmation's title.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get historyDeleteMealTitle;

  /// A day's meals: the delete confirmation's text, with the meal's name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this day?'**
  String historyDeleteMealNamed(String name);

  /// A day's meals: the delete confirmation's text, for a meal without a name.
  ///
  /// In en, this message translates to:
  /// **'Remove this meal from this day?'**
  String get historyDeleteMealUnnamed;

  /// A day's meals: cancels the delete.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get historyCancel;

  /// A day's meals: confirms the delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// A day's meals: the delete failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the meal. Try again.'**
  String get historyErrorDeleteMeal;

  /// AI Coach: the page title, and the card's name in History.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get coachTitle;

  /// AI Coach: the heading for people without YumSum Star, and the title of the How it works dialog.
  ///
  /// In en, this message translates to:
  /// **'Your AI Coach'**
  String get coachIntroTitle;

  /// AI Coach: what it is in one line, under the heading.
  ///
  /// In en, this message translates to:
  /// **'Get fresh advice tailored just for you, every Monday, to help you eat better and reach your goals.'**
  String get coachSubtitle;

  /// AI Coach: the first promise's title.
  ///
  /// In en, this message translates to:
  /// **'Spot what\'s holding you back'**
  String get coachPromiseHoldingBackTitle;

  /// AI Coach: the first promise's text.
  ///
  /// In en, this message translates to:
  /// **'Discover the eating patterns that could be slowing your progress and find small changes that help.'**
  String get coachPromiseHoldingBackBody;

  /// AI Coach: the second promise's title.
  ///
  /// In en, this message translates to:
  /// **'Build a more balanced diet'**
  String get coachPromiseBalanceTitle;

  /// AI Coach: the second promise's text.
  ///
  /// In en, this message translates to:
  /// **'See how your protein, fibre, salt and sugar compare with recommended amounts, so you know where to focus.'**
  String get coachPromiseBalanceBody;

  /// AI Coach: the third promise's title.
  ///
  /// In en, this message translates to:
  /// **'Get advice you can put into practice'**
  String get coachPromiseAdviceTitle;

  /// AI Coach: the third promise's text.
  ///
  /// In en, this message translates to:
  /// **'Make your next meal easier with practical tips and recipe ideas based on what you already eat.'**
  String get coachPromiseAdviceBody;

  /// AI Coach: the fourth promise's title.
  ///
  /// In en, this message translates to:
  /// **'Start every week with direction'**
  String get coachPromiseWeeklyTitle;

  /// AI Coach: the fourth promise's text.
  ///
  /// In en, this message translates to:
  /// **'Every Monday, get a fresh review of what\'s working and what to change, so you can build on your progress.'**
  String get coachPromiseWeeklyBody;

  /// AI Coach: closes the How it works dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get coachClose;

  /// AI Coach: tooltip on the info button.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get coachHowItWorks;

  /// AI Coach: the heading over the dates of the latest finished week.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get coachLastWeek;

  /// AI Coach: tooltip on the arrow to the week before.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get coachPrevious;

  /// AI Coach: tooltip on the arrow to the week after.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get coachNext;

  /// AI Coach: for a new member before a full week is in.
  ///
  /// In en, this message translates to:
  /// **'Your first notes come on Monday'**
  String get coachFirstNotesTitle;

  /// AI Coach: days left until the first notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day to go} other{{count} days to go}}'**
  String coachDaysToGo(int count);

  /// AI Coach: for a new member, what happens until the first notes. The date is like 16 November.
  ///
  /// In en, this message translates to:
  /// **'AI Coach reads a whole week at a time, so it\'s going over this one as you log it. On Monday {date} it\'ll tell you what went well, what held you back and what to try next week.'**
  String coachFirstNotesBody(String date);

  /// AI Coach: once YumSum Star has ended.
  ///
  /// In en, this message translates to:
  /// **'YumSum Star has ended, so no new notes are written. The ones you have stay.'**
  String get coachEnded;

  /// AI Coach: a week with too few logged days for notes.
  ///
  /// In en, this message translates to:
  /// **'Not enough logged this week for notes. They need 4 days logged, not counting days off.'**
  String get coachNotEnough;

  /// AI Coach: while the notes are written.
  ///
  /// In en, this message translates to:
  /// **'Looking over your week'**
  String get coachLooking;

  /// AI Coach: the notes failed to come.
  ///
  /// In en, this message translates to:
  /// **'Could not get this week\'s notes. Try again.'**
  String get coachErrorLoad;

  /// AI Coach: the button after the notes failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get coachTryAgain;

  /// AI Coach: a past week the coach never wrote notes on, for a member.
  ///
  /// In en, this message translates to:
  /// **'No notes on this week. AI Coach writes them during the week after, when you open this page.'**
  String get coachNoNotesPlus;

  /// AI Coach: a past week without notes, once YumSum Star has ended.
  ///
  /// In en, this message translates to:
  /// **'No notes on this week.'**
  String get coachNoNotes;

  /// AI Coach: the small heading over the tips of a note on something that went well.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get coachKeepGoing;

  /// AI Coach: the small heading over the tips of a note on something to improve.
  ///
  /// In en, this message translates to:
  /// **'Try this'**
  String get coachTryThis;

  /// History: the AI Coach card on a week that isn't over.
  ///
  /// In en, this message translates to:
  /// **'Your notes on this week come on Monday.'**
  String get coachNotesComing;

  /// History, month view: the AI Coach card, under the week's date.
  ///
  /// In en, this message translates to:
  /// **'Read your notes on that week.'**
  String get coachNotesReadThat;

  /// History, week view: the AI Coach card.
  ///
  /// In en, this message translates to:
  /// **'Read your notes on this week.'**
  String get coachNotesReadThis;

  /// History, month view: which week the AI Coach card is on. The date is like 2 November.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String coachWeekOf(String date);

  /// History, without YumSum Star: the line under the AI Coach button.
  ///
  /// In en, this message translates to:
  /// **'See what\'s working, what\'s holding you back, and get personal tips on how to improve.'**
  String get coachPromptLine;

  /// Recipes: the page title.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesTitle;

  /// Recipes: the library didn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recipes.'**
  String get recipesErrorLoad;

  /// Recipes: the search box's hint.
  ///
  /// In en, this message translates to:
  /// **'Search recipes or ingredients'**
  String get recipesSearchHint;

  /// Recipes: tooltip on the button that empties the search box.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get recipesClear;

  /// Recipes: the label over recently logged recipes.
  ///
  /// In en, this message translates to:
  /// **'Cooked recently'**
  String get recipesCookedRecently;

  /// Recipes: the filter chip for every meal.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get recipesAll;

  /// Recipes: a meal, as a filter chip and a heading.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get recipesBreakfast;

  /// Recipes: a meal, as a filter chip and a heading.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get recipesLunch;

  /// Recipes: a meal, as a filter chip and a heading.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get recipesDinner;

  /// Recipes: a meal, as a filter chip and a heading.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get recipesSnack;

  /// Recipes: no recipe for the chosen meal.
  ///
  /// In en, this message translates to:
  /// **'No recipes here yet.'**
  String get recipesEmpty;

  /// Recipes: the search found nothing.
  ///
  /// In en, this message translates to:
  /// **'No recipes match that. Try other words.'**
  String get recipesNoMatch;

  /// Recipes: the button that logs a portion, and the tooltip on a tile's +.
  ///
  /// In en, this message translates to:
  /// **'Log a portion'**
  String get recipesLogPortion;

  /// Recipes: calories on a tile and in the portions sheet.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String recipesKcal(int kcal);

  /// Recipes: protein on a tile and in the portions sheet.
  ///
  /// In en, this message translates to:
  /// **'{grams} g protein'**
  String recipesProtein(int grams);

  /// Recipes: a time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String recipesMinutes(int minutes);

  /// A recipe: the page title.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipesRecipeTitle;

  /// A recipe: it didn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recipe.'**
  String get recipesErrorLoadOne;

  /// A recipe: its calories.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per portion'**
  String recipesPerPortion(int kcal);

  /// A recipe: its calories and protein.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {protein} g protein per portion'**
  String recipesPerPortionProtein(int kcal, int protein);

  /// A recipe: label under the prep time.
  ///
  /// In en, this message translates to:
  /// **'Prep'**
  String get recipesPrep;

  /// A recipe: label under the cooking time.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get recipesCook;

  /// A recipe: label under the number of portions it makes.
  ///
  /// In en, this message translates to:
  /// **'Serves'**
  String get recipesServes;

  /// A recipe: the cooking time of a dish that isn't cooked.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get recipesNoCooking;

  /// A recipe: the ingredients' heading.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipesIngredients;

  /// A recipe: under Ingredients, how many portions they make.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{For 1 portion} other{For {count} portions}}'**
  String recipesForPortions(int count);

  /// A recipe: the steps' heading.
  ///
  /// In en, this message translates to:
  /// **'How to make it'**
  String get recipesHowToMake;

  /// Portions sheet: the question under the recipe's name.
  ///
  /// In en, this message translates to:
  /// **'How many portions?'**
  String get recipesHowMany;

  /// Portions sheet: tooltip on the minus button.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get recipesLess;

  /// Portions sheet: tooltip on the plus button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get recipesMore;

  /// Portions sheet: the button that logs the portions.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get recipesLog;

  /// Recipes: logging a portion failed.
  ///
  /// In en, this message translates to:
  /// **'Could not log the meal. Try again.'**
  String get recipesErrorLog;

  /// Recipes: a portion was logged. The meal is the recipe's name, with the portions when not 1.
  ///
  /// In en, this message translates to:
  /// **'{meal} logged.'**
  String recipesLogged(String meal);

  /// Notifications: the system refused permission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for YumSum in system settings.'**
  String get notificationsDenied;

  /// Notifications: the evening meal reminder's switch.
  ///
  /// In en, this message translates to:
  /// **'Daily meal reminder'**
  String get notificationsMeal;

  /// Notifications: when the meal reminder comes. The time is like 20:30.
  ///
  /// In en, this message translates to:
  /// **'Every evening at {time}'**
  String notificationsMealTime(String time);

  /// Notifications: the weigh-in reminder's switch.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in reminder'**
  String get notificationsWeight;

  /// Notifications: a reminder that comes daily. The time is like 08:00.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String notificationsEveryDayAt(String time);

  /// Notifications: when the weekly weigh-in reminder comes. day is the weekday in English (monday to sunday); the time is like 08:00.
  ///
  /// In en, this message translates to:
  /// **'{day, select, monday{Mondays at {time}} tuesday{Tuesdays at {time}} wednesday{Wednesdays at {time}} thursday{Thursdays at {time}} friday{Fridays at {time}} saturday{Saturdays at {time}} other{Sundays at {time}}}'**
  String notificationsWeeklyAt(String day, String time);

  /// Notifications: the weigh-in day picker's daily option, over the weekdays.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get notificationsEveryDay;

  /// Notifications: the creatine reminder's switch.
  ///
  /// In en, this message translates to:
  /// **'Daily creatine reminder'**
  String get notificationsCreatine;

  /// YumSum Star's button and chip for people without it (the star icon beside it).
  ///
  /// In en, this message translates to:
  /// **'Become a Star'**
  String get starBecome;

  /// YumSum Star page: the line under the name, for people without it.
  ///
  /// In en, this message translates to:
  /// **'Shine bright with these smart perks.'**
  String get starHeaderPitch;

  /// YumSum Star page: the line under the name, for members.
  ///
  /// In en, this message translates to:
  /// **'Everything here is yours.'**
  String get starHeaderMember;

  /// YumSum Star page: the photo logging feature's name, Запис със снимка in Bulgarian.
  ///
  /// In en, this message translates to:
  /// **'Smart Snap'**
  String get starFeatureSnapTitle;

  /// YumSum Star page: what Smart Snap does.
  ///
  /// In en, this message translates to:
  /// **'Capture your meal. The AI does the rest.'**
  String get starFeatureSnapBody;

  /// YumSum Star page: a feature's name.
  ///
  /// In en, this message translates to:
  /// **'Triple the AI estimates'**
  String get starFeatureEstimatesTitle;

  /// YumSum Star page: the AI estimates feature.
  ///
  /// In en, this message translates to:
  /// **'30 a day, so you never run out.'**
  String get starFeatureEstimatesBody;

  /// YumSum Star page: a feature's name.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Formula'**
  String get starFeatureAdaptiveTitle;

  /// YumSum Star page: the Adaptive formula feature.
  ///
  /// In en, this message translates to:
  /// **'Learns your real burn and tunes your target.'**
  String get starFeatureAdaptiveBody;

  /// YumSum Star page: a feature's name.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get starFeatureCoachTitle;

  /// YumSum Star page: the AI Coach feature.
  ///
  /// In en, this message translates to:
  /// **'Reads your week and tells you how to do better.'**
  String get starFeatureCoachBody;

  /// YumSum Star page: a feature's name.
  ///
  /// In en, this message translates to:
  /// **'Detailed Macros'**
  String get starFeatureMacrosTitle;

  /// YumSum Star page: the macros feature.
  ///
  /// In en, this message translates to:
  /// **'The full label: fat, carbs, sugars, fibre, salt.'**
  String get starFeatureMacrosBody;

  /// YumSum Star page: the yearly plan's tile.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get starYearly;

  /// YumSum Star page: the monthly plan's tile.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get starMonthly;

  /// YumSum Star page: under the yearly price.
  ///
  /// In en, this message translates to:
  /// **'a year'**
  String get starPerYear;

  /// YumSum Star page: under the monthly price.
  ///
  /// In en, this message translates to:
  /// **'a month'**
  String get starPerMonth;

  /// YumSum Star page: the yearly price worked out a month. The price has its currency, like £3.33.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String starMonthlyEquivalent(String price);

  /// YumSum Star page: the badge on the yearly plan.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String starSave(int percent);

  /// YumSum Star page: the button while a purchase is checked.
  ///
  /// In en, this message translates to:
  /// **'Checking with Google Play'**
  String get starChecking;

  /// YumSum Star page: the button when there's no free trial.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get starSubscribe;

  /// YumSum Star page: the button with a free trial.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Start 1 day free} other{Start {days} days free}}'**
  String starStartTrial(int days);

  /// YumSum Star page: the yearly plan's terms, under the button.
  ///
  /// In en, this message translates to:
  /// **'{price} a year. Renews every year until you cancel. Cancel any time in Google Play.'**
  String starTermsYearly(String price);

  /// YumSum Star page: the monthly plan's terms, under the button.
  ///
  /// In en, this message translates to:
  /// **'{price} a month. Renews every month until you cancel. Cancel any time in Google Play.'**
  String starTermsMonthly(String price);

  /// YumSum Star page: the yearly plan's terms with a free trial.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day free, then {price} a year. Renews every year until you cancel. Cancel any time in Google Play.} other{{days} days free, then {price} a year. Renews every year until you cancel. Cancel any time in Google Play.}}'**
  String starTrialTermsYearly(int days, String price);

  /// YumSum Star page: the monthly plan's terms with a free trial.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day free, then {price} a month. Renews every month until you cancel. Cancel any time in Google Play.} other{{days} days free, then {price} a month. Renews every month until you cancel. Cancel any time in Google Play.}}'**
  String starTrialTermsMonthly(int days, String price);

  /// YumSum Star page: closes a purchase message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get starOk;

  /// Snackbar once YumSum Star is bought or restored.
  ///
  /// In en, this message translates to:
  /// **'YumSum Star is on.'**
  String get starOn;

  /// Snackbar once a free trial starts. The date is like 14 November.
  ///
  /// In en, this message translates to:
  /// **'YumSum Star is on. Your free week ends on {date}.'**
  String starOnTrial(String date);

  /// YumSum Star page, for members: the card's title.
  ///
  /// In en, this message translates to:
  /// **'You\'re already a bright YumSum Star'**
  String get starAlreadyTitle;

  /// YumSum Star page, for members: under the title.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping YumSum grow.'**
  String get starThanks;

  /// YumSum Star page on the web, where it can't be bought.
  ///
  /// In en, this message translates to:
  /// **'Subscribe in the YumSum app for Android. YumSum Star then works here too, when you sign in with the same account.'**
  String get starWeb;

  /// YumSum Star page on iPhone, where it can't be bought yet.
  ///
  /// In en, this message translates to:
  /// **'YumSum Star can\'t be bought on iPhone yet.'**
  String get starNoIphone;

  /// YumSum Star page: after the plans failed to load.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get starTryAgain;

  /// YumSum Star page: the link that restores a subscription.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get starRestore;

  /// YumSum Star page: the link to the terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get starTerms;

  /// YumSum Star page: the link to the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get starPrivacy;

  /// YumSum Star page: tooltip on the close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get starClose;

  /// Account Settings: the YumSum Star row for someone without it.
  ///
  /// In en, this message translates to:
  /// **'Smart Snap, 30 AI estimates a day and more'**
  String get starStatusPitch;

  /// Account Settings: YumSum Star on hold for a failed payment.
  ///
  /// In en, this message translates to:
  /// **'Off until the payment problem is fixed in Google Play'**
  String get starStatusHold;

  /// Account Settings: the owner's YumSum Star.
  ///
  /// In en, this message translates to:
  /// **'Admin: everything on, no daily limits'**
  String get starStatusAdmin;

  /// Account Settings: YumSum Star is on, with no end date.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get starStatusOn;

  /// Account Settings: YumSum Star given until a date. The date is like 3 December.
  ///
  /// In en, this message translates to:
  /// **'On until {date}'**
  String starStatusOnUntil(String date);

  /// Account Settings: YumSum Star's free trial. The date is like 9 November.
  ///
  /// In en, this message translates to:
  /// **'Free trial until {date}'**
  String starStatusTrial(String date);

  /// Account Settings: a cancelled YumSum Star that runs to a date.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String starStatusEnds(String date);

  /// Account Settings: YumSum Star's next renewal.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String starStatusRenews(String date);

  /// Account Settings: a renewal payment failed.
  ///
  /// In en, this message translates to:
  /// **'Payment problem. Fix it in Google Play to keep YumSum Star.'**
  String get starStatusGrace;

  /// YumSum Star page: Google Play couldn't be reached.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Google Play. Check your connection and try again.'**
  String get starErrorPlay;

  /// YumSum Star page: the server couldn't check a purchase.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm your purchase. Try Restore purchase in a few minutes. If it still fails, Google Play refunds you automatically within 3 days.'**
  String get starErrorNotConfirmed;

  /// YumSum Star page: the subscription belongs to another YumSum account.
  ///
  /// In en, this message translates to:
  /// **'This Google Play subscription is linked to another YumSum account. Sign in with that account to use it.'**
  String get starErrorOtherAccount;

  /// YumSum Star page: Restore purchase found nothing.
  ///
  /// In en, this message translates to:
  /// **'No YumSum Star subscription found on this Google account.'**
  String get starNothingToRestore;

  /// YumSum Star page: the payment is pending.
  ///
  /// In en, this message translates to:
  /// **'Google Play is waiting for your payment. YumSum Star switches on once it goes through.'**
  String get starPaymentPending;

  /// Shared: the email field's label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// Shared: the password field's label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// Shared: the Log out button while signing out.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get commonSigningOut;

  /// Shared: the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get commonEnterPassword;

  /// Shared: an email field's text isn't an email address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get commonEnterValidEmail;

  /// Shared: the server says the email address isn't valid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get commonEnterValidEmailAddress;

  /// Shared: sign-in or a password check tried too often.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get commonErrorTooManyAttempts;

  /// Sign-in page: the tab for signing in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTab;

  /// Sign-in page: the tab for making an account.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpTab;

  /// Sign-in page: the main button on the Sign in tab.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// Sign-in page: the main button on the Sign up tab.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// Sign-in page: the email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get authEnterEmail;

  /// Sign-in page: the new password is too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// Sign-in page: the link that emails a new-password link.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Sign-in page: between the email form and Google.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// Sign-in page: the Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Sign-in page: banner title after signing up.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get authVerificationSentTitle;

  /// Sign-in page: banner text after signing up.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Open it to verify your account, then sign in.'**
  String authVerificationSentBody(String email);

  /// Forgot password dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// Forgot password dialog: above the email box.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you sign in with. We\'ll send a link to choose a new password.'**
  String get authResetIntro;

  /// Forgot password dialog: button that sends the reset link.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authResetSend;

  /// Forgot password dialog: the email could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Could not send the email. Try again.'**
  String get authResetError;

  /// Forgot password dialog: title once the link is asked for.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authResetSentTitle;

  /// Forgot password dialog: the same whether or not an account uses the email, so it never tells who has one.
  ///
  /// In en, this message translates to:
  /// **'If an account uses {email}, we\'ve sent it a link to choose a new password. It can take a few minutes, so check your spam too.'**
  String authResetSentBody(String email);

  /// Sign-in page: signing in before confirming the email.
  ///
  /// In en, this message translates to:
  /// **'Verify your email first. Check your inbox for the link.'**
  String get authErrorVerifyEmail;

  /// Sign-in page: Google sign-in failed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn\'t work. Try again.'**
  String get authErrorGoogle;

  /// Sign-in page: Google sign-in for an email that has a password account.
  ///
  /// In en, this message translates to:
  /// **'This email already has a password. Sign in with it instead.'**
  String get authErrorUsePassword;

  /// Sign-in page: wrong email or password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorWrongCredentials;

  /// Sign-in page: signing up with an email that has an account.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get authErrorEmailInUse;

  /// Sign-in page: no connection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Try again.'**
  String get authErrorNoInternet;

  /// Sign-in page: any other failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authErrorGeneric;

  /// Sign-in page footer; {terms} and {privacy} are the links legalTermsOfUse and legalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the {terms} and {privacy}.'**
  String legalAgreement(String terms, String privacy);

  /// Sign-in page footer: the link to YumSum's terms, inside legalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get legalTermsOfUse;

  /// Sign-in page footer: the link to YumSum's privacy policy, inside legalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicy;

  /// Sign-in page footer on the web; {privacy} and {terms} are the links legalGooglePrivacy and legalGoogleTerms.
  ///
  /// In en, this message translates to:
  /// **'Protected by reCAPTCHA Enterprise. Google\'s {privacy} and {terms} apply.'**
  String legalRecaptcha(String privacy, String terms);

  /// Sign-in page footer on the web: the link to Google's privacy policy, inside legalRecaptcha.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalGooglePrivacy;

  /// Sign-in page footer on the web: the link to Google's terms, inside legalRecaptcha.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalGoogleTerms;

  /// Onboarding and Plan Settings: the health disclaimer under the calorie target.
  ///
  /// In en, this message translates to:
  /// **'YumSum gives general estimates, not medical advice. Talk to a doctor or dietitian before changing your diet, especially if you have a health condition.'**
  String get legalMedicalNote;

  /// Daily movement card: title.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting'**
  String get planActivitySedentary;

  /// Daily movement card: text under Mostly sitting.
  ///
  /// In en, this message translates to:
  /// **'Desk day, low steps, little standing.'**
  String get planActivitySedentaryHint;

  /// Daily movement card: title.
  ///
  /// In en, this message translates to:
  /// **'Light daily movement'**
  String get planActivityLight;

  /// Daily movement card: text under Light daily movement.
  ///
  /// In en, this message translates to:
  /// **'Some walking, errands, or light chores.'**
  String get planActivityLightHint;

  /// Daily movement card: title.
  ///
  /// In en, this message translates to:
  /// **'On feet often'**
  String get planActivityModerate;

  /// Daily movement card: text under On feet often.
  ///
  /// In en, this message translates to:
  /// **'Standing or walking for much of the day.'**
  String get planActivityModerateHint;

  /// Daily movement card: title.
  ///
  /// In en, this message translates to:
  /// **'Physical job or high movement'**
  String get planActivityHigh;

  /// Daily movement card: text under Physical job or high movement.
  ///
  /// In en, this message translates to:
  /// **'Manual work, high steps, or very active days.'**
  String get planActivityHighHint;

  /// Training card: title.
  ///
  /// In en, this message translates to:
  /// **'No regular training'**
  String get planTrainingNone;

  /// Training card: text under No regular training.
  ///
  /// In en, this message translates to:
  /// **'No planned workouts most weeks.'**
  String get planTrainingNoneHint;

  /// Training card: title.
  ///
  /// In en, this message translates to:
  /// **'1 to 2 sessions/week'**
  String get planTrainingOneToTwo;

  /// Training card: text under 1 to 2 sessions.
  ///
  /// In en, this message translates to:
  /// **'A couple of lifting, cardio, or sport days.'**
  String get planTrainingOneToTwoHint;

  /// Training card: title.
  ///
  /// In en, this message translates to:
  /// **'3 to 4 sessions/week'**
  String get planTrainingThreeToFour;

  /// Training card: text under 3 to 4 sessions.
  ///
  /// In en, this message translates to:
  /// **'Regular training most weeks.'**
  String get planTrainingThreeToFourHint;

  /// Training card: title.
  ///
  /// In en, this message translates to:
  /// **'5+ sessions/week'**
  String get planTrainingFivePlus;

  /// Training card: text under 5+ sessions.
  ///
  /// In en, this message translates to:
  /// **'Frequent structured workouts.'**
  String get planTrainingFivePlusHint;

  /// Pace card: title; {amount} is 0.25 kg in the user's unit, e.g. "0.25 kg" or "0.55 lb".
  ///
  /// In en, this message translates to:
  /// **'Slow - {amount}/week'**
  String planPaceSlow(String amount);

  /// Pace card: text under Slow.
  ///
  /// In en, this message translates to:
  /// **'Gentle and easier to maintain over a longer period.'**
  String get planPaceSlowHint;

  /// Pace card: title; {amount} is 0.5 kg in the user's unit, e.g. "0.5 kg" or "1.1 lb".
  ///
  /// In en, this message translates to:
  /// **'Moderate - {amount}/week'**
  String planPaceModerate(String amount);

  /// Pace card: text under Moderate.
  ///
  /// In en, this message translates to:
  /// **'Steady progress with a moderate calorie deficit.'**
  String get planPaceModerateHint;

  /// Pace card: title; {amount} is 0.75 kg in the user's unit, e.g. "0.75 kg" or "1.65 lb".
  ///
  /// In en, this message translates to:
  /// **'Fast - {amount}/week'**
  String planPaceFast(String amount);

  /// Pace card: text under Fast.
  ///
  /// In en, this message translates to:
  /// **'Faster results, but more restrictive for most people.'**
  String get planPaceFastHint;

  /// Pace card: title.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get planPaceMaintain;

  /// Pace card: text under Maintain weight.
  ///
  /// In en, this message translates to:
  /// **'Keeps your calories around maintenance instead of creating a deficit.'**
  String get planPaceMaintainHint;

  /// Pace card: title; {amount} is 0.25 kg in the user's unit, e.g. "0.25 kg" or "0.55 lb".
  ///
  /// In en, this message translates to:
  /// **'Gain - {amount}/week'**
  String planPaceGain(String amount);

  /// Pace card: text under Gain.
  ///
  /// In en, this message translates to:
  /// **'A small calorie surplus for steady weight gain.'**
  String get planPaceGainHint;

  /// Page shown when the profile doesn't load after sign-in: heading.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile'**
  String get profileErrorLoadTitle;

  /// Page shown when the profile doesn't load after sign-in: text.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get profileErrorLoadBody;

  /// Page shown when the profile doesn't load: signs out.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get profileBackToSignIn;

  /// Settings: the page title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountTitle;

  /// Account Settings: a confirmation's text for a Google account; {description} is the text before it.
  ///
  /// In en, this message translates to:
  /// **'{description} You\'ll confirm with Google next.'**
  String accountConfirmWithGoogle(String description);

  /// Account Settings: snackbar after saving the name.
  ///
  /// In en, this message translates to:
  /// **'Name saved.'**
  String get accountNameSaved;

  /// Account Settings: saving the name failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your name. Try again.'**
  String get accountErrorSaveName;

  /// Account Settings: snackbar after sending the new-password email.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get accountResetEmailSent;

  /// Account Settings: the new-password email failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email.'**
  String get accountErrorSendReset;

  /// Account Settings: snackbar after asking to change the email.
  ///
  /// In en, this message translates to:
  /// **'Check your new email to confirm the change.'**
  String get accountCheckNewEmail;

  /// Account Settings: changing the email failed.
  ///
  /// In en, this message translates to:
  /// **'Could not change your email. Try again.'**
  String get accountErrorChangeEmail;

  /// Account Settings: the reset dialog's title.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get accountResetTitle;

  /// Account Settings: the reset dialog's text.
  ///
  /// In en, this message translates to:
  /// **'This deletes all your meals, weigh-ins and days off. Your account, profile and plan stay.'**
  String get accountResetBody;

  /// Account Settings: the reset button and the dialog's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get accountResetButton;

  /// Account Settings: snackbar after a reset.
  ///
  /// In en, this message translates to:
  /// **'All logged data deleted.'**
  String get accountResetDone;

  /// Account Settings: the reset failed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset your data.'**
  String get accountErrorReset;

  /// Account Settings: the delete dialog's title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountDeleteTitle;

  /// Account Settings: the delete dialog's text.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account and everything in it. It can\'t be undone.'**
  String get accountDeleteBody;

  /// Account Settings: the delete dialog's text while YumSum Star renews in Google Play.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account and everything in it. It can\'t be undone. Deleting your account doesn\'t cancel YumSum Star. Cancel it in Google Play first, or it keeps renewing.'**
  String get accountDeleteBodyStar;

  /// Account Settings: the delete button and the dialog's confirm button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteButton;

  /// Account Settings: deleting the account failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account.'**
  String get accountErrorDelete;

  /// Account Settings: the profile didn't load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your account.'**
  String get accountErrorLoad;

  /// Account Settings: the heading.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get accountHeading;

  /// Account Settings: under the heading, for a password account.
  ///
  /// In en, this message translates to:
  /// **'Change your name, email or password.'**
  String get accountSubtitle;

  /// Account Settings: under the heading, for a Google account.
  ///
  /// In en, this message translates to:
  /// **'Change your name. Google looks after your email and password.'**
  String get accountSubtitleGoogle;

  /// Account Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSectionAccount;

  /// Account Settings: the name field's label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// Account Settings: the name is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get accountEnterName;

  /// Account Settings: the button that opens the change-email dialog.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get accountChangeEmail;

  /// Account Settings: saves the name.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get accountSaveName;

  /// Account Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get accountSectionPassword;

  /// Account Settings: emails a new-password link.
  ///
  /// In en, this message translates to:
  /// **'Send password reset email'**
  String get accountSendReset;

  /// Settings: the reminders section, in capitals.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get accountSectionNotifications;

  /// Settings: the section over the System / Light / Dark switch, in capitals.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get accountSectionAppearance;

  /// Settings: the section over the English / Български switch, in capitals.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get accountSectionLanguage;

  /// Account Settings: section label, in capitals; a name.
  ///
  /// In en, this message translates to:
  /// **'YUMSUM STAR'**
  String get accountSectionStar;

  /// Account Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'HELP & LEGAL'**
  String get accountSectionHelp;

  /// Account Settings: opens the feedback dialog.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get accountSendFeedback;

  /// Account Settings: under Send feedback.
  ///
  /// In en, this message translates to:
  /// **'Write to the developer'**
  String get accountSendFeedbackHint;

  /// Account Settings: opens the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get accountPrivacyPolicy;

  /// Account Settings: opens the terms of use.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get accountTerms;

  /// Account Settings: opens Open Food Facts.
  ///
  /// In en, this message translates to:
  /// **'Food data from Open Food Facts'**
  String get accountOpenFoodFacts;

  /// Account Settings: under Food data from Open Food Facts.
  ///
  /// In en, this message translates to:
  /// **'A free database built by volunteers, under the Open Database License'**
  String get accountOpenFoodFactsHint;

  /// Account Settings: section label over reset and delete, in capitals.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get accountSectionDanger;

  /// Change-email dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get accountChangeEmailTitle;

  /// Change-email dialog: text.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email a link to your new address. Your email changes once you open it.'**
  String get accountChangeEmailBody;

  /// Change-email dialog: the new email's label.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get accountNewEmail;

  /// Change-email dialog: the new email is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email.'**
  String get accountEnterNewEmail;

  /// Change-email dialog: the password's label.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountCurrentPassword;

  /// Change-email dialog: the eye button's tooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountShowPassword;

  /// Change-email dialog: the eye button's tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountHidePassword;

  /// Change-email dialog: the password is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get accountEnterCurrentPassword;

  /// Change-email dialog: the confirm button.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get accountSendLink;

  /// Account Settings: an action with no one signed in.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in.'**
  String get accountErrorSignedOut;

  /// Account Settings: new-password email for an account without an email.
  ///
  /// In en, this message translates to:
  /// **'This account does not have an email address.'**
  String get accountErrorNoEmail;

  /// Account Settings: the new email is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a new email address.'**
  String get accountErrorEnterNewEmail;

  /// Account Settings: the new email is the current one.
  ///
  /// In en, this message translates to:
  /// **'That\'s already your email.'**
  String get accountErrorSameEmail;

  /// Account Settings: confirmed with a different Google account.
  ///
  /// In en, this message translates to:
  /// **'Choose the Google account you signed in with.'**
  String get accountErrorWrongGoogle;

  /// Account Settings: a password check for an account without an email.
  ///
  /// In en, this message translates to:
  /// **'This account cannot confirm with a password.'**
  String get accountErrorNoPassword;

  /// Account Settings: the password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get accountErrorWrongPassword;

  /// Account Settings: no connection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet and try again.'**
  String get accountErrorNoConnection;

  /// Account Settings: the new email belongs to another account.
  ///
  /// In en, this message translates to:
  /// **'An account already uses that email address.'**
  String get accountErrorEmailInUse;

  /// Account Settings: Firebase wants a fresh sign-in.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password and try again.'**
  String get accountErrorConfirmPassword;

  /// Account Settings: any other failure checking the password.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your password.'**
  String get accountErrorVerifyPassword;

  /// Menu: Home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menuHome;

  /// Menu: History.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get menuHistory;

  /// Menu: AI Coach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get menuCoach;

  /// Menu: Recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get menuRecipes;

  /// Menu: Weight & Progress.
  ///
  /// In en, this message translates to:
  /// **'Weight & Progress'**
  String get menuProgress;

  /// Menu: Plan Settings.
  ///
  /// In en, this message translates to:
  /// **'Plan Settings'**
  String get menuPlanSettings;

  /// Menu: the Settings page (account, reminders, appearance, language, YumSum Star, help).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Menu: follow the device's light or dark mode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get menuThemeSystem;

  /// Menu: light mode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get menuThemeLight;

  /// Menu: dark mode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get menuThemeDark;

  /// Menu: signs out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get menuLogOut;

  /// Feedback dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackTitle;

  /// Snackbar after feedback is sent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent. Thank you.'**
  String get feedbackSent;

  /// Feedback dialog: kind of message.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackKindProblem;

  /// Feedback dialog: kind of message.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get feedbackKindIdea;

  /// Feedback dialog: kind of message.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackKindOther;

  /// Feedback dialog: the text field's hint for a problem.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what did you expect?'**
  String get feedbackHintProblem;

  /// Feedback dialog: the text field's hint for an idea.
  ///
  /// In en, this message translates to:
  /// **'What would make YumSum better for you?'**
  String get feedbackHintIdea;

  /// Feedback dialog: the text field's hint for anything else.
  ///
  /// In en, this message translates to:
  /// **'Anything at all'**
  String get feedbackHintOther;

  /// Feedback dialog: where replies are sent.
  ///
  /// In en, this message translates to:
  /// **'Replies go to {email}.'**
  String feedbackRepliesTo(String email);

  /// Feedback dialog: the day's limit is used up.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You\'ve sent 1 today. You can send more tomorrow.} other{You\'ve sent {count} today. You can send more tomorrow.}}'**
  String feedbackLimitReached(int count);

  /// Feedback dialog: sending failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Try again.'**
  String get feedbackErrorSend;

  /// Feedback dialog: the Send button while sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get feedbackSending;

  /// Feedback dialog: sends the message.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// Under the start-up logo when it has been up for 15 seconds.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual. Check your connection.'**
  String get splashSlow;

  /// Website only, under splashSlow: reloads the page.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get splashReload;

  /// Splash screen: the line under YumSum. Also the confirmation email's footer.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent. Stay lean.'**
  String get splashTagline;

  /// Shown when the app fails to start: heading.
  ///
  /// In en, this message translates to:
  /// **'YumSum could not start'**
  String get startupErrorTitle;

  /// Shown when the app fails to start: text over the error message.
  ///
  /// In en, this message translates to:
  /// **'Refresh the page. If it keeps happening, send the message below to the developer.'**
  String get startupErrorBody;

  /// The app icon's long-press shortcut that starts a voice log.
  ///
  /// In en, this message translates to:
  /// **'Log by voice'**
  String get shortcutLogVoice;

  /// A weight in kg: "80.5 kg", or a range "30–300 kg". {value} comes formatted.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String unitsKg(String value);

  /// A weight in pounds: "176.4 lb", or a range "67–661 lb". {value} comes formatted.
  ///
  /// In en, this message translates to:
  /// **'{value} lb'**
  String unitsLb(String value);

  /// A weight in stones and pounds: "12 st 8 lb".
  ///
  /// In en, this message translates to:
  /// **'{stones} st {pounds} lb'**
  String unitsStLb(int stones, int pounds);

  /// A height in cm: "180 cm", or a range "100–250 cm".
  ///
  /// In en, this message translates to:
  /// **'{value} cm'**
  String unitsCm(String value);

  /// A height in feet and inches: "5 ft 11 in".
  ///
  /// In en, this message translates to:
  /// **'{feet} ft {inches} in'**
  String unitsFtIn(int feet, int inches);

  /// Weight chart in stones: a label on the side on a whole stone, "12 st".
  ///
  /// In en, this message translates to:
  /// **'{stones} st'**
  String unitsStAxis(int stones);

  /// Weight chart in stones: a label on the side between whole stones, "12 st 7" (pounds left out for room).
  ///
  /// In en, this message translates to:
  /// **'{stones} st {pounds}'**
  String unitsStLbAxis(int stones, int pounds);

  /// The kilogram on its own: the unit toggle and the weight box's suffix.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitsKgLabel;

  /// The pound on its own: the unit toggle and the pounds box's suffix.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitsLbLabel;

  /// The stone on its own: the stones box's suffix.
  ///
  /// In en, this message translates to:
  /// **'st'**
  String get unitsStLabel;

  /// The centimetre on its own: the unit toggle and the height box's suffix.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitsCmLabel;

  /// The foot on its own: the feet box's suffix.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get unitsFtLabel;

  /// The inch on its own: the inches box's suffix.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get unitsInLabel;

  /// Units toggle: kilograms and centimetres. Keep it as short as the symbols.
  ///
  /// In en, this message translates to:
  /// **'kg, cm'**
  String get unitsMetricToggle;

  /// Units toggle: pounds, and feet and inches.
  ///
  /// In en, this message translates to:
  /// **'lb, ft'**
  String get unitsLbFtToggle;

  /// Units toggle: stones and pounds, and feet and inches.
  ///
  /// In en, this message translates to:
  /// **'st, ft'**
  String get unitsStFtToggle;

  /// Label of the second weight box when typing stones and pounds.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get unitsPounds;

  /// Label of the second height box when typing feet and inches.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitsInches;

  /// A yes option on a two-way toggle.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// A no option on a two-way toggle.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Onboarding and Plan Settings: label of the age box.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get commonAge;

  /// Onboarding and Plan Settings: label of the height box, and the height unit toggle's heading.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get commonHeight;

  /// Onboarding, Plan Settings and the weigh-in dialog: label of the weight box.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get commonCurrentWeight;

  /// Onboarding and Plan Settings: label of the target weight box.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get commonTargetWeight;

  /// Onboarding and Plan Settings: the age box is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your age.'**
  String get commonEnterAge;

  /// Onboarding and Plan Settings: the age typed is out of range.
  ///
  /// In en, this message translates to:
  /// **'Valid age: 18–120.'**
  String get commonAgeRange;

  /// Onboarding and Plan Settings: the target weight is not below the current one.
  ///
  /// In en, this message translates to:
  /// **'Must be less than your current weight'**
  String get commonTargetBelowCurrent;

  /// Onboarding and Plan Settings: the target weight is not above the current one, when gaining.
  ///
  /// In en, this message translates to:
  /// **'Must be more than your current weight'**
  String get commonTargetAboveCurrent;

  /// Onboarding and Plan Settings: gender button.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get commonMale;

  /// Onboarding and Plan Settings: gender button.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get commonFemale;

  /// Onboarding and Plan Settings: gender button.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get commonOther;

  /// Onboarding: the height box is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your height.'**
  String get onboardingEnterHeight;

  /// Onboarding: the weight box is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight.'**
  String get onboardingEnterWeight;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// Onboarding: label of the name box.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get onboardingName;

  /// Onboarding card heading, over the Male, Female and Other buttons.
  ///
  /// In en, this message translates to:
  /// **'Are you…'**
  String get onboardingGenderTitle;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get onboardingAgeTitle;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'How tall are you?'**
  String get onboardingHeightTitle;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'What do you weigh now?'**
  String get onboardingWeightTitle;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get onboardingGoalTitle;

  /// Onboarding: the line under What's your goal?
  ///
  /// In en, this message translates to:
  /// **'A calorie is the energy in food. Eat a little less than your body burns to lose weight, or a little more to gain it.'**
  String get onboardingGoalBody;

  /// Onboarding: goal toggle option.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get onboardingLoseWeight;

  /// Onboarding: goal toggle option.
  ///
  /// In en, this message translates to:
  /// **'Keep my weight'**
  String get onboardingKeepWeight;

  /// Onboarding: goal option.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get onboardingGainWeight;

  /// Onboarding: the quiet line under the goal choices.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Plan Settings.'**
  String get onboardingGoalNote;

  /// Onboarding card heading.
  ///
  /// In en, this message translates to:
  /// **'What weight are you aiming for?'**
  String get onboardingTargetTitle;

  /// Onboarding card heading, over the daily movement cards.
  ///
  /// In en, this message translates to:
  /// **'How active is your normal day?'**
  String get onboardingActivityTitle;

  /// Onboarding: the line under How active is your normal day?
  ///
  /// In en, this message translates to:
  /// **'Outside workouts.'**
  String get onboardingActivityBody;

  /// Onboarding card heading, over the training cards.
  ///
  /// In en, this message translates to:
  /// **'Do you train on top of that?'**
  String get onboardingTrainingTitle;

  /// Onboarding: the line under Do you train on top of that?
  ///
  /// In en, this message translates to:
  /// **'Structured workouts, if any.'**
  String get onboardingTrainingBody;

  /// Onboarding card heading, over a Yes/No toggle.
  ///
  /// In en, this message translates to:
  /// **'Track protein too?'**
  String get onboardingProteinTitle;

  /// Onboarding: the line under Track protein too?
  ///
  /// In en, this message translates to:
  /// **'Protein keeps you full and looks after your muscle. YumSum works it out for each meal you log.'**
  String get onboardingProteinBody;

  /// Onboarding: the last card's heading. One of the two places allowed an exclamation mark.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready!'**
  String get onboardingPlanTitle;

  /// Onboarding: title of the plan card on the last card.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get onboardingPlanCardTitle;

  /// Onboarding: under the plan card.
  ///
  /// In en, this message translates to:
  /// **'You can go over all of this again, and get into more detail, in Plan Settings.'**
  String get onboardingPlanNote;

  /// Onboarding: saving the profile failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get onboardingErrorSave;

  /// Onboarding: goes to the card before.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// Onboarding: the big button to the next card.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding: the big button on the last card, which saves and opens Home.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// Plan card: the pace line when keeping weight.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan'**
  String get planPreviewMaintenance;

  /// Plan card: the pace line when the target is held at the minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum calorie floor'**
  String get planPreviewFloor;

  /// Plan card: the pace line, green.
  ///
  /// In en, this message translates to:
  /// **'Sustainable pace'**
  String get planPreviewSafe;

  /// Plan card: the pace line, amber.
  ///
  /// In en, this message translates to:
  /// **'Faster pace'**
  String get planPreviewCaution;

  /// Plan card: the pace line, red.
  ///
  /// In en, this message translates to:
  /// **'Very aggressive'**
  String get planPreviewWarning;

  /// Plan card: under Maintenance plan.
  ///
  /// In en, this message translates to:
  /// **'No calorie deficit is applied.'**
  String get planPreviewMaintenanceNote;

  /// Plan card: under Minimum calorie floor.
  ///
  /// In en, this message translates to:
  /// **'This pace would go below the minimum, so the goal date moves later.'**
  String get planPreviewFloorNote;

  /// Plan card: under Sustainable pace.
  ///
  /// In en, this message translates to:
  /// **'A moderate deficit from estimated maintenance.'**
  String get planPreviewSafeNote;

  /// Plan card: under Sustainable pace, when gaining.
  ///
  /// In en, this message translates to:
  /// **'A small surplus over estimated maintenance.'**
  String get planPreviewGainNote;

  /// Plan card: under Faster pace.
  ///
  /// In en, this message translates to:
  /// **'This needs consistency and may feel restrictive.'**
  String get planPreviewCautionNote;

  /// Plan card: under Very aggressive.
  ///
  /// In en, this message translates to:
  /// **'Consider a slower pace if this feels hard to maintain.'**
  String get planPreviewWarningNote;

  /// Plan card: the weekly loss and goal date when keeping weight.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get planPreviewMaintain;

  /// Plan card: the weekly loss, "0.5 kg/wk". {amount} is formatted in the user's unit.
  ///
  /// In en, this message translates to:
  /// **'{amount}/wk'**
  String planPreviewPerWeek(String amount);

  /// Plan card: small label over the calories a day; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get planPreviewDailyTarget;

  /// Plan card: small label over the weekly loss; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Weekly loss'**
  String get planPreviewWeeklyLoss;

  /// Plan card: small label over the weekly gain; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Weekly gain'**
  String get planPreviewWeeklyGain;

  /// Plan card: small label over the date the target weight is reached; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Goal by'**
  String get planPreviewGoalBy;

  /// Plan card: tooltip of the info button.
  ///
  /// In en, this message translates to:
  /// **'How this is calculated'**
  String get planPreviewInfoTooltip;

  /// Plan card's info dialog: title.
  ///
  /// In en, this message translates to:
  /// **'How calories are estimated'**
  String get planInfoTitle;

  /// Plan card's info dialog: the text over the sum.
  ///
  /// In en, this message translates to:
  /// **'First we estimate your resting burn from weight, height, age, and sex. Then we add your daily movement and training to estimate maintenance.'**
  String get planInfoBody;

  /// Plan card's info dialog: a line's label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Resting burn'**
  String get planInfoResting;

  /// Plan card's info dialog: a line's label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Daily movement'**
  String get planInfoMovement;

  /// Plan card's info dialog: a line's label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Training bonus'**
  String get planInfoTraining;

  /// Plan card's info dialog: a line's label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Combined activity'**
  String get planInfoActivity;

  /// Plan card's info dialog: a line's label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get planInfoMaintenance;

  /// Plan card's info dialog: the Adaptive formula's line label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Adaptive'**
  String get planInfoAdaptive;

  /// Plan card's info dialog: the calorie target's line label, 118 wide.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get planInfoTarget;

  /// Plan card's info dialog: calories a day, also at the end of a sum ("1800 - 500 = 1300 kcal/day").
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/day'**
  String planInfoKcalPerDay(int kcal);

  /// Plan card's info dialog: the target when held at the minimum.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/day, your minimum'**
  String planInfoAtMinimum(int kcal);

  /// Plan card's info dialog: under the sum when the target is held at the minimum.
  ///
  /// In en, this message translates to:
  /// **'This pace would go below the minimum, so your target stays at the minimum and the goal date moves later.'**
  String get planInfoFloorNote;

  /// Plan Settings: the page title.
  ///
  /// In en, this message translates to:
  /// **'Plan Settings'**
  String get planTitle;

  /// Plan Settings: the profile did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get planErrorLoad;

  /// Plan Settings: saving with no gender chosen.
  ///
  /// In en, this message translates to:
  /// **'Select your gender.'**
  String get planSelectGender;

  /// Plan Settings: after saving.
  ///
  /// In en, this message translates to:
  /// **'Plan saved.'**
  String get planSaved;

  /// Plan Settings: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your plan. Try again.'**
  String get planErrorSave;

  /// Plan Settings: under an empty height or weight box.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get planRequired;

  /// Plan Settings: the heading at the top.
  ///
  /// In en, this message translates to:
  /// **'Update your health plan'**
  String get planHeading;

  /// Plan Settings: under the heading.
  ///
  /// In en, this message translates to:
  /// **'Change anything below and your plan adjusts to match.'**
  String get planSubtitle;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DETAILS'**
  String get planSectionPersonal;

  /// Plan Settings: over the gender buttons.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get planGender;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get planSectionUnits;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'YOUR BODY'**
  String get planSectionBody;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'YOUR BMI'**
  String get planSectionBmi;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'YOUR GOAL'**
  String get planSectionGoal;

  /// Plan Settings: in place of the target box when keeping weight.
  ///
  /// In en, this message translates to:
  /// **'Your target weight stays at your current weight.'**
  String get planTargetStays;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'YOUR DAILY MOVEMENT'**
  String get planSectionMovement;

  /// Plan Settings: under YOUR DAILY MOVEMENT.
  ///
  /// In en, this message translates to:
  /// **'Your normal day outside workouts.'**
  String get planMovementNote;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'HOW OFTEN DO YOU TRAIN?'**
  String get planSectionTraining;

  /// Plan Settings: under HOW OFTEN DO YOU TRAIN?
  ///
  /// In en, this message translates to:
  /// **'Structured workouts on top of your normal day.'**
  String get planTrainingNote;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'TRACK PROTEIN TOO?'**
  String get planSectionProtein;

  /// Plan Settings: under TRACK PROTEIN TOO?
  ///
  /// In en, this message translates to:
  /// **'Protein helps you keep and build muscle. Off hides it everywhere.'**
  String get planProteinNote;

  /// Plan Settings: section label, in capitals.
  ///
  /// In en, this message translates to:
  /// **'YOUR PACE'**
  String get planSectionPace;

  /// Plan Settings: under the pace section label.
  ///
  /// In en, this message translates to:
  /// **'Pace sets the calorie target. Target weight sets how long the plan takes.'**
  String get planPaceNote;

  /// Plan Settings: section label over the Adaptive formula, in capitals.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL ADJUSTMENT'**
  String get planSectionAdjustment;

  /// Plan Settings: title of the plan card.
  ///
  /// In en, this message translates to:
  /// **'Updated plan'**
  String get planUpdatedPlan;

  /// Plan Settings: the save button.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get planSave;

  /// Plan Settings: under Adaptive formula.
  ///
  /// In en, this message translates to:
  /// **'Learns from your weigh-ins and adjusts your target each Monday.'**
  String get planAdaptiveNote;

  /// Plan Settings: under the Adaptive formula when a change will start it over.
  ///
  /// In en, this message translates to:
  /// **'Saving starts it again from your new plan.'**
  String get planAdaptiveRestarts;

  /// Plan Settings: BMI badge.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get planBmiUnderweight;

  /// Plan Settings: BMI badge.
  ///
  /// In en, this message translates to:
  /// **'Healthy range'**
  String get planBmiHealthy;

  /// Plan Settings: BMI badge.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get planBmiOverweight;

  /// Plan Settings: BMI badge.
  ///
  /// In en, this message translates to:
  /// **'Obese range'**
  String get planBmiObese;

  /// Plan Settings: over the BMI number.
  ///
  /// In en, this message translates to:
  /// **'Your BMI'**
  String get planBmiTitle;

  /// The Adaptive formula's name as a heading: Plan Settings and Weight & Progress.
  ///
  /// In en, this message translates to:
  /// **'Adaptive formula'**
  String get adaptiveTitle;

  /// The Adaptive formula: opens its explanation.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get adaptiveHowItWorks;

  /// Weight & Progress, without YumSum Star: under the Adaptive formula button.
  ///
  /// In en, this message translates to:
  /// **'A customised formula tailored just for you. Adapting with time and your weigh-ins.'**
  String get adaptiveTryNote;

  /// Weight & Progress: the green chip beside Adaptive formula.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get adaptiveOn;

  /// Weight & Progress: the Adaptive formula's first fact. {kcal} is shown big, e.g. "2440 kcal".
  ///
  /// In en, this message translates to:
  /// **'You burn {kcal} a day'**
  String adaptiveBurnFact(String kcal);

  /// Weight & Progress: the Adaptive formula's second fact. {kcal} is shown big, e.g. "1940 kcal".
  ///
  /// In en, this message translates to:
  /// **'Your target is {kcal} a day'**
  String adaptiveTargetFact(String kcal);

  /// Weight & Progress: under You burn, once measured.
  ///
  /// In en, this message translates to:
  /// **'Learnt from your weigh-ins and meals.'**
  String get adaptiveBurnLearnt;

  /// Weight & Progress: under You burn, before it is measured.
  ///
  /// In en, this message translates to:
  /// **'A first estimate. It learns as you weigh in.'**
  String get adaptiveBurnFirst;

  /// Weight & Progress: under Your target, when keeping weight.
  ///
  /// In en, this message translates to:
  /// **'To keep your weight steady.'**
  String get adaptiveTargetKeep;

  /// Weight & Progress: under Your target. {amount} is formatted in the user's unit, "0.5 kg".
  ///
  /// In en, this message translates to:
  /// **'To lose {amount} a week.'**
  String adaptiveTargetLose(String amount);

  /// Weight & Progress: under Your target, when gaining. {amount} is formatted in the user's unit, "0.25 kg".
  ///
  /// In en, this message translates to:
  /// **'To gain {amount} a week.'**
  String adaptiveTargetGain(String amount);

  /// The Adaptive formula's line on Home, Weight & Progress and Plan Settings when the last weigh-in is 10 days old.
  ///
  /// In en, this message translates to:
  /// **'Paused: no weigh-in for 10 days. Weigh in to keep it personal.'**
  String get adaptivePaused;

  /// The Adaptive formula's line on Home: the target is held at the minimum. {date} is "7 November".
  ///
  /// In en, this message translates to:
  /// **'Your target is at your minimum, so your goal date is now {date}.'**
  String adaptiveAtMinimum(String date);

  /// The Adaptive formula's line on Home after Monday lowered the target. {amount} is signed, "−80".
  ///
  /// In en, this message translates to:
  /// **'Adjusted for you: {amount} kcal. You burn a little less than your plan assumed.'**
  String adaptiveLowered(String amount);

  /// The Adaptive formula's line on Home after Monday raised the target. {amount} is signed, "+80".
  ///
  /// In en, this message translates to:
  /// **'Adjusted for you: {amount} kcal. You burn a little more than your plan assumed.'**
  String adaptiveRaised(String amount);

  /// The Adaptive formula's line on Home: a first sign, no change yet.
  ///
  /// In en, this message translates to:
  /// **'You may burn a little less than your plan assumed. Checking again next Monday.'**
  String get adaptiveFirstSign;

  /// The Adaptive formula's line on Home: an earlier adjustment stands. {amount} is signed, "−80".
  ///
  /// In en, this message translates to:
  /// **'Adjusted for you: {amount} kcal. No change this week.'**
  String adaptiveSteadyAdjusted(String amount);

  /// The Adaptive formula's line on Home: no change.
  ///
  /// In en, this message translates to:
  /// **'No change this week: your weight matches what you eat.'**
  String get adaptiveSteady;

  /// The Adaptive formula's line on Home.
  ///
  /// In en, this message translates to:
  /// **'Not enough weigh-ins this week, so your target stays the same.'**
  String get adaptiveFewWeighIns;

  /// The Adaptive formula's line on Home.
  ///
  /// In en, this message translates to:
  /// **'Not enough days logged this week, so your target stays the same.'**
  String get adaptiveFewDays;

  /// The Adaptive formula's line on Home.
  ///
  /// In en, this message translates to:
  /// **'Your numbers look unusual. Check your logging and weigh-ins.'**
  String get adaptiveUnusual;

  /// Plan Settings: the sum the Adaptive formula makes, "1670 from your plan − 80 adaptive = 1590 kcal". {sign} is + or −.
  ///
  /// In en, this message translates to:
  /// **'{plan} from your plan {sign} {amount} adaptive = {target} kcal'**
  String adaptiveSum(int plan, String sign, int amount, int target);

  /// Plan Settings: the Adaptive formula's sum when the target is held at the minimum.
  ///
  /// In en, this message translates to:
  /// **'{plan} from your plan {sign} {amount} adaptive = {target} kcal, your minimum'**
  String adaptiveSumMinimum(int plan, String sign, int amount, int target);

  /// Weight & Progress: the page title.
  ///
  /// In en, this message translates to:
  /// **'Weight & Progress'**
  String get progressTitle;

  /// Weight & Progress: the button that opens the weigh-in dialog.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get progressLogWeight;

  /// Weight & Progress: heading over the weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get progressHistory;

  /// Weight & Progress: the button under the weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get progressReset;

  /// Weight & Progress: the weigh-ins did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your weight history.'**
  String get progressErrorLoad;

  /// Weight & Progress: after a weigh-in that changed the target.
  ///
  /// In en, this message translates to:
  /// **'Weight saved. New target: {kcal} kcal (was {previous}).'**
  String progressSavedNewTarget(int kcal, int previous);

  /// Weight & Progress: after a weigh-in that kept the target.
  ///
  /// In en, this message translates to:
  /// **'Weight saved. Your target stays at {kcal} kcal.'**
  String progressSavedSameTarget(int kcal);

  /// Weight & Progress: title of the dialog before deleting a weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Delete weigh-in?'**
  String get progressDeleteTitle;

  /// Weight & Progress: the delete dialog. {weight} is "80.5 kg", {date} "Sat, 7 Nov".
  ///
  /// In en, this message translates to:
  /// **'Remove {weight} from {date}?'**
  String progressDeleteBody(String weight, String date);

  /// Weight & Progress: the delete dialog for the newest weigh-in. {previous} is the weigh-in before it.
  ///
  /// In en, this message translates to:
  /// **'Remove {weight} from {date}? Your plan adjusts back to {previous}.'**
  String progressDeleteBodyBack(String weight, String date, String previous);

  /// Weight & Progress: deleting failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the weigh-in. Try again.'**
  String get progressErrorDelete;

  /// Weight & Progress: after deleting a weigh-in that changed the target.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in deleted. New target: {kcal} kcal (was {previous}).'**
  String progressDeletedNewTarget(int kcal, int previous);

  /// Weight & Progress: after deleting a weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in deleted.'**
  String get progressDeleted;

  /// Weight & Progress: title of the dialog before Reset progress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get progressResetTitle;

  /// Weight & Progress: the Reset progress dialog.
  ///
  /// In en, this message translates to:
  /// **'This clears all your weight history and chart progress. Are you sure?'**
  String get progressResetBody;

  /// Weight & Progress: confirms Reset progress.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get progressResetButton;

  /// Weight & Progress: after Reset progress.
  ///
  /// In en, this message translates to:
  /// **'Weight history cleared.'**
  String get progressResetDone;

  /// Weight & Progress: Reset progress failed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset progress. Try again.'**
  String get progressErrorReset;

  /// Weight & Progress: small label over the current weight; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get progressCurrent;

  /// Weight & Progress: small label over the change since the first weigh-in; a third of the card wide.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get progressChange;

  /// Weight & Progress: small label over the target weight, and the chart's target line.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get progressTarget;

  /// Weight & Progress: the chart's touch label on the trend line, "Trend 80.2 kg".
  ///
  /// In en, this message translates to:
  /// **'Trend {weight}'**
  String progressTrend(String weight);

  /// Weight & Progress: tooltip of a weigh-in's delete button.
  ///
  /// In en, this message translates to:
  /// **'Delete weigh-in'**
  String get progressDeleteTooltip;

  /// Weight & Progress: heading with no weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'No weight logged yet'**
  String get progressEmptyTitle;

  /// Weight & Progress: the text with no weigh-ins.
  ///
  /// In en, this message translates to:
  /// **'Log your weight to see your progress. Your plan adjusts each time.'**
  String get progressEmptyBody;

  /// Weigh-in dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Log your weight'**
  String get progressWeighInTitle;

  /// Weigh-in dialog: under the title.
  ///
  /// In en, this message translates to:
  /// **'Your plan adjusts to match.'**
  String get progressWeighInNote;

  /// Weigh-in dialog: the weight is out of range. {range} is "25 and 400 kg", joined with progressWeighInRangeAnd.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between {range}.'**
  String progressWeighInRange(String range);

  /// Weigh-in dialog: joins the two ends of the weight range, spaces included.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get progressWeighInRangeAnd;

  /// Weigh-in dialog: saving failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your weight. Try again.'**
  String get progressErrorSaveWeight;

  /// Home and the Adaptive formula: after a weigh-in that changed the target.
  ///
  /// In en, this message translates to:
  /// **'Weight saved. New target: {kcal} kcal.'**
  String progressWeightSavedTarget(int kcal);

  /// Home and the Adaptive formula: after a weigh-in.
  ///
  /// In en, this message translates to:
  /// **'Weight saved.'**
  String get progressWeightSaved;
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
