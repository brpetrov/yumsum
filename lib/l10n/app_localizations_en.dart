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
    return 'Creatine reminder on for $time. Change it under Notifications in the menu.';
  }

  @override
  String get homeCreatineBlocked =>
      'Allow notifications in your phone\'s Settings, then turn it on under Notifications in the menu.';

  @override
  String get homeCreatineLater =>
      'You can turn it on any time under Notifications in the menu.';

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
}
