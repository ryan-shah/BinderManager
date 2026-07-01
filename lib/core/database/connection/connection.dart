/// Platform-conditional export for the database connection factory.
///
/// On native (Android, iOS, desktop) this exports `native.dart`.
/// On web (dart:js_interop available) this exports `web.dart`.
///
/// Both expose `QueryExecutor connect(String name)`.
library;

export 'native.dart' if (dart.library.js_interop) 'web.dart';
