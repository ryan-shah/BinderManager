import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Opens a drift database connection using native sqlite3 via FFI.
///
/// On Android, applies the workaround for bundled sqlite3 on older versions.
/// The database file is stored in the app's documents directory.
QueryExecutor connect(String name) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.sqlite'));

    // Required on older Android versions to load the bundled sqlite3 library.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}
