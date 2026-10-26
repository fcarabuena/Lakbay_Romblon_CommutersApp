import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Checked item ids for one plan, persisted so progress survives restarts.
class ChecklistProgressController extends AsyncNotifier<Set<String>> {
  ChecklistProgressController(this.planId);

  final String planId;

  @override
  Future<Set<String>> build() =>
      ref.read(checklistProgressRepositoryProvider).load(planId);

  Future<void> toggle(String itemId, {required bool done}) async {
    final current = state.value ?? const <String>{};
    state = AsyncData(
      done ? {...current, itemId} : ({...current}..remove(itemId)),
    );
    await ref
        .read(checklistProgressRepositoryProvider)
        .setDone(planId, itemId, done: done);
  }
}

final checklistProgressProvider =
    AsyncNotifierProvider.family<
      ChecklistProgressController,
      Set<String>,
      String
    >(ChecklistProgressController.new);
