import '../json.dart';
import 'localized_text.dart';

enum AdvisoryType { weather, coastGuard, portNotice, operatorNotice }

/// How serious an advisory is. [caution] and [suspended] can send push alerts.
enum AdvisorySeverity {
  info,
  caution,
  suspended;

  bool get isAlert => this != info;
}

/// A published notice about weather, sailing suspensions or port changes.
///
/// An advisory with no affected ports or voyages applies to every sea trip
/// (for example a province-wide "no sail" order). Advisories are never
/// invented: each one names its [source].
final class Advisory {
  const Advisory({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.validFrom,
    required this.source,
    this.validUntil,
    this.publishedAt,
    this.affectedPortIds = const [],
    this.affectedVoyageIds = const [],
  });

  final String id;
  final AdvisoryType type;
  final AdvisorySeverity severity;
  final LocalizedText title;
  final LocalizedText message;
  final DateTime validFrom;

  /// Null while open-ended ("until further notice").
  final DateTime? validUntil;
  final DateTime? publishedAt;
  final String source;
  final List<String> affectedPortIds;
  final List<String> affectedVoyageIds;

  bool get isProvinceWide =>
      affectedPortIds.isEmpty && affectedVoyageIds.isEmpty;

  bool isActiveAt(DateTime time) =>
      !time.isBefore(validFrom) &&
      (validUntil == null || time.isBefore(validUntil!));

  bool hasEndedAt(DateTime time) =>
      validUntil != null && !time.isBefore(validUntil!);

  factory Advisory.fromJson(Json json) {
    final until = json.opt<String>('validUntil');
    final published = json.opt<String>('publishedAt');
    return Advisory(
      id: json.req<String>('id'),
      type: AdvisoryType.values.byName(json.req<String>('type')),
      severity: AdvisorySeverity.values.byName(json.req<String>('severity')),
      title: LocalizedText.fromJson(json['title']),
      message: LocalizedText.fromJson(json['message']),
      validFrom: DateTime.parse(json.req<String>('validFrom')),
      validUntil: until == null ? null : DateTime.parse(until),
      publishedAt: published == null ? null : DateTime.parse(published),
      source: json.req<String>('source'),
      affectedPortIds: json.strings('affectedPortIds'),
      affectedVoyageIds: json.strings('affectedVoyageIds'),
    );
  }
}

/// Active advisories first (most severe, then newest), then ended ones.
List<Advisory> sortAdvisories(Iterable<Advisory> all, DateTime now) {
  int rank(Advisory a) => a.isActiveAt(now) ? 0 : (a.hasEndedAt(now) ? 2 : 1);
  return [...all]..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final bySeverity = b.severity.index.compareTo(a.severity.index);
    if (bySeverity != 0) return bySeverity;
    final byStart = b.validFrom.compareTo(a.validFrom);
    return byStart != 0 ? byStart : a.id.compareTo(b.id);
  });
}
