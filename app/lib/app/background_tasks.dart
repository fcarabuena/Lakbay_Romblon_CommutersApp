import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_controller.dart';
import '../features/alerts/application/alerts_controller.dart';
import '../features/reports/application/reports_controller.dart';
import 'router.dart';

/// Work that runs when the app starts and each time it comes back to the
/// foreground: sync data (at most every 15 minutes), send queued reports,
/// and open the advisory behind a tapped alert.
class BackgroundTasks extends ConsumerStatefulWidget {
  const BackgroundTasks({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BackgroundTasks> createState() => _BackgroundTasksState();
}

class _BackgroundTasksState extends ConsumerState<BackgroundTasks>
    with WidgetsBindingObserver {
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onForeground();
      _listenToAlerts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onForeground();
  }

  void _onForeground() {
    if (!mounted) return;
    final sync = ref.read(syncControllerProvider.notifier);
    if (sync.isAvailable) unawaited(sync.syncIfDue());
    if (ref.read(reportSenderProvider) != null) {
      unawaited(ref.read(reportsControllerProvider.notifier).flush());
    }
  }

  Future<void> _listenToAlerts() async {
    final alerts = ref.read(alertsServiceProvider);
    if (alerts == null) return;

    Future<void> open(String advisoryId) async {
      // The alert may be newer than the data on the phone.
      await ref.read(syncControllerProvider.notifier).syncNow();
      if (mounted) {
        unawaited(ref.read(appRouterProvider).push('/advisories/$advisoryId'));
      }
    }

    _subscriptions
      ..add(alerts.openedAdvisoryIds.listen(open))
      ..add(
        alerts.foregroundAlerts.listen(
          (_) => ref.read(syncControllerProvider.notifier).syncNow(),
        ),
      );
    final initial = await alerts.initialAdvisoryId();
    if (initial != null) await open(initial);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
