import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/corpus_database.dart';
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
      final result = await _engine.search(query, limit: 100);

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

      var results = result.cards;
      results = _sortResults(results, state.sort);

      state = state.copyWith(
        results: results,
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

  /// Update the sort order and re-sort existing results.
  void setSort(SearchSort sort) {
    final sorted = _sortResults(List.of(state.results), sort);
    state = state.copyWith(sort: sort, results: sorted);
  }

  static List<Card> _sortResults(List<Card> results, SearchSort sort) {
    switch (sort) {
      case SearchSort.priceDesc:
        results.sort((a, b) =>
            (b.priceUsd ?? 0).compareTo(a.priceUsd ?? 0));
      case SearchSort.priceAsc:
        results.sort((a, b) =>
            (a.priceUsd ?? 0).compareTo(b.priceUsd ?? 0));
      case SearchSort.nameAsc:
        results.sort((a, b) => a.name.compareTo(b.name));
      case SearchSort.nameDesc:
        results.sort((a, b) => b.name.compareTo(a.name));
      case SearchSort.set_:
        results.sort((a, b) => a.setCode.compareTo(b.setCode));
      case SearchSort.rarity:
        results.sort((a, b) =>
            _rarityOrder(a.rarity).compareTo(_rarityOrder(b.rarity)));
    }
    return results;
  }

  static int _rarityOrder(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'mythic':
        return 0;
      case 'rare':
        return 1;
      case 'uncommon':
        return 2;
      case 'common':
        return 3;
      default:
        return 4;
    }
  }
}

/// Provides the [SearchNotifier] and its current [SearchState].
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final engine = ref.watch(queryEngineProvider);
  return SearchNotifier(engine);
});
