import '../json.dart';

enum ReportKind {
  fareChange,
  scheduleChange,
  delayOrCancellation,
  wrongInfo,
  other,
}

enum ReportStatus { pending, approved, rejected }

/// Limits shared by the app, the admin panel and `firebase/firestore.rules`.
/// Keep the three in sync when changing one.
abstract final class ReportLimits {
  static const maxSuggested = 200;
  static const maxNote = 1000;
  static const maxLabel = 120;
  static const perDay = 10;
}

/// A traveller's text-only suggestion that some data is wrong or outdated.
///
/// Reports never change data by themselves: an admin or editor reviews each
/// one and makes (and verifies) any change in the normal editor.
final class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.kind,
    required this.targetCollection,
    required this.targetId,
    required this.targetLabel,
    required this.submittedAt,
    this.suggestedValue = '',
    this.note = '',
    this.language = 'en',
    this.status = ReportStatus.pending,
    this.rejectReason,
    this.reviewedAt,
  });

  final String id;
  final ReportKind kind;

  /// The data collection and document the report is about, e.g.
  /// `ship_fares` / `v1:odiongan-batangas:economy`. Empty for general reports.
  final String targetCollection;
  final String targetId;

  /// What the traveller saw, e.g. "Odiongan → Batangas, economy".
  final String targetLabel;
  final String suggestedValue;
  final String note;
  final String language;
  final DateTime submittedAt;
  final ReportStatus status;
  final String? rejectReason;
  final DateTime? reviewedAt;

  /// Problems that stop the report being sent; empty when it is valid.
  List<String> problems() => [
    if (suggestedValue.trim().isEmpty && note.trim().isEmpty)
      'Add a suggested value or a note',
    if (suggestedValue.length > ReportLimits.maxSuggested)
      'Suggested value is longer than ${ReportLimits.maxSuggested} characters',
    if (note.length > ReportLimits.maxNote)
      'Note is longer than ${ReportLimits.maxNote} characters',
    if (targetLabel.length > ReportLimits.maxLabel)
      'Label is longer than ${ReportLimits.maxLabel} characters',
  ];

  CommunityReport copyWith({
    String? id,
    ReportStatus? status,
    String? Function()? rejectReason,
    DateTime? Function()? reviewedAt,
  }) => CommunityReport(
    id: id ?? this.id,
    kind: kind,
    targetCollection: targetCollection,
    targetId: targetId,
    targetLabel: targetLabel,
    submittedAt: submittedAt,
    suggestedValue: suggestedValue,
    note: note,
    language: language,
    status: status ?? this.status,
    rejectReason: rejectReason == null ? this.rejectReason : rejectReason(),
    reviewedAt: reviewedAt == null ? this.reviewedAt : reviewedAt(),
  );

  /// The fields a traveller sends. Status and review fields are set by staff.
  Json toSubmissionJson() => {
    'kind': kind.name,
    'targetCollection': targetCollection,
    'targetId': targetId,
    'targetLabel': targetLabel,
    'suggestedValue': suggestedValue,
    'note': note,
    'language': language,
    'status': ReportStatus.pending.name,
  };

  Json toJson() => {
    'id': id,
    ...toSubmissionJson(),
    'status': status.name,
    'submittedAt': submittedAt.toIso8601String(),
    if (rejectReason != null) 'rejectReason': rejectReason,
    if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
  };

  factory CommunityReport.fromJson(Json json) {
    final reviewed = json.opt<String>('reviewedAt');
    return CommunityReport(
      id: json.req<String>('id'),
      kind: ReportKind.values.byName(json.req<String>('kind')),
      targetCollection: json.opt<String>('targetCollection') ?? '',
      targetId: json.opt<String>('targetId') ?? '',
      targetLabel: json.opt<String>('targetLabel') ?? '',
      suggestedValue: json.opt<String>('suggestedValue') ?? '',
      note: json.opt<String>('note') ?? '',
      language: json.opt<String>('language') ?? 'en',
      submittedAt: DateTime.parse(json.req<String>('submittedAt')),
      status: ReportStatus.values.byName(
        json.opt<String>('status') ?? 'pending',
      ),
      rejectReason: json.opt<String>('rejectReason'),
      reviewedAt: reviewed == null ? null : DateTime.parse(reviewed),
    );
  }
}

/// Document id for the [slot]-th report (1..[ReportLimits.perDay]) a device
/// sends on [day]. The security rules accept only these ids, which is how
/// the daily limit is enforced without a server.
String reportDocumentId(String uid, DateTime day, int slot) =>
    '${uid}_${utcDayNumber(day)}_$slot';

/// Days since 1970-01-01 in UTC (what the security rules compute).
int utcDayNumber(DateTime time) =>
    time.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
