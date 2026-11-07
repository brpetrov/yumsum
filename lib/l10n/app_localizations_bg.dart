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
  String get reminderCreatineBody => 'Приеми днешната доза креатин.';

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
  String get commonBecomeStar => 'Отключи YumSum Star';

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
  String get homeDeleteMealBody => 'Да го премахнем ли от днешния ден?';

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
  String get homeOnTrack => 'В целта';

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
  String get homeMealsTitle => 'Днешни хранения';

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
    return 'Всеки ден в $time ще ти напомняме. Можеш да смениш часа по-късно.';
  }

  @override
  String get homeCreatineNo => 'Не, благодаря';

  @override
  String get homeCreatineYes => 'Напомняй ми';

  @override
  String homeCreatineOn(String time) {
    return 'Ще ти напомняме за креатин в $time. Можеш да го смениш от „Известия“ в настройките.';
  }

  @override
  String get homeCreatineBlocked =>
      'Разреши известията в настройките на телефона, после включи напомнянето от „Известия“ в настройките.';

  @override
  String get homeCreatineLater =>
      'Можеш да включиш напомнянето по всяко време от „Известия“ в настройките.';

  @override
  String get homeDayOffBackTitle => 'Обратно към плана?';

  @override
  String get homeDayOffTakeTitle => 'Почивен ден днес?';

  @override
  String get homeDayOffBackBody =>
      'Днешният ден отново ще се сравнява с целта ти.';

  @override
  String get homeDayOffIntro => 'За празници и излизания.';

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
  String get homeDayOffTakeButton => 'Вземи почивен ден';

  @override
  String get adaptiveIntroTitle => 'Калории по твоя мярка';

  @override
  String get adaptiveIntroSubtitle =>
      'Яж по-уверено с умна формула, която всяка седмица се настройва към теб.';

  @override
  String get adaptiveIntroBurnTitle => 'Разбери колко изгаряш';

  @override
  String get adaptiveIntroBurnBody =>
      'Записаните хранения и теглото ти показват колко калории изгаряш на ден, така че целта ти вече не е на око.';

  @override
  String get adaptiveIntroBodyTitle => 'Според твоето тяло';

  @override
  String get adaptiveIntroBodyBody =>
      'Целта ти се оформя според това как реално реагира тялото ти, за да откриеш какво работи при теб.';

  @override
  String get adaptiveIntroChangeTitle => 'Остани в целта, докато се променяш';

  @override
  String get adaptiveIntroChangeBody =>
      'Нуждата ти от калории се променя, докато сваляш килограми. Целта ти се настройва, за да продължиш да напредваш.';

  @override
  String get adaptiveIntroWeighTitle => 'Всяко претегляне е важно';

  @override
  String get adaptiveIntroWeighBody =>
      'Всяко претегляне допълва картината. Редовните записи прецизират целта ти с времето.';

  @override
  String get adaptiveIntroLogWeight => 'Запиши теглото си';

  @override
  String get adaptiveLapseTitle => 'Абонаментът ти за YumSum Star изтече';

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
  String get quickLogMisTap =>
      'Не успяхме да те чуем. Натисни микрофона и опитай отново.';

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
  String get quickLogHint => 'Добави хранене';

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
  String get quickLogListening => 'Слушам… Натисни „Спри“, когато приключиш.';

  @override
  String get quickLogWorking => 'Момент…';

  @override
  String get mealAiOff => 'AI оценките още не са включени.';

  @override
  String get mealAiBusy => 'AI е зает в момента. Опитай отново след минута.';

  @override
  String get mealAiPaused =>
      'AI оценките са спрени засега. Все още можеш да въведеш калориите ръчно.';

  @override
  String get mealAiBusyShort =>
      'AI е зает. Опитай отново след няколко секунди.';

  @override
  String get mealAiNoStar =>
      'YumSum Star не е включен за този профил. Опитай отново.';

  @override
  String get mealAiErrorEstimate =>
      'Не успяхме да изчислим калориите. Опитай отново.';

  @override
  String get mealAiNoMeal =>
      'Не разпознахме хранене в записа. Натисни микрофона и опитай отново.';

  @override
  String get mealAiErrorVoice =>
      'Не успяхме да разберем записа. Опитай отново.';

  @override
  String get mealAiNoFood =>
      'Не открихме храна на снимката. Опитай отново с цялата чиния в кадър.';

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
      'Този месец нямаш повече промени по минали дни.';

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
      'Разреши достъп до камерата, за да сканираш баркодове и да снимаш. Ако достъпът е бил отказан, включи го от настройките на телефона.';

  @override
  String get cameraErrorReader =>
      'Не успяхме да включим четеца на баркодове. Опитай отново.';

  @override
  String get cameraErrorPhoto =>
      'Не успяхме да направим снимката. Опитай отново.';

  @override
  String get cameraChoosePhoto => 'Избери снимка';

  @override
  String get cameraTakePhoto => 'Снимай';

  @override
  String cameraStep(int number, int total) {
    return 'Стъпка $number от $total';
  }

  @override
  String get cameraBarcodeTitle => 'Насочи камерата към баркода';

  @override
  String get cameraBarcodeTip =>
      'Дръж баркода в рамката и той ще се разчете автоматично.';

  @override
  String get cameraMealTitle => 'Снимай храната си';

  @override
  String get cameraMealTip => 'Отгоре, с цялата чиния в кадър.';

  @override
  String get cameraFrontTitle => 'Снимай опаковката отпред';

  @override
  String get cameraFrontTip => 'Цялата предна страна в кадър, заедно с името.';

  @override
  String get cameraTableTitle => 'Снимай таблицата с хранителните стойности';

  @override
  String get cameraTableTip =>
      'Таблицата да изпълва кадъра, изпъната и на фокус, за да се чете всяко число.';

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
  String get foodSearchError => 'Търсенето не е достъпно в момента.';

  @override
  String get foodSearchEmpty =>
      'Няма резултати. Опитай с други думи или остави AI да го изчисли.';

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
      'Не успяхме да се свържем с базата с храни. Провери връзката си.';

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
  String get contributeLogIt => 'Запиши';

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
      'Достигна дневния лимит. Утре можеш да изпратиш още.';

  @override
  String get contributeErrorRejected =>
      'Open Food Facts не го прие. Опитай отново след малко.';

  @override
  String get contributeErrorOffline =>
      'Не успяхме да се свържем с Open Food Facts. Провери връзката си и опитай отново.';

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
      'Енергията в храната. Яж по-малко, отколкото изгаряш, и ще отслабваш.';

  @override
  String get macroGuideCaloriesTarget =>
      'Колкото изгаряш на ден според възрастта, ръста, теглото и активността ти, минус малко, ако отслабваш.';

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
      'Засища и пази мускулите, докато изгаряш мазнини.';

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
      'Вдига кръвното. Най-много се крие в хляба, сиренето и готовите храни.';

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

  @override
  String get historyTitle => 'История';

  @override
  String get historyErrorLoad => 'Не успяхме да заредим историята ти.';

  @override
  String get historyWeek => 'Седмица';

  @override
  String get historyMonth => 'Месец';

  @override
  String get historyPrevious => 'Назад';

  @override
  String get historyNext => 'Напред';

  @override
  String get historyToday => 'Днес';

  @override
  String get historyStatusOnTrack => 'В целта';

  @override
  String get historyStatusClose => 'Близо';

  @override
  String get historyStatusOffTrack => 'Извън целта';

  @override
  String get historyNotLogged => 'Без записи';

  @override
  String get historyReviewTomorrow =>
      'Прегледът ти започва утре, след като днешният ден свърши.';

  @override
  String get historyNothingLogged => 'Още няма записи за този период.';

  @override
  String historyOnTrackCount(int count) {
    return '$count в целта';
  }

  @override
  String historyCloseCount(int count) {
    return '$count близо';
  }

  @override
  String historyOffTrackCount(int count) {
    return '$count извън целта';
  }

  @override
  String historyDaysOffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count почивни дни',
      one: '1 почивен ден',
    );
    return '$_temp0';
  }

  @override
  String get historyOnTrackShare => 'от записаните дни са в целта';

  @override
  String historyDaysLogged(int logged, int days) {
    return 'Записани $logged от $days дни';
  }

  @override
  String historyAverageKcal(int kcal) {
    return 'Средно $kcal ккал на ден';
  }

  @override
  String get historyGuidanceNoMeals => 'Няма записани хранения за този период.';

  @override
  String get historyGuidanceMostClose =>
      'Повечето записани дни са близо до целта.';

  @override
  String get historyGuidanceSomeClose =>
      'Някои записани дни са близо до целта, а няколко – доста далеч от нея.';

  @override
  String get historyGuidanceMostOff =>
      'Повечето записани дни са доста над или под целта.';

  @override
  String get historyGuidanceLogMore =>
      'Някои дни не са записани. Записвай повече дни за по-ясен преглед.';

  @override
  String historyBarNoCalories(String date) {
    return '$date: няма записани калории';
  }

  @override
  String historyBarKcal(String date, int kcal) {
    return '$date: $kcal ккал';
  }

  @override
  String historyBarKcalProtein(String date, int kcal, int protein) {
    return '$date: $kcal ккал · $protein г протеин';
  }

  @override
  String get historyDayNothingLogged => 'Няма записи';

  @override
  String historyDayKcal(int total, int target) {
    return '$total от $target ккал';
  }

  @override
  String historyDayKcalProtein(int total, int target, int protein) {
    return '$total от $target ккал · $protein г протеин';
  }

  @override
  String get historyDayOff => 'Почивен ден';

  @override
  String get historyDayNoMacros =>
      'Няма данни за макроси в храненията от този ден';

  @override
  String historyChangesLeft(int left, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Остават $left от $limit промени по минали дни този месец',
      one: 'Остава 1 от $limit промени по минали дни този месец',
    );
    return '$_temp0';
  }

  @override
  String get historyNoChangesLeft =>
      'Този месец нямаш повече промени по минали дни.';

  @override
  String get historyDayNoMeals => 'Няма записани хранения за този ден.';

  @override
  String get historyAddMeal => 'Добави хранене';

  @override
  String get historyDeleteMealTitle => 'Да изтрием ли храненето?';

  @override
  String historyDeleteMealNamed(String name) {
    return 'Да премахнем ли „$name“ от този ден?';
  }

  @override
  String get historyDeleteMealUnnamed =>
      'Да премахнем ли това хранене от този ден?';

  @override
  String get historyCancel => 'Отказ';

  @override
  String get historyDelete => 'Изтрий';

  @override
  String get historyErrorDeleteMeal =>
      'Не успяхме да изтрием храненето. Опитай отново.';

  @override
  String get coachTitle => 'AI треньор';

  @override
  String get coachIntroTitle => 'Твоят AI треньор';

  @override
  String get coachSubtitle =>
      'Всеки понеделник – нови съвети, съобразени с теб, за да се храниш по-добре и да постигнеш целите си.';

  @override
  String get coachPromiseHoldingBackTitle => 'Виж какво те спъва';

  @override
  String get coachPromiseHoldingBackBody =>
      'Открий навиците в храненето, които може да бавят напредъка ти, и малките промени, които помагат.';

  @override
  String get coachPromiseBalanceTitle => 'Храни се по-балансирано';

  @override
  String get coachPromiseBalanceBody =>
      'Сравни протеина, фибрите, солта и захарта си с препоръчителното и разбери върху какво да наблегнеш.';

  @override
  String get coachPromiseAdviceTitle => 'Съвети, които да приложиш веднага';

  @override
  String get coachPromiseAdviceBody =>
      'Практични идеи и рецепти според това, което вече ядеш, за да ти е по-лесно със следващото хранене.';

  @override
  String get coachPromiseWeeklyTitle => 'Започвай всяка седмица с посока';

  @override
  String get coachPromiseWeeklyBody =>
      'Всеки понеделник – нов поглед върху това какво работи и какво да промениш, за да надградиш постигнатото.';

  @override
  String get coachClose => 'Затвори';

  @override
  String get coachHowItWorks => 'Как работи';

  @override
  String get coachLastWeek => 'Миналата седмица';

  @override
  String get coachPrevious => 'Предишна седмица';

  @override
  String get coachNext => 'Следваща седмица';

  @override
  String get coachFirstNotesTitle => 'Първите ти бележки идват в понеделник';

  @override
  String coachDaysToGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Остават $count дни',
      one: 'Остава 1 ден',
    );
    return '$_temp0';
  }

  @override
  String coachFirstNotesBody(String date) {
    return 'AI треньорът преглежда цялата седмица наведнъж, затова следи тази, докато записваш храненията си. В понеделник, $date, ще ти каже какво е вървяло добре, какво те е спъвало и какво да опиташ следващата седмица.';
  }

  @override
  String get coachEnded =>
      'YumSum Star изтече, затова нови бележки не се пишат. Тези, които имаш, остават.';

  @override
  String get coachNotEnough =>
      'Тази седмица има твърде малко записи за бележки. Нужни са 4 записани дни, без почивните.';

  @override
  String get coachLooking => 'Преглеждаме седмицата ти';

  @override
  String get coachErrorLoad =>
      'Не успяхме да заредим бележките за седмицата. Опитай отново.';

  @override
  String get coachTryAgain => 'Опитай отново';

  @override
  String get coachNoNotesPlus =>
      'Няма бележки за тази седмица. AI треньорът ги пише през следващата седмица, когато отвориш тази страница.';

  @override
  String get coachNoNotes => 'Няма бележки за тази седмица.';

  @override
  String get coachKeepGoing => 'Продължавай така';

  @override
  String get coachTryThis => 'Опитай това';

  @override
  String get coachNotesComing =>
      'Бележките за тази седмица идват в понеделник.';

  @override
  String get coachNotesReadThat => 'Прочети бележките за седмицата.';

  @override
  String get coachNotesReadThis => 'Прочети бележките за тази седмица.';

  @override
  String coachWeekOf(String date) {
    return 'Седмицата от $date';
  }

  @override
  String get coachPromptLine =>
      'Виж какво работи, какво те спъва и как да напреднеш – с лични съвети.';

  @override
  String get recipesTitle => 'Рецепти';

  @override
  String get recipesErrorLoad => 'Не успяхме да заредим рецептите.';

  @override
  String get recipesSearchHint => 'Търси рецепти или съставки';

  @override
  String get recipesClear => 'Изчисти';

  @override
  String get recipesCookedRecently => 'Готвени наскоро';

  @override
  String get recipesAll => 'Всички';

  @override
  String get recipesBreakfast => 'Закуска';

  @override
  String get recipesLunch => 'Обяд';

  @override
  String get recipesDinner => 'Вечеря';

  @override
  String get recipesSnack => 'Междинно хранене';

  @override
  String get recipesEmpty => 'Още няма рецепти тук.';

  @override
  String get recipesNoMatch => 'Няма намерени рецепти. Опитай с други думи.';

  @override
  String get recipesLogPortion => 'Запиши порция';

  @override
  String recipesKcal(int kcal) {
    return '$kcal ккал';
  }

  @override
  String recipesProtein(int grams) {
    return '$grams г протеин';
  }

  @override
  String recipesMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get recipesRecipeTitle => 'Рецепта';

  @override
  String get recipesErrorLoadOne => 'Не успяхме да заредим рецептата.';

  @override
  String recipesPerPortion(int kcal) {
    return '$kcal ккал на порция';
  }

  @override
  String recipesPerPortionProtein(int kcal, int protein) {
    return '$kcal ккал · $protein г протеин на порция';
  }

  @override
  String get recipesPrep => 'Подготовка';

  @override
  String get recipesCook => 'Готвене';

  @override
  String get recipesServes => 'Порции';

  @override
  String get recipesNoCooking => 'Няма';

  @override
  String get recipesIngredients => 'Съставки';

  @override
  String recipesForPortions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'За $count порции',
      one: 'За 1 порция',
    );
    return '$_temp0';
  }

  @override
  String get recipesHowToMake => 'Начин на приготвяне';

  @override
  String get recipesHowMany => 'Колко порции?';

  @override
  String get recipesLess => 'По-малко';

  @override
  String get recipesMore => 'Повече';

  @override
  String get recipesLog => 'Запиши';

  @override
  String get recipesErrorLog =>
      'Не успяхме да запишем храненето. Опитай отново.';

  @override
  String recipesLogged(String meal) {
    return 'Записахме „$meal“.';
  }

  @override
  String get notificationsDenied =>
      'Разреши известията за YumSum в системните настройки.';

  @override
  String get notificationsMeal => 'Напомняне за храненията';

  @override
  String notificationsMealTime(String time) {
    return 'Всяка вечер в $time';
  }

  @override
  String get notificationsWeight => 'Напомняне за претегляне';

  @override
  String notificationsEveryDayAt(String time) {
    return 'Всеки ден в $time';
  }

  @override
  String notificationsWeeklyAt(String day, String time) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'monday': 'Всеки понеделник в $time',
      'tuesday': 'Всеки вторник в $time',
      'wednesday': 'Всяка сряда в $time',
      'thursday': 'Всеки четвъртък в $time',
      'friday': 'Всеки петък в $time',
      'saturday': 'Всяка събота в $time',
      'other': 'Всяка неделя в $time',
    });
    return '$_temp0';
  }

  @override
  String get notificationsEveryDay => 'Всеки ден';

  @override
  String get notificationsCreatine => 'Напомняне за креатин';

  @override
  String get starBecome => 'Отключи Star';

  @override
  String get starHeaderPitch => 'Отключи още умни функции.';

  @override
  String get starHeaderMember => 'Всичко това е твое.';

  @override
  String get starFeatureSnapTitle => 'Smart Snap';

  @override
  String get starFeatureSnapBody => 'Снимай храната си. AI прави останалото.';

  @override
  String get starFeatureEstimatesTitle => 'Три пъти повече AI оценки';

  @override
  String get starFeatureEstimatesBody => '30 на ден – винаги ще ти стигат.';

  @override
  String get starFeatureAdaptiveTitle => 'Адаптивна формула';

  @override
  String get starFeatureAdaptiveBody =>
      'Научава колко изгаряш реално и настройва целта ти.';

  @override
  String get starFeatureCoachTitle => 'AI треньор';

  @override
  String get starFeatureCoachBody =>
      'Преглежда седмицата ти и подсказва какво да подобриш.';

  @override
  String get starFeatureMacrosTitle => 'Подробни макроси';

  @override
  String get starFeatureMacrosBody =>
      'Целият етикет: мазнини, въглехидрати, захари, фибри, сол.';

  @override
  String get starYearly => 'Годишен';

  @override
  String get starMonthly => 'Месечен';

  @override
  String get starPerYear => 'на година';

  @override
  String get starPerMonth => 'на месец';

  @override
  String starMonthlyEquivalent(String price) {
    return '$price на месец';
  }

  @override
  String starSave(int percent) {
    return 'Спести $percent%';
  }

  @override
  String get starChecking => 'Проверяваме в Google Play';

  @override
  String get starSubscribe => 'Абонирай се';

  @override
  String starStartTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Опитай $days дни безплатно',
      one: 'Опитай 1 ден безплатно',
    );
    return '$_temp0';
  }

  @override
  String starTermsYearly(String price) {
    return '$price на година. Подновява се автоматично всяка година. Можеш да прекратиш абонамента по всяко време в Google Play.';
  }

  @override
  String starTermsMonthly(String price) {
    return '$price на месец. Подновява се автоматично всеки месец. Можеш да прекратиш абонамента по всяко време в Google Play.';
  }

  @override
  String starTrialTermsYearly(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days дни безплатно, след това $price на година. Подновява се автоматично всяка година. Можеш да прекратиш абонамента по всяко време в Google Play.',
      one:
          '1 ден безплатно, след това $price на година. Подновява се автоматично всяка година. Можеш да прекратиш абонамента по всяко време в Google Play.',
    );
    return '$_temp0';
  }

  @override
  String starTrialTermsMonthly(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days дни безплатно, след това $price на месец. Подновява се автоматично всеки месец. Можеш да прекратиш абонамента по всяко време в Google Play.',
      one:
          '1 ден безплатно, след това $price на месец. Подновява се автоматично всеки месец. Можеш да прекратиш абонамента по всяко време в Google Play.',
    );
    return '$_temp0';
  }

  @override
  String get starOk => 'Добре';

  @override
  String get starOn => 'Вече имаш YumSum Star.';

  @override
  String starOnTrial(String date) {
    return 'Вече имаш YumSum Star. Безплатната ти седмица изтича на $date.';
  }

  @override
  String get starAlreadyTitle => 'Вече имаш YumSum Star';

  @override
  String get starThanks => 'Благодарим ти, че помагаш на YumSum да расте.';

  @override
  String get starWeb =>
      'Абонирай се от приложението YumSum за Android и YumSum Star ще работи и тук, щом влезеш със същия профил.';

  @override
  String get starNoIphone => 'YumSum Star още не може да се купи на iPhone.';

  @override
  String get starTryAgain => 'Опитай отново';

  @override
  String get starRestore => 'Възстанови покупка';

  @override
  String get starTerms => 'Условия';

  @override
  String get starPrivacy => 'Поверителност';

  @override
  String get starClose => 'Затвори';

  @override
  String get starStatusPitch => 'Smart Snap, 30 AI оценки на ден и още';

  @override
  String get starStatusHold =>
      'Спрян, докато не уредиш плащането в Google Play';

  @override
  String get starStatusAdmin => 'Админ: всичко е включено, без дневни лимити';

  @override
  String get starStatusOn => 'Активен';

  @override
  String starStatusOnUntil(String date) {
    return 'Активен до $date';
  }

  @override
  String starStatusTrial(String date) {
    return 'Безплатен пробен период до $date';
  }

  @override
  String starStatusEnds(String date) {
    return 'Изтича на $date';
  }

  @override
  String starStatusRenews(String date) {
    return 'Подновява се на $date';
  }

  @override
  String get starStatusGrace =>
      'Проблем с плащането. Уреди го в Google Play, за да запазиш YumSum Star.';

  @override
  String get starErrorPlay =>
      'Не успяхме да се свържем с Google Play. Провери връзката си и опитай отново.';

  @override
  String get starErrorNotConfirmed =>
      'Не успяхме да потвърдим покупката ти. Опитай „Възстанови покупка“ след няколко минути. Ако отново не успее, Google Play ще ти върне парите автоматично до 3 дни.';

  @override
  String get starErrorOtherAccount =>
      'Този абонамент в Google Play е свързан с друг профил в YumSum. Влез с другия профил, за да го ползваш.';

  @override
  String get starNothingToRestore =>
      'Не намерихме абонамент за YumSum Star в този профил в Google.';

  @override
  String get starPaymentPending =>
      'Google Play очаква плащането ти. YumSum Star ще се включи, щом то бъде потвърдено.';

  @override
  String get commonEmail => 'Имейл';

  @override
  String get commonPassword => 'Парола';

  @override
  String get commonSigningOut => 'Излизане…';

  @override
  String get commonEnterPassword => 'Въведи паролата си.';

  @override
  String get commonEnterValidEmail => 'Въведи валиден имейл.';

  @override
  String get commonEnterValidEmailAddress => 'Въведи валиден имейл адрес.';

  @override
  String get commonErrorTooManyAttempts =>
      'Твърде много опити. Опитай отново по-късно.';

  @override
  String get authSignInTab => 'Вход';

  @override
  String get authSignUpTab => 'Регистрация';

  @override
  String get authSignInButton => 'Влез';

  @override
  String get authCreateAccountButton => 'Създай профил';

  @override
  String get authEnterEmail => 'Въведи имейла си.';

  @override
  String get authPasswordTooShort => 'Паролата трябва да е поне 6 знака.';

  @override
  String get authForgotPassword => 'Забравена парола?';

  @override
  String get authForgotPasswordNeedsEmail =>
      'Първо въведи имейла си горе, после натисни „Забравена парола?“';

  @override
  String get authOr => 'или';

  @override
  String get authContinueWithGoogle => 'Продължи с Google';

  @override
  String get authVerificationSentTitle => 'Имейлът за потвърждение е изпратен';

  @override
  String authVerificationSentBody(String email) {
    return 'Изпратихме линк на $email. Отвори го, за да потвърдиш профила си, и после влез.';
  }

  @override
  String get authResetSentTitle => 'Имейлът за нова парола е изпратен.';

  @override
  String authResetSentBody(String email) {
    return 'Изпратихме линк на $email. Отвори го, за да избереш нова парола, и после влез.';
  }

  @override
  String get authErrorVerifyEmail =>
      'Първо потвърди имейла си. Линкът е във входящата ти поща.';

  @override
  String get authErrorGoogle => 'Входът с Google не успя. Опитай отново.';

  @override
  String get authErrorUsePassword => 'Този имейл вече има парола. Влез с нея.';

  @override
  String get authErrorWrongCredentials => 'Грешен имейл или парола.';

  @override
  String get authErrorEmailInUse =>
      'Вече има профил с този имейл. Влез в него.';

  @override
  String get authErrorNoInternet => 'Няма връзка с интернет. Опитай отново.';

  @override
  String get authErrorGeneric => 'Нещо се обърка. Опитай отново.';

  @override
  String legalAgreement(String terms, String privacy) {
    return 'Като продължиш, приемаш $terms и $privacy.';
  }

  @override
  String get legalTermsOfUse => 'Условията за ползване';

  @override
  String get legalPrivacyPolicy => 'Политиката за поверителност';

  @override
  String legalRecaptcha(String privacy, String terms) {
    return 'Защитено с reCAPTCHA Enterprise. Важат $privacy и $terms на Google.';
  }

  @override
  String get legalGooglePrivacy => 'Правилата за поверителност';

  @override
  String get legalGoogleTerms => 'Общите условия';

  @override
  String get legalMedicalNote =>
      'YumSum дава общи ориентировъчни стойности, а не медицински съвет. Говори с лекар или диетолог, преди да промениш храненето си, особено ако имаш здравословен проблем.';

  @override
  String get planActivitySedentary => 'Предимно седене';

  @override
  String get planActivitySedentaryHint =>
      'Работа на бюро, малко крачки, рядко на крак.';

  @override
  String get planActivityLight => 'Леко движение през деня';

  @override
  String get planActivityLightHint =>
      'Малко ходене, задачи навън или лека домакинска работа.';

  @override
  String get planActivityModerate => 'Често на крак';

  @override
  String get planActivityModerateHint =>
      'Стоиш или ходиш през голяма част от деня.';

  @override
  String get planActivityHigh => 'Физическа работа или много движение';

  @override
  String get planActivityHighHint =>
      'Физически труд, много крачки или особено активни дни.';

  @override
  String get planTrainingNone => 'Без редовни тренировки';

  @override
  String get planTrainingNoneHint =>
      'През повечето седмици няма планирани тренировки.';

  @override
  String get planTrainingOneToTwo => '1–2 тренировки седмично';

  @override
  String get planTrainingOneToTwoHint =>
      'Един-два дни с тежести, кардио или спорт.';

  @override
  String get planTrainingThreeToFour => '3–4 тренировки седмично';

  @override
  String get planTrainingThreeToFourHint =>
      'Редовни тренировки през повечето седмици.';

  @override
  String get planTrainingFivePlus => '5+ тренировки седмично';

  @override
  String get planTrainingFivePlusHint => 'Чести тренировки по план.';

  @override
  String planPaceSlow(String amount) {
    return 'Бавно – $amount седмично';
  }

  @override
  String get planPaceSlowHint =>
      'По-щадящо и по-лесно за спазване в дългосрочен план.';

  @override
  String planPaceModerate(String amount) {
    return 'Умерено – $amount седмично';
  }

  @override
  String get planPaceModerateHint =>
      'Стабилен напредък с умерен калориен дефицит.';

  @override
  String planPaceFast(String amount) {
    return 'Бързо – $amount седмично';
  }

  @override
  String get planPaceFastHint =>
      'По-бързи резултати, но по-трудно за повечето хора.';

  @override
  String get planPaceMaintain => 'Запазване на теглото';

  @override
  String get planPaceMaintainHint =>
      'Калориите ти остават около поддържащите, без дефицит.';

  @override
  String get profileErrorLoadTitle => 'Не успяхме да заредим профила ти';

  @override
  String get profileErrorLoadBody => 'Провери връзката си и опитай отново.';

  @override
  String get profileBackToSignIn => 'Обратно към входа';

  @override
  String get accountTitle => 'Настройки';

  @override
  String accountConfirmWithGoogle(String description) {
    return '$description След това ще потвърдиш с Google.';
  }

  @override
  String get accountNameSaved => 'Името е запазено.';

  @override
  String get accountErrorSaveName =>
      'Не успяхме да запазим името ти. Опитай отново.';

  @override
  String get accountResetEmailSent => 'Изпратихме ти имейл за нова парола.';

  @override
  String get accountErrorSendReset =>
      'Не успяхме да изпратим имейла за нова парола.';

  @override
  String get accountCheckNewEmail => 'Потвърди смяната от новия си имейл.';

  @override
  String get accountErrorChangeEmail =>
      'Не успяхме да сменим имейла ти. Опитай отново.';

  @override
  String get accountResetTitle => 'Да нулираме ли всички данни?';

  @override
  String get accountResetBody =>
      'Това изтрива всичките ти хранения, претегляния и почивни дни. Профилът, личните ти данни и планът остават.';

  @override
  String get accountResetButton => 'Нулирай всички данни';

  @override
  String get accountResetDone => 'Всички записани данни са изтрити.';

  @override
  String get accountErrorReset => 'Не успяхме да нулираме данните ти.';

  @override
  String get accountDeleteTitle => 'Да изтрием ли профила?';

  @override
  String get accountDeleteBody =>
      'Това изтрива профила ти и всичко в него. Не може да се отмени.';

  @override
  String get accountDeleteBodyStar =>
      'Това изтрива профила ти и всичко в него. Не може да се отмени. Изтриването на профила не спира YumSum Star. Първо откажи абонамента в Google Play, иначе ще продължи да се подновява.';

  @override
  String get accountDeleteButton => 'Изтрий профила';

  @override
  String get accountErrorDelete => 'Не успяхме да изтрием профила ти.';

  @override
  String get accountErrorLoad => 'Не успяхме да заредим профила ти.';

  @override
  String get accountHeading => 'Управлявай профила си';

  @override
  String get accountSubtitle => 'Смени името, имейла или паролата си.';

  @override
  String get accountSubtitleGoogle =>
      'Смени името си. Имейлът и паролата ти се управляват от Google.';

  @override
  String get accountSectionAccount => 'ПРОФИЛ';

  @override
  String get accountName => 'Име';

  @override
  String get accountEnterName => 'Въведи името си.';

  @override
  String get accountChangeEmail => 'Смени имейла';

  @override
  String get accountSaveName => 'Запази името';

  @override
  String get accountSectionPassword => 'ПАРОЛА';

  @override
  String get accountSendReset => 'Изпрати имейл за нова парола';

  @override
  String get accountSectionNotifications => 'ИЗВЕСТИЯ';

  @override
  String get accountSectionAppearance => 'ИЗГЛЕД';

  @override
  String get accountSectionLanguage => 'ЕЗИК';

  @override
  String get accountSectionStar => 'YUMSUM STAR';

  @override
  String get accountSectionHelp => 'ПОМОЩ И ПРАВНА ИНФОРМАЦИЯ';

  @override
  String get accountSendFeedback => 'Изпрати обратна връзка';

  @override
  String get accountSendFeedbackHint => 'Пиши на разработчика';

  @override
  String get accountPrivacyPolicy => 'Политика за поверителност';

  @override
  String get accountTerms => 'Условия за ползване';

  @override
  String get accountOpenFoodFacts => 'Данни за храните от Open Food Facts';

  @override
  String get accountOpenFoodFactsHint =>
      'Свободна база данни, създадена от доброволци, под лиценза Open Database License';

  @override
  String get accountSectionDanger => 'ОПАСНА ЗОНА';

  @override
  String get accountChangeEmailTitle => 'Смяна на имейла';

  @override
  String get accountChangeEmailBody =>
      'Ще изпратим линк на новия ти адрес. Имейлът ти се сменя, щом го отвориш.';

  @override
  String get accountNewEmail => 'Нов имейл';

  @override
  String get accountEnterNewEmail => 'Въведи новия си имейл.';

  @override
  String get accountCurrentPassword => 'Текуща парола';

  @override
  String get accountShowPassword => 'Покажи паролата';

  @override
  String get accountHidePassword => 'Скрий паролата';

  @override
  String get accountEnterCurrentPassword => 'Въведи текущата си парола.';

  @override
  String get accountSendLink => 'Изпрати линка';

  @override
  String get accountErrorSignedOut => 'Влез отново в профила си.';

  @override
  String get accountErrorNoEmail => 'Този профил няма имейл адрес.';

  @override
  String get accountErrorEnterNewEmail => 'Въведи нов имейл адрес.';

  @override
  String get accountErrorSameEmail => 'Това вече е твоят имейл.';

  @override
  String get accountErrorWrongGoogle =>
      'Избери профила в Google, с който влезе.';

  @override
  String get accountErrorNoPassword =>
      'Този профил не може да се потвърди с парола.';

  @override
  String get accountErrorWrongPassword => 'Грешна парола.';

  @override
  String get accountErrorNoConnection =>
      'Не успяхме да се свържем. Провери връзката си и опитай отново.';

  @override
  String get accountErrorEmailInUse => 'Вече има профил с този имейл адрес.';

  @override
  String get accountErrorConfirmPassword =>
      'Потвърди паролата си и опитай отново.';

  @override
  String get accountErrorVerifyPassword =>
      'Не успяхме да проверим паролата ти.';

  @override
  String get menuHome => 'Начало';

  @override
  String get menuHistory => 'История';

  @override
  String get menuCoach => 'AI треньор';

  @override
  String get menuRecipes => 'Рецепти';

  @override
  String get menuProgress => 'Тегло и напредък';

  @override
  String get menuPlanSettings => 'Настройки на плана';

  @override
  String get menuSettings => 'Настройки';

  @override
  String get menuThemeSystem => 'Системен';

  @override
  String get menuThemeLight => 'Светъл';

  @override
  String get menuThemeDark => 'Тъмен';

  @override
  String get menuLogOut => 'Изход';

  @override
  String get feedbackTitle => 'Обратна връзка';

  @override
  String get feedbackSent => 'Изпратено. Благодарим ти.';

  @override
  String get feedbackKindProblem => 'Проблем';

  @override
  String get feedbackKindIdea => 'Идея';

  @override
  String get feedbackKindOther => 'Друго';

  @override
  String get feedbackHintProblem => 'Какво се случи и какво очакваше?';

  @override
  String get feedbackHintIdea => 'Какво би направило YumSum по-добро за теб?';

  @override
  String get feedbackHintOther => 'Всичко, което искаш да споделиш';

  @override
  String feedbackRepliesTo(String email) {
    return 'Ще ти отговорим на $email.';
  }

  @override
  String feedbackLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Днес вече изпрати $count съобщения. Утре можеш да изпратиш още.',
      one: 'Днес вече изпрати 1 съобщение. Утре можеш да изпратиш още.',
    );
    return '$_temp0';
  }

  @override
  String get feedbackErrorSend =>
      'Не успяхме да изпратим съобщението. Опитай отново.';

  @override
  String get feedbackSending => 'Изпращане…';

  @override
  String get feedbackSend => 'Изпрати';

  @override
  String get splashTagline => 'Постоянство всеки ден. Винаги във форма.';

  @override
  String get startupErrorTitle => 'YumSum не успя да стартира';

  @override
  String get startupErrorBody =>
      'Презареди страницата. Ако се повтаря, изпрати съобщението отдолу на разработчика.';

  @override
  String get shortcutLogVoice => 'Запиши с глас';

  @override
  String unitsKg(String value) {
    return '$value кг';
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
    return '$value см';
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
  String get unitsKgLabel => 'кг';

  @override
  String get unitsLbLabel => 'lb';

  @override
  String get unitsStLabel => 'st';

  @override
  String get unitsCmLabel => 'см';

  @override
  String get unitsFtLabel => 'ft';

  @override
  String get unitsInLabel => 'in';

  @override
  String get unitsMetricToggle => 'кг, см';

  @override
  String get unitsLbFtToggle => 'lb, ft';

  @override
  String get unitsStFtToggle => 'st, ft';

  @override
  String get unitsPounds => 'Фунтове';

  @override
  String get unitsInches => 'Инчове';

  @override
  String get commonYes => 'Да';

  @override
  String get commonNo => 'Не';

  @override
  String get commonAge => 'Възраст';

  @override
  String get commonHeight => 'Ръст';

  @override
  String get commonCurrentWeight => 'Сегашно тегло';

  @override
  String get commonTargetWeight => 'Желано тегло';

  @override
  String get commonEnterAge => 'Въведи възрастта си.';

  @override
  String get commonAgeRange => 'Въведи възраст от 18 до 120.';

  @override
  String get commonTargetBelowCurrent => 'Трябва да е под сегашното ти тегло';

  @override
  String get commonMale => 'Мъж';

  @override
  String get commonFemale => 'Жена';

  @override
  String get commonOther => 'Друго';

  @override
  String get onboardingEnterHeight => 'Въведи ръста си.';

  @override
  String get onboardingEnterWeight => 'Въведи теглото си.';

  @override
  String get onboardingNameTitle => 'Как се казваш?';

  @override
  String get onboardingName => 'Име';

  @override
  String get onboardingGenderTitle => 'Ти си…';

  @override
  String get onboardingAgeTitle => 'На колко години си?';

  @override
  String get onboardingHeightTitle => 'Какъв е ръстът ти?';

  @override
  String get onboardingWeightTitle => 'Колко тежиш сега?';

  @override
  String get onboardingGoalTitle => 'Каква е целта ти?';

  @override
  String get onboardingGoalBody =>
      'Калориите са енергията в храната. Яж малко по-малко, отколкото изгаря тялото ти, и ще отслабваш – постепенно и безопасно.';

  @override
  String get onboardingLoseWeight => 'Да отслабна';

  @override
  String get onboardingKeepWeight => 'Да запазя теглото';

  @override
  String get onboardingTargetTitle => 'Към какво тегло се стремиш?';

  @override
  String get onboardingActivityTitle => 'Колко се движиш в обикновен ден?';

  @override
  String get onboardingActivityBody => 'Без да броим тренировките.';

  @override
  String get onboardingTrainingTitle => 'Тренираш ли освен това?';

  @override
  String get onboardingTrainingBody => 'Планирани тренировки, ако имаш такива.';

  @override
  String get onboardingProteinTitle => 'Да следим ли и протеина?';

  @override
  String get onboardingProteinBody =>
      'Протеинът те засища и пази мускулите ти. YumSum го изчислява за всяко хранене, което запишеш.';

  @override
  String get onboardingPlanTitle => 'Планът ти е готов!';

  @override
  String get onboardingPlanCardTitle => 'Твоят план';

  @override
  String get onboardingPlanNote =>
      'Можеш да прегледаш всичко отново, и по-подробно, в „Настройки на плана“.';

  @override
  String get onboardingErrorSave => 'Нещо се обърка. Опитай отново.';

  @override
  String get onboardingBack => 'Назад';

  @override
  String get onboardingNext => 'Продължи';

  @override
  String get onboardingStart => 'Започни';

  @override
  String get planPreviewMaintenance => 'План за поддържане';

  @override
  String get planPreviewFloor => 'Долна граница на калориите';

  @override
  String get planPreviewSafe => 'Устойчиво темпо';

  @override
  String get planPreviewCaution => 'По-бързо темпо';

  @override
  String get planPreviewWarning => 'Твърде бързо темпо';

  @override
  String get planPreviewMaintenanceNote => 'Без калориен дефицит.';

  @override
  String get planPreviewFloorNote =>
      'При това темпо калориите ще паднат под минимума, затова желаното тегло ще дойде по-късно.';

  @override
  String get planPreviewSafeNote =>
      'Умерен дефицит спрямо поддържащите калории.';

  @override
  String get planPreviewCautionNote =>
      'Изисква постоянство и може да ти се стори ограничаващо.';

  @override
  String get planPreviewWarningNote =>
      'Ако ти е трудно да го спазваш, избери по-бавно темпо.';

  @override
  String get planPreviewMaintain => 'Поддържане';

  @override
  String planPreviewPerWeek(String amount) {
    return '$amount/седм.';
  }

  @override
  String get planPreviewDailyTarget => 'Дневна цел';

  @override
  String get planPreviewWeeklyLoss => 'Темпо';

  @override
  String get planPreviewGoalBy => 'Цел до';

  @override
  String get planPreviewInfoTooltip => 'Как се изчислява';

  @override
  String get planInfoTitle => 'Как изчисляваме калориите';

  @override
  String get planInfoBody =>
      'Първо изчисляваме колко изгаряш в покой според теглото, ръста, възрастта и пола ти. После добавяме движението и тренировките, за да получим поддържащите калории.';

  @override
  String get planInfoResting => 'В покой';

  @override
  String get planInfoMovement => 'Движение';

  @override
  String get planInfoTraining => 'Тренировки';

  @override
  String get planInfoActivity => 'Обща активност';

  @override
  String get planInfoMaintenance => 'Поддържащи';

  @override
  String get planInfoAdaptive => 'Адаптивна';

  @override
  String get planInfoTarget => 'Цел';

  @override
  String planInfoKcalPerDay(int kcal) {
    return '$kcal ккал/ден';
  }

  @override
  String planInfoAtMinimum(int kcal) {
    return '$kcal ккал/ден – твоят минимум';
  }

  @override
  String get planInfoFloorNote =>
      'При това темпо калориите ще паднат под минимума, затова оставаш на минимума, а желаното тегло ще дойде по-късно.';

  @override
  String get planTitle => 'Настройки на плана';

  @override
  String get planErrorLoad => 'Не успяхме да заредим профила ти.';

  @override
  String get planSelectGender => 'Избери пола си.';

  @override
  String get planSaved => 'Планът е запазен.';

  @override
  String get planErrorSave => 'Не успяхме да запазим плана ти. Опитай отново.';

  @override
  String get planRequired => 'Задължително';

  @override
  String get planHeading => 'Обнови плана си';

  @override
  String get planSubtitle =>
      'Промени каквото искаш отдолу и планът ти ще се настрои.';

  @override
  String get planSectionPersonal => 'ЛИЧНИ ДАННИ';

  @override
  String get planGender => 'Пол';

  @override
  String get planSectionUnits => 'МЕРНИ ЕДИНИЦИ';

  @override
  String get planSectionBody => 'ТЯЛОТО ТИ';

  @override
  String get planSectionBmi => 'ТВОЯТ ИТМ';

  @override
  String get planSectionGoal => 'ТВОЯТА ЦЕЛ';

  @override
  String get planTargetStays => 'Желаното ти тегло остава сегашното.';

  @override
  String get planSectionMovement => 'ДВИЖЕНИЕТО ТИ ПРЕЗ ДЕНЯ';

  @override
  String get planMovementNote =>
      'Обикновеният ти ден, без да броим тренировките.';

  @override
  String get planSectionTraining => 'КОЛКО ЧЕСТО ТРЕНИРАШ?';

  @override
  String get planTrainingNote => 'Планирани тренировки освен обичайния ти ден.';

  @override
  String get planSectionProtein => 'ДА СЛЕДИМ ЛИ И ПРОТЕИНА?';

  @override
  String get planProteinNote =>
      'Протеинът помага да запазиш мускулите, докато отслабваш. С „Не“ се скрива навсякъде.';

  @override
  String get planSectionPace => 'КОЛКО БЪРЗО ИСКАШ ДА ОТСЛАБНЕШ?';

  @override
  String get planPaceNote =>
      'Темпото определя дневните калории, а желаното тегло – колко ще продължи планът.';

  @override
  String get planSectionAdjustment => 'ЛИЧНА НАСТРОЙКА';

  @override
  String get planUpdatedPlan => 'Обновен план';

  @override
  String get planSave => 'Запази плана';

  @override
  String get planAdaptiveNote =>
      'Учи се от претеглянията ти и настройва целта ти всеки понеделник.';

  @override
  String get planAdaptiveRestarts =>
      'Ако запазиш, започва отначало с новия ти план.';

  @override
  String get planBmiUnderweight => 'Поднормено тегло';

  @override
  String get planBmiHealthy => 'Нормално тегло';

  @override
  String get planBmiOverweight => 'Наднормено тегло';

  @override
  String get planBmiObese => 'Затлъстяване';

  @override
  String get planBmiTitle => 'Твоят ИТМ';

  @override
  String get adaptiveTitle => 'Адаптивна формула';

  @override
  String get adaptiveHowItWorks => 'Как работи';

  @override
  String get adaptiveTryNote =>
      'Формула, създадена специално за теб. Настройва се с времето и с всяко претегляне.';

  @override
  String get adaptiveOn => 'Включена';

  @override
  String adaptiveBurnFact(String kcal) {
    return 'Изгаряш $kcal на ден';
  }

  @override
  String adaptiveTargetFact(String kcal) {
    return 'Целта ти е $kcal на ден';
  }

  @override
  String get adaptiveBurnLearnt => 'Научено от претеглянията и храненията ти.';

  @override
  String get adaptiveBurnFirst =>
      'Първа оценка. Уточнява се с всяко претегляне.';

  @override
  String get adaptiveTargetKeep => 'За да запазиш теглото си.';

  @override
  String adaptiveTargetLose(String amount) {
    return 'За да сваляш по $amount седмично.';
  }

  @override
  String get adaptivePaused =>
      'На пауза: няма претегляне от 10 дни. Претегли се, за да продължи да се настройва към теб.';

  @override
  String adaptiveAtMinimum(String date) {
    return 'Дневната ти цел е на минимума, затова новата дата за желаното тегло е $date.';
  }

  @override
  String adaptiveLowered(String amount) {
    return 'Настроено за теб: $amount ккал. Изгаряш малко по-малко, отколкото предвиждаше планът.';
  }

  @override
  String adaptiveRaised(String amount) {
    return 'Настроено за теб: $amount ккал. Изгаряш малко повече, отколкото предвиждаше планът.';
  }

  @override
  String get adaptiveFirstSign =>
      'Може би изгаряш малко по-малко, отколкото предвижда планът. Ще проверим пак следващия понеделник.';

  @override
  String adaptiveSteadyAdjusted(String amount) {
    return 'Настроено за теб: $amount ккал. Без промяна тази седмица.';
  }

  @override
  String get adaptiveSteady =>
      'Без промяна тази седмица: теглото ти отговаря на това, което ядеш.';

  @override
  String get adaptiveFewWeighIns =>
      'Тази седмица има твърде малко претегляния, затова целта ти остава същата.';

  @override
  String get adaptiveFewDays =>
      'Тази седмица има твърде малко записани дни, затова целта ти остава същата.';

  @override
  String get adaptiveUnusual =>
      'Числата ти изглеждат необичайно. Провери записите и претеглянията си.';

  @override
  String adaptiveSum(int plan, String sign, int amount, int target) {
    return '$plan по план $sign $amount адаптивно = $target ккал';
  }

  @override
  String adaptiveSumMinimum(int plan, String sign, int amount, int target) {
    return '$plan по план $sign $amount адаптивно = $target ккал – твоят минимум';
  }

  @override
  String get progressTitle => 'Тегло и напредък';

  @override
  String get progressLogWeight => 'Запиши тегло';

  @override
  String get progressHistory => 'История';

  @override
  String get progressReset => 'Нулирай напредъка';

  @override
  String get progressErrorLoad =>
      'Не успяхме да заредим историята на теглото ти.';

  @override
  String progressSavedNewTarget(int kcal, int previous) {
    return 'Теглото е записано. Нова цел: $kcal ккал (беше $previous).';
  }

  @override
  String progressSavedSameTarget(int kcal) {
    return 'Теглото е записано. Целта ти остава $kcal ккал.';
  }

  @override
  String get progressDeleteTitle => 'Да изтрием ли претеглянето?';

  @override
  String progressDeleteBody(String weight, String date) {
    return 'Да премахнем ли $weight от $date?';
  }

  @override
  String progressDeleteBodyBack(String weight, String date, String previous) {
    return 'Да премахнем ли $weight от $date? Планът ти ще се върне към $previous.';
  }

  @override
  String get progressErrorDelete =>
      'Не успяхме да изтрием претеглянето. Опитай отново.';

  @override
  String progressDeletedNewTarget(int kcal, int previous) {
    return 'Претеглянето е изтрито. Нова цел: $kcal ккал (беше $previous).';
  }

  @override
  String get progressDeleted => 'Претеглянето е изтрито.';

  @override
  String get progressResetTitle => 'Да нулираме ли напредъка?';

  @override
  String get progressResetBody =>
      'Това изтрива цялата история на теглото ти и графиката. Не може да се отмени.';

  @override
  String get progressResetButton => 'Нулирай';

  @override
  String get progressResetDone => 'Историята на теглото е изтрита.';

  @override
  String get progressErrorReset =>
      'Не успяхме да нулираме напредъка. Опитай отново.';

  @override
  String get progressCurrent => 'Сега';

  @override
  String get progressChange => 'Промяна';

  @override
  String get progressTarget => 'Цел';

  @override
  String progressTrend(String weight) {
    return 'Тенденция $weight';
  }

  @override
  String get progressDeleteTooltip => 'Изтрий претеглянето';

  @override
  String get progressEmptyTitle => 'Още няма записано тегло';

  @override
  String get progressEmptyBody =>
      'Записвай теглото си, за да виждаш напредъка. Планът ти се настройва всеки път.';

  @override
  String get progressWeighInTitle => 'Запиши теглото си';

  @override
  String get progressWeighInNote => 'Планът ти ще се настрои според него.';

  @override
  String progressWeighInRange(String range) {
    return 'Въведи тегло между $range.';
  }

  @override
  String get progressWeighInRangeAnd => ' и ';

  @override
  String get progressErrorSaveWeight =>
      'Не успяхме да запишем теглото ти. Опитай отново.';

  @override
  String progressWeightSavedTarget(int kcal) {
    return 'Теглото е записано. Нова цел: $kcal ккал.';
  }

  @override
  String get progressWeightSaved => 'Теглото е записано.';
}
