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

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonMaybeLater => 'Maybe later';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonBecomeStar => 'Become a Star';

  @override
  String commonKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get commonKcalUnit => 'kcal';

  @override
  String get commonGramsUnit => 'g';

  @override
  String commonGrams(String grams) {
    return '$grams g';
  }

  @override
  String commonKcalProtein(int kcal, int protein) {
    return '$kcal kcal · $protein g protein';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get homeErrorProfile => 'Could not load your profile.';

  @override
  String get homeErrorMeals => 'Could not load your meals.';

  @override
  String get homeErrorMonth => 'Could not load this month.';

  @override
  String get homeDeleteMealTitle => 'Delete meal?';

  @override
  String get homeDeleteMealBody => 'Remove this meal from today?';

  @override
  String get homeErrorDelete => 'Could not delete the meal. Try again.';

  @override
  String get homeDayOff => 'Day off';

  @override
  String get homeDayOffTake => 'Take the day off';

  @override
  String get homeErrorDayOff => 'Could not change your day off. Try again.';

  @override
  String get homeOnTrack => 'On track';

  @override
  String get homeOverTarget => 'Over target';

  @override
  String get homeKcalLeft => 'kcal left';

  @override
  String get homeKcalOver => 'kcal over';

  @override
  String homeKcalEaten(int eaten, int target) {
    return '$eaten of $target kcal eaten';
  }

  @override
  String get homeTargetsTooltip => 'About your targets';

  @override
  String get homeMealsTitle => 'Today\'s meals';

  @override
  String homeMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logged',
    );
    return '$_temp0';
  }

  @override
  String get homeNothingLogged =>
      'Nothing logged yet. Type or tap the mic below.';

  @override
  String get homeHistory => 'History';

  @override
  String get homeNoDaysThisMonth => 'No logged days yet this month.';

  @override
  String homeDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days logged',
    );
    return '$_temp0';
  }

  @override
  String get homeWeight => 'Weight';

  @override
  String get homeWeightEmpty => 'Log your weight to track progress';

  @override
  String homeWeightLatest(String weight) {
    return 'Latest: $weight';
  }

  @override
  String homeWeightLatestAgo(String weight, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Latest: $weight · $days days ago',
    );
    return '$_temp0';
  }

  @override
  String get homeWeightLog => 'Log';

  @override
  String get homeStarPitch =>
      'Smart Snap, the Adaptive Formula, an AI Assisted Coach and Detailed Macros.';

  @override
  String get homeStarHide => 'Hide for now';

  @override
  String get homeCreatineTitle => 'Take creatine?';

  @override
  String homeCreatineBody(String time) {
    return 'Get a daily reminder at $time. You can change the time later.';
  }

  @override
  String get homeCreatineNo => 'No thanks';

  @override
  String get homeCreatineYes => 'Remind me';

  @override
  String homeCreatineOn(String time) {
    return 'Creatine reminder on for $time. Change it under Notifications in Settings.';
  }

  @override
  String get homeCreatineBlocked =>
      'Allow notifications in your phone\'s settings, then turn it on under Notifications in Settings.';

  @override
  String get homeCreatineLater =>
      'You can turn it on any time under Notifications in Settings.';

  @override
  String get homeDayOffBackTitle => 'Back on plan?';

  @override
  String get homeDayOffTakeTitle => 'Take today off?';

  @override
  String get homeDayOffBackBody =>
      'Today will be measured against your target again.';

  @override
  String get homeDayOffIntro => 'For holidays and nights out.';

  @override
  String get homeDayOffLog => 'Log your meals as usual.';

  @override
  String get homeDayOffNoColours => 'No green, yellow or red today.';

  @override
  String get homeDayOffHistory => 'Left out of History scores.';

  @override
  String get homeDayOffUndo => 'Tap the umbrella to undo.';

  @override
  String get homeDayOffBackButton => 'Back on plan';

  @override
  String get homeDayOffTakeButton => 'Take day off';

  @override
  String get adaptiveIntroTitle => 'Your calories, personalised';

  @override
  String get adaptiveIntroSubtitle =>
      'Feel more confident about how much to eat, with a smart formula that adapts to you every week.';

  @override
  String get adaptiveIntroBurnTitle => 'Understand what you burn';

  @override
  String get adaptiveIntroBurnBody =>
      'Your food logs and weight trends help estimate your daily calorie burn, taking the guesswork out of your target.';

  @override
  String get adaptiveIntroBodyTitle => 'Built around your body';

  @override
  String get adaptiveIntroBodyBody =>
      'Get a target shaped by how your body actually responds, helping you find what works for you.';

  @override
  String get adaptiveIntroChangeTitle => 'Stay on track as you change';

  @override
  String get adaptiveIntroChangeBody =>
      'Your calorie needs can change as you lose weight. Your target adjusts to help you keep making progress.';

  @override
  String get adaptiveIntroWeighTitle => 'Make every weigh-in count';

  @override
  String get adaptiveIntroWeighBody =>
      'Each weigh-in adds to the picture. Consistent logging helps fine-tune your target over time.';

  @override
  String get adaptiveIntroLogWeight => 'Log my weight';

  @override
  String get adaptiveLapseTitle => 'Your YumSum Star has ended';

  @override
  String adaptiveLapseBody(String date) {
    return 'Your target goes back to your standard plan on $date.';
  }

  @override
  String quickLogLimit(int limit) {
    return 'Today\'s $limit AI estimates are used up. Type the calories yourself.';
  }

  @override
  String get quickLogErrorSave => 'Could not save meal. Try again.';

  @override
  String get quickLogAllowMic => 'Allow microphone access to log by voice.';

  @override
  String get quickLogErrorRecord => 'Could not start recording. Try again.';

  @override
  String get quickLogMisTap => 'Didn\'t catch that. Tap the mic and try again.';

  @override
  String get quickLogNoCalories =>
      'Open Food Facts has no calories for this product yet. Take a photo of the packet instead.';

  @override
  String get quickLogNotListed =>
      'This product isn\'t on Open Food Facts. Take a photo of the packet instead.';

  @override
  String quickLogAiLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI estimates left today',
      one: '1 AI estimate left today',
      zero: 'No AI estimates left today',
    );
    return '$_temp0';
  }

  @override
  String get quickLogHint => 'Type a meal';

  @override
  String get quickLogClear => 'Clear';

  @override
  String get quickLogProteinHint => 'protein (g)';

  @override
  String get quickLogProteinUnit => 'g protein';

  @override
  String get quickLogSearchFoods => 'Search foods';

  @override
  String quickLogChip(String name, int kcal) {
    return '$name · $kcal kcal';
  }

  @override
  String get quickLogStop => 'Stop';

  @override
  String get quickLogPhoto => 'Take a photo';

  @override
  String get quickLogBarcode => 'Scan a barcode';

  @override
  String get quickLogSpeak => 'Speak';

  @override
  String get quickLogEstimate => 'Estimate';

  @override
  String get quickLogListening => 'Listening... tap stop when you\'re done.';

  @override
  String get quickLogWorking => 'Working...';

  @override
  String get mealAiOff => 'AI estimates aren\'t switched on yet.';

  @override
  String get mealAiBusy => 'The AI is busy right now. Try again in a minute.';

  @override
  String get mealAiPaused =>
      'AI estimates are paused for now. You can still type the calories yourself.';

  @override
  String get mealAiBusyShort => 'The AI is busy. Try again in a few seconds.';

  @override
  String get mealAiNoStar =>
      'YumSum Star isn\'t on for this account. Try again.';

  @override
  String get mealAiErrorEstimate => 'Could not estimate calories. Try again.';

  @override
  String get mealAiNoMeal =>
      'Couldn\'t hear a meal in that. Tap the mic and try again.';

  @override
  String get mealAiErrorVoice =>
      'Could not understand the recording. Try again.';

  @override
  String get mealAiNoFood =>
      'No food found in that photo. Try again with the plate in view.';

  @override
  String get mealAiErrorPhoto => 'Could not read that photo. Try again.';

  @override
  String get mealAiNoLabel =>
      'Those photos don\'t show a label. Fill in the details yourself.';

  @override
  String get mealAiLimit =>
      'Daily AI limit reached. Enter the calories yourself.';

  @override
  String get mealErrorAi => 'Could not reach the AI. Try again.';

  @override
  String get mealErrorNoCalories => 'Enter the calories, or estimate them.';

  @override
  String get mealErrorEditLimit => 'No past-day changes left this month.';

  @override
  String get mealErrorSave => 'Could not save the meal. Try again.';

  @override
  String get mealEditTitle => 'Edit meal';

  @override
  String get mealAddTitle => 'Add meal';

  @override
  String get mealName => 'Meal';

  @override
  String get mealNameHint => 'e.g. Musaka, chicken wrap';

  @override
  String get mealCalories => 'Calories';

  @override
  String get mealProtein => 'Protein';

  @override
  String get mealProteinNote =>
      'Leave protein blank to estimate it from the name.';

  @override
  String get mealEstimateFromName => 'Estimate from name';

  @override
  String get mealSaveChanges => 'Save changes';

  @override
  String get mealSave => 'Save meal';

  @override
  String get mealUnnamed => 'Unnamed meal';

  @override
  String get mealNutrition => 'Nutrition';

  @override
  String mealProteinGrams(int grams) {
    return '$grams g protein';
  }

  @override
  String get mealOptions => 'Meal options';

  @override
  String get mealTapWeight => 'Tap a weight to change it.';

  @override
  String get mealWeight => 'Weight';

  @override
  String get mealUseWeight => 'Use';

  @override
  String mealKcalGrams(int kcal, int grams) {
    return '$kcal kcal · $grams g';
  }

  @override
  String get mealChoiceTitle => 'Which did you have?';

  @override
  String get mealChoiceNote => 'We went with the first.';

  @override
  String get cameraNotFound => 'No camera found.';

  @override
  String get cameraCouldNotStart => 'The camera could not start.';

  @override
  String get cameraAllowWeb =>
      'Allow camera access in your browser to scan barcodes and take photos.';

  @override
  String get cameraAllowApp =>
      'Allow camera access to scan barcodes and take photos. If you said no before, turn it on in your phone\'s Settings.';

  @override
  String get cameraErrorReader =>
      'Could not start the barcode reader. Try again.';

  @override
  String get cameraErrorPhoto => 'Could not take the photo. Try again.';

  @override
  String get cameraChoosePhoto => 'Choose a photo instead';

  @override
  String get cameraTakePhoto => 'Take photo';

  @override
  String cameraStep(int number, int total) {
    return 'Step $number of $total';
  }

  @override
  String get cameraBarcodeTitle => 'Point at the barcode';

  @override
  String get cameraBarcodeTip =>
      'Hold it inside the box and it\'s read by itself.';

  @override
  String get cameraMealTitle => 'Take a photo of your meal';

  @override
  String get cameraMealTip => 'From above, with the whole plate in.';

  @override
  String get cameraFrontTitle => 'Take a photo of the front of the pack';

  @override
  String get cameraFrontTip => 'Get the whole front in, name and all.';

  @override
  String get cameraTableTitle => 'Take a photo of the nutrition table';

  @override
  String get cameraTableTip =>
      'Fill the frame with the table, flat and sharp, so every number can be read.';

  @override
  String get cameraSmartSnap => 'Smart Snap';

  @override
  String get cameraSmartSnapSubtitle =>
      'Make food logging as easy as taking a photo.';

  @override
  String get cameraSmartSnapSkipTitle => 'Skip the manual entry';

  @override
  String get cameraSmartSnapSkipBody =>
      'Snap your meal and let AI identify the food, with estimated calories and macros for each item.';

  @override
  String get cameraSmartSnapControlTitle => 'You\'re always in control';

  @override
  String get cameraSmartSnapControlBody =>
      'Review your meal, make any changes and save when you\'re happy.';

  @override
  String get foodSearchSource => 'Packaged foods · Open Food Facts';

  @override
  String get foodSearchError => 'Could not search right now.';

  @override
  String get foodSearchEmpty =>
      'Nothing found. Try other words, or let the AI estimate it.';

  @override
  String foodPer100g(int kcal) {
    return '$kcal kcal per 100 g';
  }

  @override
  String foodPortionSource(String amounts) {
    return '$amounts per 100 g · Open Food Facts';
  }

  @override
  String get foodPortionAmount => 'Amount';

  @override
  String get foodErrorNotAnswering =>
      'The food database is not answering right now.';

  @override
  String get foodErrorOffline =>
      'Could not reach the food database. Check your connection.';

  @override
  String get contributeAddNutritionTitle => 'Add its nutrition';

  @override
  String get contributeAddProductTitle => 'Be the first to add this';

  @override
  String get contributeAddNutritionBody =>
      'This product is in the database, but its nutrition isn\'t yet. Add it with one photo of the nutrition table and it\'ll be there for you and everyone who scans it next.';

  @override
  String get contributeAddProductBody =>
      'This product isn\'t in the database yet. Add it with two photos and it\'ll be there for you and everyone who scans it next.';

  @override
  String get contributeTakesSeconds =>
      'It takes 30 seconds and helps everyone, forever ♥';

  @override
  String get contributeButton => 'Contribute';

  @override
  String get contributeNotNow => 'Not now';

  @override
  String contributeAiRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The AI read these from your photos. Check them against the packet: they will be public.',
      one:
          'The AI read these from your photo. Check them against the packet: they will be public.',
    );
    return '$_temp0';
  }

  @override
  String get contributeAiLimit =>
      'Daily AI limit reached. Copy the details from the packet yourself.';

  @override
  String get contributeErrorRead =>
      'Could not read the label. Fill in the details yourself.';

  @override
  String get contributeNotSignedIn => 'Not signed in.';

  @override
  String get contributeErrorMissing =>
      'Add the product name and energy (kcal).';

  @override
  String get contributeEnergy => 'Energy (kcal)';

  @override
  String get contributeProtein => 'Protein (g)';

  @override
  String get contributeFat => 'Fat (g)';

  @override
  String get contributeSaturates => 'of which saturates (g)';

  @override
  String get contributeCarbs => 'Carbohydrate (g)';

  @override
  String get contributeSugars => 'of which sugars (g)';

  @override
  String get contributeFibre => 'Fibre (g)';

  @override
  String get contributeSalt => 'Salt (g)';

  @override
  String get contributeThanks => 'Thank you!';

  @override
  String contributeThanksProduct(String product) {
    return '$product is now on Open Food Facts for everyone who scans it next.';
  }

  @override
  String contributeThanksNutrition(String product) {
    return '$product now has its nutrition on Open Food Facts for everyone who scans it next.';
  }

  @override
  String contributeThanksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'That\'s $count products you\'ve added.',
    );
    return '$_temp0';
  }

  @override
  String get contributeLogIt => 'Log it';

  @override
  String get contributeCheckDetails => 'Check the details';

  @override
  String get contributeCheckNutrition => 'Check the nutrition';

  @override
  String contributeBarcode(String barcode) {
    return 'Barcode $barcode';
  }

  @override
  String get contributeReading => 'Reading the label...';

  @override
  String get contributeProductName => 'Product name';

  @override
  String get contributeBrand => 'Brand';

  @override
  String get contributePackSize => 'Pack size, e.g. 400 g';

  @override
  String get contributeServing => 'Serving, e.g. 30 g';

  @override
  String get contributePer100 => 'PER 100 G (OR 100 ML)';

  @override
  String get contributePublishNew =>
      'Your photos and these details will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.';

  @override
  String get contributePublishFigures =>
      'These figures will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.';

  @override
  String get contributePublishPhoto =>
      'Your photo and these figures will be published on Open Food Facts under open licences (CC BY-SA and ODbL), so anyone can use them. Your name and email are never shared.';

  @override
  String get contributeErrorLimit =>
      'You\'ve sent all you can today. You can send more tomorrow.';

  @override
  String get contributeErrorRejected =>
      'Open Food Facts didn\'t accept it. Try again in a moment.';

  @override
  String get contributeErrorOffline =>
      'Could not reach Open Food Facts. Check your connection and try again.';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroFibre => 'Fibre';

  @override
  String get macroSugars => 'Sugars';

  @override
  String get macroSaturates => 'Saturates';

  @override
  String get macroSalt => 'Salt';

  @override
  String get macroRingCarbs => 'Carbs';

  @override
  String get macroRingSaturates => 'Saturates';

  @override
  String macroRingMax(int grams) {
    return 'max $grams g';
  }

  @override
  String macroRingOf(int grams) {
    return 'of $grams g';
  }

  @override
  String macroNotCountedProtein(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals not counted (no protein info)',
      one: '1 meal not counted (no protein info)',
    );
    return '$_temp0';
  }

  @override
  String macroNotCountedMacros(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals not counted (no macro info)',
      one: '1 meal not counted (no macro info)',
    );
    return '$_temp0';
  }

  @override
  String get macroUnlockLabel => 'Unlock full macros with YumSum Star';

  @override
  String get macroUnlock => 'Unlock full macros';

  @override
  String get macroNoneToday => 'No macro info for today\'s meals';

  @override
  String get macroAbout => 'About macros';

  @override
  String macroAtLeast(String grams) {
    return 'at least $grams';
  }

  @override
  String get macroGuideTargets => 'Your targets';

  @override
  String get macroGuideMacros => 'Your macros';

  @override
  String get macroGuideIntro =>
      'Your targets come from your plan, so they change with it.';

  @override
  String get macroGuideCalories => 'Calories';

  @override
  String get macroGuideCaloriesWhy =>
      'The energy in food. Eat less than you burn and you lose weight.';

  @override
  String get macroGuideCaloriesTarget =>
      'What you burn in a day, from your age, height, weight and activity, with a little taken off if you\'re losing weight.';

  @override
  String get macroGuideAimFor => 'Aim for';

  @override
  String get macroGuideBalance => 'Keep in balance';

  @override
  String get macroGuideKeepUnder => 'Keep under';

  @override
  String get macroGuideKeepUnderNote =>
      'Keep these under the amounts shown. Going over day after day is what harms your teeth, heart and blood pressure.';

  @override
  String get macroGuideProteinWhy =>
      'Keeps you full and protects your muscle while you lose fat.';

  @override
  String get macroGuideProteinTarget =>
      '1.2 to 2 g per kg of your goal weight, more the more you train.';

  @override
  String get macroGuideFibreWhy => 'Keeps you full and your gut healthy.';

  @override
  String get macroGuideFibreTarget => 'At least 30 g a day.';

  @override
  String get macroGuideCarbsWhy =>
      'Your main fuel: bread, rice, pasta, potatoes and fruit.';

  @override
  String get macroGuideCarbsTarget => 'What\'s left after protein and fat.';

  @override
  String get macroGuideFatWhy => 'Energy, and it helps you absorb vitamins.';

  @override
  String get macroGuideFatTarget => 'About 30% of your calories.';

  @override
  String get macroGuideSugarsWhy =>
      'Calories that don\'t fill you up, and bad for your teeth.';

  @override
  String get macroGuideSugarsTarget => 'Under 18% of your calories.';

  @override
  String get macroGuideSaturatesWhy =>
      'Raises your cholesterol: butter, cheese, fatty meat and cakes.';

  @override
  String get macroGuideSaturatesTarget => 'Under 10% of your calories.';

  @override
  String get macroGuideSaltWhy =>
      'Raises your blood pressure. Most is hidden in bread, cheese and ready meals.';

  @override
  String get macroGuideSaltTarget => 'Under 6 g a day, about a teaspoon.';

  @override
  String get macroGuideTarget => 'Target: ';

  @override
  String get macroGuideDisclaimer =>
      'General guidance for adults, not medical advice.';

  @override
  String get macroFibreBadge => 'Rich in fibre';

  @override
  String get historyTitle => 'History';

  @override
  String get historyErrorLoad => 'Could not load your history.';

  @override
  String get historyWeek => 'Week';

  @override
  String get historyMonth => 'Month';

  @override
  String get historyPrevious => 'Previous';

  @override
  String get historyNext => 'Next';

  @override
  String get historyToday => 'Today';

  @override
  String get historyStatusOnTrack => 'On track';

  @override
  String get historyStatusClose => 'Close';

  @override
  String get historyStatusOffTrack => 'Off track';

  @override
  String get historyNotLogged => 'Not logged';

  @override
  String get historyReviewTomorrow =>
      'Your review starts tomorrow, once today is over.';

  @override
  String get historyNothingLogged => 'Nothing logged in this period yet.';

  @override
  String historyOnTrackCount(int count) {
    return '$count on track';
  }

  @override
  String historyCloseCount(int count) {
    return '$count close';
  }

  @override
  String historyOffTrackCount(int count) {
    return '$count off track';
  }

  @override
  String historyDaysOffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days off',
      one: '1 day off',
    );
    return '$_temp0';
  }

  @override
  String get historyOnTrackShare => 'of logged days on track';

  @override
  String historyDaysLogged(int logged, int days) {
    return '$logged of $days days logged';
  }

  @override
  String historyAverageKcal(int kcal) {
    return 'Average $kcal kcal a day';
  }

  @override
  String get historyGuidanceNoMeals => 'No meals logged in this period.';

  @override
  String get historyGuidanceMostClose =>
      'Most logged days stayed close to target.';

  @override
  String get historyGuidanceSomeClose =>
      'Some logged days stayed close to target; a few were well off.';

  @override
  String get historyGuidanceMostOff =>
      'Most logged days were well above or below target.';

  @override
  String get historyGuidanceLogMore =>
      'Some days weren\'t logged. Log more days for a clearer review.';

  @override
  String historyBarNoCalories(String date) {
    return '$date: no calories logged';
  }

  @override
  String historyBarKcal(String date, int kcal) {
    return '$date: $kcal kcal';
  }

  @override
  String historyBarKcalProtein(String date, int kcal, int protein) {
    return '$date: $kcal kcal · $protein g protein';
  }

  @override
  String get historyDayNothingLogged => 'Nothing logged';

  @override
  String historyDayKcal(int total, int target) {
    return '$total of $target kcal';
  }

  @override
  String historyDayKcalProtein(int total, int target, int protein) {
    return '$total of $target kcal · $protein g protein';
  }

  @override
  String get historyDayOff => 'Day off';

  @override
  String get historyDayNoMacros => 'No macro info for this day\'s meals';

  @override
  String historyChangesLeft(int left, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left of $limit past-day changes left this month',
    );
    return '$_temp0';
  }

  @override
  String get historyNoChangesLeft => 'No past-day changes left this month.';

  @override
  String get historyDayNoMeals => 'No meals logged on this day.';

  @override
  String get historyAddMeal => 'Add meal';

  @override
  String get historyDeleteMealTitle => 'Delete meal?';

  @override
  String historyDeleteMealNamed(String name) {
    return 'Remove $name from this day?';
  }

  @override
  String get historyDeleteMealUnnamed => 'Remove this meal from this day?';

  @override
  String get historyCancel => 'Cancel';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyErrorDeleteMeal => 'Could not delete the meal. Try again.';

  @override
  String get coachTitle => 'AI Coach';

  @override
  String get coachIntroTitle => 'Your AI Coach';

  @override
  String get coachSubtitle =>
      'Get fresh advice tailored just for you, every Monday, to help you eat better and reach your goals.';

  @override
  String get coachPromiseHoldingBackTitle => 'Spot what\'s holding you back';

  @override
  String get coachPromiseHoldingBackBody =>
      'Discover the eating patterns that could be slowing your progress and find small changes that help.';

  @override
  String get coachPromiseBalanceTitle => 'Build a more balanced diet';

  @override
  String get coachPromiseBalanceBody =>
      'See how your protein, fibre, salt and sugar compare with recommended amounts, so you know where to focus.';

  @override
  String get coachPromiseAdviceTitle => 'Get advice you can put into practice';

  @override
  String get coachPromiseAdviceBody =>
      'Make your next meal easier with practical tips and recipe ideas based on what you already eat.';

  @override
  String get coachPromiseWeeklyTitle => 'Start every week with direction';

  @override
  String get coachPromiseWeeklyBody =>
      'Every Monday, get a fresh review of what\'s working and what to change, so you can build on your progress.';

  @override
  String get coachClose => 'Close';

  @override
  String get coachHowItWorks => 'How it works';

  @override
  String get coachLastWeek => 'Last week';

  @override
  String get coachPrevious => 'Previous';

  @override
  String get coachNext => 'Next';

  @override
  String get coachFirstNotesTitle => 'Your first notes come on Monday';

  @override
  String coachDaysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days to go',
      one: '1 day to go',
    );
    return '$_temp0';
  }

  @override
  String coachFirstNotesBody(String date) {
    return 'AI Coach reads a whole week at a time, so it\'s going over this one as you log it. On Monday $date it\'ll tell you what went well, what held you back and what to try next week.';
  }

  @override
  String get coachEnded =>
      'YumSum Star has ended, so no new notes are written. The ones you have stay.';

  @override
  String get coachNotEnough =>
      'Not enough logged this week for notes. They need 4 days logged, not counting days off.';

  @override
  String get coachLooking => 'Looking over your week';

  @override
  String get coachErrorLoad => 'Could not get this week\'s notes. Try again.';

  @override
  String get coachTryAgain => 'Try again';

  @override
  String get coachNoNotesPlus =>
      'No notes on this week. AI Coach writes them during the week after, when you open this page.';

  @override
  String get coachNoNotes => 'No notes on this week.';

  @override
  String get coachKeepGoing => 'Keep going';

  @override
  String get coachTryThis => 'Try this';

  @override
  String get coachNotesComing => 'Your notes on this week come on Monday.';

  @override
  String get coachNotesReadThat => 'Read your notes on that week.';

  @override
  String get coachNotesReadThis => 'Read your notes on this week.';

  @override
  String coachWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get coachPromptLine =>
      'See what\'s working, what\'s holding you back, and get personal tips on how to improve.';

  @override
  String get recipesTitle => 'Recipes';

  @override
  String get recipesErrorLoad => 'Could not load the recipes.';

  @override
  String get recipesSearchHint => 'Search recipes or ingredients';

  @override
  String get recipesClear => 'Clear';

  @override
  String get recipesCookedRecently => 'Cooked recently';

  @override
  String get recipesAll => 'All';

  @override
  String get recipesBreakfast => 'Breakfast';

  @override
  String get recipesLunch => 'Lunch';

  @override
  String get recipesDinner => 'Dinner';

  @override
  String get recipesSnack => 'Snack';

  @override
  String get recipesEmpty => 'No recipes here yet.';

  @override
  String get recipesNoMatch => 'No recipes match that. Try other words.';

  @override
  String get recipesLogPortion => 'Log a portion';

  @override
  String recipesKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String recipesProtein(int grams) {
    return '$grams g protein';
  }

  @override
  String recipesMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get recipesRecipeTitle => 'Recipe';

  @override
  String get recipesErrorLoadOne => 'Could not load the recipe.';

  @override
  String recipesPerPortion(int kcal) {
    return '$kcal kcal per portion';
  }

  @override
  String recipesPerPortionProtein(int kcal, int protein) {
    return '$kcal kcal · $protein g protein per portion';
  }

  @override
  String get recipesPrep => 'Prep';

  @override
  String get recipesCook => 'Cook';

  @override
  String get recipesServes => 'Serves';

  @override
  String get recipesNoCooking => 'None';

  @override
  String get recipesIngredients => 'Ingredients';

  @override
  String recipesForPortions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'For $count portions',
      one: 'For 1 portion',
    );
    return '$_temp0';
  }

  @override
  String get recipesHowToMake => 'How to make it';

  @override
  String get recipesHowMany => 'How many portions?';

  @override
  String get recipesLess => 'Less';

  @override
  String get recipesMore => 'More';

  @override
  String get recipesLog => 'Log';

  @override
  String get recipesErrorLog => 'Could not log the meal. Try again.';

  @override
  String recipesLogged(String meal) {
    return '$meal logged.';
  }

  @override
  String get notificationsDenied =>
      'Allow notifications for YumSum in system settings.';

  @override
  String get notificationsMeal => 'Daily meal reminder';

  @override
  String notificationsMealTime(String time) {
    return 'Every evening at $time';
  }

  @override
  String get notificationsWeight => 'Weigh-in reminder';

  @override
  String notificationsEveryDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String notificationsWeeklyAt(String day, String time) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'monday': 'Mondays at $time',
      'tuesday': 'Tuesdays at $time',
      'wednesday': 'Wednesdays at $time',
      'thursday': 'Thursdays at $time',
      'friday': 'Fridays at $time',
      'saturday': 'Saturdays at $time',
      'other': 'Sundays at $time',
    });
    return '$_temp0';
  }

  @override
  String get notificationsEveryDay => 'Every day';

  @override
  String get notificationsCreatine => 'Daily creatine reminder';

  @override
  String get starBecome => 'Become a Star';

  @override
  String get starHeaderPitch => 'Shine bright with these smart perks.';

  @override
  String get starHeaderMember => 'Everything here is yours.';

  @override
  String get starFeatureSnapTitle => 'Smart Snap';

  @override
  String get starFeatureSnapBody => 'Capture your meal. The AI does the rest.';

  @override
  String get starFeatureEstimatesTitle => 'Triple the AI estimates';

  @override
  String get starFeatureEstimatesBody => '30 a day, so you never run out.';

  @override
  String get starFeatureAdaptiveTitle => 'Adaptive Formula';

  @override
  String get starFeatureAdaptiveBody =>
      'Learns your real burn and tunes your target.';

  @override
  String get starFeatureCoachTitle => 'AI Coach';

  @override
  String get starFeatureCoachBody =>
      'Reads your week and tells you how to do better.';

  @override
  String get starFeatureMacrosTitle => 'Detailed Macros';

  @override
  String get starFeatureMacrosBody =>
      'The full label: fat, carbs, sugars, fibre, salt.';

  @override
  String get starYearly => 'Yearly';

  @override
  String get starMonthly => 'Monthly';

  @override
  String get starPerYear => 'a year';

  @override
  String get starPerMonth => 'a month';

  @override
  String starMonthlyEquivalent(String price) {
    return '$price a month';
  }

  @override
  String starSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get starChecking => 'Checking with Google Play';

  @override
  String get starSubscribe => 'Subscribe';

  @override
  String starStartTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Start $days days free',
      one: 'Start 1 day free',
    );
    return '$_temp0';
  }

  @override
  String starTermsYearly(String price) {
    return '$price a year. Renews every year until you cancel. Cancel any time in Google Play.';
  }

  @override
  String starTermsMonthly(String price) {
    return '$price a month. Renews every month until you cancel. Cancel any time in Google Play.';
  }

  @override
  String starTrialTermsYearly(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days days free, then $price a year. Renews every year until you cancel. Cancel any time in Google Play.',
      one:
          '1 day free, then $price a year. Renews every year until you cancel. Cancel any time in Google Play.',
    );
    return '$_temp0';
  }

  @override
  String starTrialTermsMonthly(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days days free, then $price a month. Renews every month until you cancel. Cancel any time in Google Play.',
      one:
          '1 day free, then $price a month. Renews every month until you cancel. Cancel any time in Google Play.',
    );
    return '$_temp0';
  }

  @override
  String get starOk => 'OK';

  @override
  String get starOn => 'YumSum Star is on.';

  @override
  String starOnTrial(String date) {
    return 'YumSum Star is on. Your free week ends on $date.';
  }

  @override
  String get starAlreadyTitle => 'You\'re already a bright YumSum Star';

  @override
  String get starThanks => 'Thank you for helping YumSum grow.';

  @override
  String get starWeb =>
      'Subscribe in the YumSum app for Android. YumSum Star then works here too, when you sign in with the same account.';

  @override
  String get starNoIphone => 'YumSum Star can\'t be bought on iPhone yet.';

  @override
  String get starTryAgain => 'Try again';

  @override
  String get starRestore => 'Restore purchase';

  @override
  String get starTerms => 'Terms';

  @override
  String get starPrivacy => 'Privacy';

  @override
  String get starClose => 'Close';

  @override
  String get starStatusPitch => 'Smart Snap, 30 AI estimates a day and more';

  @override
  String get starStatusHold =>
      'Off until the payment problem is fixed in Google Play';

  @override
  String get starStatusAdmin => 'Admin: everything on, no daily limits';

  @override
  String get starStatusOn => 'On';

  @override
  String starStatusOnUntil(String date) {
    return 'On until $date';
  }

  @override
  String starStatusTrial(String date) {
    return 'Free trial until $date';
  }

  @override
  String starStatusEnds(String date) {
    return 'Ends on $date';
  }

  @override
  String starStatusRenews(String date) {
    return 'Renews on $date';
  }

  @override
  String get starStatusGrace =>
      'Payment problem. Fix it in Google Play to keep YumSum Star.';

  @override
  String get starErrorPlay =>
      'Could not reach Google Play. Check your connection and try again.';

  @override
  String get starErrorNotConfirmed =>
      'Could not confirm your purchase. Try Restore purchase in a few minutes. If it still fails, Google Play refunds you automatically within 3 days.';

  @override
  String get starErrorOtherAccount =>
      'This Google Play subscription is linked to another YumSum account. Sign in with that account to use it.';

  @override
  String get starNothingToRestore =>
      'No YumSum Star subscription found on this Google account.';

  @override
  String get starPaymentPending =>
      'Google Play is waiting for your payment. YumSum Star switches on once it goes through.';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonSigningOut => 'Signing out...';

  @override
  String get commonEnterPassword => 'Enter your password.';

  @override
  String get commonEnterValidEmail => 'Enter a valid email.';

  @override
  String get commonEnterValidEmailAddress => 'Enter a valid email address.';

  @override
  String get commonErrorTooManyAttempts =>
      'Too many attempts. Try again later.';

  @override
  String get authSignInTab => 'Sign in';

  @override
  String get authSignUpTab => 'Sign up';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authEnterEmail => 'Enter your email.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordNeedsEmail =>
      'Enter your email above first, then tap Forgot password.';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authVerificationSentTitle => 'Verification email sent';

  @override
  String authVerificationSentBody(String email) {
    return 'We sent a link to $email. Open it to verify your account, then sign in.';
  }

  @override
  String get authResetSentTitle => 'Password reset email sent.';

  @override
  String authResetSentBody(String email) {
    return 'We sent a link to $email. Open it to choose a new password, then sign in.';
  }

  @override
  String get authErrorVerifyEmail =>
      'Verify your email first. Check your inbox for the link.';

  @override
  String get authErrorGoogle => 'Google sign-in didn\'t work. Try again.';

  @override
  String get authErrorUsePassword =>
      'This email already has a password. Sign in with it instead.';

  @override
  String get authErrorWrongCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get authErrorNoInternet => 'No internet connection. Try again.';

  @override
  String get authErrorGeneric => 'Something went wrong. Try again.';

  @override
  String legalAgreement(String terms, String privacy) {
    return 'By continuing you agree to the $terms and $privacy.';
  }

  @override
  String get legalTermsOfUse => 'Terms of Use';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String legalRecaptcha(String privacy, String terms) {
    return 'Protected by reCAPTCHA Enterprise. Google\'s $privacy and $terms apply.';
  }

  @override
  String get legalGooglePrivacy => 'Privacy Policy';

  @override
  String get legalGoogleTerms => 'Terms of Service';

  @override
  String get legalMedicalNote =>
      'YumSum gives general estimates, not medical advice. Talk to a doctor or dietitian before changing your diet, especially if you have a health condition.';

  @override
  String get planActivitySedentary => 'Mostly sitting';

  @override
  String get planActivitySedentaryHint =>
      'Desk day, low steps, little standing.';

  @override
  String get planActivityLight => 'Light daily movement';

  @override
  String get planActivityLightHint => 'Some walking, errands, or light chores.';

  @override
  String get planActivityModerate => 'On feet often';

  @override
  String get planActivityModerateHint =>
      'Standing or walking for much of the day.';

  @override
  String get planActivityHigh => 'Physical job or high movement';

  @override
  String get planActivityHighHint =>
      'Manual work, high steps, or very active days.';

  @override
  String get planTrainingNone => 'No regular training';

  @override
  String get planTrainingNoneHint => 'No planned workouts most weeks.';

  @override
  String get planTrainingOneToTwo => '1 to 2 sessions/week';

  @override
  String get planTrainingOneToTwoHint =>
      'A couple of lifting, cardio, or sport days.';

  @override
  String get planTrainingThreeToFour => '3 to 4 sessions/week';

  @override
  String get planTrainingThreeToFourHint => 'Regular training most weeks.';

  @override
  String get planTrainingFivePlus => '5+ sessions/week';

  @override
  String get planTrainingFivePlusHint => 'Frequent structured workouts.';

  @override
  String planPaceSlow(String amount) {
    return 'Slow - $amount/week';
  }

  @override
  String get planPaceSlowHint =>
      'Gentle and easier to maintain over a longer period.';

  @override
  String planPaceModerate(String amount) {
    return 'Moderate - $amount/week';
  }

  @override
  String get planPaceModerateHint =>
      'Steady progress with a moderate calorie deficit.';

  @override
  String planPaceFast(String amount) {
    return 'Fast - $amount/week';
  }

  @override
  String get planPaceFastHint =>
      'Faster results, but more restrictive for most people.';

  @override
  String get planPaceMaintain => 'Maintain weight';

  @override
  String get planPaceMaintainHint =>
      'Keeps your calories around maintenance instead of creating a deficit.';

  @override
  String get profileErrorLoadTitle => 'Could not load your profile';

  @override
  String get profileErrorLoadBody => 'Check your connection and try again.';

  @override
  String get profileBackToSignIn => 'Back to sign in';

  @override
  String get accountTitle => 'Settings';

  @override
  String accountConfirmWithGoogle(String description) {
    return '$description You\'ll confirm with Google next.';
  }

  @override
  String get accountNameSaved => 'Name saved.';

  @override
  String get accountErrorSaveName => 'Could not save your name. Try again.';

  @override
  String get accountResetEmailSent => 'Password reset email sent.';

  @override
  String get accountErrorSendReset => 'Could not send reset email.';

  @override
  String get accountCheckNewEmail =>
      'Check your new email to confirm the change.';

  @override
  String get accountErrorChangeEmail =>
      'Could not change your email. Try again.';

  @override
  String get accountResetTitle => 'Reset all data?';

  @override
  String get accountResetBody =>
      'This deletes all your meals, weigh-ins and days off. Your account, profile and plan stay.';

  @override
  String get accountResetButton => 'Reset all data';

  @override
  String get accountResetDone => 'All logged data deleted.';

  @override
  String get accountErrorReset => 'Could not reset your data.';

  @override
  String get accountDeleteTitle => 'Delete account?';

  @override
  String get accountDeleteBody =>
      'This deletes your account and everything in it. It can\'t be undone.';

  @override
  String get accountDeleteBodyStar =>
      'This deletes your account and everything in it. It can\'t be undone. Deleting your account doesn\'t cancel YumSum Star. Cancel it in Google Play first, or it keeps renewing.';

  @override
  String get accountDeleteButton => 'Delete account';

  @override
  String get accountErrorDelete => 'Could not delete your account.';

  @override
  String get accountErrorLoad => 'Could not load your account.';

  @override
  String get accountHeading => 'Manage your account';

  @override
  String get accountSubtitle => 'Change your name, email or password.';

  @override
  String get accountSubtitleGoogle =>
      'Change your name. Google looks after your email and password.';

  @override
  String get accountSectionAccount => 'ACCOUNT';

  @override
  String get accountName => 'Name';

  @override
  String get accountEnterName => 'Enter your name.';

  @override
  String get accountChangeEmail => 'Change email';

  @override
  String get accountSaveName => 'Save name';

  @override
  String get accountSectionPassword => 'PASSWORD';

  @override
  String get accountSendReset => 'Send password reset email';

  @override
  String get accountSectionNotifications => 'NOTIFICATIONS';

  @override
  String get accountSectionAppearance => 'APPEARANCE';

  @override
  String get accountSectionLanguage => 'LANGUAGE';

  @override
  String get accountSectionStar => 'YUMSUM STAR';

  @override
  String get accountSectionHelp => 'HELP & LEGAL';

  @override
  String get accountSendFeedback => 'Send feedback';

  @override
  String get accountSendFeedbackHint => 'Write to the developer';

  @override
  String get accountPrivacyPolicy => 'Privacy policy';

  @override
  String get accountTerms => 'Terms of use';

  @override
  String get accountOpenFoodFacts => 'Food data from Open Food Facts';

  @override
  String get accountOpenFoodFactsHint =>
      'A free database built by volunteers, under the Open Database License';

  @override
  String get accountSectionDanger => 'DANGER ZONE';

  @override
  String get accountChangeEmailTitle => 'Change email';

  @override
  String get accountChangeEmailBody =>
      'We\'ll email a link to your new address. Your email changes once you open it.';

  @override
  String get accountNewEmail => 'New email';

  @override
  String get accountEnterNewEmail => 'Enter your new email.';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountShowPassword => 'Show password';

  @override
  String get accountHidePassword => 'Hide password';

  @override
  String get accountEnterCurrentPassword => 'Enter your current password.';

  @override
  String get accountSendLink => 'Send link';

  @override
  String get accountErrorSignedOut => 'You are not signed in.';

  @override
  String get accountErrorNoEmail =>
      'This account does not have an email address.';

  @override
  String get accountErrorEnterNewEmail => 'Enter a new email address.';

  @override
  String get accountErrorSameEmail => 'That\'s already your email.';

  @override
  String get accountErrorWrongGoogle =>
      'Choose the Google account you signed in with.';

  @override
  String get accountErrorNoPassword =>
      'This account cannot confirm with a password.';

  @override
  String get accountErrorWrongPassword => 'Incorrect password.';

  @override
  String get accountErrorNoConnection =>
      'Could not connect. Check your internet and try again.';

  @override
  String get accountErrorEmailInUse =>
      'An account already uses that email address.';

  @override
  String get accountErrorConfirmPassword =>
      'Confirm your password and try again.';

  @override
  String get accountErrorVerifyPassword => 'Could not verify your password.';

  @override
  String get menuHome => 'Home';

  @override
  String get menuHistory => 'History';

  @override
  String get menuCoach => 'AI Coach';

  @override
  String get menuRecipes => 'Recipes';

  @override
  String get menuProgress => 'Weight & Progress';

  @override
  String get menuPlanSettings => 'Plan Settings';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuThemeSystem => 'System';

  @override
  String get menuThemeLight => 'Light';

  @override
  String get menuThemeDark => 'Dark';

  @override
  String get menuLogOut => 'Log out';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackSent => 'Feedback sent. Thank you.';

  @override
  String get feedbackKindProblem => 'Problem';

  @override
  String get feedbackKindIdea => 'Idea';

  @override
  String get feedbackKindOther => 'Other';

  @override
  String get feedbackHintProblem => 'What happened, and what did you expect?';

  @override
  String get feedbackHintIdea => 'What would make YumSum better for you?';

  @override
  String get feedbackHintOther => 'Anything at all';

  @override
  String feedbackRepliesTo(String email) {
    return 'Replies go to $email.';
  }

  @override
  String feedbackLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ve sent $count today. You can send more tomorrow.',
      one: 'You\'ve sent 1 today. You can send more tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get feedbackErrorSend => 'Could not send. Try again.';

  @override
  String get feedbackSending => 'Sending…';

  @override
  String get feedbackSend => 'Send';

  @override
  String get splashSlow => 'Taking longer than usual. Check your connection.';

  @override
  String get splashReload => 'Reload';

  @override
  String get splashTagline => 'Stay consistent. Stay lean.';

  @override
  String get startupErrorTitle => 'YumSum could not start';

  @override
  String get startupErrorBody =>
      'Refresh the page. If it keeps happening, send the message below to the developer.';

  @override
  String get shortcutLogVoice => 'Log by voice';

  @override
  String unitsKg(String value) {
    return '$value kg';
  }

  @override
  String unitsLb(String value) {
    return '$value lb';
  }

  @override
  String unitsStLb(int stones, int pounds) {
    return '$stones st $pounds lb';
  }

  @override
  String unitsCm(String value) {
    return '$value cm';
  }

  @override
  String unitsFtIn(int feet, int inches) {
    return '$feet ft $inches in';
  }

  @override
  String unitsStAxis(int stones) {
    return '$stones st';
  }

  @override
  String unitsStLbAxis(int stones, int pounds) {
    return '$stones st $pounds';
  }

  @override
  String get unitsKgLabel => 'kg';

  @override
  String get unitsLbLabel => 'lb';

  @override
  String get unitsStLabel => 'st';

  @override
  String get unitsCmLabel => 'cm';

  @override
  String get unitsFtLabel => 'ft';

  @override
  String get unitsInLabel => 'in';

  @override
  String get unitsMetricToggle => 'kg, cm';

  @override
  String get unitsLbFtToggle => 'lb, ft';

  @override
  String get unitsStFtToggle => 'st, ft';

  @override
  String get unitsPounds => 'Pounds';

  @override
  String get unitsInches => 'Inches';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonAge => 'Age';

  @override
  String get commonHeight => 'Height';

  @override
  String get commonCurrentWeight => 'Current weight';

  @override
  String get commonTargetWeight => 'Target weight';

  @override
  String get commonEnterAge => 'Enter your age.';

  @override
  String get commonAgeRange => 'Valid age: 18–120.';

  @override
  String get commonTargetBelowCurrent =>
      'Must be less than your current weight';

  @override
  String get commonMale => 'Male';

  @override
  String get commonFemale => 'Female';

  @override
  String get commonOther => 'Other';

  @override
  String get onboardingEnterHeight => 'Enter your height.';

  @override
  String get onboardingEnterWeight => 'Enter your weight.';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingName => 'Name';

  @override
  String get onboardingGenderTitle => 'Are you…';

  @override
  String get onboardingAgeTitle => 'How old are you?';

  @override
  String get onboardingHeightTitle => 'How tall are you?';

  @override
  String get onboardingWeightTitle => 'What do you weigh now?';

  @override
  String get onboardingGoalTitle => 'What\'s your goal?';

  @override
  String get onboardingGoalBody =>
      'A calorie is the energy in food. Eat a little less than your body burns and you lose weight, steadily and safely.';

  @override
  String get onboardingLoseWeight => 'Lose weight';

  @override
  String get onboardingKeepWeight => 'Keep my weight';

  @override
  String get onboardingTargetTitle => 'What weight are you aiming for?';

  @override
  String get onboardingActivityTitle => 'How active is your normal day?';

  @override
  String get onboardingActivityBody => 'Outside workouts.';

  @override
  String get onboardingTrainingTitle => 'Do you train on top of that?';

  @override
  String get onboardingTrainingBody => 'Structured workouts, if any.';

  @override
  String get onboardingProteinTitle => 'Track protein too?';

  @override
  String get onboardingProteinBody =>
      'Protein keeps you full and looks after your muscle. YumSum works it out for each meal you log.';

  @override
  String get onboardingPlanTitle => 'Your plan is ready!';

  @override
  String get onboardingPlanCardTitle => 'Your plan';

  @override
  String get onboardingPlanNote =>
      'You can go over all of this again, and get into more detail, in Plan Settings.';

  @override
  String get onboardingErrorSave => 'Something went wrong. Try again.';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get planPreviewMaintenance => 'Maintenance plan';

  @override
  String get planPreviewFloor => 'Minimum calorie floor';

  @override
  String get planPreviewSafe => 'Sustainable pace';

  @override
  String get planPreviewCaution => 'Faster pace';

  @override
  String get planPreviewWarning => 'Very aggressive';

  @override
  String get planPreviewMaintenanceNote => 'No calorie deficit is applied.';

  @override
  String get planPreviewFloorNote =>
      'This pace would go below the minimum, so the goal date moves later.';

  @override
  String get planPreviewSafeNote =>
      'A moderate deficit from estimated maintenance.';

  @override
  String get planPreviewCautionNote =>
      'This needs consistency and may feel restrictive.';

  @override
  String get planPreviewWarningNote =>
      'Consider a slower pace if this feels hard to maintain.';

  @override
  String get planPreviewMaintain => 'Maintain';

  @override
  String planPreviewPerWeek(String amount) {
    return '$amount/wk';
  }

  @override
  String get planPreviewDailyTarget => 'Daily target';

  @override
  String get planPreviewWeeklyLoss => 'Weekly loss';

  @override
  String get planPreviewGoalBy => 'Goal by';

  @override
  String get planPreviewInfoTooltip => 'How this is calculated';

  @override
  String get planInfoTitle => 'How calories are estimated';

  @override
  String get planInfoBody =>
      'First we estimate your resting burn from weight, height, age, and sex. Then we add your daily movement and training to estimate maintenance.';

  @override
  String get planInfoResting => 'Resting burn';

  @override
  String get planInfoMovement => 'Daily movement';

  @override
  String get planInfoTraining => 'Training bonus';

  @override
  String get planInfoActivity => 'Combined activity';

  @override
  String get planInfoMaintenance => 'Maintenance';

  @override
  String get planInfoAdaptive => 'Adaptive';

  @override
  String get planInfoTarget => 'Target';

  @override
  String planInfoKcalPerDay(int kcal) {
    return '$kcal kcal/day';
  }

  @override
  String planInfoAtMinimum(int kcal) {
    return '$kcal kcal/day, your minimum';
  }

  @override
  String get planInfoFloorNote =>
      'This pace would go below the minimum, so your target stays at the minimum and the goal date moves later.';

  @override
  String get planTitle => 'Plan Settings';

  @override
  String get planErrorLoad => 'Could not load your profile.';

  @override
  String get planSelectGender => 'Select your gender.';

  @override
  String get planSaved => 'Plan saved.';

  @override
  String get planErrorSave => 'Could not save your plan. Try again.';

  @override
  String get planRequired => 'Required';

  @override
  String get planHeading => 'Update your health plan';

  @override
  String get planSubtitle =>
      'Change anything below and your plan adjusts to match.';

  @override
  String get planSectionPersonal => 'PERSONAL DETAILS';

  @override
  String get planGender => 'Gender';

  @override
  String get planSectionUnits => 'UNITS';

  @override
  String get planSectionBody => 'YOUR BODY';

  @override
  String get planSectionBmi => 'YOUR BMI';

  @override
  String get planSectionGoal => 'YOUR GOAL';

  @override
  String get planTargetStays =>
      'Your target weight stays at your current weight.';

  @override
  String get planSectionMovement => 'YOUR DAILY MOVEMENT';

  @override
  String get planMovementNote => 'Your normal day outside workouts.';

  @override
  String get planSectionTraining => 'HOW OFTEN DO YOU TRAIN?';

  @override
  String get planTrainingNote =>
      'Structured workouts on top of your normal day.';

  @override
  String get planSectionProtein => 'TRACK PROTEIN TOO?';

  @override
  String get planProteinNote =>
      'Protein helps keep muscle while you lose weight. Off hides it everywhere.';

  @override
  String get planSectionPace => 'HOW FAST DO YOU WANT TO LOSE WEIGHT?';

  @override
  String get planPaceNote =>
      'Pace sets the calorie target. Target weight sets how long the plan takes.';

  @override
  String get planSectionAdjustment => 'PERSONAL ADJUSTMENT';

  @override
  String get planUpdatedPlan => 'Updated plan';

  @override
  String get planSave => 'Save plan';

  @override
  String get planAdaptiveNote =>
      'Learns from your weigh-ins and adjusts your target each Monday.';

  @override
  String get planAdaptiveRestarts =>
      'Saving starts it again from your new plan.';

  @override
  String get planBmiUnderweight => 'Underweight';

  @override
  String get planBmiHealthy => 'Healthy range';

  @override
  String get planBmiOverweight => 'Overweight';

  @override
  String get planBmiObese => 'Obese range';

  @override
  String get planBmiTitle => 'Your BMI';

  @override
  String get adaptiveTitle => 'Adaptive formula';

  @override
  String get adaptiveHowItWorks => 'How it works';

  @override
  String get adaptiveTryNote =>
      'A customised formula tailored just for you. Adapting with time and your weigh-ins.';

  @override
  String get adaptiveOn => 'On';

  @override
  String adaptiveBurnFact(String kcal) {
    return 'You burn $kcal a day';
  }

  @override
  String adaptiveTargetFact(String kcal) {
    return 'Your target is $kcal a day';
  }

  @override
  String get adaptiveBurnLearnt => 'Learnt from your weigh-ins and meals.';

  @override
  String get adaptiveBurnFirst =>
      'A first estimate. It learns as you weigh in.';

  @override
  String get adaptiveTargetKeep => 'To keep your weight steady.';

  @override
  String adaptiveTargetLose(String amount) {
    return 'To lose $amount a week.';
  }

  @override
  String get adaptivePaused =>
      'Paused: no weigh-in for 10 days. Weigh in to keep it personal.';

  @override
  String adaptiveAtMinimum(String date) {
    return 'Your target is at your minimum, so your goal date is now $date.';
  }

  @override
  String adaptiveLowered(String amount) {
    return 'Adjusted for you: $amount kcal. You burn a little less than your plan assumed.';
  }

  @override
  String adaptiveRaised(String amount) {
    return 'Adjusted for you: $amount kcal. You burn a little more than your plan assumed.';
  }

  @override
  String get adaptiveFirstSign =>
      'You may burn a little less than your plan assumed. Checking again next Monday.';

  @override
  String adaptiveSteadyAdjusted(String amount) {
    return 'Adjusted for you: $amount kcal. No change this week.';
  }

  @override
  String get adaptiveSteady =>
      'No change this week: your weight matches what you eat.';

  @override
  String get adaptiveFewWeighIns =>
      'Not enough weigh-ins this week, so your target stays the same.';

  @override
  String get adaptiveFewDays =>
      'Not enough days logged this week, so your target stays the same.';

  @override
  String get adaptiveUnusual =>
      'Your numbers look unusual. Check your logging and weigh-ins.';

  @override
  String adaptiveSum(int plan, String sign, int amount, int target) {
    return '$plan from your plan $sign $amount adaptive = $target kcal';
  }

  @override
  String adaptiveSumMinimum(int plan, String sign, int amount, int target) {
    return '$plan from your plan $sign $amount adaptive = $target kcal, your minimum';
  }

  @override
  String get progressTitle => 'Weight & Progress';

  @override
  String get progressLogWeight => 'Log weight';

  @override
  String get progressHistory => 'History';

  @override
  String get progressReset => 'Reset progress';

  @override
  String get progressErrorLoad => 'Could not load your weight history.';

  @override
  String progressSavedNewTarget(int kcal, int previous) {
    return 'Weight saved. New target: $kcal kcal (was $previous).';
  }

  @override
  String progressSavedSameTarget(int kcal) {
    return 'Weight saved. Your target stays at $kcal kcal.';
  }

  @override
  String get progressDeleteTitle => 'Delete weigh-in?';

  @override
  String progressDeleteBody(String weight, String date) {
    return 'Remove $weight from $date?';
  }

  @override
  String progressDeleteBodyBack(String weight, String date, String previous) {
    return 'Remove $weight from $date? Your plan adjusts back to $previous.';
  }

  @override
  String get progressErrorDelete => 'Could not delete the weigh-in. Try again.';

  @override
  String progressDeletedNewTarget(int kcal, int previous) {
    return 'Weigh-in deleted. New target: $kcal kcal (was $previous).';
  }

  @override
  String get progressDeleted => 'Weigh-in deleted.';

  @override
  String get progressResetTitle => 'Reset progress?';

  @override
  String get progressResetBody =>
      'This clears all your weight history and chart progress. Are you sure?';

  @override
  String get progressResetButton => 'Reset';

  @override
  String get progressResetDone => 'Weight history cleared.';

  @override
  String get progressErrorReset => 'Could not reset progress. Try again.';

  @override
  String get progressCurrent => 'Current';

  @override
  String get progressChange => 'Change';

  @override
  String get progressTarget => 'Target';

  @override
  String progressTrend(String weight) {
    return 'Trend $weight';
  }

  @override
  String get progressDeleteTooltip => 'Delete weigh-in';

  @override
  String get progressEmptyTitle => 'No weight logged yet';

  @override
  String get progressEmptyBody =>
      'Log your weight to see your progress. Your plan adjusts each time.';

  @override
  String get progressWeighInTitle => 'Log your weight';

  @override
  String get progressWeighInNote => 'Your plan adjusts to match.';

  @override
  String progressWeighInRange(String range) {
    return 'Enter a weight between $range.';
  }

  @override
  String get progressWeighInRangeAnd => ' and ';

  @override
  String get progressErrorSaveWeight =>
      'Could not save your weight. Try again.';

  @override
  String progressWeightSavedTarget(int kcal) {
    return 'Weight saved. New target: $kcal kcal.';
  }

  @override
  String get progressWeightSaved => 'Weight saved.';
}
