import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/allocation/allocation_planner.dart';
import '../../core/allocation/allocator.dart';
import '../../core/binders/binder_repository.dart';
import '../../core/database/user_database.dart';
import '../../core/models/binder_diff.dart';
import '../../core/state/change_staging_service.dart';
import 'change_staging_provider.dart';
import 'corpus_provider.dart';
import 'deck_providers.dart';
import 'query_provider.dart';
import 'user_database_provider.dart';

/// The binder repository, bound to the singleton user database.
final binderRepositoryProvider = Provider<BinderRepository>((ref) {
  return BinderRepository(ref.watch(userDatabaseProvider));
});

/// All binders in priority order (0 = filled first), live.
final bindersProvider = StreamProvider<List<Binder>>((ref) {
  return ref.watch(binderRepositoryProvider).watchBinders();
});

/// All committed placements across binders, live.
final binderSlotsProvider = StreamProvider<List<BinderSlotRow>>((ref) {
  return ref.watch(binderRepositoryProvider).watchAllSlots();
});

/// Computes planned allocations from live database state (D6/D13).
final allocationPlannerProvider = Provider<AllocationPlanner>((ref) {
  return AllocationPlanner(
    userDb: ref.watch(userDatabaseProvider),
    corpus: ref.watch(corpusDatabaseProvider),
    engine: ref.watch(queryEngineProvider),
  );
});

/// The current allocation across all binders, recomputed whenever binders,
/// committed slots, or the collection/deck state change. Drives the §7 fill
/// gauges and overflow badges; staging recomputes independently so a staged
/// diff is always fresher than this cache.
final allocationProvider = FutureProvider<AllocationResult>((ref) async {
  // Watched only to recompute when the underlying tables change.
  ref.watch(bindersProvider);
  ref.watch(binderSlotsProvider);
  ref.watch(reservationProvider);
  return ref.read(allocationPlannerProvider).plan();
});

/// Turns a change event into a staged D7 diff: recomputes planned
/// placements and stages them against the committed state.
///
/// Virtual binders are non-consuming *views* (D6) — their placements are
/// what-if display state, never physically sleeved, so they are excluded
/// from the staged diff.
class BinderChangeStager {
  BinderChangeStager({
    required AllocationPlanner planner,
    required BinderRepository repository,
    required ChangeStagingService staging,
  })  : _planner = planner,
        _repository = repository,
        _staging = staging;

  final AllocationPlanner _planner;
  final BinderRepository _repository;
  final ChangeStagingService _staging;

  Future<void> stage(ChangeTrigger trigger) async {
    final result = await _planner.plan();
    final binders = await _repository.listBinders();
    final virtualIds = {
      for (final binder in binders)
        if (binder.isVirtual) binder.id,
    };

    final planned = <PlannedPlacement>[];
    final overflow = <OverflowEntry>[];
    for (final allocation in result.allocations) {
      if (virtualIds.contains(allocation.binderId)) continue;
      planned.addAll(allocation.placements);
      overflow.addAll(allocation.overflow);
    }

    await _staging.stage(
      trigger: trigger,
      planned: planned,
      overflow: overflow,
    );
  }
}

/// The app-wide change-event → staged-diff bridge. Every mutating event
/// (import, deck change, rule edit, reorder, price refresh) goes through
/// [BinderChangeStager.stage] with its trigger.
final binderChangeStagerProvider = Provider<BinderChangeStager>((ref) {
  return BinderChangeStager(
    planner: ref.watch(allocationPlannerProvider),
    repository: ref.watch(binderRepositoryProvider),
    staging: ref.watch(changeStagingProvider.notifier),
  );
});
