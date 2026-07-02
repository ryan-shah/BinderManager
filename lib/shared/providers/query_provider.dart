import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/query/query_engine.dart';
import 'corpus_provider.dart';
import 'user_database_provider.dart';

/// Provides a [QueryEngine] wired to the corpus and user databases, so
/// `have:`/`unused:` filter against real owned/idle quantities.
///
/// Usage:
/// ```dart
/// final engine = ref.watch(queryEngineProvider);
/// final result = await engine.search('c:W t:creature');
/// ```
final queryEngineProvider = Provider<QueryEngine>((ref) {
  final db = ref.watch(corpusDatabaseProvider);
  final userDb = ref.watch(userDatabaseProvider);
  return QueryEngine(db, userDb: userDb);
});
