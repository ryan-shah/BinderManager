import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/binder_diff.dart';
import '../shared/providers/binder_providers.dart';
import '../shared/providers/corpus_provider.dart';
import '../shared/providers/search_provider.dart';

/// Recomputes collection-dependent state when a corpus import completes
/// (D11 "Refresh data" is a change event).
///
/// Lives at the app root, not in the Settings screen: a refresh takes
/// minutes and keeps running after the user navigates away, so the
/// completion hook must outlive whatever screen started it.
class CorpusRefreshListener extends ConsumerWidget {
  const CorpusRefreshListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CorpusImportState>(corpusImportProvider, (previous, next) {
      final justCompleted = next.complete && previous?.complete != true;
      if (justCompleted) {
        // Prices and card data changed under any open search results.
        ref.read(searchProvider.notifier).refresh();
        // Price movement is a D7 change event: restage the binder diff.
        unawaited(
          ref
              .read(binderChangeStagerProvider)
              .stage(ChangeTrigger.priceRefresh),
        );
      }
    });
    return child;
  }
}
