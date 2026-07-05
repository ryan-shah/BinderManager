import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/corpus_database.dart';
import '../../core/models/ordering.dart';
import '../../core/query/query_engine.dart';
import 'query_provider.dart';

/// Sorting options for search results.
enum SearchSort {
  priceDesc('Price (high-low)'),
  priceAsc('Price (low-high)'),
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  set_('Set'),
  rarity('Rarity');

  const SearchSort(this.label);
  final String label;
}

/// Immutable state for the collection search screen.
class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.errorPosition,
    this.sort = SearchSort.nameAsc,
  });

  final String query;
  final List<Card> results;
  final int totalCount;
  final bool isLoading;
  final String? error;
  final int? errorPosition;
  final SearchSort sort;

  SearchState copyWith({
    String? query,
    List<Card>? results,
    int? totalCount,
    bool? isLoading,
    String? error,
    int? errorPosition,
    SearchSort? sort,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorPosition: errorPosition,
      sort: sort ?? this.sort,
    );
  }
}

/// Manages search state using the [QueryEngine].
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._engine) : super(const SearchState());

  final QueryEngine _engine;

  /// Update the search query and execute the search.
  Future<void> search(String query) async {
    if (query == state.query && !state.isLoading) return;
    await _run(query);
  }

  /// Re-run the current query, bypassing the same-query guard.
  ///
  /// Call after anything that changes what `have:`/`unused:` match —
  /// collection imports, deck commits — or results go stale.
  Future<void> refresh() async {
    if (state.query.isEmpty) return;
    await _run(state.query);
  }

  Future<void> _run(String query) async {
    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
      errorPosition: null,
    );

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: [],
        totalCount: 0,
        isLoading: false,
      );
      return;
    }

    try {
      final result = await _engine.search(
        query,
        limit: 100,
        order: _orderFor(state.sort),
      );

      if (!result.isSuccess) {
        state = state.copyWith(
          results: [],
          totalCount: 0,
          isLoading: false,
          error: result.parseError,
          errorPosition: result.errorPosition,
        );
        return;
      }

      state = state.copyWith(
        results: result.cards,
        totalCount: result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        totalCount: 0,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update the sort order and re-run the query so the whole result set is
  /// re-ordered in SQL — sorting only the fetched page would show an
  /// arbitrary slice for results larger than one page.
  Future<void> setSort(SearchSort sort) async {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    if (state.query.trim().isEmpty) return;
    await _run(state.query);
  }

  static QueryOrder _orderFor(SearchSort sort) => switch (sort) {
        SearchSort.priceDesc =>
          const QueryOrder(OrderField.price, SortDirection.desc),
        SearchSort.priceAsc =>
          const QueryOrder(OrderField.price, SortDirection.asc),
        SearchSort.nameAsc =>
          const QueryOrder(OrderField.name, SortDirection.asc),
        SearchSort.nameDesc =>
          const QueryOrder(OrderField.name, SortDirection.desc),
        SearchSort.set_ =>
          const QueryOrder(OrderField.setCode, SortDirection.asc),
        // Ascending rank = mythic first, matching the old in-memory sort.
        SearchSort.rarity =>
          const QueryOrder(OrderField.rarity, SortDirection.asc),
      };
}

/// Provides the [SearchNotifier] and its current [SearchState].
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final engine = ref.watch(queryEngineProvider);
  return SearchNotifier(engine);
});
