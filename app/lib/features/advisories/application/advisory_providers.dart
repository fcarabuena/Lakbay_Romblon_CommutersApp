import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';

/// Advisories in effect right now, most severe first.
final activeAdvisoriesProvider = Provider<List<Advisory>>((ref) {
  final now = ref.watch(clockProvider)();
  return [
    for (final a in sortAdvisories(
      ref.watch(travelDataProvider).advisories,
      now,
    ))
      if (a.isActiveAt(now)) a,
  ];
});

/// Every advisory for the list screen: active, upcoming, then those that
/// ended in the last [recentDays] days.
final advisoryListProvider = Provider<List<Advisory>>((ref) {
  const recentDays = 7;
  final now = ref.watch(clockProvider)();
  return [
    for (final a in sortAdvisories(
      ref.watch(travelDataProvider).advisories,
      now,
    ))
      if (!a.hasEndedAt(now) ||
          now.difference(a.validUntil!).inDays < recentDays)
        a,
  ];
});
