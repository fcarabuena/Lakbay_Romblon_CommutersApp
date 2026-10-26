import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bno.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_loc.dart';
import 'app_localizations_rol.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bno'),
    Locale('en'),
    Locale('fil'),
    Locale('loc'),
    Locale('rol'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lakbay Romblon'**
  String get appTitle;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get navSchedules;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @placeholderDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Sample data only. Fares and schedules are not verified yet.'**
  String get placeholderDataBanner;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lakbay Romblon'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip between Romblon and Metro Manila, door to door: local rides, ships, buses, and what to expect at each step.'**
  String get welcomeBody;

  /// No description provided for @welcomeSampleNotice.
  ///
  /// In en, this message translates to:
  /// **'This early version uses sample data. Always confirm fares and schedules with the shipping line or bus company.'**
  String get welcomeSampleNotice;

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeStart;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip'**
  String get plannerTitle;

  /// No description provided for @directionToManila.
  ///
  /// In en, this message translates to:
  /// **'To Manila'**
  String get directionToManila;

  /// No description provided for @directionToRomblon.
  ///
  /// In en, this message translates to:
  /// **'Going home'**
  String get directionToRomblon;

  /// No description provided for @hometownLabel.
  ///
  /// In en, this message translates to:
  /// **'Your hometown in Romblon'**
  String get hometownLabel;

  /// No description provided for @manilaEndTo.
  ///
  /// In en, this message translates to:
  /// **'Where in Metro Manila?'**
  String get manilaEndTo;

  /// No description provided for @manilaEndFrom.
  ///
  /// In en, this message translates to:
  /// **'Leaving from (Metro Manila)'**
  String get manilaEndFrom;

  /// No description provided for @otherPlace.
  ///
  /// In en, this message translates to:
  /// **'Other place'**
  String get otherPlace;

  /// No description provided for @customPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get customPlaceName;

  /// No description provided for @customNearestHub.
  ///
  /// In en, this message translates to:
  /// **'Nearest bus hub'**
  String get customNearestHub;

  /// No description provided for @customFareLabel.
  ///
  /// In en, this message translates to:
  /// **'Your fare estimate for this part (₱, optional)'**
  String get customFareLabel;

  /// No description provided for @customMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Your time estimate (minutes, optional)'**
  String get customMinutesLabel;

  /// No description provided for @departureLabel.
  ///
  /// In en, this message translates to:
  /// **'When are you leaving?'**
  String get departureLabel;

  /// No description provided for @departureAny.
  ///
  /// In en, this message translates to:
  /// **'Any day (waiting time not included)'**
  String get departureAny;

  /// No description provided for @departurePick.
  ///
  /// In en, this message translates to:
  /// **'Pick date and time'**
  String get departurePick;

  /// No description provided for @departureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get departureClear;

  /// No description provided for @travellersLabel.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get travellersLabel;

  /// No description provided for @passengerRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get passengerRegular;

  /// No description provided for @passengerStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get passengerStudent;

  /// No description provided for @passengerSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior citizen'**
  String get passengerSenior;

  /// No description provided for @passengerPwd.
  ///
  /// In en, this message translates to:
  /// **'PWD'**
  String get passengerPwd;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer {type}'**
  String decrease(String type);

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'More {type}'**
  String increase(String type);

  /// No description provided for @fareClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Ship class'**
  String get fareClassLabel;

  /// No description provided for @fareClassAny.
  ///
  /// In en, this message translates to:
  /// **'Cheapest available'**
  String get fareClassAny;

  /// No description provided for @fareClassEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get fareClassEconomy;

  /// No description provided for @fareClassTourist.
  ///
  /// In en, this message translates to:
  /// **'Tourist (air-conditioned)'**
  String get fareClassTourist;

  /// No description provided for @fareClassCabin.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get fareClassCabin;

  /// No description provided for @findRoutes.
  ///
  /// In en, this message translates to:
  /// **'Find routes'**
  String get findRoutes;

  /// No description provided for @errorPickHometown.
  ///
  /// In en, this message translates to:
  /// **'Please pick your hometown.'**
  String get errorPickHometown;

  /// No description provided for @errorCustomName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the place name.'**
  String get errorCustomName;

  /// No description provided for @errorNoTravellers.
  ///
  /// In en, this message translates to:
  /// **'Add at least one traveller.'**
  String get errorNoTravellers;

  /// No description provided for @errorNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, or leave it empty.'**
  String get errorNumber;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get resultsTitle;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortLabel;

  /// No description provided for @sortCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get sortCheapest;

  /// No description provided for @sortFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get sortFastest;

  /// No description provided for @sortFewestTransfers.
  ///
  /// In en, this message translates to:
  /// **'Fewest transfers'**
  String get sortFewestTransfers;

  /// No description provided for @noRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes found for this trip. Try another destination or ship class.'**
  String get noRoutes;

  /// No description provided for @transfersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transfers} =1{1 transfer} other{{count} transfers}}'**
  String transfersCount(int count);

  /// No description provided for @viaPorts.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String viaPorts(String from, String to);

  /// No description provided for @planDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip plan'**
  String get planDetailTitle;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'This route is no longer available. Please plan again.'**
  String get planNotFound;

  /// No description provided for @planAgain.
  ///
  /// In en, this message translates to:
  /// **'Plan again'**
  String get planAgain;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Fares'**
  String get totalFare;

  /// No description provided for @totalFees.
  ///
  /// In en, this message translates to:
  /// **'Terminal fees'**
  String get totalFees;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalCost;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Door to door'**
  String get totalTime;

  /// No description provided for @arrivalWindow.
  ///
  /// In en, this message translates to:
  /// **'Arrive {earliest} – {latest}'**
  String arrivalWindow(String earliest, String latest);

  /// No description provided for @warningPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This estimate includes unverified sample values.'**
  String get warningPlaceholder;

  /// No description provided for @warningNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'Waiting for departures is not included. Pick a date to include it.'**
  String get warningNoSchedule;

  /// No description provided for @warningMissingEstimate.
  ///
  /// In en, this message translates to:
  /// **'The last part of the trip has no fare estimate, so it is not in the total.'**
  String get warningMissingEstimate;

  /// No description provided for @travellerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{For 1 traveller} other{For {count} travellers}}'**
  String travellerCount(int count);

  /// No description provided for @legRide.
  ///
  /// In en, this message translates to:
  /// **'{mode}: {from} → {to}'**
  String legRide(String mode, String from, String to);

  /// No description provided for @legShip.
  ///
  /// In en, this message translates to:
  /// **'Ship: {from} → {to}'**
  String legShip(String from, String to);

  /// No description provided for @legBus.
  ///
  /// In en, this message translates to:
  /// **'Bus: {from} → {to}'**
  String legBus(String from, String to);

  /// No description provided for @legCustom.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String legCustom(String from, String to);

  /// No description provided for @modeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get modeWalk;

  /// No description provided for @modeTricycle.
  ///
  /// In en, this message translates to:
  /// **'Tricycle'**
  String get modeTricycle;

  /// No description provided for @modeJeepney.
  ///
  /// In en, this message translates to:
  /// **'Jeepney'**
  String get modeJeepney;

  /// No description provided for @modeVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get modeVan;

  /// No description provided for @modeMulticab.
  ///
  /// In en, this message translates to:
  /// **'Multicab'**
  String get modeMulticab;

  /// No description provided for @modeHabalHabal.
  ///
  /// In en, this message translates to:
  /// **'Habal-habal'**
  String get modeHabalHabal;

  /// No description provided for @modePumpboat.
  ///
  /// In en, this message translates to:
  /// **'Pumpboat'**
  String get modePumpboat;

  /// No description provided for @modeTaxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get modeTaxi;

  /// No description provided for @stopsAt.
  ///
  /// In en, this message translates to:
  /// **'Stops at {ports}'**
  String stopsAt(String ports);

  /// No description provided for @departsAt.
  ///
  /// In en, this message translates to:
  /// **'Departs {time}'**
  String departsAt(String time);

  /// No description provided for @checkInNote.
  ///
  /// In en, this message translates to:
  /// **'Be at the port at least {minutes} min before departure'**
  String checkInNote(int minutes);

  /// No description provided for @waitTime.
  ///
  /// In en, this message translates to:
  /// **'Waiting: {range}'**
  String waitTime(String range);

  /// No description provided for @perTripFare.
  ///
  /// In en, this message translates to:
  /// **'per trip, shared'**
  String get perTripFare;

  /// No description provided for @yourEstimate.
  ///
  /// In en, this message translates to:
  /// **'your own estimate'**
  String get yourEstimate;

  /// No description provided for @noEstimate.
  ///
  /// In en, this message translates to:
  /// **'no estimate'**
  String get noEstimate;

  /// No description provided for @freeLeg.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLeg;

  /// No description provided for @feeIncluded.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} terminal fee per person'**
  String feeIncluded(String amount);

  /// No description provided for @badgePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Sample, not verified'**
  String get badgePlaceholder;

  /// No description provided for @badgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String badgeVerified(String date);

  /// No description provided for @badgeStale.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}, may be outdated'**
  String badgeStale(String date);

  /// No description provided for @badgeUserEstimate.
  ///
  /// In en, this message translates to:
  /// **'Your estimate'**
  String get badgeUserEstimate;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @startFirstTimer.
  ///
  /// In en, this message translates to:
  /// **'First-Timer Mode'**
  String get startFirstTimer;

  /// No description provided for @checkBudget.
  ///
  /// In en, this message translates to:
  /// **'Check my budget'**
  String get checkBudget;

  /// No description provided for @saveTrip.
  ///
  /// In en, this message translates to:
  /// **'Save trip'**
  String get saveTrip;

  /// No description provided for @tripSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip saved to My trips.'**
  String get tripSaved;

  /// No description provided for @firstTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'First-Timer Mode'**
  String get firstTimerTitle;

  /// No description provided for @firstTimerProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String firstTimerProgress(int done, int total);

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @firstTimerAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done. Have a safe trip!'**
  String get firstTimerAllDone;

  /// No description provided for @firstTimerCurrent.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get firstTimerCurrent;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget planner'**
  String get budgetTitle;

  /// No description provided for @budgetCash.
  ///
  /// In en, this message translates to:
  /// **'How much money do you have? (₱)'**
  String get budgetCash;

  /// No description provided for @budgetFoodPerMeal.
  ///
  /// In en, this message translates to:
  /// **'Food per meal, per person (₱)'**
  String get budgetFoodPerMeal;

  /// No description provided for @budgetMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals on the way'**
  String get budgetMeals;

  /// No description provided for @budgetExtras.
  ///
  /// In en, this message translates to:
  /// **'Other expenses (₱)'**
  String get budgetExtras;

  /// No description provided for @budgetExtrasHint.
  ///
  /// In en, this message translates to:
  /// **'Pasalubong, load, etc.'**
  String get budgetExtrasHint;

  /// No description provided for @budgetBufferPercent.
  ///
  /// In en, this message translates to:
  /// **'Emergency buffer: {percent}%'**
  String budgetBufferPercent(int percent);

  /// No description provided for @budgetBufferMinimum.
  ///
  /// In en, this message translates to:
  /// **'At least {amount}'**
  String budgetBufferMinimum(String amount);

  /// No description provided for @budgetManualFares.
  ///
  /// In en, this message translates to:
  /// **'Estimated fares (₱)'**
  String get budgetManualFares;

  /// No description provided for @budgetManualFees.
  ///
  /// In en, this message translates to:
  /// **'Estimated terminal fees (₱)'**
  String get budgetManualFees;

  /// No description provided for @budgetFromPlan.
  ///
  /// In en, this message translates to:
  /// **'Fares and fees come from your trip plan (higher estimate, to be safe).'**
  String get budgetFromPlan;

  /// No description provided for @budgetNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No trip selected. Enter your own fare estimate, or plan a trip first.'**
  String get budgetNoPlan;

  /// No description provided for @budgetFares.
  ///
  /// In en, this message translates to:
  /// **'Fares'**
  String get budgetFares;

  /// No description provided for @budgetFees.
  ///
  /// In en, this message translates to:
  /// **'Terminal fees'**
  String get budgetFees;

  /// No description provided for @budgetFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get budgetFood;

  /// No description provided for @budgetOther.
  ///
  /// In en, this message translates to:
  /// **'Other expenses'**
  String get budgetOther;

  /// No description provided for @budgetBuffer.
  ///
  /// In en, this message translates to:
  /// **'Emergency buffer'**
  String get budgetBuffer;

  /// No description provided for @budgetNeeded.
  ///
  /// In en, this message translates to:
  /// **'You need'**
  String get budgetNeeded;

  /// No description provided for @budgetYouHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get budgetYouHave;

  /// No description provided for @budgetLeftover.
  ///
  /// In en, this message translates to:
  /// **'Left over: {amount}'**
  String budgetLeftover(String amount);

  /// No description provided for @budgetShortBy.
  ///
  /// In en, this message translates to:
  /// **'Short by: {amount}'**
  String budgetShortBy(String amount);

  /// No description provided for @budgetCovered.
  ///
  /// In en, this message translates to:
  /// **'Your money covers this trip.'**
  String get budgetCovered;

  /// No description provided for @budgetTight.
  ///
  /// In en, this message translates to:
  /// **'Enough for the trip, but your emergency buffer is low.'**
  String get budgetTight;

  /// No description provided for @budgetShort.
  ///
  /// In en, this message translates to:
  /// **'Not enough for this trip yet.'**
  String get budgetShort;

  /// No description provided for @schedulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedulesTitle;

  /// No description provided for @tabShips.
  ///
  /// In en, this message translates to:
  /// **'Ships'**
  String get tabShips;

  /// No description provided for @tabBuses.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get tabBuses;

  /// No description provided for @filterPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get filterPort;

  /// No description provided for @allPorts.
  ///
  /// In en, this message translates to:
  /// **'All ports'**
  String get allPorts;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @sailingDays.
  ///
  /// In en, this message translates to:
  /// **'Sails: {days}'**
  String sailingDays(String days);

  /// No description provided for @voyageStops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get voyageStops;

  /// No description provided for @fareTable.
  ///
  /// In en, this message translates to:
  /// **'Fares (per person, regular)'**
  String get fareTable;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @busHours.
  ///
  /// In en, this message translates to:
  /// **'{first} – {last}, about every {minutes} min'**
  String busHours(String first, String last, int minutes);

  /// No description provided for @dropOffs.
  ///
  /// In en, this message translates to:
  /// **'Drop-off points'**
  String get dropOffs;

  /// No description provided for @aircon.
  ///
  /// In en, this message translates to:
  /// **'Air-conditioned'**
  String get aircon;

  /// No description provided for @noSchedules.
  ///
  /// In en, this message translates to:
  /// **'No schedules for this port.'**
  String get noSchedules;

  /// No description provided for @dayLater.
  ///
  /// In en, this message translates to:
  /// **'+{days} day'**
  String dayLater(int days);

  /// No description provided for @tripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get tripsTitle;

  /// No description provided for @noTrips.
  ///
  /// In en, this message translates to:
  /// **'No saved trips yet. Plan a trip and tap Save trip.'**
  String get noTrips;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About and data'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Lakbay Romblon helps travellers from Romblon get to Metro Manila and back home, with local rides, ships and buses in one plan.'**
  String get aboutBody;

  /// No description provided for @aboutDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Fares, schedules and travel times change often. Every value shows when it was last verified. Values marked as samples are not real yet. Always confirm with the operator.'**
  String get aboutDisclaimer;

  /// No description provided for @dataVersion.
  ///
  /// In en, this message translates to:
  /// **'Data version {version}'**
  String dataVersion(int version);

  /// No description provided for @dataPrepared.
  ///
  /// In en, this message translates to:
  /// **'Data prepared {date}'**
  String dataPrepared(String date);

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load travel data.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get navGuide;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get navSafety;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get myTrips;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Pier and terminal guides'**
  String get guideTitle;

  /// No description provided for @guidePorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get guidePorts;

  /// No description provided for @guideTerminals.
  ///
  /// In en, this message translates to:
  /// **'Bus terminals'**
  String get guideTerminals;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locating;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not given. You can still use every guide.'**
  String get locationDenied;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on your phone.'**
  String get locationOff;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location.'**
  String get locationError;

  /// No description provided for @locationPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your location stays on your phone.'**
  String get locationPrivacy;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String distanceKm(String km);

  /// No description provided for @nearestBadge.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearestBadge;

  /// No description provided for @tabLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get tabLayout;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tabTips;

  /// No description provided for @layoutIllustrative.
  ///
  /// In en, this message translates to:
  /// **'Illustrative layout, not to scale. Verify on site.'**
  String get layoutIllustrative;

  /// No description provided for @layoutAreas.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get layoutAreas;

  /// No description provided for @seaSide.
  ///
  /// In en, this message translates to:
  /// **'Sea'**
  String get seaSide;

  /// No description provided for @mapNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'The map needs internet. Without a connection, use the Layout tab.'**
  String get mapNeedsInternet;

  /// No description provided for @mapTilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Map tiles could not load. Check your connection or use the Layout tab.'**
  String get mapTilesFailed;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @noLocationForPlace.
  ///
  /// In en, this message translates to:
  /// **'This place has no map location yet.'**
  String get noLocationForPlace;

  /// No description provided for @photosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosTitle;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get noPhotos;

  /// No description provided for @noGuide.
  ///
  /// In en, this message translates to:
  /// **'No guide for this place yet.'**
  String get noGuide;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyTitle;

  /// No description provided for @emergencyCallout.
  ///
  /// In en, this message translates to:
  /// **'In an emergency, call 911.'**
  String get emergencyCallout;

  /// No description provided for @hotlinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency hotlines'**
  String get hotlinesTitle;

  /// No description provided for @hotlinesNational.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get hotlinesNational;

  /// No description provided for @hotlinesProvince.
  ///
  /// In en, this message translates to:
  /// **'Romblon province'**
  String get hotlinesProvince;

  /// No description provided for @hotlinesPorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get hotlinesPorts;

  /// No description provided for @hotlinesTowns.
  ///
  /// In en, this message translates to:
  /// **'Towns'**
  String get hotlinesTowns;

  /// No description provided for @hotlinesYourTown.
  ///
  /// In en, this message translates to:
  /// **'Your hometown'**
  String get hotlinesYourTown;

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callNumber(String number);

  /// No description provided for @numberNeeded.
  ///
  /// In en, this message translates to:
  /// **'Number needed'**
  String get numberNeeded;

  /// No description provided for @hotlineUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not yet verified. Confirm before relying on it.'**
  String get hotlineUnverified;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer.'**
  String get callFailed;

  /// No description provided for @scamTitle.
  ///
  /// In en, this message translates to:
  /// **'Scam warnings'**
  String get scamTitle;

  /// No description provided for @safetyTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety tips'**
  String get safetyTipsTitle;

  /// No description provided for @cancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'If your trip is cancelled'**
  String get cancellationTitle;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Show this to staff'**
  String get sosTitle;

  /// No description provided for @sosBody.
  ///
  /// In en, this message translates to:
  /// **'I am travelling from {from} to {to}. Please help me find my ship or bus.'**
  String sosBody(String from, String to);

  /// No description provided for @sosNoTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip to see your trip summary here.'**
  String get sosNoTrip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get languageSystem;

  /// No description provided for @translationDraft.
  ///
  /// In en, this message translates to:
  /// **'draft, needs review'**
  String get translationDraft;

  /// No description provided for @translationInProgress.
  ///
  /// In en, this message translates to:
  /// **'translation in progress'**
  String get translationInProgress;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeExtraLarge;

  /// No description provided for @textSizePreview.
  ///
  /// In en, this message translates to:
  /// **'This is how text will look.'**
  String get textSizePreview;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your trips, checklist progress and location stay on your phone. Map images come from OpenStreetMap, and travel updates and photos from Google Firebase. Reports you send have no name or number attached. Advisory alerts are off unless you turn them on.'**
  String get privacyBody;

  /// No description provided for @advisoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Advisories'**
  String get advisoriesTitle;

  /// No description provided for @advisoriesActive.
  ///
  /// In en, this message translates to:
  /// **'In effect now'**
  String get advisoriesActive;

  /// No description provided for @advisoriesUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get advisoriesUpcoming;

  /// No description provided for @advisoriesEnded.
  ///
  /// In en, this message translates to:
  /// **'Recently ended'**
  String get advisoriesEnded;

  /// No description provided for @advisoriesNone.
  ///
  /// In en, this message translates to:
  /// **'No advisories right now.'**
  String get advisoriesNone;

  /// No description provided for @advisoriesMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String advisoriesMore(int count);

  /// No description provided for @advisoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Always confirm with the Coast Guard or shipping line before travelling.'**
  String get advisoryConfirm;

  /// No description provided for @advisoryFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String advisoryFrom(String date);

  /// No description provided for @advisoryGone.
  ///
  /// In en, this message translates to:
  /// **'This advisory is no longer available.'**
  String get advisoryGone;

  /// No description provided for @advisoryHasEnded.
  ///
  /// In en, this message translates to:
  /// **'This advisory has ended.'**
  String get advisoryHasEnded;

  /// No description provided for @advisoryValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get advisoryValidFrom;

  /// No description provided for @advisoryValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get advisoryValidUntil;

  /// No description provided for @advisoryUntilFurtherNotice.
  ///
  /// In en, this message translates to:
  /// **'Until further notice'**
  String get advisoryUntilFurtherNotice;

  /// No description provided for @advisorySource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get advisorySource;

  /// No description provided for @advisoryPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get advisoryPublished;

  /// No description provided for @advisoryAffects.
  ///
  /// In en, this message translates to:
  /// **'Affected trips'**
  String get advisoryAffects;

  /// No description provided for @advisoryAllTrips.
  ///
  /// In en, this message translates to:
  /// **'All sea trips in Romblon'**
  String get advisoryAllTrips;

  /// No description provided for @severitySuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get severitySuspended;

  /// No description provided for @severityCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get severityCaution;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get severityInfo;

  /// No description provided for @tripAffected.
  ///
  /// In en, this message translates to:
  /// **'Advisory: {title}'**
  String tripAffected(String title);

  /// No description provided for @resultsAdvisoryNotice.
  ///
  /// In en, this message translates to:
  /// **'Some trips are affected by an advisory.'**
  String get resultsAdvisoryNotice;

  /// No description provided for @resultsAvoidAdvisories.
  ///
  /// In en, this message translates to:
  /// **'Show only trips that avoid it'**
  String get resultsAvoidAdvisories;

  /// No description provided for @resultsCannotAvoid.
  ///
  /// In en, this message translates to:
  /// **'It covers all sea trips, so there is no way around it. Wait for the advisory to end.'**
  String get resultsCannotAvoid;

  /// No description provided for @noRoutesAvoiding.
  ///
  /// In en, this message translates to:
  /// **'No trips avoid the advisory. Turn off the filter to see all trips.'**
  String get noRoutesAvoiding;

  /// No description provided for @reportUpdate.
  ///
  /// In en, this message translates to:
  /// **'Report an update'**
  String get reportUpdate;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an update'**
  String get reportTitle;

  /// No description provided for @reportAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get reportAbout;

  /// No description provided for @reportWhat.
  ///
  /// In en, this message translates to:
  /// **'What changed?'**
  String get reportWhat;

  /// No description provided for @reportKindFare.
  ///
  /// In en, this message translates to:
  /// **'Fare changed'**
  String get reportKindFare;

  /// No description provided for @reportKindSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule changed'**
  String get reportKindSchedule;

  /// No description provided for @reportKindDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay or cancellation'**
  String get reportKindDelay;

  /// No description provided for @reportKindWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong information'**
  String get reportKindWrong;

  /// No description provided for @reportKindOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportKindOther;

  /// No description provided for @reportSuggested.
  ///
  /// In en, this message translates to:
  /// **'Correct value (optional)'**
  String get reportSuggested;

  /// No description provided for @reportSuggestedHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ₱720, or leaves 19:30'**
  String get reportSuggestedHint;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportNote;

  /// No description provided for @reportNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What did you see, and when?'**
  String get reportNoteHint;

  /// No description provided for @reportNeedsText.
  ///
  /// In en, this message translates to:
  /// **'Add the correct value or some details.'**
  String get reportNeedsText;

  /// No description provided for @reportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'No name or phone number needed. Please don\'t include personal details. An admin checks every report before anything changes.'**
  String get reportPrivacy;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report was sent for review.'**
  String get reportSent;

  /// No description provided for @reportQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved. It will be sent when you are online.'**
  String get reportQueued;

  /// No description provided for @reportLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent the most reports allowed today. It will be sent tomorrow.'**
  String get reportLimit;

  /// No description provided for @myReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReportsTitle;

  /// No description provided for @myReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates you sent and their status'**
  String get myReportsSubtitle;

  /// No description provided for @myReportsNone.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t sent any reports yet.'**
  String get myReportsNone;

  /// No description provided for @reportStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get reportStatusWaiting;

  /// No description provided for @reportStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Sent, waiting for review'**
  String get reportStatusPending;

  /// No description provided for @reportStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved, thank you!'**
  String get reportStatusApproved;

  /// No description provided for @reportStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not used'**
  String get reportStatusRejected;

  /// No description provided for @reportRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reportRejectReason(String reason);

  /// No description provided for @photoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading photo…'**
  String get photoLoading;

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo not available offline yet'**
  String get photoUnavailable;

  /// No description provided for @photoNumber.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumber(int number);

  /// No description provided for @photoCredit.
  ///
  /// In en, this message translates to:
  /// **'Photo: {credit}'**
  String photoCredit(String credit);

  /// No description provided for @photosSaveOffline.
  ///
  /// In en, this message translates to:
  /// **'Save photos for offline'**
  String get photosSaveOffline;

  /// No description provided for @photosSaved.
  ///
  /// In en, this message translates to:
  /// **'Photos saved on this phone'**
  String get photosSaved;

  /// No description provided for @photosSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Some photos could not be saved. Try again on Wi-Fi.'**
  String get photosSaveFailed;

  /// No description provided for @photosMobileDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Use mobile data?'**
  String get photosMobileDataTitle;

  /// No description provided for @photosMobileDataBody.
  ///
  /// In en, this message translates to:
  /// **'You are on mobile data. Download {count} photos (up to 200 KB each)?'**
  String photosMobileDataBody(int count);

  /// No description provided for @photosDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get photosDownload;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel data'**
  String get dataTitle;

  /// No description provided for @dataLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String dataLastUpdated(String date);

  /// No description provided for @dataNeverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Using the data that came with the app.'**
  String get dataNeverUpdated;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get syncNow;

  /// No description provided for @syncUpdated.
  ///
  /// In en, this message translates to:
  /// **'Travel data updated.'**
  String get syncUpdated;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date.'**
  String get syncUpToDate;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Check your internet and try again.'**
  String get syncFailed;

  /// No description provided for @syncNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Online updates are not set up in this version.'**
  String get syncNotConfigured;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advisory alerts'**
  String get alertsTitle;

  /// No description provided for @alertsEnable.
  ///
  /// In en, this message translates to:
  /// **'Alert me about suspensions and cautions'**
  String get alertsEnable;

  /// No description provided for @alertsExplain.
  ///
  /// In en, this message translates to:
  /// **'Only for trips being suspended or needing caution. You can turn this off anytime.'**
  String get alertsExplain;

  /// No description provided for @alertsAllRomblon.
  ///
  /// In en, this message translates to:
  /// **'All of Romblon'**
  String get alertsAllRomblon;

  /// No description provided for @alertsChosenPorts.
  ///
  /// In en, this message translates to:
  /// **'Only these ports'**
  String get alertsChosenPorts;

  /// No description provided for @alertsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app. Turn them on in your phone settings.'**
  String get alertsPermissionDenied;

  /// No description provided for @alertsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update alerts. Check your internet and try again.'**
  String get alertsFailed;

  /// No description provided for @fareClassComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort (reclining seat)'**
  String get fareClassComfort;

  /// No description provided for @fareClassPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium (air-conditioned)'**
  String get fareClassPremium;

  /// No description provided for @fareClassReclining.
  ///
  /// In en, this message translates to:
  /// **'Reclining seat'**
  String get fareClassReclining;

  /// No description provided for @fareClassEconomyBed.
  ///
  /// In en, this message translates to:
  /// **'Economy bed'**
  String get fareClassEconomyBed;

  /// No description provided for @fareClassTouristBed.
  ///
  /// In en, this message translates to:
  /// **'Tourist bed'**
  String get fareClassTouristBed;

  /// No description provided for @fareClassVipRoom.
  ///
  /// In en, this message translates to:
  /// **'VIP room'**
  String get fareClassVipRoom;

  /// No description provided for @timeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'To be confirmed'**
  String get timeToConfirm;

  /// No description provided for @timeEstimateSuffix.
  ///
  /// In en, this message translates to:
  /// **'(estimate)'**
  String get timeEstimateSuffix;

  /// No description provided for @timesToConfirmNotice.
  ///
  /// In en, this message translates to:
  /// **'Some days or times for this trip are not confirmed yet. Ask the shipping line before you travel.'**
  String get timesToConfirmNotice;

  /// No description provided for @priceHalfFare.
  ///
  /// In en, this message translates to:
  /// **'Half fare (ask the shipping line who qualifies)'**
  String get priceHalfFare;

  /// No description provided for @priceMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor (2–11 years)'**
  String get priceMinor;

  /// No description provided for @priceInfant.
  ///
  /// In en, this message translates to:
  /// **'Infant (under 2 years)'**
  String get priceInfant;

  /// No description provided for @roomPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} per room (for {count} people)'**
  String roomPrice(String price, int count);

  /// No description provided for @discountPricesLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount prices'**
  String get discountPricesLabel;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact the shipping line'**
  String get contactTitle;

  /// No description provided for @officeLabel.
  ///
  /// In en, this message translates to:
  /// **'Office: {address}'**
  String officeLabel(String address);

  /// No description provided for @openOfficialPage.
  ///
  /// In en, this message translates to:
  /// **'Official page'**
  String get openOfficialPage;

  /// No description provided for @openBooking.
  ///
  /// In en, this message translates to:
  /// **'Book online'**
  String get openBooking;
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
      <String>['bno', 'en', 'fil', 'loc', 'rol'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bno':
      return AppLocalizationsBno();
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
    case 'loc':
      return AppLocalizationsLoc();
    case 'rol':
      return AppLocalizationsRol();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
