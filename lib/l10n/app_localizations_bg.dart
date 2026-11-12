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
  String get reminderMealChannel => 'Ежедневно напомняне за храненията';

  @override
  String get reminderMealChannelDescription =>
      'Напомня ти всяка вечер да запишеш храненията си.';

  @override
  String get reminderWeightTitle => 'Време е за претегляне';

  @override
  String get reminderWeightBodyDaily =>
      'Запиши теглото си днес, за да съобразим плана с него.';

  @override
  String get reminderWeightBodyWeekly =>
      'Запиши теглото си тази седмица, за да съобразим плана с него.';

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
  String get homeErrorMonth => 'Не успяхме да заредим данните за месеца.';

  @override
  String get homeDeleteMealTitle => 'Да изтрием ли храненето?';

  @override
  String get homeDeleteMealBody => 'Да го премахнем ли от днешните записи?';

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
  String get homeOnTrack => 'По план';

  @override
  String get homeOverTarget => 'Над целта';

  @override
  String get homeKcalLeft => 'ккал остават';

  @override
  String get homeKcalOver => 'ккал в повече';

  @override
  String homeKcalEaten(int eaten, int target) {
    return 'Приети $eaten от $target ккал';
  }

  @override
  String get homeTargetsTooltip => 'За целите ти';

  @override
  String get homeMealsTitle => 'Днешни хранения';

  @override
  String get homeSlotMorning => 'Сутрин';

  @override
  String get homeSlotAfternoon => 'Следобед';

  @override
  String get homeSlotEvening => 'Вечер';

  @override
  String homeSlotItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записа',
      one: '1 запис',
    );
    return '$_temp0';
  }

  @override
  String homeSlotTotal(int kcal, int protein) {
    return '$kcal ккал · $protein г';
  }

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
      'Още няма записани хранения. Опиши храната или натисни микрофона долу.';

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
      'Запис със снимка, адаптивна формула, AI треньор и подробни макроси.';

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
    return 'Ще ти напомняме за креатин в $time. Можеш да смениш часа от „Известия“ в настройките на приложението.';
  }

  @override
  String get homeCreatineBlocked =>
      'Разреши известията в настройките на телефона. После включи напомнянето от „Известия“ в настройките на приложението.';

  @override
  String get homeCreatineLater =>
      'Можеш да включиш напомнянето по всяко време от „Известия“ в настройките.';

  @override
  String get homeDayOffBackTitle => 'Да се върнем ли към плана?';

  @override
  String get homeDayOffTakeTitle => 'Почивен ден днес?';

  @override
  String get homeDayOffBackBody =>
      'Калориите за днес отново ще се сравняват с дневната ти цел.';

  @override
  String get homeDayOffIntro => 'За празници и излизания.';

  @override
  String get homeDayOffLog => 'Записвай храненията си както обикновено.';

  @override
  String get homeDayOffNoColours => 'Днес няма цветна оценка.';

  @override
  String get homeDayOffHistory => 'Денят не влияе на резултатите в „История“.';

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
      'Преценявай по-лесно колко да ядеш с формула, която всяка седмица се адаптира към теб.';

  @override
  String get adaptiveIntroBurnTitle => 'Разбери колко изгаряш';

  @override
  String get adaptiveIntroBurnBody =>
      'По записаните хранения и промените в теглото ти изчисляваме приблизително колко калории изгаряш на ден. Така дневната ти цел е по-точна.';

  @override
  String get adaptiveIntroBodyTitle => 'Според твоето тяло';

  @override
  String get adaptiveIntroBodyBody =>
      'Дневната ти цел се съобразява с реакцията на тялото ти, за да откриеш какво ти помага да напредваш.';

  @override
  String get adaptiveIntroChangeTitle => 'Целта се променя заедно с теб';

  @override
  String get adaptiveIntroChangeBody =>
      'Нуждата ти от калории се променя заедно с теглото ти. Целта ти се настройва, за да продължиш да напредваш.';

  @override
  String get adaptiveIntroWeighTitle => 'Всяко претегляне е важно';

  @override
  String get adaptiveIntroWeighBody =>
      'Всяко претегляне дава повече информация. С редовни записи дневната ти цел става по-точна.';

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
      'В Open Food Facts още няма данни за калориите на този продукт. Вместо това снимай опаковката.';

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
  String get quickLogHint => 'Опиши храната';

  @override
  String get quickLogClear => 'Изчисти';

  @override
  String get quickLogProteinHint => 'протеин (г)';

  @override
  String get quickLogProteinUnit => 'г';

  @override
  String get quickLogSearchFoods => 'Търси храни';

  @override
  String quickLogChipKcal(int kcal) {
    return '· $kcal ккал';
  }

  @override
  String get quickLogStop => 'Спри';

  @override
  String get quickLogTime => 'Час на хранене';

  @override
  String get mealTime => 'Час';

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
      'Промените за минали дни са изчерпани за този месец.';

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
      'Остави полето за протеин празно и ще изчислим количеството по описанието на храната.';

  @override
  String get mealEstimateFromName => 'Изчисли по описанието';

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
  String get mealLogAgain => 'Запиши отново';

  @override
  String get mealLoggedAgain => 'Добавено към днес.';

  @override
  String get mealOptions => 'Опции за храненето';

  @override
  String get mealWeight => 'Грамаж';

  @override
  String get mealUseWeight => 'Приложи';

  @override
  String mealKcalGrams(int kcal, int grams) {
    return '$kcal ккал · $grams г';
  }

  @override
  String get mealChoiceRegular => 'Средно';

  @override
  String get cameraNotFound => 'Не открихме камера.';

  @override
  String get cameraCouldNotStart => 'Не успяхме да включим камерата.';

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
  String get cameraFrontTip =>
      'Нека се вижда цялата предна страна, включително името на продукта.';

  @override
  String get cameraTableTitle => 'Снимай таблицата с хранителните стойности';

  @override
  String get cameraTableTip =>
      'Снимай таблицата отблизо и на фокус. Дръж опаковката изправена, за да се четат всички числа.';

  @override
  String get cameraSmartSnap => 'Запис със снимка';

  @override
  String get cameraSmartSnapSubtitle =>
      'Записвай храната си само с една снимка.';

  @override
  String get cameraSmartSnapSkipTitle => 'Без ръчно въвеждане';

  @override
  String get cameraSmartSnapSkipBody =>
      'Снимай храната си, а AI ще я разпознае и ще изчисли приблизителните калории и макроси за всяка храна в чинията.';

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
      'Няма резултати. Опитай с други думи или изчисли калориите с AI.';

  @override
  String foodPer100g(int kcal) {
    return '$kcal ккал на 100 г';
  }

  @override
  String foodPortionSource(String amounts) {
    return '$amounts на 100 г · Open Food Facts';
  }

  @override
  String foodPortionServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count порции',
      one: '1 порция',
    );
    return '$_temp0';
  }

  @override
  String get foodPortionWholePack => 'Цялата опаковка';

  @override
  String foodPortionServingIs(String label) {
    return 'Порция: $label';
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
      'Продуктът е в базата, но липсват хранителните му стойности. Добави ги със снимка на таблицата. Така ще са достъпни за теб и за всеки, който сканира продукта.';

  @override
  String get contributeAddProductBody =>
      'Продуктът още не е в базата. Добави го с две снимки, за да е достъпен за теб и за всеки, който го сканира.';

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
    return '$product вече е в Open Food Facts и е достъпен за всеки, който го сканира.';
  }

  @override
  String contributeThanksNutrition(String product) {
    return 'Хранителните стойности на $product вече са в Open Food Facts и са достъпни за всички.';
  }

  @override
  String contributeThanksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Твоят принос: $count добавени продукта.',
      one: 'Твоят принос: 1 добавен продукт.',
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
  String get contributePackSize => 'Разфасовка, напр. 400 г';

  @override
  String get contributeServing => 'Порция, напр. 30 г';

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
  String macroRingAtLeast(int grams) {
    return '$grams+ г';
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
      'Целите се определят според плана ти и се променят заедно с него.';

  @override
  String get macroGuideCalories => 'Калории';

  @override
  String get macroGuideCaloriesWhy =>
      'Калориите измерват енергията в храната. Отслабваш, когато приемаш по-малко калории, отколкото изгаряш, и качваш, когато приемаш повече.';

  @override
  String get macroGuideCaloriesTarget =>
      'Изчисляваме дневния ти разход според възрастта, ръста, теглото и активността ти. За отслабване задаваме малко по-ниска цел, а за качване – малко по-висока.';

  @override
  String get macroGuideAimFor => 'Стреми се към';

  @override
  String get macroGuideBalance => 'Поддържай баланс';

  @override
  String get macroGuideKeepUnder => 'Не надвишавай';

  @override
  String get macroGuideKeepUnderNote =>
      'Не надвишавай посочените количества. Редовното превишаване вреди на зъбите и сърцето и повишава кръвното налягане.';

  @override
  String get macroGuideProteinWhy =>
      'Засища, пази мускулите, докато отслабваш, и помага да ги изградиш, докато качваш.';

  @override
  String get macroGuideProteinTarget =>
      'От 1,2 до 2 г на кг от желаното тегло. Колкото повече тренираш, толкова по-висока е целта.';

  @override
  String get macroGuideFibreWhy => 'Засищат и поддържат червата здрави.';

  @override
  String get macroGuideFibreTarget => 'Поне 25 г на ден. Повече е по-добре.';

  @override
  String get macroGuideCarbsWhy =>
      'Основното ти гориво: хляб, ориз, паста, картофи и плодове.';

  @override
  String get macroGuideCarbsTarget =>
      'Останалите калории след протеина и мазнините.';

  @override
  String get macroGuideFatWhy =>
      'Дават енергия и помагат за усвояването на витамините.';

  @override
  String get macroGuideFatTarget => 'Около 30% от калориите ти.';

  @override
  String get macroGuideSugarsWhy =>
      'Дават калории, без да засищат, и вредят на зъбите.';

  @override
  String get macroGuideSugarsTarget => 'Под 18% от калориите ти.';

  @override
  String get macroGuideSaturatesWhy =>
      'Повишават холестерола. Съдържат се в маслото, сиренето, тлъстото месо и сладкишите.';

  @override
  String get macroGuideSaturatesTarget => 'Под 10% от калориите ти.';

  @override
  String get macroGuideSaltWhy =>
      'Повишава кръвното налягане. По-голямата част от солта приемаме с хляба, сиренето и готовите ястия.';

  @override
  String get macroGuideSaltTarget =>
      'Под 6 г на ден – около една чаена лъжичка.';

  @override
  String get macroGuideColours => 'Цветове: ';

  @override
  String macroGuideUnder(int grams) {
    return 'под $grams г';
  }

  @override
  String macroGuideRange(int from, int to) {
    return '$from–$to г';
  }

  @override
  String macroGuideOverUpTo(int percent) {
    return 'до $percent% отгоре';
  }

  @override
  String macroGuideOverRange(int from, int to) {
    return '$from–$to% отгоре';
  }

  @override
  String macroGuideOverMore(int percent) {
    return 'над $percent% отгоре';
  }

  @override
  String get macroGuideWithinLimit => 'в рамките на лимита';

  @override
  String get macroGuideTarget => 'Цел: ';

  @override
  String get macroGuideDisclaimer =>
      'Това са общи насоки за възрастни и не заместват медицински съвет.';

  @override
  String get macroFibreBadge => 'Богато на фибри';

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
  String get historyStatusOnTrack => 'По план';

  @override
  String get historyStatusClose => 'Близо';

  @override
  String get historyStatusOffTrack => 'Извън плана';

  @override
  String get historyNotLogged => 'Без записи';

  @override
  String get historyReviewTomorrow =>
      'Обобщението ще е достъпно утре, след края на днешния ден.';

  @override
  String get historyNothingLogged => 'Още няма записи за този период.';

  @override
  String historyOnTrackCount(int count) {
    return '$count по план';
  }

  @override
  String historyCloseCount(int count) {
    return '$count близо';
  }

  @override
  String historyOffTrackCount(int count) {
    return '$count извън плана';
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
  String get historyOnTrackShare => 'от записаните дни са по план';

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
      'През повечето записани дни калориите са близо до целта.';

  @override
  String get historyGuidanceSomeClose =>
      'През някои дни калориите са близо до целта, но в няколко има големи отклонения.';

  @override
  String get historyGuidanceMostOff =>
      'През повечето записани дни калориите са доста над или под целта.';

  @override
  String historyGuidanceOver(int kcal) {
    return 'Средно калориите ти са с $kcal ккал на ден над целта.';
  }

  @override
  String historyGuidanceOverGoalDate(int kcal) {
    return 'Средно калориите ти са с $kcal ккал на ден над целта, затова срокът за желаното тегло леко се удължава.';
  }

  @override
  String historyGuidanceUnderGoalDate(int kcal) {
    return 'Средно калориите ти са с $kcal ккал на ден под целта, затова срокът за желаното тегло леко се удължава.';
  }

  @override
  String get historyGuidanceLogMore =>
      'За някои дни няма записи. Записвай храненията си по-редовно за по-точно обобщение.';

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
      other: 'За този месец остават $left от $limit промени за минали дни',
      one: 'За този месец остава 1 от $limit промени за минали дни',
    );
    return '$_temp0';
  }

  @override
  String get historyNoChangesLeft =>
      'Промените за минали дни са изчерпани за този месец.';

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
      'Виж дали приемаш препоръчителните количества протеин, фибри, сол и захари и къде има нужда от промяна.';

  @override
  String get coachPromiseAdviceTitle => 'Съвети, които да приложиш веднага';

  @override
  String get coachPromiseAdviceBody =>
      'Избирай по-лесно следващото си хранене с практични съвети и рецепти според обичайните ти хранения.';

  @override
  String get coachPromiseWeeklyTitle => 'Всяка седмица с ясна цел';

  @override
  String get coachPromiseWeeklyBody =>
      'Всеки понеделник разбираш какво ти помага да напредваш и какво можеш да промениш през новата седмица.';

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
  String get coachFirstNotesTitle =>
      'Първите ти съвети ще са готови в понеделник';

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
    return 'AI треньорът обобщава цяла седмица. Засега записвай храненията си. В понеделник, $date, ще получиш съвети за това какво ти помага, какво те затруднява и какво да опиташ през следващата седмица.';
  }

  @override
  String get coachEnded =>
      'Абонаментът ти за YumSum Star изтече. Няма да получаваш нови съвети, но предишните се запазват.';

  @override
  String get coachNotEnough =>
      'Няма достатъчно записи за съвети тази седмица. Нужни са поне 4 дни със записани хранения, без почивните дни.';

  @override
  String get coachLooking => 'Преглеждаме седмицата ти';

  @override
  String get coachErrorLoad =>
      'Не успяхме да заредим съветите за седмицата. Опитай отново.';

  @override
  String get coachTryAgain => 'Опитай отново';

  @override
  String get coachNoNotesPlus =>
      'Няма съвети за тази седмица. AI треньорът ги подготвя през следващата седмица, когато отвориш тази страница.';

  @override
  String get coachNoNotes => 'Няма съвети за тази седмица.';

  @override
  String get coachKeepGoing => 'Продължавай така';

  @override
  String get coachTryThis => 'Опитай това';

  @override
  String get coachNotesComing =>
      'Съветите за тази седмица ще са готови в понеделник.';

  @override
  String get coachNotesReadThat => 'Прочети съветите за седмицата.';

  @override
  String get coachNotesReadThis => 'Прочети съветите за тази седмица.';

  @override
  String coachWeekOf(String date) {
    return 'Седмицата от $date';
  }

  @override
  String get coachPromptLine =>
      'Получи съвети според навиците си. Виж какво ти помага да напредваш и какво те затруднява.';

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
  String get recipesIngredients => 'Продукти';

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
  String get starHeaderMember => 'Всички тези функции са достъпни за теб.';

  @override
  String get starFeatureSnapTitle => 'Запис със снимка';

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
      'Изчислява колко калории изгаряш и съобразява целта с теб.';

  @override
  String get starFeatureCoachTitle => 'AI треньор';

  @override
  String get starFeatureCoachBody =>
      'Преглежда седмицата ти и подсказва какво да подобриш.';

  @override
  String get starFeatureMacrosTitle => 'Подробни макроси';

  @override
  String get starFeatureMacrosBody =>
      'Следи и мазнините, въглехидратите, захарите, фибрите и солта.';

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
  String get starThanks => 'Благодарим ти, че подкрепяш развитието на YumSum.';

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
  String get starStatusPitch => 'Запис със снимка, 30 AI оценки на ден и още';

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
      'Не успяхме да потвърдим покупката ти. Натисни „Възстанови покупка“ след няколко минути. Ако проблемът остане, Google Play ще ти върне парите автоматично до 3 дни.';

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
  String get authOr => 'или';

  @override
  String get authContinueWithGoogle => 'Продължи с Google';

  @override
  String get authVerificationSentTitle => 'Имейлът за потвърждение е изпратен';

  @override
  String authVerificationSentBody(String email) {
    return 'Изпратихме линк на $email. Отвори го, за да потвърдиш профила си, и после влез. Не го виждаш? Провери и папката за спам.';
  }

  @override
  String get authResetTitle => 'Смени паролата си';

  @override
  String get authResetIntro =>
      'Въведи имейла, с който влизаш. Ще изпратим линк, за да избереш нова парола.';

  @override
  String get authResetSend => 'Изпрати линк';

  @override
  String get authResetError => 'Не успяхме да изпратим имейла. Опитай отново.';

  @override
  String get authResetSentTitle => 'Провери пощата си';

  @override
  String authResetSentBody(String email) {
    return 'Ако има профил с $email, изпратихме му линк за нова парола. Може да отнеме няколко минути, затова провери и папката за спам.';
  }

  @override
  String get authErrorVerifyEmail =>
      'Първо потвърди имейла си. Линкът е във входящата ти поща.';

  @override
  String get authResendVerification => 'Изпрати линка отново';

  @override
  String get authErrorGoogle => 'Входът с Google не успя. Опитай отново.';

  @override
  String get authErrorUsePassword =>
      'За този имейл има профил с парола. Влез с нея.';

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
  String get planActivitySedentary => 'Предимно в седнало положение';

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
      'Стоиш на крак или ходиш през голяма част от деня.';

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
      'По-бързи резултати, но с повече ограничения в храненето.';

  @override
  String get planPaceMaintain => 'Запазване на теглото';

  @override
  String get planPaceMaintainHint =>
      'Приемаш приблизително толкова калории, колкото изгаряш, без дефицит.';

  @override
  String planPaceGain(String amount) {
    return 'Качване – $amount седмично';
  }

  @override
  String get planPaceGainHint =>
      'Малък калориен излишък за постепенно качване на тегло.';

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
  String get accountCheckNewEmail =>
      'Провери пощата на новия си адрес и потвърди промяната.';

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
      'Това изтрива профила ти и всичко в него. Не може да се отмени. Изтриването на профила не прекратява абонамента за YumSum Star. Първо го прекрати в Google Play, иначе ще продължи да се подновява.';

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
      'Безплатна база данни от доброволци, достъпна под лиценза Open Database License';

  @override
  String get accountSectionDanger => 'ИЗТРИВАНЕ НА ДАННИ';

  @override
  String get accountChangeEmailTitle => 'Смяна на имейла';

  @override
  String get accountChangeEmailBody =>
      'Ще изпратим линк на новия ти имейл адрес. Промяната ще влезе в сила, когато отвориш линка.';

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
      'За този профил потвърждението с парола не е достъпно.';

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
  String get feedbackSent => 'Съобщението е изпратено. Благодарим ти.';

  @override
  String get feedbackKindProblem => 'Проблем';

  @override
  String get feedbackKindIdea => 'Идея';

  @override
  String get feedbackKindOther => 'Друго';

  @override
  String get feedbackHintProblem => 'Какво се случи и какво очакваше?';

  @override
  String get feedbackHintIdea => 'Какво би направило YumSum по-полезно за теб?';

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
  String get splashSlow =>
      'Отнема повече време от обикновено. Провери връзката си.';

  @override
  String get splashReload => 'Презареди';

  @override
  String get splashTagline => 'Постоянство всеки ден. Винаги във форма.';

  @override
  String get startupErrorTitle => 'YumSum не успя да стартира';

  @override
  String get startupErrorBody =>
      'Презареди страницата. Ако проблемът се повтори, изпрати съобщението по-долу на разработчика.';

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
  String get commonAgeRange => 'Въведи възраст от 18 до 120 години.';

  @override
  String get commonTargetBelowCurrent => 'Трябва да е под сегашното ти тегло';

  @override
  String get commonTargetAboveCurrent => 'Трябва да е над сегашното ти тегло';

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
      'Калориите измерват енергията в храната. Яж малко по-малко, отколкото изгаряш, за да отслабнеш, или малко повече, за да качиш тегло.';

  @override
  String get onboardingLoseWeight => 'Отслабване';

  @override
  String get onboardingKeepWeight => 'Поддържане';

  @override
  String get onboardingGainWeight => 'Качване на тегло';

  @override
  String get onboardingGoalNote =>
      'Можеш да промениш това по всяко време в „Настройки на плана“.';

  @override
  String get onboardingTargetTitle => 'Към какво тегло се стремиш?';

  @override
  String get onboardingActivityTitle => 'Колко се движиш през деня?';

  @override
  String get onboardingActivityBody => 'Без да броим тренировките.';

  @override
  String get onboardingTrainingTitle => 'Колко често тренираш?';

  @override
  String get onboardingTrainingBody => 'Планирани тренировки, ако имаш такива.';

  @override
  String get onboardingProteinTitle => 'Да следим ли и протеина?';

  @override
  String get onboardingProteinBody =>
      'Протеинът те засища и помага да запазиш мускулите, докато отслабваш, или да ги изградиш, докато качваш. YumSum го изчислява за всяко хранене, което запишеш.';

  @override
  String get onboardingBuildingTitle => 'Подготвяме плана ти';

  @override
  String get onboardingBuildingBurn => 'Изчисляваме колко изгаряш…';

  @override
  String get onboardingBuildingTarget => 'Задаваме дневната ти цел…';

  @override
  String get onboardingBuildingPlan => 'Подреждаме плана ти…';

  @override
  String onboardingBuildingPercent(int percent) {
    return '$percent %';
  }

  @override
  String get onboardingBuildingFact =>
      '1 от всеки 8 души по света живее със затлъстяване, а много ежедневни храни съдържат повече калории, отколкото изглежда.';

  @override
  String get onboardingBuildingFactSource =>
      'Световна здравна организация, 2022 г.';

  @override
  String get onboardingBuildingGainFact =>
      'Малкият излишък стига, за да изградиш мускули. Ако ядеш много повече, се трупат предимно мазнини.';

  @override
  String get onboardingBuildingCalorieFact =>
      'Един килограм телесни мазнини съдържа около 7700 ккал, затова малките промени всеки ден се натрупват през седмиците.';

  @override
  String get onboardingBuildingStart =>
      'Днес започваш пътя си с YumSum: да опознаеш какво има в чинията ти и да се подобряваш с всяко хранене.';

  @override
  String get onboardingPlanTitle => 'Планът ти е готов!';

  @override
  String get onboardingPlanCardTitle => 'Твоят план';

  @override
  String get onboardingPlanNote =>
      'Можеш да прегледаш и промениш подробностите в „Настройки на плана“.';

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
  String get planPreviewFloor => 'Минимален прием на калории';

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
      'При това темпо дневната цел би била под минимума, затова срокът за достигане на желаното тегло се удължава.';

  @override
  String get planPreviewSafeNote =>
      'Умерен дефицит спрямо калориите за поддържане на теглото.';

  @override
  String get planPreviewGainNote =>
      'Малък излишък спрямо калориите за поддържане на теглото.';

  @override
  String get planPreviewCautionNote =>
      'Изисква постоянство и по-строги ограничения в храненето.';

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
  String get planPreviewWeeklyGain => 'Темпо';

  @override
  String get planPreviewGoalBy => 'Очаквана дата';

  @override
  String get planPreviewInfoTooltip => 'Как се изчислява';

  @override
  String get planInfoTitle => 'Как изчисляваме калориите';

  @override
  String get planInfoBody =>
      'Първо изчисляваме колко калории изгаряш в покой според теглото, ръста, възрастта и пола ти. Добавяме разхода от движение и тренировки, за да определим калориите за поддържане на теглото.';

  @override
  String get planInfoResting => 'В покой';

  @override
  String get planInfoMovement => 'Движение';

  @override
  String get planInfoTraining => 'Тренировки';

  @override
  String get planInfoActivity => 'Обща активност';

  @override
  String get planInfoMaintenance => 'За поддържане';

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
      'При това темпо дневната цел би била под минимума. Затова я запазваме на минималната стойност и удължаваме срока за достигане на желаното тегло.';

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
      'Промени данните по-долу и планът ще се съобрази с тях.';

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
  String get planTargetStays => 'Целта е да запазиш сегашното си тегло.';

  @override
  String get planSectionMovement => 'ДВИЖЕНИЕТО ТИ ПРЕЗ ДЕНЯ';

  @override
  String get planMovementNote =>
      'Обичайното ти движение през деня, без тренировките.';

  @override
  String get planSectionTraining => 'КОЛКО ЧЕСТО ТРЕНИРАШ?';

  @override
  String get planTrainingNote =>
      'Тренировки в допълнение към ежедневното движение.';

  @override
  String get planSectionProtein => 'ДА СЛЕДИМ ЛИ И ПРОТЕИНА?';

  @override
  String get planProteinNote =>
      'Протеинът помага да запазиш мускулите, докато отслабваш, и да ги изградиш, докато качваш. Ако избереш „Не“, данните за протеин няма да се показват в приложението.';

  @override
  String get planSectionPace => 'ТВОЕТО ТЕМПО';

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
      'Използва записите за теглото ти, за да коригира дневната цел всеки понеделник.';

  @override
  String get planAdaptiveRestarts =>
      'След запазване формулата започва отначало с новия ти план.';

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
      'Формула, съобразена с теб. С времето и записите за теглото ти определя все по-точно нужните калории.';

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
  String get adaptiveBurnLearnt =>
      'Изчислено по записите за теглото и храненията ти.';

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
  String adaptiveTargetGain(String amount) {
    return 'За да качваш по $amount седмично.';
  }

  @override
  String get adaptivePaused =>
      'Формулата е на пауза, защото няма записано тегло от 10 дни. Запиши теглото си, за да продължи да се адаптира към теб.';

  @override
  String adaptiveAtMinimum(String date) {
    return 'Дневната ти цел е на минимума, затова новата дата за желаното тегло е $date.';
  }

  @override
  String adaptiveLowered(String amount) {
    return 'Корекция на целта: $amount ккал. Изгаряш малко по-малко, отколкото предвиждаше планът.';
  }

  @override
  String adaptiveRaised(String amount) {
    return 'Корекция на целта: $amount ккал. Изгаряш малко повече, отколкото предвиждаше планът.';
  }

  @override
  String get adaptiveFirstSign =>
      'Може би изгаряш малко по-малко, отколкото предвижда планът. Ще проверим пак следващия понеделник.';

  @override
  String adaptiveSteadyAdjusted(String amount) {
    return 'Корекция на целта: $amount ккал. Без промяна тази седмица.';
  }

  @override
  String get adaptiveSteady =>
      'Целта остава същата тази седмица. Теглото ти се променя според очакваното за приетите калории.';

  @override
  String get adaptiveFewWeighIns =>
      'Тази седмица има твърде малко претегляния, затова целта ти остава същата.';

  @override
  String get adaptiveFewDays =>
      'Тази седмица има твърде малко записани дни, затова целта ти остава същата.';

  @override
  String get adaptiveUnusual =>
      'Данните се разминават с очакваното. Провери записите за храненията и теглото си.';

  @override
  String adaptiveSum(int plan, String sign, int amount, int target) {
    return '$plan по план $sign $amount корекция = $target ккал';
  }

  @override
  String adaptiveSumMinimum(int plan, String sign, int amount, int target) {
    return '$plan по план $sign $amount корекция = $target ккал (минимум)';
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
    return 'Теглото е записано. Нова цел: $kcal ккал (преди: $previous).';
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
    return 'Претеглянето е изтрито. Нова цел: $kcal ккал (преди: $previous).';
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
  String get progressWeighInNote => 'Планът ти ще се съобрази с новото тегло.';

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
