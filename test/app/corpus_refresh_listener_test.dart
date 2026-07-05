import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/app/corpus_refresh_listener.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';
import 'package:binder_manager/shared/providers/search_provider.dart';

class FakeImportNotifier extends StateNotifier<CorpusImportState>
    implements CorpusImportNotifier {
  FakeImportNotifier() : super(const CorpusImportState());

  @override
  Future<void> runImport({int? cardLimit}) async {}

  void emit(CorpusImportState next) => state = next;
}

class FakeSearchNotifier extends StateNotifier<SearchState>
    implements SearchNotifier {
  FakeSearchNotifier() : super(const SearchState());

  int refreshCalls = 0;

  @override
  Future<void> search(String query) async {}

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> setSort(SearchSort sort) async {}
}

void main() {
  late FakeImportNotifier importNotifier;
  late FakeSearchNotifier searchNotifier;

  Future<void> pumpListener(WidgetTester tester) async {
    importNotifier = FakeImportNotifier();
    searchNotifier = FakeSearchNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corpusImportProvider.overrideWith((_) => importNotifier),
          searchProvider.overrideWith((_) => searchNotifier),
        ],
        child: const CorpusRefreshListener(child: SizedBox()),
      ),
    );
  }

  testWidgets('refreshes search when an import completes', (tester) async {
    await pumpListener(tester);

    importNotifier.emit(const CorpusImportState(
      phase: 'downloading',
      progress: 0.5,
    ));
    await tester.pump();
    expect(searchNotifier.refreshCalls, 0);

    importNotifier.emit(const CorpusImportState(
      phase: 'complete (5000 cards)',
      cardsImported: 5000,
      complete: true,
    ));
    await tester.pump();
    expect(searchNotifier.refreshCalls, 1);
  });

  testWidgets('does not refresh on errors or repeated complete states',
      (tester) async {
    await pumpListener(tester);

    importNotifier.emit(const CorpusImportState(
      phase: 'error',
      error: 'network down',
    ));
    await tester.pump();
    expect(searchNotifier.refreshCalls, 0);

    importNotifier.emit(const CorpusImportState(
      phase: 'complete (5000 cards)',
      complete: true,
    ));
    await tester.pump();
    expect(searchNotifier.refreshCalls, 1);

    // A no-op state emission while already complete must not re-fire.
    importNotifier.emit(const CorpusImportState(
      phase: 'complete (5000 cards)',
      complete: true,
      cardsImported: 5000,
    ));
    await tester.pump();
    expect(searchNotifier.refreshCalls, 1);
  });
}
