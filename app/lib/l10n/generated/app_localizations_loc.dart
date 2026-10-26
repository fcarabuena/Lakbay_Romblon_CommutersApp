// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Inonhan (`loc`).
class AppLocalizationsLoc extends AppLocalizations {
  AppLocalizationsLoc([String locale = 'loc']) : super(locale);

  @override
  String get appTitle => 'Lakbay Romblon';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSchedules => 'Schedules';

  @override
  String get navMore => 'More';

  @override
  String get placeholderDataBanner =>
      'Sample data only. Fares and schedules are not verified yet.';

  @override
  String get welcomeTitle => 'Welcome to Lakbay Romblon';

  @override
  String get welcomeBody =>
      'Plan your trip between Romblon and Metro Manila, door to door: local rides, ships, buses, and what to expect at each step.';

  @override
  String get welcomeSampleNotice =>
      'This early version uses sample data. Always confirm fares and schedules with the shipping line or bus company.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get plannerTitle => 'Plan a trip';

  @override
  String get directionToManila => 'To Manila';

  @override
  String get directionToRomblon => 'Going home';

  @override
  String get hometownLabel => 'Your hometown in Romblon';

  @override
  String get manilaEndTo => 'Where in Metro Manila?';

  @override
  String get manilaEndFrom => 'Leaving from (Metro Manila)';

  @override
  String get otherPlace => 'Other place';

  @override
  String get customPlaceName => 'Place name';

  @override
  String get customNearestHub => 'Nearest bus hub';

  @override
  String get customFareLabel =>
      'Your fare estimate for this part (₱, optional)';

  @override
  String get customMinutesLabel => 'Your time estimate (minutes, optional)';

  @override
  String get departureLabel => 'When are you leaving?';

  @override
  String get departureAny => 'Any day (waiting time not included)';

  @override
  String get departurePick => 'Pick date and time';

  @override
  String get departureClear => 'Clear date';

  @override
  String get travellersLabel => 'Travellers';

  @override
  String get passengerRegular => 'Regular';

  @override
  String get passengerStudent => 'Student';

  @override
  String get passengerSenior => 'Senior citizen';

  @override
  String get passengerPwd => 'PWD';

  @override
  String decrease(String type) {
    return 'Fewer $type';
  }

  @override
  String increase(String type) {
    return 'More $type';
  }

  @override
  String get fareClassLabel => 'Ship class';

  @override
  String get fareClassAny => 'Cheapest available';

  @override
  String get fareClassEconomy => 'Economy';

  @override
  String get fareClassTourist => 'Tourist (air-conditioned)';

  @override
  String get fareClassCabin => 'Cabin';

  @override
  String get findRoutes => 'Find routes';

  @override
  String get errorPickHometown => 'Please pick your hometown.';

  @override
  String get errorCustomName => 'Please enter the place name.';

  @override
  String get errorNoTravellers => 'Add at least one traveller.';

  @override
  String get errorNumber => 'Enter a number, or leave it empty.';

  @override
  String get resultsTitle => 'Routes';

  @override
  String get sortLabel => 'Sort by';

  @override
  String get sortCheapest => 'Cheapest';

  @override
  String get sortFastest => 'Fastest';

  @override
  String get sortFewestTransfers => 'Fewest transfers';

  @override
  String get noRoutes =>
      'No routes found for this trip. Try another destination or ship class.';

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers',
      one: '1 transfer',
      zero: 'No transfers',
    );
    return '$_temp0';
  }

  @override
  String viaPorts(String from, String to) {
    return '$from → $to';
  }

  @override
  String get planDetailTitle => 'Trip plan';

  @override
  String get planNotFound =>
      'This route is no longer available. Please plan again.';

  @override
  String get planAgain => 'Plan again';

  @override
  String get totalFare => 'Fares';

  @override
  String get totalFees => 'Terminal fees';

  @override
  String get totalCost => 'Total';

  @override
  String get totalTime => 'Door to door';

  @override
  String arrivalWindow(String earliest, String latest) {
    return 'Arrive $earliest – $latest';
  }

  @override
  String get warningPlaceholder =>
      'This estimate includes unverified sample values.';

  @override
  String get warningNoSchedule =>
      'Waiting for departures is not included. Pick a date to include it.';

  @override
  String get warningMissingEstimate =>
      'The last part of the trip has no fare estimate, so it is not in the total.';

  @override
  String travellerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'For $count travellers',
      one: 'For 1 traveller',
    );
    return '$_temp0';
  }

  @override
  String legRide(String mode, String from, String to) {
    return '$mode: $from → $to';
  }

  @override
  String legShip(String from, String to) {
    return 'Ship: $from → $to';
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
  String get modeWalk => 'Walk';

  @override
  String get modeTricycle => 'Tricycle';

  @override
  String get modeJeepney => 'Jeepney';

  @override
  String get modeVan => 'Van';

  @override
  String get modeMulticab => 'Multicab';

  @override
  String get modeHabalHabal => 'Habal-habal';

  @override
  String get modePumpboat => 'Pumpboat';

  @override
  String get modeTaxi => 'Taxi';

  @override
  String stopsAt(String ports) {
    return 'Stops at $ports';
  }

  @override
  String departsAt(String time) {
    return 'Departs $time';
  }

  @override
  String checkInNote(int minutes) {
    return 'Be at the port at least $minutes min before departure';
  }

  @override
  String waitTime(String range) {
    return 'Waiting: $range';
  }

  @override
  String get perTripFare => 'per trip, shared';

  @override
  String get yourEstimate => 'your own estimate';

  @override
  String get noEstimate => 'no estimate';

  @override
  String get freeLeg => 'Free';

  @override
  String feeIncluded(String amount) {
    return '+ $amount terminal fee per person';
  }

  @override
  String get badgePlaceholder => 'Sample, not verified';

  @override
  String badgeVerified(String date) {
    return 'Verified $date';
  }

  @override
  String badgeStale(String date) {
    return 'Verified $date, may be outdated';
  }

  @override
  String get badgeUserEstimate => 'Your estimate';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get startFirstTimer => 'First-Timer Mode';

  @override
  String get checkBudget => 'Check my budget';

  @override
  String get saveTrip => 'Save trip';

  @override
  String get tripSaved => 'Trip saved to My trips.';

  @override
  String get firstTimerTitle => 'First-Timer Mode';

  @override
  String firstTimerProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get firstTimerAllDone => 'All done. Have a safe trip!';

  @override
  String get firstTimerCurrent => 'You are here';

  @override
  String get budgetTitle => 'Budget planner';

  @override
  String get budgetCash => 'How much money do you have? (₱)';

  @override
  String get budgetFoodPerMeal => 'Food per meal, per person (₱)';

  @override
  String get budgetMeals => 'Meals on the way';

  @override
  String get budgetExtras => 'Other expenses (₱)';

  @override
  String get budgetExtrasHint => 'Pasalubong, load, etc.';

  @override
  String budgetBufferPercent(int percent) {
    return 'Emergency buffer: $percent%';
  }

  @override
  String budgetBufferMinimum(String amount) {
    return 'At least $amount';
  }

  @override
  String get budgetManualFares => 'Estimated fares (₱)';

  @override
  String get budgetManualFees => 'Estimated terminal fees (₱)';

  @override
  String get budgetFromPlan =>
      'Fares and fees come from your trip plan (higher estimate, to be safe).';

  @override
  String get budgetNoPlan =>
      'No trip selected. Enter your own fare estimate, or plan a trip first.';

  @override
  String get budgetFares => 'Fares';

  @override
  String get budgetFees => 'Terminal fees';

  @override
  String get budgetFood => 'Food';

  @override
  String get budgetOther => 'Other expenses';

  @override
  String get budgetBuffer => 'Emergency buffer';

  @override
  String get budgetNeeded => 'You need';

  @override
  String get budgetYouHave => 'You have';

  @override
  String budgetLeftover(String amount) {
    return 'Left over: $amount';
  }

  @override
  String budgetShortBy(String amount) {
    return 'Short by: $amount';
  }

  @override
  String get budgetCovered => 'Your money covers this trip.';

  @override
  String get budgetTight =>
      'Enough for the trip, but your emergency buffer is low.';

  @override
  String get budgetShort => 'Not enough for this trip yet.';

  @override
  String get schedulesTitle => 'Schedules';

  @override
  String get tabShips => 'Ships';

  @override
  String get tabBuses => 'Buses';

  @override
  String get filterPort => 'Port';

  @override
  String get allPorts => 'All ports';

  @override
  String get everyDay => 'Every day';

  @override
  String sailingDays(String days) {
    return 'Sails: $days';
  }

  @override
  String get voyageStops => 'Stops';

  @override
  String get fareTable => 'Fares (per person, regular)';

  @override
  String get checkIn => 'Check-in';

  @override
  String busHours(String first, String last, int minutes) {
    return '$first – $last, about every $minutes min';
  }

  @override
  String get dropOffs => 'Drop-off points';

  @override
  String get aircon => 'Air-conditioned';

  @override
  String get noSchedules => 'No schedules for this port.';

  @override
  String dayLater(int days) {
    return '+$days day';
  }

  @override
  String get tripsTitle => 'My trips';

  @override
  String get noTrips => 'No saved trips yet. Plan a trip and tap Save trip.';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get moreTitle => 'More';

  @override
  String get aboutTitle => 'About and data';

  @override
  String get aboutBody =>
      'Lakbay Romblon helps travellers from Romblon get to Metro Manila and back home, with local rides, ships and buses in one plan.';

  @override
  String get aboutDisclaimer =>
      'Fares, schedules and travel times change often. Every value shows when it was last verified. Values marked as samples are not real yet. Always confirm with the operator.';

  @override
  String dataVersion(int version) {
    return 'Data version $version';
  }

  @override
  String dataPrepared(String date) {
    return 'Data prepared $date';
  }

  @override
  String get loadError => 'Could not load travel data.';

  @override
  String get retry => 'Try again';

  @override
  String get navGuide => 'Guide';

  @override
  String get navSafety => 'Safety';

  @override
  String get myTrips => 'My trips';

  @override
  String get guideTitle => 'Pier and terminal guides';

  @override
  String get guidePorts => 'Ports';

  @override
  String get guideTerminals => 'Bus terminals';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locating => 'Finding your location…';

  @override
  String get locationDenied =>
      'Location permission was not given. You can still use every guide.';

  @override
  String get locationOff => 'Location is turned off on your phone.';

  @override
  String get locationError => 'Could not get your location.';

  @override
  String get locationPrivacy => 'Your location stays on your phone.';

  @override
  String distanceKm(String km) {
    return '$km km away';
  }

  @override
  String get nearestBadge => 'Nearest';

  @override
  String get tabLayout => 'Layout';

  @override
  String get tabMap => 'Map';

  @override
  String get tabTips => 'Tips';

  @override
  String get layoutIllustrative =>
      'Illustrative layout, not to scale. Verify on site.';

  @override
  String get layoutAreas => 'Areas';

  @override
  String get seaSide => 'Sea';

  @override
  String get mapNeedsInternet =>
      'The map needs internet. Without a connection, use the Layout tab.';

  @override
  String get mapTilesFailed =>
      'Map tiles could not load. Check your connection or use the Layout tab.';

  @override
  String get myLocation => 'My location';

  @override
  String get noLocationForPlace => 'This place has no map location yet.';

  @override
  String get photosTitle => 'Photos';

  @override
  String get noPhotos => 'No photos yet.';

  @override
  String get noGuide => 'No guide for this place yet.';

  @override
  String get safetyTitle => 'Safety';

  @override
  String get emergencyCallout => 'In an emergency, call 911.';

  @override
  String get hotlinesTitle => 'Emergency hotlines';

  @override
  String get hotlinesNational => 'National';

  @override
  String get hotlinesProvince => 'Romblon province';

  @override
  String get hotlinesPorts => 'Ports';

  @override
  String get hotlinesTowns => 'Towns';

  @override
  String get hotlinesYourTown => 'Your hometown';

  @override
  String callNumber(String number) {
    return 'Call $number';
  }

  @override
  String get numberNeeded => 'Number needed';

  @override
  String get hotlineUnverified =>
      'Not yet verified. Confirm before relying on it.';

  @override
  String get callFailed => 'Could not open the phone dialer.';

  @override
  String get scamTitle => 'Scam warnings';

  @override
  String get safetyTipsTitle => 'Safety tips';

  @override
  String get cancellationTitle => 'If your trip is cancelled';

  @override
  String get sosTitle => 'Show this to staff';

  @override
  String sosBody(String from, String to) {
    return 'I am travelling from $from to $to. Please help me find my ship or bus.';
  }

  @override
  String get sosNoTrip => 'Plan a trip to see your trip summary here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'Phone default';

  @override
  String get translationDraft => 'draft, needs review';

  @override
  String get translationInProgress => 'translation in progress';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get textSizePreview => 'This is how text will look.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody =>
      'Your trips, checklist progress and location stay on your phone. Map images come from OpenStreetMap, and travel updates and photos from Google Firebase. Reports you send have no name or number attached. Advisory alerts are off unless you turn them on.';

  @override
  String get advisoriesTitle => 'Advisories';

  @override
  String get advisoriesActive => 'In effect now';

  @override
  String get advisoriesUpcoming => 'Coming up';

  @override
  String get advisoriesEnded => 'Recently ended';

  @override
  String get advisoriesNone => 'No advisories right now.';

  @override
  String advisoriesMore(int count) {
    return '+$count more';
  }

  @override
  String get advisoryConfirm =>
      'Always confirm with the Coast Guard or shipping line before travelling.';

  @override
  String advisoryFrom(String date) {
    return 'From $date';
  }

  @override
  String get advisoryGone => 'This advisory is no longer available.';

  @override
  String get advisoryHasEnded => 'This advisory has ended.';

  @override
  String get advisoryValidFrom => 'Starts';

  @override
  String get advisoryValidUntil => 'Ends';

  @override
  String get advisoryUntilFurtherNotice => 'Until further notice';

  @override
  String get advisorySource => 'Source';

  @override
  String get advisoryPublished => 'Published';

  @override
  String get advisoryAffects => 'Affected trips';

  @override
  String get advisoryAllTrips => 'All sea trips in Romblon';

  @override
  String get severitySuspended => 'Suspended';

  @override
  String get severityCaution => 'Caution';

  @override
  String get severityInfo => 'Notice';

  @override
  String tripAffected(String title) {
    return 'Advisory: $title';
  }

  @override
  String get resultsAdvisoryNotice => 'Some trips are affected by an advisory.';

  @override
  String get resultsAvoidAdvisories => 'Show only trips that avoid it';

  @override
  String get resultsCannotAvoid =>
      'It covers all sea trips, so there is no way around it. Wait for the advisory to end.';

  @override
  String get noRoutesAvoiding =>
      'No trips avoid the advisory. Turn off the filter to see all trips.';

  @override
  String get reportUpdate => 'Report an update';

  @override
  String get reportTitle => 'Report an update';

  @override
  String get reportAbout => 'About';

  @override
  String get reportWhat => 'What changed?';

  @override
  String get reportKindFare => 'Fare changed';

  @override
  String get reportKindSchedule => 'Schedule changed';

  @override
  String get reportKindDelay => 'Delay or cancellation';

  @override
  String get reportKindWrong => 'Wrong information';

  @override
  String get reportKindOther => 'Something else';

  @override
  String get reportSuggested => 'Correct value (optional)';

  @override
  String get reportSuggestedHint => 'e.g. ₱720, or leaves 19:30';

  @override
  String get reportNote => 'Details (optional)';

  @override
  String get reportNoteHint => 'What did you see, and when?';

  @override
  String get reportNeedsText => 'Add the correct value or some details.';

  @override
  String get reportPrivacy =>
      'No name or phone number needed. Please don\'t include personal details. An admin checks every report before anything changes.';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Thank you! Your report was sent for review.';

  @override
  String get reportQueued => 'Saved. It will be sent when you are online.';

  @override
  String get reportLimit =>
      'You\'ve sent the most reports allowed today. It will be sent tomorrow.';

  @override
  String get myReportsTitle => 'My reports';

  @override
  String get myReportsSubtitle => 'Updates you sent and their status';

  @override
  String get myReportsNone => 'You haven\'t sent any reports yet.';

  @override
  String get reportStatusWaiting => 'Waiting to send';

  @override
  String get reportStatusPending => 'Sent, waiting for review';

  @override
  String get reportStatusApproved => 'Approved, thank you!';

  @override
  String get reportStatusRejected => 'Not used';

  @override
  String reportRejectReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get photoLoading => 'Loading photo…';

  @override
  String get photoUnavailable => 'Photo not available offline yet';

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String photoCredit(String credit) {
    return 'Photo: $credit';
  }

  @override
  String get photosSaveOffline => 'Save photos for offline';

  @override
  String get photosSaved => 'Photos saved on this phone';

  @override
  String get photosSaveFailed =>
      'Some photos could not be saved. Try again on Wi-Fi.';

  @override
  String get photosMobileDataTitle => 'Use mobile data?';

  @override
  String photosMobileDataBody(int count) {
    return 'You are on mobile data. Download $count photos (up to 200 KB each)?';
  }

  @override
  String get photosDownload => 'Download';

  @override
  String get cancel => 'Cancel';

  @override
  String get dataTitle => 'Travel data';

  @override
  String dataLastUpdated(String date) {
    return 'Last updated $date';
  }

  @override
  String get dataNeverUpdated => 'Using the data that came with the app.';

  @override
  String get syncNow => 'Refresh now';

  @override
  String get syncUpdated => 'Travel data updated.';

  @override
  String get syncUpToDate => 'Already up to date.';

  @override
  String get syncFailed =>
      'Couldn\'t refresh. Check your internet and try again.';

  @override
  String get syncNotConfigured =>
      'Online updates are not set up in this version.';

  @override
  String get alertsTitle => 'Advisory alerts';

  @override
  String get alertsEnable => 'Alert me about suspensions and cautions';

  @override
  String get alertsExplain =>
      'Only for trips being suspended or needing caution. You can turn this off anytime.';

  @override
  String get alertsAllRomblon => 'All of Romblon';

  @override
  String get alertsChosenPorts => 'Only these ports';

  @override
  String get alertsPermissionDenied =>
      'Notifications are off for this app. Turn them on in your phone settings.';

  @override
  String get alertsFailed =>
      'Couldn\'t update alerts. Check your internet and try again.';

  @override
  String get fareClassComfort => 'Comfort (reclining seat)';

  @override
  String get fareClassPremium => 'Premium (air-conditioned)';

  @override
  String get fareClassReclining => 'Reclining seat';

  @override
  String get fareClassEconomyBed => 'Economy bed';

  @override
  String get fareClassTouristBed => 'Tourist bed';

  @override
  String get fareClassVipRoom => 'VIP room';

  @override
  String get timeToConfirm => 'To be confirmed';

  @override
  String get timeEstimateSuffix => '(estimate)';

  @override
  String get timesToConfirmNotice =>
      'Some days or times for this trip are not confirmed yet. Ask the shipping line before you travel.';

  @override
  String get priceHalfFare => 'Half fare (ask the shipping line who qualifies)';

  @override
  String get priceMinor => 'Minor (2–11 years)';

  @override
  String get priceInfant => 'Infant (under 2 years)';

  @override
  String roomPrice(String price, int count) {
    return '$price per room (for $count people)';
  }

  @override
  String get discountPricesLabel => 'Discount prices';

  @override
  String get contactTitle => 'Contact the shipping line';

  @override
  String officeLabel(String address) {
    return 'Office: $address';
  }

  @override
  String get openOfficialPage => 'Official page';

  @override
  String get openBooking => 'Book online';
}
