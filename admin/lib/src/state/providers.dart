import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/admin_backend.dart';
import '../backend/dataset.dart';

final backendProvider = Provider<AdminBackend>(
  (ref) => throw UnimplementedError('backendProvider'),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Ids for change-log entries; overridable for tests.
final idGeneratorProvider = Provider<String Function()>((ref) {
  var n = 0;
  return () => '${DateTime.now().microsecondsSinceEpoch}-${n++}';
});

final authUserProvider = StreamProvider<AdminUser?>(
  (ref) => ref.watch(backendProvider).authChanges(),
);

/// The signed-in user's staff record; null if they are not an admin or editor.
final staffProvider = FutureProvider<StaffMember?>((ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  return ref.watch(backendProvider).staffRecord(user.uid);
});

/// The signed-in staff member. Only read inside the signed-in shell.
final currentStaffProvider = Provider<StaffMember>(
  (ref) => ref.watch(staffProvider).value ?? (throw StateError('Not staff')),
);

class DatasetController extends AsyncNotifier<Dataset> {
  @override
  Future<Dataset> build() => ref.watch(backendProvider).loadDataset();

  Future<void> reload() async {
    // Keep showing the current data until the new copy arrives.
    state = await AsyncValue.guard(ref.read(backendProvider).loadDataset);
  }
}

final datasetProvider = AsyncNotifierProvider<DatasetController, Dataset>(
  DatasetController.new,
);

final reportsProvider = FutureProvider.family<List<ReportItem>, bool>(
  (ref, pendingOnly) =>
      ref.watch(backendProvider).listReports(pendingOnly: pendingOnly),
);

final auditProvider = FutureProvider.family<List<AuditEntry>, String?>(
  (ref, collection) =>
      ref.watch(backendProvider).listAudit(collection: collection),
);

final staffListProvider = FutureProvider<List<StaffMember>>(
  (ref) => ref.watch(backendProvider).listStaff(),
);
