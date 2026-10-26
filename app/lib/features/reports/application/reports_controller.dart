import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../data/reports_repository.dart';

final reportStoreProvider = Provider<ReportStore>(
  (ref) => throw UnimplementedError('reportStoreProvider'),
);

/// Null when Firebase is not set up: reports then wait in the outbox.
final reportSenderProvider = Provider<ReportSender?>((ref) => null);

class ReportsState {
  const ReportsState({
    this.outbox = const [],
    this.sent = const [],
    this.limitReached = false,
  });

  /// Saved on the phone, not sent yet (offline or over the daily limit).
  final List<CommunityReport> outbox;
  final List<CommunityReport> sent;
  final bool limitReached;
}

class ReportsController extends AsyncNotifier<ReportsState> {
  @override
  Future<ReportsState> build() => _load();

  ReportStore get _store => ref.read(reportStoreProvider);

  Future<ReportsState> _load({bool limitReached = false}) async => ReportsState(
    outbox: await _store.outbox(),
    sent: await _store.sent(),
    limitReached: limitReached,
  );

  /// Saves [report] to the outbox, then tries to send everything waiting.
  /// Returns true if the report was sent right away.
  Future<bool> submit(CommunityReport report) async {
    final local = report.copyWith(
      id: 'local-${ref.read(clockProvider)().microsecondsSinceEpoch}',
    );
    await _store.enqueue(local);
    state = AsyncData(await _load());
    await flush();
    return (state.value?.outbox ?? const []).every((r) => r.id != local.id);
  }

  /// Sends queued reports, oldest first. Stops at the first failure (usually
  /// no internet) and keeps the rest for next time.
  Future<void> flush() async {
    final sender = ref.read(reportSenderProvider);
    if (sender == null) return;
    var limitReached = false;
    for (final report in await _store.outbox()) {
      try {
        final id = await sender.send(report);
        await _store.markSent(report.id, report.copyWith(id: id));
      } on ReportLimitReached {
        limitReached = true;
        break;
      } on Object catch (e) {
        debugPrint('Report not sent yet: $e');
        break;
      }
    }
    state = AsyncData(await _load(limitReached: limitReached));
  }

  /// Refreshes the review status of sent reports.
  Future<void> refreshStatuses() async {
    final sender = ref.read(reportSenderProvider);
    if (sender == null) return;
    try {
      await _store.updateSent(await sender.fetchMine());
      state = AsyncData(await _load());
    } on Object catch (e) {
      debugPrint('Could not refresh report status: $e');
    }
  }
}

final reportsControllerProvider =
    AsyncNotifierProvider<ReportsController, ReportsState>(
      ReportsController.new,
    );
