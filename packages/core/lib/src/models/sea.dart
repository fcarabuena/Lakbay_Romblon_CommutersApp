import '../json.dart';
import 'discounts.dart';
import 'localized_text.dart';
import 'verification.dart';

final class ShippingLine {
  const ShippingLine({
    required this.id,
    required this.name,
    required this.isPlaceholder,
    this.contact,
    this.phones = const [],
    this.contactLabel,
    this.office,
    this.website,
    this.bookingUrl,
  });

  final String id;
  final String name;
  final String? contact;

  /// Numbers travellers can call (shown as call buttons).
  final List<String> phones;

  /// Whose numbers they are, e.g. "Starlite Cajidiocan office".
  final String? contactLabel;
  final String? office;

  /// Official page (e.g. Facebook) and online booking site.
  final String? website;
  final String? bookingUrl;
  final bool isPlaceholder;

  factory ShippingLine.fromJson(Json json) => ShippingLine(
    id: json.req<String>('id'),
    name: json.req<String>('name'),
    contact: json.opt<String>('contact'),
    phones: json.strings('phones'),
    contactLabel: json.opt<String>('contactLabel'),
    office: json.opt<String>('office'),
    website: json.opt<String>('website'),
    bookingUrl: json.opt<String>('bookingUrl'),
    isPlaceholder: json.opt<bool>('isPlaceholder') ?? true,
  );
}

/// One port call on a voyage. Times are local, in minutes after midnight;
/// [dayOffset] counts days after the voyage's first departure.
final class VoyageStop {
  const VoyageStop({
    required this.portId,
    this.arrive,
    this.depart,
    this.dayOffset = 0,
    this.estimated = false,
  });

  final String portId;
  final int? arrive;
  final int? depart;
  final int dayOffset;

  /// True when the times here are estimates (e.g. worked out from "about
  /// 10 hours"), not from a published schedule.
  final bool estimated;

  /// Absolute minutes since the voyage's day-0 midnight.
  int? get arriveAbs => arrive == null ? null : arrive! + dayOffset * 1440;
  int? get departAbs => depart == null ? null : depart! + dayOffset * 1440;

  factory VoyageStop.fromJson(Json json) {
    final arrive = json.opt<String>('arrive');
    final depart = json.opt<String>('depart');
    return VoyageStop(
      portId: json.req<String>('portId'),
      arrive: arrive == null ? null : parseClock(arrive),
      depart: depart == null ? null : parseClock(depart),
      dayOffset: json.opt<int>('dayOffset') ?? 0,
      estimated: json.opt<bool>('estimated') ?? false,
    );
  }
}

/// A scheduled sailing with its ordered stops.
final class Voyage {
  const Voyage({
    required this.id,
    required this.lineId,
    required this.vesselName,
    required this.stops,
    required this.daysOfWeek,
    required this.verification,
    this.checkInMinutes = 60,
    this.delayAllowanceMinutes = 0,
    this.timesToConfirm = false,
    this.note,
  });

  final String id;
  final String lineId;
  final String vesselName;
  final List<VoyageStop> stops;

  /// ISO weekdays the voyage leaves its first port (1 = Monday ... 7 = Sunday).
  final List<int> daysOfWeek;

  /// How early passengers should be at the port before departure.
  final int checkInMinutes;

  /// Extra minutes added to the upper time estimate for typical delays.
  final int delayAllowanceMinutes;

  /// Some days or times are not known yet. Missing times are shown as "to be
  /// confirmed", and segments without both times are left out of trip plans.
  final bool timesToConfirm;

  /// Shown with the voyage, e.g. "Schedule subject to change without notice".
  final LocalizedText? note;
  final Verification verification;

  factory Voyage.fromJson(Json json) => Voyage(
    id: json.req<String>('id'),
    lineId: json.req<String>('lineId'),
    vesselName: json.req<String>('vesselName'),
    stops: json.objects('stops').map(VoyageStop.fromJson).toList(),
    daysOfWeek: json.ints('daysOfWeek'),
    checkInMinutes: json.opt<int>('checkInMinutes') ?? 60,
    delayAllowanceMinutes: json.opt<int>('delayAllowanceMinutes') ?? 0,
    timesToConfirm: json.opt<bool>('timesToConfirm') ?? false,
    note: LocalizedText.maybe(json['note']),
    verification: Verification.fromJson(json.opt<Json>('verification')),
  );
}

/// Keys allowed in a fare's `pricesPhp` (besides the regular fare).
abstract final class FarePriceKey {
  static const student = 'student';
  static const senior = 'senior';
  static const pwd = 'pwd';
  static const halfFare = 'halfFare';

  /// 2 to 11 years old.
  static const minor = 'minor';

  /// 0 to 1 year 11 months.
  static const infant = 'infant';

  static const all = [student, senior, pwd, halfFare, minor, infant];
}

/// Fare for one passenger between two stops of a voyage, in one class.
///
/// When the operator publishes its own student, senior, PWD and other prices,
/// they are in [prices] and used instead of the general discount percentages.
/// A [roomFor] fare is the price of a whole room (e.g. a VIP room for 2).
final class ShipFare {
  const ShipFare({
    required this.voyageId,
    required this.fromPortId,
    required this.toPortId,
    required this.fareClass,
    required this.amount,
    required this.verification,
    this.prices = const {},
    this.pricesVerification,
    this.roomFor,
  });

  final String voyageId;
  final String fromPortId;
  final String toPortId;
  final String fareClass;

  /// Regular (undiscounted) fare in centavos; for a room, the room price.
  final int amount;

  /// Published prices by [FarePriceKey], in centavos.
  final Map<String, int> prices;

  /// When the [prices] were checked, if different from [verification]
  /// (e.g. a poster that may have a typo in its discount prices).
  final Verification? pricesVerification;

  /// The number of people a room fare covers; null for per-person fares.
  final int? roomFor;
  final Verification verification;

  bool get isRoom => roomFor != null;

  /// The published price for [type], or null to use the discount rules.
  int? priceFor(PassengerType type) => switch (type) {
    PassengerType.regular => amount,
    PassengerType.student => prices[FarePriceKey.student],
    PassengerType.senior => prices[FarePriceKey.senior],
    PassengerType.pwd => prices[FarePriceKey.pwd],
  };

  factory ShipFare.fromJson(Json json) {
    final prices = json.opt<Json>('pricesPhp') ?? const <String, Object?>{};
    final pricesVerification = json.opt<Json>('pricesVerification');
    return ShipFare(
      voyageId: json.req<String>('voyageId'),
      fromPortId: json.req<String>('fromPortId'),
      toPortId: json.req<String>('toPortId'),
      fareClass: json.req<String>('fareClass'),
      amount: pesosToCentavos(json.req<num>('farePhp')),
      prices: {
        for (final key in prices.keys)
          key: pesosToCentavos(prices.req<num>(key)),
      },
      pricesVerification: pricesVerification == null
          ? null
          : Verification.fromJson(pricesVerification),
      roomFor: json.opt<int>('roomFor'),
      verification: Verification.fromJson(json.opt<Json>('verification')),
    );
  }
}
