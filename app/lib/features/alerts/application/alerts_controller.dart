import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/settings_controller.dart';
import '../data/alerts_service.dart';

final alertPrefsRepositoryProvider = Provider<AlertPrefsRepository>(
  (ref) => throw UnimplementedError('alertPrefsRepositoryProvider'),
);

/// Read at startup so the settings screen shows the saved choice at once.
final initialAlertPrefsProvider = Provider<AlertPrefs>(
  (ref) => const AlertPrefs(),
);

/// Null when Firebase is not set up: the alert settings are then hidden.
final alertsServiceProvider = Provider<AlertsService?>((ref) => null);

enum AlertChangeResult { done, permissionDenied, failed }

class AlertsController extends Notifier<AlertPrefs> {
  @override
  AlertPrefs build() {
    // Alerts come in the app language, so re-subscribe when it changes.
    ref.listen(
      appSettingsProvider.select((s) => s.languageCode),
      (_, _) => unawaited(_apply(state)),
    );
    return ref.read(initialAlertPrefsProvider);
  }

  Future<AlertChangeResult> setEnabled(bool enabled) async {
    if (enabled) {
      final service = ref.read(alertsServiceProvider);
      if (service == null) return AlertChangeResult.failed;
      if (!await service.requestPermission()) {
        return AlertChangeResult.permissionDenied;
      }
    }
    return _apply(state.copyWith(enabled: enabled));
  }

  Future<AlertChangeResult> setAllPorts() =>
      _apply(state.copyWith(allPorts: true));

  Future<AlertChangeResult> togglePort(String portId, {required bool on}) {
    final ports = {...state.portIds};
    on ? ports.add(portId) : ports.remove(portId);
    return _apply(state.copyWith(allPorts: false, portIds: ports));
  }

  Future<AlertChangeResult> _apply(AlertPrefs next) async {
    final service = ref.read(alertsServiceProvider);
    final wanted = next.enabled
        ? alertTopics(
            allPorts: next.allPorts,
            portIds: next.portIds,
            languageCode: ref.read(appSettingsProvider).languageCode,
          )
        : const <String>{};
    var subscribed = {...next.subscribedTopics};
    var result = AlertChangeResult.done;
    if (service != null) {
      try {
        for (final topic in subscribed.difference(wanted)) {
          await service.unsubscribe(topic);
          subscribed.remove(topic);
        }
        for (final topic in wanted.difference(subscribed)) {
          await service.subscribe(topic);
          subscribed.add(topic);
        }
      } on Object catch (e) {
        debugPrint('Alert topics not updated: $e');
        result = AlertChangeResult.failed;
      }
    } else {
      subscribed = {};
    }
    state = next.copyWith(subscribedTopics: subscribed);
    await ref.read(alertPrefsRepositoryProvider).save(state);
    return result;
  }
}

final alertsControllerProvider = NotifierProvider<AlertsController, AlertPrefs>(
  AlertsController.new,
);
