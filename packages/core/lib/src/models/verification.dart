import '../json.dart';

/// Where a fare, schedule or estimate came from and when it was last checked.
///
/// Every value shown to travellers carries one of these. Seed data is always
/// [isPlaceholder] until a trusted editor verifies it.
final class Verification {
  const Verification({
    required this.source,
    required this.isPlaceholder,
    this.lastVerified,
    this.verifiedBy,
  });

  static const placeholder = Verification(
    source: 'PLACEHOLDER',
    isPlaceholder: true,
  );

  /// Values older than this get a "may be outdated" warning.
  static const staleAfter = Duration(days: 90);

  final DateTime? lastVerified;
  final String source;
  final bool isPlaceholder;

  /// The admin panel user id that verified the value, if any.
  final String? verifiedBy;

  bool get isVerified => !isPlaceholder && lastVerified != null;

  bool isStale(DateTime now) =>
      lastVerified != null && now.difference(lastVerified!) > staleAfter;

  factory Verification.fromJson(Json? json) {
    if (json == null) return placeholder;
    final date = json.opt<String>('lastVerified');
    return Verification(
      source: json.opt<String>('source') ?? 'PLACEHOLDER',
      isPlaceholder: json.opt<bool>('isPlaceholder') ?? true,
      lastVerified: date == null ? null : DateTime.parse(date),
      verifiedBy: json.opt<String>('verifiedBy'),
    );
  }

  Json toJson() => {
    'source': source,
    'isPlaceholder': isPlaceholder,
    'lastVerified': lastVerified?.toIso8601String().substring(0, 10),
    if (verifiedBy != null) 'verifiedBy': verifiedBy,
  };

  /// The least trustworthy of several verifications (used for plan totals).
  static Verification weakest(Iterable<Verification> all) {
    Verification? result;
    for (final v in all) {
      if (v.isPlaceholder) return v;
      if (result == null ||
          (v.lastVerified != null &&
              (result.lastVerified == null ||
                  v.lastVerified!.isBefore(result.lastVerified!)))) {
        result = v;
      }
    }
    return result ?? placeholder;
  }
}
