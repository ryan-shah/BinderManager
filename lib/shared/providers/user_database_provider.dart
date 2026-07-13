import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/connection/connection.dart' as db;
import '../../core/database/user_database.dart';

/// Provides the durable [UserDatabase] as a long-lived singleton.
///
/// Separate file from the replaceable corpus database (D12): `user.sqlite`
/// on native, its own OPFS bucket on web. Closing is tied to the provider
/// container's lifecycle; in practice it stays open for the app's lifetime.
final userDatabaseProvider = Provider<UserDatabase>((ref) {
  final database = UserDatabase(db.connect('user'));
  ref.onDispose(() => database.close());
  return database;
});

/// Streams the total owned quantity per scryfallId, summed across all finishes
/// and provenances. Updates automatically whenever the stacks table changes.
final ownedQuantitiesProvider = StreamProvider<Map<String, int>>((ref) {
  final userDb = ref.watch(userDatabaseProvider);
  return userDb.select(userDb.stacks).watch().map((stacks) {
    final totals = <String, int>{};
    for (final stack in stacks) {
      totals[stack.scryfallId] = (totals[stack.scryfallId] ?? 0) + stack.quantity;
    }
    return totals;
  });
});
