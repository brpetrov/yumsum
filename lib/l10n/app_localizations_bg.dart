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

  @override
  String get commonCancel => 'Отказ';

  @override
  String get commonDelete => 'Изтрий';

  @override
  String get commonEdit => 'Редактирай';

  @override
  String get commonSave => 'Запази';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonOk => 'Добре';

  @override
  String get commonClose => 'Затвори';

  @override
  String get commonTryAgain => 'Опитай отново';

  @override
  String get commonMaybeLater => 'По-късно';

  @override
  String get commonGotIt => 'Разбрах';

  @override
  String get commonBecomeStar => 'Стани Star';

  @override
  String commonKcal(int kcal) {
    return '$kcal ккал';
  }

  @override
  String get commonKcalUnit => 'ккал';

  @override
  String get commonGramsUnit => 'г';

  @override
  String commonGrams(String grams) {
    return '$grams г';
  }

  @override
  String commonKcalProtein(int kcal, int protein) {
    return '$kcal ккал · $protein г протеин';
  }

  @override
  String get homeTitle => 'Начало';

  @override
  String get homeErrorProfile => 'Не успяхме да заредим профила ти.';

  @override
  String get homeErrorMeals => 'Не успяхме да заредим храненията ти.';

  @override
  String get homeErrorMonth => 'Не успяхме да заредим месеца.';

  @override
  String get homeDeleteMealTitle => 'Да изтрием ли храненето?';

  @override
  String get homeDeleteMealBody => 'Ще изчезне от днешния ден.';

  @override
  String get homeErrorDelete =>
      'Не успяхме да изтрием храненето. Опитай отново.';

  @override
  String get homeDayOff => 'Почивен ден';

  @override
  String get homeDayOffTake => 'Вземи почивен ден';

  @override
  String get homeErrorDayOff =>
      'Не успяхме да сменим почивния ден. Опитай отново.';

  @override
  String get homeOnTrack => 'В норма';

  @override
  String get homeOverTarget => 'Над целта';

  @override
  String get homeKcalLeft => 'ккал остават';

  @override
  String get homeKcalOver => 'ккал в повече';

  @override
  String homeKcalEaten(int eaten, int target) {
    return 'Изядени $eaten от $target ккал';
  }

  @override
  String get homeTargetsTooltip => 'За целите ти';

  @override
  String get homeMealsTitle => 'Храненията днес';

  @override
  String homeMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записани',
      one: '1 записано',
    );
    return '$_temp0';
  }

  @override
  String get homeNothingLogged =>
      'Още няма записани хранения. Напиши или натисни микрофона отдолу.';

  @override
  String get homeHistory => 'История';

  @override
  String get homeNoDaysThisMonth => 'Този месец още няма записани дни.';

  @override
  String homeDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записани дни',
      one: '1 записан ден',
    );
    return '$_temp0';
  }

  @override
  String get homeWeight => 'Тегло';

  @override
  String get homeWeightEmpty => 'Записвай теглото си, за да следиш напредъка';

  @override
  String homeWeightLatest(String weight) {
    return 'Последно: $weight';
  }

  @override
  String homeWeightLatestAgo(String weight, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Последно: $weight · преди $days дни',
      one: 'Последно: $weight · преди 1 ден',
    );
    return '$_temp0';
  }

  @override
  String get homeWeightLog => 'Запиши';

  @override
  String get homeStarPitch =>
      'Smart Snap, адаптивна формула, AI треньор и подробни макроси.';

  @override
  String get homeStarHide => 'Скрий засега';

  @override
  String get homeCreatineTitle => 'Приемаш ли креатин?';

  @override
  String homeCreatineBody(String time) {
    return 'Получавай напомняне всеки ден в $time. Часа можеш да смениш по-късно.';
  }

  @override
  String get homeCreatineNo => 'Не, благодаря';

  @override
  String get homeCreatineYes => 'Напомняй ми';

  @override
  String homeCreatineOn(String time) {
    return 'Напомнянето за креатин е за $time. Можеш да го смениш от „Известия“ в менюто.';
  }

  @override
  String get homeCreatineBlocked =>
      'Разреши известията в настройките на телефона, после го включи от „Известия“ в менюто.';

  @override
  String get homeCreatineLater =>
      'Можеш да го включиш по всяко време от „Известия“ в менюто.';

  @override
  String get homeDayOffBackTitle => 'Обратно към плана?';

  @override
  String get homeDayOffTakeTitle => 'Почивен ден днес?';

  @override
  String get homeDayOffBackBody =>
      'Днешният ден отново ще се сравнява с целта ти.';

  @override
  String get homeDayOffIntro => 'За празници и вечери навън.';

  @override
  String get homeDayOffLog => 'Записвай храненията си както обикновено.';

  @override
  String get homeDayOffNoColours => 'Днес без зелено, жълто и червено.';

  @override
  String get homeDayOffHistory => 'Не се брои в „История“.';

  @override
  String get homeDayOffUndo => 'Натисни чадъра, за да отмениш.';

  @override
  String get homeDayOffBackButton => 'Обратно към плана';

  @override
  String get homeDayOffTakeButton => 'Почивен ден';

  @override
  String get adaptiveIntroTitle => 'Калории по твоя мярка';

  @override
  String get adaptiveIntroSubtitle =>
      'Яж с повече увереност – с умна формула, която всяка седмица се настройва към теб.';

  @override
  String get adaptiveIntroBurnTitle => 'Разбери колко гориш';

  @override
  String get adaptiveIntroBurnBody =>
      'Записаните хранения и теглото ти показват колко калории гориш на ден, така че целта ти вече не е на око.';

  @override
  String get adaptiveIntroBodyTitle => 'Според твоето тяло';

  @override
  String get adaptiveIntroBodyBody =>
      'Целта ти се оформя според това как реално реагира тялото ти, за да откриеш какво работи при теб.';

  @override
  String get adaptiveIntroChangeTitle => 'Напредвай, докато се променяш';

  @override
  String get adaptiveIntroChangeBody =>
      'Нуждата ти от калории се променя, докато сваляш килограми. Целта ти се настройва, за да продължиш да напредваш.';

  @override
  String get adaptiveIntroWeighTitle => 'Всяко претегляне е важно';

  @override
  String get adaptiveIntroWeighBody =>
      'Всяко претегляне допълва картината. Редовните записи прецизират целта ти с времето.';

  @override
  String get adaptiveIntroLogWeight => 'Запиши теглото';

  @override
  String get adaptiveLapseTitle => 'Твоят YumSum Star приключи';

  @override
  String adaptiveLapseBody(String date) {
    return 'На $date целта ти се връща към стандартния план.';
  }

  @override
  String quickLogLimit(int limit) {
    return 'Днешните $limit AI оценки са изчерпани. Въведи калориите ръчно.';
  }

  @override
  String get quickLogErrorSave =>
      'Не успяхме да запазим храненето. Опитай отново.';

  @override
  String get quickLogAllowMic =>
      'Разреши достъп до микрофона, за да записваш с глас.';

  @override
  String get quickLogErrorRecord =>
      'Не успяхме да започнем записа. Опитай отново.';

  @override
  String get quickLogMisTap => 'Не те чух. Натисни микрофона и опитай пак.';

  @override
  String get quickLogNoCalories =>
      'Open Food Facts още няма калории за този продукт. Вместо това снимай опаковката.';

  @override
  String get quickLogNotListed =>
      'Този продукт го няма в Open Food Facts. Вместо това снимай опаковката.';

  @override
  String quickLogAiLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'За днес остават $count AI оценки',
      one: 'За днес остава 1 AI оценка',
      zero: 'За днес не остават AI оценки',
    );
    return '$_temp0';
  }

  @override
  String get quickLogHint => 'Какво хапна?';

  @override
  String get quickLogClear => 'Изчисти';

  @override
  String get quickLogProteinHint => 'протеин (г)';

  @override
  String get quickLogProteinUnit => 'г протеин';

  @override
  String get quickLogSearchFoods => 'Търси храни';

  @override
  String quickLogChip(String name, int kcal) {
    return '$name · $kcal ккал';
  }

  @override
  String get quickLogStop => 'Спри';

  @override
  String get quickLogPhoto => 'Снимай';

  @override
  String get quickLogBarcode => 'Сканирай баркод';

  @override
  String get quickLogSpeak => 'Говори';

  @override
  String get quickLogEstimate => 'Изчисли';

  @override
  String get quickLogListening => 'Слушам… Натисни стоп, когато приключиш.';

  @override
  String get quickLogWorking => 'Момент…';

  @override
  String get mealAiOff => 'AI оценките още не са включени.';

  @override
  String get mealAiBusy => 'AI е зает в момента. Опитай пак след минута.';

  @override
  String get mealAiPaused =>
      'AI оценките са спрени засега. Пак можеш да въведеш калориите ръчно.';

  @override
  String get mealAiBusyShort => 'AI е зает. Опитай пак след няколко секунди.';

  @override
  String get mealAiNoStar =>
      'YumSum Star не е включен за този профил. Опитай отново.';

  @override
  String get mealAiErrorEstimate =>
      'Не успяхме да изчислим калориите. Опитай отново.';

  @override
  String get mealAiNoMeal =>
      'Не чухме хранене в записа. Натисни микрофона и опитай пак.';

  @override
  String get mealAiErrorVoice =>
      'Не успяхме да разберем записа. Опитай отново.';

  @override
  String get mealAiNoFood =>
      'Не открихме храна на снимката. Опитай пак с чинията в кадър.';

  @override
  String get mealAiErrorPhoto =>
      'Не успяхме да разчетем снимката. Опитай отново.';

  @override
  String get mealAiNoLabel =>
      'На снимките не се вижда етикет. Попълни данните ръчно.';

  @override
  String get mealAiLimit =>
      'Дневният лимит за AI е изчерпан. Въведи калориите ръчно.';

  @override
  String get mealErrorAi => 'Не успяхме да се свържем с AI. Опитай отново.';

  @override
  String get mealErrorNoCalories => 'Въведи калориите или ги изчисли.';

  @override
  String get mealErrorEditLimit =>
      'Промените по минали дни за този месец свършиха.';

  @override
  String get mealErrorSave => 'Не успяхме да запазим храненето. Опитай отново.';

  @override
  String get mealEditTitle => 'Редактирай храненето';

  @override
  String get mealAddTitle => 'Добави хранене';

  @override
  String get mealName => 'Хранене';

  @override
  String get mealNameHint => 'напр. мусака, баница';

  @override
  String get mealCalories => 'Калории';

  @override
  String get mealProtein => 'Протеин';

  @override
  String get mealProteinNote =>
      'Остави протеина празен и ще го изчислим по името.';

  @override
  String get mealEstimateFromName => 'Изчисли по името';

  @override
  String get mealSaveChanges => 'Запази промените';

  @override
  String get mealSave => 'Запази храненето';

  @override
  String get mealUnnamed => 'Хранене без име';

  @override
  String get mealNutrition => 'Стойности';

  @override
  String mealProteinGrams(int grams) {
    return '$grams г протеин';
  }

  @override
  String get mealOptions => 'Опции за храненето';

  @override
  String get mealTapWeight => 'Натисни грамажа, за да го промениш.';

  @override
  String get mealWeight => 'Грамаж';

  @override
  String get mealUseWeight => 'Приложи';

  @override
  String mealKcalGrams(int kcal, int grams) {
    return '$kcal ккал · $grams г';
  }

  @override
  String get mealChoiceTitle => 'Кое точно беше?';

  @override
  String get mealChoiceNote => 'Избрахме първото.';

  @override
  String get cameraNotFound => 'Не открихме камера.';

  @override
  String get cameraCouldNotStart => 'Камерата не успя да се включи.';

  @override
  String get cameraAllowWeb =>
      'Разреши достъп до камерата в браузъра, за да сканираш баркодове и да снимаш.';

  @override
  String get cameraAllowApp =>
      'Разреши достъп до камерата, за да сканираш баркодове и да снимаш. Ако по-рано е отказан, включи го от настройките на телефона.';

  @override
  String get cameraErrorReader =>
      'Не успяхме да пуснем четеца на баркодове. Опитай отново.';

  @override
  String get cameraErrorPhoto =>
      'Не успяхме да направим снимката. Опитай отново.';

  @override
  String get cameraChoosePhoto => 'Избери готова снимка';

  @override
  String get cameraTakePhoto => 'Снимай';

  @override
  String cameraStep(int number, int total) {
    return 'Стъпка $number от $total';
  }

  @override
  String get cameraBarcodeTitle => 'Насочи към баркода';

  @override
  String get cameraBarcodeTip => 'Дръж го в рамката и ще се прочете сам.';

  @override
  String get cameraMealTitle => 'Снимай храната си';

  @override
  String get cameraMealTip => 'Отгоре, с цялата чиния в кадър.';

  @override
  String get cameraFrontTitle => 'Снимай опаковката отпред';

  @override
  String get cameraFrontTip =>
      'Да се вижда цялата предна страна, заедно с името.';

  @override
  String get cameraTableTitle => 'Снимай таблицата с хранителните стойности';

  @override
  String get cameraTableTip =>
      'Таблицата да изпълва кадъра, изправена и на фокус, за да се чете всяко число.';

  @override
  String get cameraSmartSnap => 'Smart Snap';

  @override
  String get cameraSmartSnapSubtitle =>
      'Записването на храна – лесно колкото една снимка.';

  @override
  String get cameraSmartSnapSkipTitle => 'Без ръчно въвеждане';

  @override
  String get cameraSmartSnapSkipBody =>
      'Снимай чинията и AI ще разпознае храната, с приблизителни калории и макроси за всяка съставка.';

  @override
  String get cameraSmartSnapControlTitle => 'Последната дума е твоя';

  @override
  String get cameraSmartSnapControlBody =>
      'Прегледай храненето, промени каквото трябва и запази, когато всичко е наред.';

  @override
  String get foodSearchSource => 'Пакетирани храни · Open Food Facts';

  @override
  String get foodSearchError => 'Не успяхме да потърсим в момента.';

  @override
  String get foodSearchEmpty =>
      'Нищо не открихме. Опитай с други думи или остави AI да го изчисли.';

  @override
  String foodPer100g(int kcal) {
    return '$kcal ккал на 100 г';
  }

  @override
  String foodPortionSource(String amounts) {
    return '$amounts на 100 г · Open Food Facts';
  }

  @override
  String get foodPortionAmount => 'Количество';

  @override
  String get foodErrorNotAnswering => 'Базата с храни не отговаря в момента.';

  @override
  String get foodErrorOffline =>
      'Няма връзка с базата с храни. Провери интернета си.';

  @override
  String get contributeAddNutritionTitle => 'Добави хранителните стойности';

  @override
  String get contributeAddProductTitle => 'Добави продукта в базата';

  @override
  String get contributeAddNutritionBody =>
      'Продуктът е в базата, но без хранителни стойности. Добави ги с една снимка на таблицата и ще са там за теб и за всеки, който го сканира след теб.';

  @override
  String get contributeAddProductBody =>
      'Продуктът още не е в базата. Добави го с две снимки и ще е там за теб и за всеки, който го сканира след теб.';

  @override
  String get contributeTakesSeconds =>
      'Отнема 30 секунди и помага на всички, завинаги ♥';

  @override
  String get contributeButton => 'Добави';

  @override
  String get contributeNotNow => 'Не сега';

  @override
  String contributeAiRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'AI прочете данните от снимките. Сравни ги с опаковката: ще бъдат публични.',
      one:
          'AI прочете данните от снимката. Сравни ги с опаковката: ще бъдат публични.',
    );
    return '$_temp0';
  }

  @override
  String get contributeAiLimit =>
      'Дневният лимит за AI е изчерпан. Препиши данните от опаковката.';

  @override
  String get contributeErrorRead =>
      'Не успяхме да прочетем етикета. Попълни данните ръчно.';

  @override
  String get contributeNotSignedIn => 'Влез отново в профила си.';

  @override
  String get contributeErrorMissing =>
      'Добави името на продукта и енергията (ккал).';

  @override
  String get contributeEnergy => 'Енергия (ккал)';

  @override
  String get contributeProtein => 'Протеин (г)';

  @override
  String get contributeFat => 'Мазнини (г)';

  @override
  String get contributeSaturates => 'от които наситени (г)';

  @override
  String get contributeCarbs => 'Въглехидрати (г)';

  @override
  String get contributeSugars => 'от които захари (г)';

  @override
  String get contributeFibre => 'Фибри (г)';

  @override
  String get contributeSalt => 'Сол (г)';

  @override
  String get contributeThanks => 'Благодарим ти!';

  @override
  String contributeThanksProduct(String product) {
    return '$product вече е в Open Food Facts за всеки, който го сканира след теб.';
  }

  @override
  String contributeThanksNutrition(String product) {
    return '$product вече има хранителни стойности в Open Food Facts за всеки, който го сканира след теб.';
  }

  @override
  String contributeThanksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Това са вече $count продукта от теб.',
      one: 'Това е 1 продукт от теб.',
    );
    return '$_temp0';
  }

  @override
  String get contributeLogIt => 'Запиши го';

  @override
  String get contributeCheckDetails => 'Провери данните';

  @override
  String get contributeCheckNutrition => 'Провери стойностите';

  @override
  String contributeBarcode(String barcode) {
    return 'Баркод $barcode';
  }

  @override
  String get contributeReading => 'Четем етикета…';

  @override
  String get contributeProductName => 'Име на продукта';

  @override
  String get contributeBrand => 'Марка';

  @override
  String get contributePackSize => 'Опаковка, напр. 400 g';

  @override
  String get contributeServing => 'Порция, напр. 30 g';

  @override
  String get contributePer100 => 'НА 100 Г (ИЛИ 100 МЛ)';

  @override
  String get contributePublishNew =>
      'Снимките и данните ще бъдат публикувани в Open Food Facts под свободни лицензи (CC BY-SA и ODbL), за да може всеки да ги ползва. Името и имейлът ти никога не се споделят.';

  @override
  String get contributePublishFigures =>
      'Стойностите ще бъдат публикувани в Open Food Facts под свободни лицензи (CC BY-SA и ODbL), за да може всеки да ги ползва. Името и имейлът ти никога не се споделят.';

  @override
  String get contributePublishPhoto =>
      'Снимката и стойностите ще бъдат публикувани в Open Food Facts под свободни лицензи (CC BY-SA и ODbL), за да може всеки да ги ползва. Името и имейлът ти никога не се споделят.';

  @override
  String get contributeErrorLimit =>
      'Стигна дневния лимит. Утре можеш да изпратиш още.';

  @override
  String get contributeErrorRejected =>
      'Open Food Facts не го прие. Опитай отново след малко.';

  @override
  String get contributeErrorOffline =>
      'Няма връзка с Open Food Facts. Провери интернета си и опитай отново.';

  @override
  String get macroProtein => 'Протеин';

  @override
  String get macroCarbs => 'Въглехидрати';

  @override
  String get macroFat => 'Мазнини';

  @override
  String get macroFibre => 'Фибри';

  @override
  String get macroSugars => 'Захари';

  @override
  String get macroSaturates => 'Наситени мазнини';

  @override
  String get macroSalt => 'Сол';

  @override
  String get macroRingCarbs => 'Въглехидр.';

  @override
  String get macroRingSaturates => 'Наситени';

  @override
  String macroRingMax(int grams) {
    return 'макс. $grams г';
  }

  @override
  String macroRingOf(int grams) {
    return 'от $grams г';
  }

  @override
  String macroNotCountedProtein(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хранения не са отчетени (няма данни за протеин)',
      one: '1 хранене не е отчетено (няма данни за протеин)',
    );
    return '$_temp0';
  }

  @override
  String macroNotCountedMacros(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хранения не са отчетени (няма данни за макроси)',
      one: '1 хранене не е отчетено (няма данни за макроси)',
    );
    return '$_temp0';
  }

  @override
  String get macroUnlockLabel => 'Отключи всички макроси с YumSum Star';

  @override
  String get macroUnlock => 'Отключи макроси';

  @override
  String get macroNoneToday => 'Няма данни за макроси в днешните хранения';

  @override
  String get macroAbout => 'За макросите';

  @override
  String macroAtLeast(String grams) {
    return 'поне $grams';
  }

  @override
  String get macroGuideTargets => 'Твоите цели';

  @override
  String get macroGuideMacros => 'Твоите макроси';

  @override
  String get macroGuideIntro =>
      'Целите идват от плана ти, така че се променят заедно с него.';

  @override
  String get macroGuideCalories => 'Калории';

  @override
  String get macroGuideCaloriesWhy =>
      'Енергията в храната. Яж по-малко, отколкото гориш, и ще отслабваш.';

  @override
  String get macroGuideCaloriesTarget =>
      'Колкото гориш на ден според възрастта, ръста, теглото и активността ти, минус малко, ако отслабваш.';

  @override
  String get macroGuideAimFor => 'Стреми се към';

  @override
  String get macroGuideBalance => 'Дръж в баланс';

  @override
  String get macroGuideKeepUnder => 'Не надвишавай';

  @override
  String get macroGuideKeepUnderNote =>
      'Дръж ги под посочените количества. Превишаването ден след ден вреди на зъбите, сърцето и кръвното.';

  @override
  String get macroGuideProteinWhy =>
      'Засища и пази мускулите, докато гориш мазнини.';

  @override
  String get macroGuideProteinTarget =>
      'От 1,2 до 2 г на кг от желаното тегло – повече, колкото повече тренираш.';

  @override
  String get macroGuideFibreWhy => 'Засищат и поддържат червата здрави.';

  @override
  String get macroGuideFibreTarget => 'Поне 30 г на ден.';

  @override
  String get macroGuideCarbsWhy =>
      'Основното ти гориво: хляб, ориз, паста, картофи и плодове.';

  @override
  String get macroGuideCarbsTarget =>
      'Каквото остане след протеина и мазнините.';

  @override
  String get macroGuideFatWhy =>
      'Енергия, а и помагат за усвояването на витамините.';

  @override
  String get macroGuideFatTarget => 'Около 30% от калориите ти.';

  @override
  String get macroGuideSugarsWhy =>
      'Калории, които не засищат и вредят на зъбите.';

  @override
  String get macroGuideSugarsTarget => 'Под 18% от калориите ти.';

  @override
  String get macroGuideSaturatesWhy =>
      'Вдигат холестерола: масло, сирене, тлъсто месо и сладкиши.';

  @override
  String get macroGuideSaturatesTarget => 'Под 10% от калориите ти.';

  @override
  String get macroGuideSaltWhy =>
      'Вдига кръвното. Повечето е скрита в хляба, сиренето и готовите храни.';

  @override
  String get macroGuideSaltTarget =>
      'Под 6 г на ден – около една чаена лъжичка.';

  @override
  String get macroGuideTarget => 'Цел: ';

  @override
  String get macroGuideDisclaimer =>
      'Общи насоки за възрастни, не медицински съвет.';

  @override
  String get macroFibreBadge => 'Много фибри';
}
