import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../shared/providers/search_provider.dart';
import '../../shared/widgets/applied_filter_chips.dart';
import '../../shared/widgets/card_tile.dart';
import '../../shared/widgets/query_filter_builder.dart';

/// The main collection search screen.
///
/// - **Desktop** (>= 808 px): collapsible filter rail on the left, card grid
///   on the right with query bar, applied filter chips, sort control.
/// - **Mobile** (< 808 px): query bar + filter chips + grid, with a "Filters"
///   button that opens a bottom sheet containing [QueryFilterBuilder].
class CollectionSearchScreen extends ConsumerStatefulWidget {
  const CollectionSearchScreen({super.key});

  @override
  ConsumerState<CollectionSearchScreen> createState() =>
      _CollectionSearchScreenState();
}

class _CollectionSearchScreenState
    extends ConsumerState<CollectionSearchScreen> {
  late final TextEditingController _queryController;
  bool _filterRailOpen = true;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _submitQuery(String query) {
    ref.read(searchProvider.notifier).search(query);
  }

  void _onFilterQueryChanged(String filterQuery) {
    _queryController.text = filterQuery;
    _submitQuery(filterQuery);
  }

  void _onChipRemoved(String updatedQuery) {
    _queryController.text = updatedQuery;
    _submitQuery(updatedQuery);
  }

  void _onSortChanged(SearchSort? sort) {
    if (sort != null) {
      ref.read(searchProvider.notifier).setSort(sort);
    }
  }

  // ---------------------------------------------------------------------------
  // Query bar
  // ---------------------------------------------------------------------------

  Widget _buildQueryBar() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: _queryController,
        decoration: InputDecoration(
          hintText: 'Search cards...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _queryController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _queryController.clear();
                    _submitQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.neutral50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        style: AppTypography.query,
        onSubmitted: _submitQuery,
        onChanged: (_) {
          // Rebuild to show/hide clear button.
          setState(() {});
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sort + count bar
  // ---------------------------------------------------------------------------

  Widget _buildSortBar(SearchState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            '${state.totalCount} result${state.totalCount == 1 ? '' : 's'}',
            style: AppTypography.meta,
          ),
          const Spacer(),
          DropdownButton<SearchSort>(
            value: state.sort,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: AppTypography.meta,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            items: SearchSort.values.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.label, style: AppTypography.meta),
              );
            }).toList(),
            onChanged: _onSortChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error display
  // ---------------------------------------------------------------------------

  Widget _buildError(SearchState state) {
    if (state.error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        state.error!,
        style: AppTypography.bodySm.copyWith(
          color: AppColors.statusRemoveText,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Results grid
  // ---------------------------------------------------------------------------

  Widget _buildResults(SearchState state, LayoutMode mode) {
    if (state.isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.query.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Search your collection',
            style: AppTypography.body.copyWith(color: AppColors.neutral400),
          ),
        ),
      );
    }

    if (state.results.isEmpty && !state.isLoading) {
      return Expanded(
        child: Center(
          child: Text(
            'No cards match your query',
            style: AppTypography.body.copyWith(color: AppColors.neutral400),
          ),
        ),
      );
    }

    final crossAxisCount = mode == LayoutMode.desktop
        ? _desktopColumnCount()
        : _mobileColumnCount();

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.65,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final card = state.results[index];
          return CardTile(
            name: card.name,
            imageUri: card.imageUriSmall,
            typeLine: card.typeLine,
            setCode: card.setCode,
            rarity: card.rarity,
            priceUsd: card.priceUsd,
            finishes: card.finishes,
            compact: true,
            onTap: () {
              // Card detail navigation — Phase 3
            },
          );
        },
      ),
    );
  }

  int _desktopColumnCount() {
    final width = MediaQuery.sizeOf(context).width;
    // Subtract sidebar (208) + filter rail (280 if open) + padding
    final available = width - 208 - (_filterRailOpen ? 280 : 0);
    if (available > 1200) return 7;
    if (available > 900) return 6;
    return 5;
  }

  int _mobileColumnCount() {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 600) return 3;
    return 2;
  }

  // ---------------------------------------------------------------------------
  // Desktop layout
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(SearchState state) {
    return Row(
      children: [
        // Filter rail
        if (_filterRailOpen)
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppColors.neutral0,
              border: Border(
                right: BorderSide(color: AppColors.neutral100),
              ),
            ),
            child: Column(
              children: [
                // Filter header
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text('FILTERS', style: AppTypography.sectionLabel),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() => _filterRailOpen = false);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppColors.neutral500,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: QueryFilterBuilder(
                    initialQuery: state.query,
                    onQueryChanged: _onFilterQueryChanged,
                  ),
                ),
              ],
            ),
          ),

        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle filter rail button + query bar
              Row(
                children: [
                  if (!_filterRailOpen)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, size: 20),
                        onPressed: () {
                          setState(() => _filterRailOpen = true);
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.neutral50,
                          side: const BorderSide(color: AppColors.neutral200),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: _buildQueryBar()),
                ],
              ),

              // Applied filter chips
              if (state.query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppliedFilterChips(
                    query: state.query,
                    onChipRemoved: _onChipRemoved,
                  ),
                ),

              // Error
              _buildError(state),

              // Sort + count
              if (state.results.isNotEmpty) _buildSortBar(state),

              const SizedBox(height: AppSpacing.sm),

              // Results
              _buildResults(state, LayoutMode.desktop),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile layout
  // ---------------------------------------------------------------------------

  Widget _buildMobile(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Query bar
        _buildQueryBar(),

        // Applied filter chips
        if (state.query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppliedFilterChips(
              query: state.query,
              onChipRemoved: _onChipRemoved,
            ),
          ),

        // Error
        _buildError(state),

        // Sort + count
        if (state.results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSortBar(state),
          ),

        // Results
        _buildResults(state, LayoutMode.mobile),
      ],
    );
  }

  void _showFilterSheet() {
    final state = ref.read(searchProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
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
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Text('FILTERS', style: AppTypography.sectionLabel),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: QueryFilterBuilder(
                    initialQuery: state.query,
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
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final mode = layoutModeOf(context);

    if (mode == LayoutMode.desktop) {
      return _buildDesktop(state);
    }

    return Scaffold(
      body: _buildMobile(state),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showFilterSheet,
        backgroundColor: AppColors.neutral900,
        foregroundColor: AppColors.neutral0,
        elevation: 4,
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}
