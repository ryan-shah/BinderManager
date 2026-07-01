import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/query/query_engine.dart';
import 'corpus_provider.dart';

/// Provides a [QueryEngine] instance wired to the corpus database.
///
/// Usage:
/// ```dart
/// final engine = ref.watch(queryEngineProvider);
/// final result = await engine.search('c:W t:creature');
/// ```
final queryEngineProvider = Provider<QueryEngine>((ref) {
  final db = ref.watch(corpusDatabaseProvider);
  return QueryEngine(db);
});
