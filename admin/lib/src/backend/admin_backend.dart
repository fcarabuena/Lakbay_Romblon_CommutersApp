import 'dart:typed_data';

import 'package:lakbay_core/lakbay_core.dart';

import 'dataset.dart';

enum StaffRole {
  /// Everything, including managing users and deleting change-log entries.
  admin,

  /// Edits data and reviews reports; cannot manage users or delete the log.
  editor,
}

class AdminUser {
  const AdminUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class StaffMember {
  const StaffMember({
    required this.uid,
    required this.email,
    required this.role,
  });

  final String uid;
  final String email;
  final StaffRole role;

  bool get isAdmin => role == StaffRole.admin;
}

/// A save of one document plus its change-log entry, written together.
///
/// The security rules refuse a data write whose `auditId` entry is not in
/// the same batch, so every change is logged.
class AuditedWrite {
  const AuditedWrite({
    required this.collection,
    required this.docId,
    required this.auditId,
    required this.before,
    required this.after,
    this.reportId,
    this.note,
    this.restore = false,
  });

  /// A travel collection, or `config` for `config/meta`.
  final String collection;
  final String docId;
  final String auditId;
  final Json? before;

  /// The new item; null for a (soft) delete.
  final Json? after;
  final String? reportId;
  final String? note;

  /// Putting back an item deleted earlier (from the change log).
  final bool restore;

  String get action => restore
      ? 'restore'
      : after == null
      ? 'delete'
      : before == null
      ? 'create'
      : 'update';

  /// Document fields, without `updatedAt` (the backend adds server time).
  Json documentFields(String uid) => {
    ...?(after ?? before),
    if (after == null) 'deleted': true,
    'updatedBy': uid,
    'auditId': auditId,
  };

  /// Change-log fields, without `at` (the backend adds server time).
  Json auditFields(AdminUser user) => {
    'uid': user.uid,
    'email': user.email,
    'collection': collection,
    'docId': docId,
    'action': action,
    'before': before,
    'after': after,
    if (reportId != null) 'reportId': reportId,
    if (note != null) 'note': note,
  };
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.uid,
    required this.email,
    required this.collection,
    required this.docId,
    required this.action,
    required this.at,
    this.before,
    this.after,
    this.note,
  });

  final String id;
  final String uid;
  final String email;
  final String collection;
  final String docId;
  final String action;
  final DateTime? at;
  final Object? before;
  final Object? after;
  final String? note;
}

/// A traveller report as staff see it.
class ReportItem {
  const ReportItem({required this.report, this.reviewedBy, this.appVersion});

  final CommunityReport report;
  final String? reviewedBy;
  final String? appVersion;
}

/// Everything the admin panel needs from Firebase, so screens can be tested
/// with an in-memory backend.
abstract interface class AdminBackend {
  Stream<AdminUser?> authChanges();
  AdminUser? get currentUser;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  Future<StaffMember?> staffRecord(String uid);
  Future<List<StaffMember>> listStaff();

  /// Adds a user. Creates their sign-in account when [existingUid] is null
  /// and emails them a link to set a password.
  Future<StaffMember> addStaff({
    required String email,
    required StaffRole role,
    String? existingUid,
  });
  Future<void> setRole(String uid, StaffRole role);
  Future<void> removeStaff(String uid);

  Future<Dataset> loadDataset();

  /// Writes the document and its change-log entry in one batch.
  Future<void> save(AuditedWrite write);

  /// Writes many documents (e.g. the starter data), each with its log entry.
  Future<void> saveAll(List<AuditedWrite> writes);

  Future<List<ReportItem>> listReports({required bool pendingOnly});
  Future<void> reviewReport(
    String reportId, {
    required ReportStatus status,
    String? rejectReason,
    String? auditId,
  });

  Future<List<AuditEntry>> listAudit({String? collection, int limit = 100});
  Future<void> deleteAudit(String entryId);

  /// Uploads an image and returns its public download URL.
  Future<String> uploadImage(String storagePath, Uint8List bytes);
  Future<void> deleteFile(String storagePath);
}
