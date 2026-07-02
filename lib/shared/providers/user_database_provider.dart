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
