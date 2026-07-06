import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/allocation/allocator.dart';
import '../../core/binders/binder_repository.dart';
import '../../core/database/user_database.dart';
import '../../core/models/binder_diff.dart';
import '../../shared/providers/binder_providers.dart';

/// Binders list (§7): priority-ordered, drag-reorderable binder rows with
/// fill gauge and overflow badge. Order = allocation priority, top wins
/// (D6); reordering is a change event → diff/commit (D7).
class BindersListScreen extends ConsumerStatefulWidget {
  const BindersListScreen({super.key});

  @override
  ConsumerState<BindersListScreen> createState() => _BindersListScreenState();
}

class _BindersListScreenState extends ConsumerState<BindersListScreen> {
  /// Optimistic order shown between a drop and the stream re-emitting.
  List<Binder>? _localOrder;

  /// [newIndex] is already adjusted for the removed item (onReorderItem).
  Future<void> _onReorder(List<Binder> binders, int oldIndex, int newIndex) async {
    final reordered = [...binders];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() => _localOrder = reordered);

    await ref
        .read(binderRepositoryProvider)
        .reorderBinders([for (final binder in reordered) binder.id]);
    await ref
        .read(binderChangeStagerProvider)
        .stage(ChangeTrigger.priorityReorder);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bindersProvider, (_, _) {
      if (_localOrder != null) setState(() => _localOrder = null);
    });

    final bindersAsync = ref.watch(bindersProvider);
    final allocation = ref.watch(allocationProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text('Binders', style: AppTypography.headingLg),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/binders/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New binder'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Text(
                'Drag to set allocation priority — the top binder claims '
                'matching cards first. Reordering stages a change.',
                style: AppTypography.meta,
              ),
            ),
            const Divider(),
            Expanded(
              child: bindersAsync.when(
                data: (binders) {
                  final displayed = _localOrder ?? binders;
                  if (displayed.isEmpty) {
                    return _EmptyState(
                      onCreate: () => context.go('/binders/new'),
                    );
                  }
                  return ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: displayed.length,
                    onReorderItem: (oldIndex, newIndex) =>
                        _onReorder(displayed, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final binder = displayed[index];
                      return _BinderRow(
                        key: ValueKey(binder.id),
                        index: index,
                        binder: binder,
                        allocation: allocation?.forBinder(binder.id),
                        onTap: () =>
                            context.go('/binders/${binder.id}/edit'),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load binders: $e',
                    style: AppTypography.body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinderRow extends StatelessWidget {
  const _BinderRow({
    super.key,
    required this.index,
    required this.binder,
    required this.allocation,
    required this.onTap,
  });

  final int index;
  final Binder binder;
  final BinderAllocation? allocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final geometry = binder.geometry;
    final capacity = geometry.capacity;
    final used = allocation?.placements.length;
    final overflowCount = allocation?.overflow.length ?? 0;

    final meta = [
      '${geometry.rows}×${geometry.cols}',
      '${geometry.pageCount} pages',
      binder.doubleSided ? 'double-sided' : 'single-sided',
      '$capacity pockets',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutral100)),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: AppColors.neutral400,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(binder.name, style: AppTypography.headingSm),
                  const SizedBox(height: 2),
                  Text(meta, style: AppTypography.meta),
                  const SizedBox(height: 2),
                  Text(
                    binder.query,
                    style: AppTypography.query
                        .copyWith(color: AppColors.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FillGauge(used: used, capacity: capacity),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (overflowCount > 0) ...[
              _Tag("+$overflowCount didn't fit", amber: true),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (binder.isVirtual) ...[
              const _Tag('VIRTUAL'),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Used/total pocket gauge (§7). Shows an indeterminate track while the
/// allocation is still computing.
class _FillGauge extends StatelessWidget {
  const _FillGauge({required this.used, required this.capacity});

  final int? used;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final fraction =
        capacity == 0 ? 0.0 : ((used ?? 0) / capacity).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: LinearProgressIndicator(
              value: used == null ? null : fraction,
              minHeight: 6,
              backgroundColor: AppColors.neutral100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.neutral700),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          used == null ? '… / $capacity' : '$used / $capacity',
          style: AppTypography.meta,
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.amber = false});

  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: amber ? AppColors.amberBg : AppColors.neutral75,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(
          color: amber ? AppColors.amberBorder : AppColors.neutral150,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.tag.copyWith(
          color: amber ? AppColors.amberText : AppColors.neutral600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories, size: 48, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.lg),
          Text('No binders yet', style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Define a binder — a rule, a size, an organization — and the '
            'allocator fills it from your idle cards.',
            style: AppTypography.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('New binder'),
          ),
        ],
      ),
    );
  }
}
