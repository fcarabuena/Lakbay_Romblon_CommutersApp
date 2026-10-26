import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/languages.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get languageCode => Localizations.localeOf(this).languageCode;
}

String formatDuration(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l10n.durationMinutes(m);
  if (m == 0) return l10n.durationHours(h);
  return l10n.durationHoursMinutes(h, m);
}

String formatDurationRange(AppLocalizations l10n, IntRange range) =>
    range.isExact
    ? formatDuration(l10n, range.min)
    : '${formatDuration(l10n, range.min)} – ${formatDuration(l10n, range.max)}';

String formatDateTime(AppLocalizations l10n, DateTime t) =>
    DateFormat.MMMEd(intlLocaleFor(l10n.localeName)).add_Hm().format(t);

String formatDate(AppLocalizations l10n, DateTime t) =>
    DateFormat.yMMMd(intlLocaleFor(l10n.localeName)).format(t);

/// Weekday names for ISO day numbers, e.g. "Mon, Wed, Fri".
String formatWeekdays(AppLocalizations l10n, List<int> days) {
  if (days.toSet().length == 7) return l10n.everyDay;
  final format = DateFormat.E(intlLocaleFor(l10n.localeName));
  // 2024-01-01 was a Monday.
  return ([
    ...days,
  ]..sort()).map((d) => format.format(DateTime(2024, 1, d))).join(', ');
}

String rideModeLabel(AppLocalizations l10n, RideMode mode) => switch (mode) {
  RideMode.walk => l10n.modeWalk,
  RideMode.tricycle => l10n.modeTricycle,
  RideMode.jeepney => l10n.modeJeepney,
  RideMode.van => l10n.modeVan,
  RideMode.multicab => l10n.modeMulticab,
  RideMode.habalHabal => l10n.modeHabalHabal,
  RideMode.pumpboat => l10n.modePumpboat,
  RideMode.taxi => l10n.modeTaxi,
};

String fareClassLabel(AppLocalizations l10n, String fareClass) =>
    switch (fareClass) {
      'economy' => l10n.fareClassEconomy,
      'tourist' => l10n.fareClassTourist,
      'cabin' => l10n.fareClassCabin,
      'comfort' => l10n.fareClassComfort,
      'premium' => l10n.fareClassPremium,
      'reclining' => l10n.fareClassReclining,
      'economy_bed' => l10n.fareClassEconomyBed,
      'tourist_bed' => l10n.fareClassTouristBed,
      'vip_room' => l10n.fareClassVipRoom,
      _ => fareClass,
    };

String passengerLabel(AppLocalizations l10n, PassengerType type) =>
    switch (type) {
      PassengerType.regular => l10n.passengerRegular,
      PassengerType.student => l10n.passengerStudent,
      PassengerType.senior => l10n.passengerSenior,
      PassengerType.pwd => l10n.passengerPwd,
    };

/// Display name for a place id, including the traveller's custom place.
String placeName(TravelData data, String id, {TripRequest? request}) {
  if (id == CustomPlace.placeId) return request?.custom?.name ?? id;
  return data.place(id)?.name ?? id;
}

String legTitle(
  AppLocalizations l10n,
  TravelData data,
  Leg leg, {
  TripRequest? request,
}) {
  final from = placeName(data, leg.fromId, request: request);
  final to = placeName(data, leg.toId, request: request);
  return switch (leg.kind) {
    LegKind.localRide => l10n.legRide(
      rideModeLabel(l10n, leg.rideMode ?? RideMode.tricycle),
      from,
      to,
    ),
    LegKind.ship => l10n.legShip(from, to),
    LegKind.bus => l10n.legBus(from, to),
    LegKind.custom => l10n.legCustom(from, to),
  };
}

/// Names of the ports a ship leg passes without the traveller getting off.
List<String> intermediateStops(TravelData data, Leg leg) {
  final voyage = leg.voyageId == null ? null : data.voyage(leg.voyageId!);
  if (voyage == null) return const [];
  final ports = voyage.stops.map((s) => s.portId).toList();
  final from = ports.indexOf(leg.fromId);
  final to = ports.lastIndexOf(leg.toId);
  if (from < 0 || to <= from + 1) return const [];
  return [for (final id in ports.sublist(from + 1, to)) placeName(data, id)];
}

/// Parses an optional peso amount typed by the user into centavos.
int? parsePesoInput(String text) {
  final cleaned = text.replaceAll(RegExp(r'[₱,\s]'), '');
  if (cleaned.isEmpty) return null;
  final value = num.tryParse(cleaned);
  return value == null || value < 0 ? null : pesosToCentavos(value);
}
