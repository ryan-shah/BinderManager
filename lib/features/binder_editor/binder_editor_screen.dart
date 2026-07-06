import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/allocation/allocation_planner.dart';
import '../../core/models/binder_diff.dart';
import '../../core/models/binder_position.dart';
import '../../core/models/ordering.dart';
import '../../shared/providers/binder_providers.dart';
import '../../shared/providers/query_provider.dart';
import '../../shared/widgets/applied_filter_chips.dart';
import '../../shared/widgets/query_filter_builder.dart';

/// Live match/fit/overflow numbers for the current draft (§8).
class _Preview {
  const _Preview({
    required this.corpusMatches,
    required this.eligibleStacks,
    required this.placed,
    required this.overflow,
  });

  /// Corpus printings matching the query, owned or not.
  final int corpusMatches;

  /// Idle stacks eligible for this binder at its priority turn.
  final int eligibleStacks;

  final int placed;
  final int overflow;
}

/// Binder editor / rule definition (§8): type + contents (query) +
/// organization + capacity (D5/D6/D9), with a live match/fit/overflow
/// preview through the real allocator.
class BinderEditorScreen extends ConsumerStatefulWidget {
  const BinderEditorScreen({super.key, this.binderId});

  /// Null when creating a new binder.
  final String? binderId;

  @override
  ConsumerState<BinderEditorScreen> createState() =>
      _BinderEditorScreenState();
}

class _BinderEditorScreenState extends ConsumerState<BinderEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _queryController;

  /// Pocket grid is square per the D9 layouts (2×2 / 3×3 / 4×4).
  int _layoutSize = 3;
  int _pageCount = 10;
  bool _doubleSided = true;
  BinderAxis? _groupBy;
  BinderAxis _sortBy = BinderAxis.price;
  SortDirection _sortDir = SortDirection.desc;
  bool _isVirtual = false;

  /// Bumped to re-seed [QueryFilterBuilder] after raw submits/chip removals
  /// (same convention as the collection search screen).
  int _filterBuilderKey = 0;

  bool _loading = true;
  bool _missing = false;
  bool _saving = false;
  String? _queryError;
  String? _nameError;
  _Preview? _preview;
  bool _previewPending = false;

  Timer? _debounce;
  int _previewSeq = 0;

  bool get _isEditing => widget.binderId != null;

  BinderGeometry get _geometry => BinderGeometry(
        rows: _layoutSize,
        cols: _layoutSize,
        pageCount: _pageCount,
        doubleSided: _doubleSided,
      );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _queryController = TextEditingController();
    if (_isEditing) {
      _loadBinder();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadBinder() async {
    final binder = await ref
        .read(binderRepositoryProvider)
        .getBinder(widget.binderId!);
    if (!mounted) return;
    if (binder == null) {
      setState(() {
        _loading = false;
        _missing = true;
      });
      return;
    }
    setState(() {
      _nameController.text = binder.name;
      _queryController.text = binder.query;
      _layoutSize = binder.layoutRows;
      _pageCount = binder.pageCount;
      _doubleSided = binder.doubleSided;
      _groupBy = binder.groupBy;
      _sortBy = binder.sortBy;
      _sortDir = binder.sortDir;
      _isVirtual = binder.isVirtual;
      _loading = false;
    });
    _schedulePreview();
  }

  // ---------------------------------------------------------------------------
  // Live preview
  // ---------------------------------------------------------------------------

  void _schedulePreview() {
    _debounce?.cancel();
    setState(() => _previewPending = true);
    _debounce = Timer(const Duration(milliseconds: 350), _computePreview);
  }

  Future<void> _computePreview() async {
    final seq = ++_previewSeq;
    final query = _queryController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _preview = null;
        _queryError = null;
        _previewPending = false;
      });
      return;
    }

    final engine = ref.read(queryEngineProvider);
    final parsed = engine.parse(query);
    if (!parsed.isSuccess) {
      setState(() {
        _queryError = parsed.error;
        _preview = null;
        _previewPending = false;
      });
      return;
    }

    try {
      final draft = BinderDraft(
        id: widget.binderId,
        query: query,
        geometry: _geometry,
        groupBy: _groupBy,
        sortBy: _sortBy,
        sortDir: _sortDir,
        isVirtual: _isVirtual,
      );
      final corpusResult = await engine.search(query, limit: 1);
      final result =
          await ref.read(allocationPlannerProvider).plan(draft: draft);
      if (!mounted || seq != _previewSeq) return;

      final allocation = result.forBinder(draft.effectiveId);
      setState(() {
        _queryError = null;
        _previewPending = false;
        _preview = _Preview(
          corpusMatches: corpusResult.totalCount,
          eligibleStacks: allocation?.matchCount ?? 0,
          placed: allocation?.placements.length ?? 0,
          overflow: allocation?.overflow.length ?? 0,
        );
      });
    } catch (error) {
      if (!mounted || seq != _previewSeq) return;
      setState(() {
        _queryError = error.toString();
        _preview = null;
        _previewPending = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Query field / filter sync (§6 conventions)
  // ---------------------------------------------------------------------------

  void _onFilterQueryChanged(String filterQuery) {
    _queryController.text = filterQuery;
    _schedulePreview();
  }

  void _onChipRemoved(String updatedQuery) {
    _queryController.text = updatedQuery;
    setState(() => _filterBuilderKey++);
    _schedulePreview();
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Text('FILTERS', style: AppTypography.sectionLabel),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.neutral900),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: QueryFilterBuilder(
                    key: ValueKey('filter-$_filterBuilderKey'),
                    initialQuery: _queryController.text,
                    onQueryChanged: _onFilterQueryChanged,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Save / delete
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final query = _queryController.text.trim();

    var hasError = false;
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the binder a name.');
      hasError = true;
    } else {
      setState(() => _nameError = null);
    }
    if (query.isEmpty) {
      setState(() => _queryError = 'Define the contents query.');
      hasError = true;
    } else {
      final parsed = ref.read(queryEngineProvider).parse(query);
      if (!parsed.isSuccess) {
        setState(() => _queryError = parsed.error);
        hasError = true;
      }
    }
    if (hasError || _saving) return;

    setState(() => _saving = true);
    try {
      final repository = ref.read(binderRepositoryProvider);
      if (_isEditing) {
        await repository.updateBinder(
          id: widget.binderId!,
          name: name,
          query: query,
          layoutRows: _layoutSize,
          layoutCols: _layoutSize,
          pageCount: _pageCount,
          doubleSided: _doubleSided,
          groupBy: _groupBy,
          sortBy: _sortBy,
          sortDir: _sortDir,
          isVirtual: _isVirtual,
        );
      } else {
        await repository.createBinder(
          name: name,
          query: query,
          layoutRows: _layoutSize,
          layoutCols: _layoutSize,
          pageCount: _pageCount,
          doubleSided: _doubleSided,
          groupBy: _groupBy,
          sortBy: _sortBy,
          sortDir: _sortDir,
          isVirtual: _isVirtual,
        );
      }
      await ref
          .read(binderChangeStagerProvider)
          .stage(ChangeTrigger.ruleEdit);
      if (mounted) context.go('/binders');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete binder?'),
        content: const Text(
          'Its committed placements are removed and its cards return to '
          'the idle pool for other binders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(binderRepositoryProvider).deleteBinder(widget.binderId!);
      await ref
          .read(binderChangeStagerProvider)
          .stage(ChangeTrigger.ruleEdit);
      if (mounted) context.go('/binders');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_missing) {
      return Scaffold(
        body: Center(
          child: Text('Binder not found.', style: AppTypography.body),
        ),
      );
    }

    final mode = layoutModeOf(context);
    final form = _buildForm();
    final preview = _PreviewPanel(
      geometry: _geometry,
      preview: _preview,
      pending: _previewPending,
      queryError: _queryError,
      hasQuery: _queryController.text.trim().isNotEmpty,
      isVirtual: _isVirtual,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => context.go('/binders'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Edit binder' : 'New binder',
                    style: AppTypography.headingLg,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: mode == LayoutMode.desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: form),
                        Container(
                          width: 320,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppColors.neutral100),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: preview,
                          ),
                        ),
                      ],
                    )
                  : form,
            ),
            if (mode == LayoutMode.mobile)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: preview,
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(child: _buildSaveBar()),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(top: BorderSide(color: AppColors.neutral150)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (_isEditing)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: Text(
                'Delete',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.statusRemoveText),
              ),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: _saving ? null : () => context.go('/binders'),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save changes' : 'Create binder'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionLabel('NAME'),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g. Premium trade binder',
            errorText: _nameError,
          ),
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),

        _SectionLabel('TYPE'),
        Row(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2×2')),
                ButtonSegment(value: 3, label: Text('3×3')),
                ButtonSegment(value: 4, label: Text('4×4')),
              ],
              selected: {_layoutSize},
              onSelectionChanged: (selection) {
                setState(() => _layoutSize = selection.first);
                _schedulePreview();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('Pages', style: AppTypography.body),
            const SizedBox(width: AppSpacing.md),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: _pageCount > 1
                  ? () {
                      setState(() => _pageCount--);
                      _schedulePreview();
                    }
                  : null,
            ),
            Text('$_pageCount', style: AppTypography.headingSm),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () {
                setState(() => _pageCount++);
                _schedulePreview();
              },
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Double-sided pages', style: AppTypography.body),
          subtitle: Text(
            'Pockets on both sides of each sheet',
            style: AppTypography.meta,
          ),
          value: _doubleSided,
          onChanged: (v) {
            setState(() => _doubleSided = v);
            _schedulePreview();
          },
        ),
        Text(
          'Capacity: ${_geometry.capacity} pockets',
          style: AppTypography.meta,
        ),
        const SizedBox(height: AppSpacing.xl),

        _SectionLabel('CONTENTS'),
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            hintText: 'e.g. usd>=5 -t:land',
            errorText: _queryError,
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_list, size: 18),
              tooltip: 'Filters',
              onPressed: _showFilterSheet,
            ),
          ),
          style: AppTypography.query,
          onChanged: (_) => _schedulePreview(),
          onSubmitted: (_) {
            setState(() => _filterBuilderKey++);
            _schedulePreview();
          },
        ),
        if (_queryController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppliedFilterChips(
              query: _queryController.text,
              onChipRemoved: _onChipRemoved,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),

        _SectionLabel('ORGANIZATION'),
        Row(
          children: [
            Expanded(
              child: _AxisDropdown<BinderAxis?>(
                label: 'Group by',
                value: _groupBy,
                items: [
                  const DropdownMenuItem<BinderAxis?>(
                    value: null,
                    child: Text('None'),
                  ),
                  for (final axis in BinderAxis.values)
                    DropdownMenuItem<BinderAxis?>(
                      value: axis,
                      child: Text(axis.label),
                    ),
                ],
                onChanged: (axis) {
                  setState(() => _groupBy = axis);
                  _schedulePreview();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _AxisDropdown<BinderAxis>(
                label: 'Sort by',
                value: _sortBy,
                items: [
                  for (final axis in BinderAxis.values)
                    DropdownMenuItem<BinderAxis>(
                      value: axis,
                      child: Text(axis.label),
                    ),
                ],
                onChanged: (axis) {
                  if (axis == null) return;
                  setState(() => _sortBy = axis);
                  _schedulePreview();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<SortDirection>(
          segments: const [
            ButtonSegment(
              value: SortDirection.desc,
              label: Text('High → low'),
            ),
            ButtonSegment(
              value: SortDirection.asc,
              label: Text('Low → high'),
            ),
          ],
          selected: {_sortDir},
          onSelectionChanged: (selection) {
            setState(() => _sortDir = selection.first);
            _schedulePreview();
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        _SectionLabel('MODE'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Virtual (overlap allowed)', style: AppTypography.body),
          subtitle: Text(
            'A what-if view: draws from the full idle pool and never '
            'consumes cards from other binders.',
            style: AppTypography.meta,
          ),
          value: _isVirtual,
          onChanged: (v) {
            setState(() => _isVirtual = v);
            _schedulePreview();
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: AppTypography.sectionLabel),
    );
  }
}

class _AxisDropdown<T> extends StatelessWidget {
  const _AxisDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.meta),
        const SizedBox(height: 2),
        DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: AppTypography.body.copyWith(color: AppColors.neutral900),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// "Matches N · fits M · overflow K" (§8), fed by the real allocator.
class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.geometry,
    required this.preview,
    required this.pending,
    required this.queryError,
    required this.hasQuery,
    required this.isVirtual,
  });

  final BinderGeometry geometry;
  final _Preview? preview;
  final bool pending;
  final String? queryError;
  final bool hasQuery;
  final bool isVirtual;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (queryError != null) {
      body = Text(
        queryError!,
        style: AppTypography.bodySm.copyWith(color: AppColors.statusRemoveText),
      );
    } else if (!hasQuery) {
      body = Text(
        'Define a contents query to preview what this binder holds.',
        style: AppTypography.bodySm,
      );
    } else if (preview == null || pending) {
      body = Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Computing…', style: AppTypography.bodySm),
        ],
      );
    } else {
      final p = preview!;
      final overCapacity = p.overflow > 0;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewLine('Query matches', '${p.corpusMatches} printings'),
          _PreviewLine('Idle stacks eligible', '${p.eligibleStacks}'),
          _PreviewLine('Fits', '${p.placed} of ${geometry.capacity} pockets'),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              overCapacity
                  ? "Overflow: ${p.overflow} didn't fit"
                  : 'Overflow: none',
              style: AppTypography.bodySm.copyWith(
                color: overCapacity
                    ? AppColors.amberText
                    : AppColors.neutral500,
              ),
            ),
          ),
          if (isVirtual)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Virtual: preview ignores other binders\' claims.',
                style: AppTypography.meta,
              ),
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.neutral150),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREVIEW', style: AppTypography.sectionLabel),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySm),
          Text(value, style: AppTypography.bodySm),
        ],
      ),
    );
  }
}
