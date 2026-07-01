import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a drift database connection using WASM sqlite3 for web.
///
/// Drift probes the browser for available storage implementations (OPFS,
/// IndexedDB, etc.) and picks the most reliable one automatically.
/// Requires `sqlite3.wasm` and `drift_worker.js` in the web/ folder.
QueryExecutor connect(String name) {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Log missing features but don't fail -- drift will pick the best
      // available storage, falling back to in-memory if necessary.
      // ignore: avoid_print
      print(
        'Drift web: missing browser features: ${result.missingFeatures}. '
        'Using ${result.chosenImplementation}.',
      );
    }

    return result.resolvedExecutor;
  }));
}
