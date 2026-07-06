import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/binder_diff.dart';
import '../../core/state/change_staging_service.dart';
import 'user_database_provider.dart';

/// The app-wide D7 staging engine. Watch it for the staged diff (`null` =
/// no pending changes); use the notifier to stage, commit, or roll back.
///
/// Change events (imports, deck commits, rule edits, reorders, refresh)
/// stage through this provider; the change-review screen (§10) and the
/// Commit/Rollback bar (§13) watch it.
final changeStagingProvider =
    StateNotifierProvider<ChangeStagingService, StagedDiff?>((ref) {
  return ChangeStagingService(ref.watch(userDatabaseProvider));
});
