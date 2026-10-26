// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'Lakbay Romblon';

  @override
  String get navPlan => 'Plano';

  @override
  String get navSchedules => 'Iskedyul';

  @override
  String get navMore => 'Iba pa';

  @override
  String get placeholderDataBanner =>
      'Halimbawang datos lamang. Hindi pa beripikado ang pamasahe at iskedyul.';

  @override
  String get welcomeTitle => 'Maligayang pagdating sa Lakbay Romblon';

  @override
  String get welcomeBody =>
      'Planuhin ang biyahe sa pagitan ng Romblon at Metro Manila mula pinto hanggang pinto: lokal na sakay, barko, bus, at ang aasahan sa bawat hakbang.';

  @override
  String get welcomeSampleNotice =>
      'Gumagamit ng halimbawang datos ang maagang bersyong ito. Laging kumpirmahin ang pamasahe at iskedyul sa shipping line o kompanya ng bus.';

  @override
  String get welcomeStart => 'Magsimula';

  @override
  String get plannerTitle => 'Magplano ng biyahe';

  @override
  String get directionToManila => 'Papuntang Maynila';

  @override
  String get directionToRomblon => 'Pauwi';

  @override
  String get hometownLabel => 'Ang inyong bayan sa Romblon';

  @override
  String get manilaEndTo => 'Saan sa Metro Manila?';

  @override
  String get manilaEndFrom => 'Aalis mula sa (Metro Manila)';

  @override
  String get otherPlace => 'Ibang lugar';

  @override
  String get customPlaceName => 'Pangalan ng lugar';

  @override
  String get customNearestHub => 'Pinakamalapit na terminal ng bus';

  @override
  String get customFareLabel =>
      'Tantiyang pamasahe para sa bahaging ito (₱, opsyonal)';

  @override
  String get customMinutesLabel => 'Tantiyang oras (minuto, opsyonal)';

  @override
  String get departureLabel => 'Kailan kayo aalis?';

  @override
  String get departureAny =>
      'Kahit anong araw (hindi kasama ang oras ng paghihintay)';

  @override
  String get departurePick => 'Pumili ng petsa at oras';

  @override
  String get departureClear => 'Burahin ang petsa';

  @override
  String get travellersLabel => 'Mga pasahero';

  @override
  String get passengerRegular => 'Regular';

  @override
  String get passengerStudent => 'Estudyante';

  @override
  String get passengerSenior => 'Senior citizen';

  @override
  String get passengerPwd => 'PWD';

  @override
  String decrease(String type) {
    return 'Bawasan ang $type';
  }

  @override
  String increase(String type) {
    return 'Dagdagan ang $type';
  }

  @override
  String get fareClassLabel => 'Klase sa barko';

  @override
  String get fareClassAny => 'Pinakamura na mayroon';

  @override
  String get fareClassEconomy => 'Economy';

  @override
  String get fareClassTourist => 'Tourist (may aircon)';

  @override
  String get fareClassCabin => 'Cabin';

  @override
  String get findRoutes => 'Hanapin ang mga ruta';

  @override
  String get errorPickHometown => 'Pakipili ang inyong bayan.';

  @override
  String get errorCustomName => 'Pakilagay ang pangalan ng lugar.';

  @override
  String get errorNoTravellers => 'Magdagdag ng kahit isang pasahero.';

  @override
  String get errorNumber => 'Maglagay ng numero, o iwanang blangko.';

  @override
  String get resultsTitle => 'Mga ruta';

  @override
  String get sortLabel => 'Ayusin ayon sa';

  @override
  String get sortCheapest => 'Pinakamura';

  @override
  String get sortFastest => 'Pinakamabilis';

  @override
  String get sortFewestTransfers => 'Pinakakaunting lipat';

  @override
  String get noRoutes =>
      'Walang nakitang ruta para sa biyaheng ito. Subukan ang ibang destinasyon o klase sa barko.';

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lipat',
      one: '1 lipat',
      zero: 'Walang lipat',
    );
    return '$_temp0';
  }

  @override
  String viaPorts(String from, String to) {
    return '$from → $to';
  }

  @override
  String get planDetailTitle => 'Plano ng biyahe';

  @override
  String get planNotFound => 'Wala na ang rutang ito. Pakiplano muli.';

  @override
  String get planAgain => 'Magplano muli';

  @override
  String get totalFare => 'Pamasahe';

  @override
  String get totalFees => 'Terminal fee';

  @override
  String get totalCost => 'Kabuuan';

  @override
  String get totalTime => 'Mula pinto hanggang pinto';

  @override
  String arrivalWindow(String earliest, String latest) {
    return 'Darating $earliest – $latest';
  }

  @override
  String get warningPlaceholder =>
      'May kasamang halimbawang halaga na hindi pa beripikado ang tantiyang ito.';

  @override
  String get warningNoSchedule =>
      'Hindi kasama ang paghihintay sa alis. Pumili ng petsa para maisama ito.';

  @override
  String get warningMissingEstimate =>
      'Walang tantiyang pamasahe ang huling bahagi ng biyahe, kaya hindi ito kasama sa kabuuan.';

  @override
  String travellerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Para sa $count pasahero',
      one: 'Para sa 1 pasahero',
    );
    return '$_temp0';
  }

  @override
  String legRide(String mode, String from, String to) {
    return '$mode: $from → $to';
  }

  @override
  String legShip(String from, String to) {
    return 'Barko: $from → $to';
  }

  @override
  String legBus(String from, String to) {
    return 'Bus: $from → $to';
  }

  @override
  String legCustom(String from, String to) {
    return '$from → $to';
  }

  @override
  String get modeWalk => 'Lakad';

  @override
  String get modeTricycle => 'Tricycle';

  @override
  String get modeJeepney => 'Jeep';

  @override
  String get modeVan => 'Van';

  @override
  String get modeMulticab => 'Multicab';

  @override
  String get modeHabalHabal => 'Habal-habal';

  @override
  String get modePumpboat => 'Bangkang de-motor';

  @override
  String get modeTaxi => 'Taxi';

  @override
  String stopsAt(String ports) {
    return 'Dadaan sa $ports';
  }

  @override
  String departsAt(String time) {
    return 'Aalis $time';
  }

  @override
  String checkInNote(int minutes) {
    return 'Nasa pantalan na nang hindi bababa sa $minutes minuto bago umalis';
  }

  @override
  String waitTime(String range) {
    return 'Paghihintay: $range';
  }

  @override
  String get perTripFare => 'bawat biyahe, hati-hati';

  @override
  String get yourEstimate => 'sariling tantiya';

  @override
  String get noEstimate => 'walang tantiya';

  @override
  String get freeLeg => 'Libre';

  @override
  String feeIncluded(String amount) {
    return '+ $amount terminal fee bawat tao';
  }

  @override
  String get badgePlaceholder => 'Halimbawa, hindi beripikado';

  @override
  String badgeVerified(String date) {
    return 'Beripikado $date';
  }

  @override
  String badgeStale(String date) {
    return 'Beripikado $date, maaaring luma na';
  }

  @override
  String get badgeUserEstimate => 'Sariling tantiya';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours oras $minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours oras';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get startFirstTimer => 'First-Timer Mode';

  @override
  String get checkBudget => 'Suriin ang budget';

  @override
  String get saveTrip => 'I-save ang biyahe';

  @override
  String get tripSaved => 'Na-save ang biyahe sa Aking mga biyahe.';

  @override
  String get firstTimerTitle => 'First-Timer Mode';

  @override
  String firstTimerProgress(int done, int total) {
    return '$done sa $total tapos na';
  }

  @override
  String get whatHappensNext => 'Ano ang susunod';

  @override
  String get firstTimerAllDone => 'Tapos na lahat. Ingat sa biyahe!';

  @override
  String get firstTimerCurrent => 'Narito ka';

  @override
  String get budgetTitle => 'Budget planner';

  @override
  String get budgetCash => 'Magkano ang pera ninyo? (₱)';

  @override
  String get budgetFoodPerMeal => 'Pagkain bawat kain, bawat tao (₱)';

  @override
  String get budgetMeals => 'Bilang ng kain sa biyahe';

  @override
  String get budgetExtras => 'Iba pang gastos (₱)';

  @override
  String get budgetExtrasHint => 'Pasalubong, load, atbp.';

  @override
  String budgetBufferPercent(int percent) {
    return 'Pang-emergency na reserba: $percent%';
  }

  @override
  String budgetBufferMinimum(String amount) {
    return 'Hindi bababa sa $amount';
  }

  @override
  String get budgetManualFares => 'Tantiyang pamasahe (₱)';

  @override
  String get budgetManualFees => 'Tantiyang terminal fee (₱)';

  @override
  String get budgetFromPlan =>
      'Galing sa plano ng biyahe ang pamasahe at fee (mas mataas na tantiya, para sigurado).';

  @override
  String get budgetNoPlan =>
      'Walang napiling biyahe. Ilagay ang sariling tantiyang pamasahe, o magplano muna ng biyahe.';

  @override
  String get budgetFares => 'Pamasahe';

  @override
  String get budgetFees => 'Terminal fee';

  @override
  String get budgetFood => 'Pagkain';

  @override
  String get budgetOther => 'Iba pang gastos';

  @override
  String get budgetBuffer => 'Pang-emergency na reserba';

  @override
  String get budgetNeeded => 'Kailangan ninyo';

  @override
  String get budgetYouHave => 'Mayroon kayo';

  @override
  String budgetLeftover(String amount) {
    return 'Matitira: $amount';
  }

  @override
  String budgetShortBy(String amount) {
    return 'Kulang ng: $amount';
  }

  @override
  String get budgetCovered => 'Sapat ang pera ninyo para sa biyaheng ito.';

  @override
  String get budgetTight =>
      'Sapat para sa biyahe, pero kulang ang pang-emergency na reserba.';

  @override
  String get budgetShort => 'Hindi pa sapat para sa biyaheng ito.';

  @override
  String get schedulesTitle => 'Iskedyul';

  @override
  String get tabShips => 'Barko';

  @override
  String get tabBuses => 'Bus';

  @override
  String get filterPort => 'Pantalan';

  @override
  String get allPorts => 'Lahat ng pantalan';

  @override
  String get everyDay => 'Araw-araw';

  @override
  String sailingDays(String days) {
    return 'Biyahe: $days';
  }

  @override
  String get voyageStops => 'Mga hintuan';

  @override
  String get fareTable => 'Pamasahe (bawat tao, regular)';

  @override
  String get checkIn => 'Check-in';

  @override
  String busHours(String first, String last, int minutes) {
    return '$first – $last, mga bawat $minutes min';
  }

  @override
  String get dropOffs => 'Mga babaan';

  @override
  String get aircon => 'May aircon';

  @override
  String get noSchedules => 'Walang iskedyul para sa pantalang ito.';

  @override
  String dayLater(int days) {
    return '+$days araw';
  }

  @override
  String get tripsTitle => 'Aking mga biyahe';

  @override
  String get noTrips =>
      'Wala pang naka-save na biyahe. Magplano ng biyahe at pindutin ang I-save ang biyahe.';

  @override
  String get deleteTrip => 'Burahin ang biyahe';

  @override
  String get moreTitle => 'Iba pa';

  @override
  String get aboutTitle => 'Tungkol sa app at datos';

  @override
  String get aboutBody =>
      'Tinutulungan ng Lakbay Romblon ang mga taga-Romblon na makarating sa Metro Manila at makauwi, kasama ang lokal na sakay, barko at bus sa iisang plano.';

  @override
  String get aboutDisclaimer =>
      'Madalas magbago ang pamasahe, iskedyul at tagal ng biyahe. Ipinapakita ng bawat halaga kung kailan ito huling beripikado. Hindi pa totoo ang mga halagang may markang halimbawa. Laging kumpirmahin sa operator.';

  @override
  String dataVersion(int version) {
    return 'Bersyon ng datos $version';
  }

  @override
  String dataPrepared(String date) {
    return 'Inihanda ang datos $date';
  }

  @override
  String get loadError => 'Hindi ma-load ang datos ng biyahe.';

  @override
  String get retry => 'Subukang muli';

  @override
  String get navGuide => 'Gabay';

  @override
  String get navSafety => 'Kaligtasan';

  @override
  String get myTrips => 'Aking mga biyahe';

  @override
  String get guideTitle => 'Gabay sa pantalan at terminal';

  @override
  String get guidePorts => 'Mga pantalan';

  @override
  String get guideTerminals => 'Mga terminal ng bus';

  @override
  String get useMyLocation => 'Gamitin ang aking lokasyon';

  @override
  String get locating => 'Hinahanap ang inyong lokasyon…';

  @override
  String get locationDenied =>
      'Hindi pinayagan ang lokasyon. Magagamit pa rin ninyo ang lahat ng gabay.';

  @override
  String get locationOff => 'Naka-off ang lokasyon sa inyong cellphone.';

  @override
  String get locationError => 'Hindi makuha ang inyong lokasyon.';

  @override
  String get locationPrivacy =>
      'Nananatili sa inyong cellphone ang inyong lokasyon.';

  @override
  String distanceKm(String km) {
    return '$km km ang layo';
  }

  @override
  String get nearestBadge => 'Pinakamalapit';

  @override
  String get tabLayout => 'Plano ng lugar';

  @override
  String get tabMap => 'Mapa';

  @override
  String get tabTips => 'Payo';

  @override
  String get layoutIllustrative =>
      'Halimbawang plano lamang, hindi eksakto ang sukat. Tiyakin sa mismong lugar.';

  @override
  String get layoutAreas => 'Mga bahagi';

  @override
  String get seaSide => 'Dagat';

  @override
  String get mapNeedsInternet =>
      'Kailangan ng internet ang mapa. Kung walang koneksyon, gamitin ang tab na Plano ng lugar.';

  @override
  String get mapTilesFailed =>
      'Hindi ma-load ang mapa. Suriin ang koneksyon o gamitin ang tab na Plano ng lugar.';

  @override
  String get myLocation => 'Aking lokasyon';

  @override
  String get noLocationForPlace =>
      'Wala pang lokasyon sa mapa ang lugar na ito.';

  @override
  String get photosTitle => 'Mga larawan';

  @override
  String get noPhotos => 'Wala pang larawan.';

  @override
  String get noGuide => 'Wala pang gabay para sa lugar na ito.';

  @override
  String get safetyTitle => 'Kaligtasan';

  @override
  String get emergencyCallout => 'Kung may emergency, tumawag sa 911.';

  @override
  String get hotlinesTitle => 'Mga emergency hotline';

  @override
  String get hotlinesNational => 'Pambansa';

  @override
  String get hotlinesProvince => 'Probinsya ng Romblon';

  @override
  String get hotlinesPorts => 'Mga pantalan';

  @override
  String get hotlinesTowns => 'Mga bayan';

  @override
  String get hotlinesYourTown => 'Ang inyong bayan';

  @override
  String callNumber(String number) {
    return 'Tawagan ang $number';
  }

  @override
  String get numberNeeded => 'Kailangan pa ng numero';

  @override
  String get hotlineUnverified =>
      'Hindi pa beripikado. Kumpirmahin bago umasa rito.';

  @override
  String get callFailed => 'Hindi mabuksan ang dialer ng telepono.';

  @override
  String get scamTitle => 'Babala sa panloloko';

  @override
  String get safetyTipsTitle => 'Payo sa kaligtasan';

  @override
  String get cancellationTitle => 'Kung kanselado ang biyahe';

  @override
  String get sosTitle => 'Ipakita ito sa kawani';

  @override
  String sosBody(String from, String to) {
    return 'Bumibiyahe ako mula $from papuntang $to. Pakitulungan akong hanapin ang aking barko o bus.';
  }

  @override
  String get sosNoTrip => 'Magplano ng biyahe para makita rito ang buod nito.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Wika';

  @override
  String get languageSystem => 'Wika ng cellphone';

  @override
  String get translationDraft => 'draft, kailangang suriin';

  @override
  String get translationInProgress => 'isinasalin pa';

  @override
  String get textSizeLabel => 'Laki ng teksto';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Malaki';

  @override
  String get textSizeExtraLarge => 'Mas malaki';

  @override
  String get textSizePreview => 'Ganito ang magiging itsura ng teksto.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Nananatili sa inyong cellphone ang inyong mga biyahe, progreso sa checklist at lokasyon. Galing sa OpenStreetMap ang larawan ng mapa, at sa Google Firebase ang mga update at larawan. Walang pangalan o numero ang mga ulat na ipinapadala ninyo. Naka-off ang mga alerto maliban kung bubuksan ninyo.';

  @override
  String get advisoriesTitle => 'Mga abiso';

  @override
  String get advisoriesActive => 'Umiiral ngayon';

  @override
  String get advisoriesUpcoming => 'Paparating';

  @override
  String get advisoriesEnded => 'Kakatapos lang';

  @override
  String get advisoriesNone => 'Walang abiso sa ngayon.';

  @override
  String advisoriesMore(int count) {
    return '+$count pa';
  }

  @override
  String get advisoryConfirm =>
      'Laging kumpirmahin sa Coast Guard o sa shipping line bago bumiyahe.';

  @override
  String advisoryFrom(String date) {
    return 'Mula $date';
  }

  @override
  String get advisoryGone => 'Wala na ang abisong ito.';

  @override
  String get advisoryHasEnded => 'Tapos na ang abisong ito.';

  @override
  String get advisoryValidFrom => 'Simula';

  @override
  String get advisoryValidUntil => 'Katapusan';

  @override
  String get advisoryUntilFurtherNotice => 'Hanggang may bagong abiso';

  @override
  String get advisorySource => 'Pinagmulan';

  @override
  String get advisoryPublished => 'Inilathala';

  @override
  String get advisoryAffects => 'Mga apektadong biyahe';

  @override
  String get advisoryAllTrips => 'Lahat ng biyahe sa dagat sa Romblon';

  @override
  String get severitySuspended => 'Suspendido';

  @override
  String get severityCaution => 'Mag-ingat';

  @override
  String get severityInfo => 'Paalala';

  @override
  String tripAffected(String title) {
    return 'Abiso: $title';
  }

  @override
  String get resultsAdvisoryNotice => 'May mga biyaheng apektado ng abiso.';

  @override
  String get resultsAvoidAdvisories =>
      'Ipakita lang ang mga biyaheng iiwas dito';

  @override
  String get resultsCannotAvoid =>
      'Sakop nito ang lahat ng biyahe sa dagat, kaya walang ibang daan. Hintaying matapos ang abiso.';

  @override
  String get noRoutesAvoiding =>
      'Walang biyaheng nakaiiwas sa abiso. Patayin ang filter para makita lahat.';

  @override
  String get reportUpdate => 'Mag-ulat ng pagbabago';

  @override
  String get reportTitle => 'Mag-ulat ng pagbabago';

  @override
  String get reportAbout => 'Tungkol sa';

  @override
  String get reportWhat => 'Ano ang nagbago?';

  @override
  String get reportKindFare => 'Nagbago ang pamasahe';

  @override
  String get reportKindSchedule => 'Nagbago ang iskedyul';

  @override
  String get reportKindDelay => 'Naantala o kinansela';

  @override
  String get reportKindWrong => 'Maling impormasyon';

  @override
  String get reportKindOther => 'Iba pa';

  @override
  String get reportSuggested => 'Tamang halaga (opsyonal)';

  @override
  String get reportSuggestedHint => 'hal. ₱720, o umaalis 19:30';

  @override
  String get reportNote => 'Detalye (opsyonal)';

  @override
  String get reportNoteHint => 'Ano ang nakita mo, at kailan?';

  @override
  String get reportNeedsText => 'Ilagay ang tamang halaga o ilang detalye.';

  @override
  String get reportPrivacy =>
      'Hindi kailangan ang pangalan o numero ng telepono. Huwag isama ang personal na detalye. Sinusuri ng admin ang bawat ulat bago may baguhin.';

  @override
  String get reportSend => 'Ipadala ang ulat';

  @override
  String get reportSent => 'Salamat! Naipadala ang ulat mo para suriin.';

  @override
  String get reportQueued => 'Na-save. Ipapadala ito kapag may internet ka na.';

  @override
  String get reportLimit =>
      'Naabot mo na ang pinakamaraming ulat ngayong araw. Ipapadala ito bukas.';

  @override
  String get myReportsTitle => 'Aking mga ulat';

  @override
  String get myReportsSubtitle =>
      'Mga ipinadala mong ulat at ang kalagayan nila';

  @override
  String get myReportsNone => 'Wala ka pang naipadalang ulat.';

  @override
  String get reportStatusWaiting => 'Naghihintay maipadala';

  @override
  String get reportStatusPending => 'Naipadala, hinihintay ang pagsusuri';

  @override
  String get reportStatusApproved => 'Inaprubahan, salamat!';

  @override
  String get reportStatusRejected => 'Hindi ginamit';

  @override
  String reportRejectReason(String reason) {
    return 'Dahilan: $reason';
  }

  @override
  String get photoLoading => 'Nilo-load ang larawan…';

  @override
  String get photoUnavailable => 'Hindi pa makikita ang larawan nang offline';

  @override
  String photoNumber(int number) {
    return 'Larawan $number';
  }

  @override
  String photoCredit(String credit) {
    return 'Larawan: $credit';
  }

  @override
  String get photosSaveOffline => 'I-save ang mga larawan para sa offline';

  @override
  String get photosSaved => 'Naka-save ang mga larawan sa teleponong ito';

  @override
  String get photosSaveFailed =>
      'May mga larawang hindi na-save. Subukang muli gamit ang Wi-Fi.';

  @override
  String get photosMobileDataTitle => 'Gagamit ng mobile data?';

  @override
  String photosMobileDataBody(int count) {
    return 'Naka-mobile data ka. I-download ang $count larawan (hanggang 200 KB bawat isa)?';
  }

  @override
  String get photosDownload => 'I-download';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get dataTitle => 'Datos ng biyahe';

  @override
  String dataLastUpdated(String date) {
    return 'Huling na-update $date';
  }

  @override
  String get dataNeverUpdated => 'Ginagamit ang datos na kasama ng app.';

  @override
  String get syncNow => 'I-refresh ngayon';

  @override
  String get syncUpdated => 'Na-update ang datos ng biyahe.';

  @override
  String get syncUpToDate => 'Pinakabago na.';

  @override
  String get syncFailed =>
      'Hindi ma-refresh. Tingnan ang internet mo at subukang muli.';

  @override
  String get syncNotConfigured =>
      'Hindi pa naka-set up ang online na update sa bersyong ito.';

  @override
  String get alertsTitle => 'Mga alerto sa abiso';

  @override
  String get alertsEnable => 'Alertuhan ako tungkol sa suspensyon at babala';

  @override
  String get alertsExplain =>
      'Para lang sa biyaheng suspendido o kailangang mag-ingat. Puwede mo itong patayin anumang oras.';

  @override
  String get alertsAllRomblon => 'Buong Romblon';

  @override
  String get alertsChosenPorts => 'Ang mga daungang ito lang';

  @override
  String get alertsPermissionDenied =>
      'Naka-off ang notification para sa app na ito. Buksan ito sa settings ng telepono.';

  @override
  String get alertsFailed =>
      'Hindi ma-update ang mga alerto. Tingnan ang internet mo at subukang muli.';

  @override
  String get fareClassComfort => 'Comfort (reclining na upuan)';

  @override
  String get fareClassPremium => 'Premium (may aircon)';

  @override
  String get fareClassReclining => 'Reclining na upuan';

  @override
  String get fareClassEconomyBed => 'Economy na kama';

  @override
  String get fareClassTouristBed => 'Tourist na kama';

  @override
  String get fareClassVipRoom => 'VIP na kuwarto';

  @override
  String get timeToConfirm => 'Kukumpirmahin pa';

  @override
  String get timeEstimateSuffix => '(tantiya)';

  @override
  String get timesToConfirmNotice =>
      'May mga araw o oras sa biyaheng ito na hindi pa kumpirmado. Magtanong sa shipping line bago bumiyahe.';

  @override
  String get priceHalfFare =>
      'Kalahating pamasahe (itanong sa shipping line kung sino ang puwede)';

  @override
  String get priceMinor => 'Bata (2–11 taon)';

  @override
  String get priceInfant => 'Sanggol (wala pang 2 taon)';

  @override
  String roomPrice(String price, int count) {
    return '$price bawat kuwarto (para sa $count tao)';
  }

  @override
  String get discountPricesLabel => 'Presyo para sa may diskwento';

  @override
  String get contactTitle => 'Makipag-ugnayan sa shipping line';

  @override
  String officeLabel(String address) {
    return 'Opisina: $address';
  }

  @override
  String get openOfficialPage => 'Opisyal na pahina';

  @override
  String get openBooking => 'Mag-book online';
}
