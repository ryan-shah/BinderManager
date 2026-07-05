/// Versioned JSON serialization of the committed binder state (D7/D12).
///
/// A snapshot covers binder state ONLY (D7 amendment 2026-07-03): binder
/// definitions (including priority order via `priorityIndex`) and committed
/// placements. Collection and deck data are NOT part of snapshots — imports
/// keep their own review gates and enter D7 as triggering events.
///
/// ## Schema (version 1)
///
/// ```json
/// {
///   "version": 1,
///   "binders": [
///     {"id", "name", "query", "priorityIndex", "layoutRows", "layoutCols",
///      "pageCount", "doubleSided", "groupBy", "sortBy", "sortDir",
///      "isVirtual", "createdAt", "updatedAt"}
///   ],
///   "binderSlots": [
///     {"id", "binderId", "scryfallId", "finish", "quantity", "page",
///      "side", "pocket", "isPinned", "createdAt", "updatedAt"}
///   ]
/// }
/// ```
///
/// Enums serialize by name; timestamps as UTC ISO-8601 strings. The fields
/// are written explicitly (not via drift's generated `toJson`) so the wire
/// format stays stable even if drift's serializer defaults change.
library;

import 'dart:convert';

import '../database/user_database.dart' show Binder, BinderSlotRow;
import '../models/binder_position.dart';
import '../models/card_identity.dart';
import '../models/ordering.dart';

/// Current snapshot schema version. Bump when the shape changes and add a
/// migration path in [decodeBinderState].
const int binderStateSchemaVersion = 1;

/// The decoded contents of a snapshot: binder definitions + placements.
class BinderStateSnapshot {
  const BinderStateSnapshot({required this.binders, required this.slots});

  final List<Binder> binders;
  final List<BinderSlotRow> slots;
}

/// Serializes the full committed binder state to versioned JSON.
String encodeBinderState({
  required List<Binder> binders,
  required List<BinderSlotRow> slots,
}) {
  return jsonEncode({
    'version': binderStateSchemaVersion,
    'binders': [for (final binder in binders) _binderToJson(binder)],
    'binderSlots': [for (final slot in slots) _slotToJson(slot)],
  });
}

/// Deserializes snapshot JSON produced by [encodeBinderState].
///
/// Throws a [FormatException] for malformed JSON, a missing/unknown
/// `version`, or invalid enum values — a snapshot that cannot be fully
/// understood must never be half-restored.
BinderStateSnapshot decodeBinderState(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    rethrow;
  }
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('snapshot root must be a JSON object');
  }

  final version = decoded['version'];
  if (version != binderStateSchemaVersion) {
    throw FormatException(
      'unsupported snapshot schema version: $version '
      '(expected $binderStateSchemaVersion)',
    );
  }

  final bindersJson = decoded['binders'];
  final slotsJson = decoded['binderSlots'];
  if (bindersJson is! List || slotsJson is! List) {
    throw const FormatException(
        'snapshot must contain "binders" and "binderSlots" lists');
  }

  return BinderStateSnapshot(
    binders: [for (final entry in bindersJson) _binderFromJson(_asMap(entry))],
    slots: [for (final entry in slotsJson) _slotFromJson(_asMap(entry))],
  );
}

Map<String, dynamic> _binderToJson(Binder binder) => {
      'id': binder.id,
      'name': binder.name,
      'query': binder.query,
      'priorityIndex': binder.priorityIndex,
      'layoutRows': binder.layoutRows,
      'layoutCols': binder.layoutCols,
      'pageCount': binder.pageCount,
      'doubleSided': binder.doubleSided,
      'groupBy': binder.groupBy?.name,
      'sortBy': binder.sortBy.name,
      'sortDir': binder.sortDir.name,
      'isVirtual': binder.isVirtual,
      'createdAt': binder.createdAt.toUtc().toIso8601String(),
      'updatedAt': binder.updatedAt.toUtc().toIso8601String(),
    };

Binder _binderFromJson(Map<String, dynamic> json) => Binder(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      query: _string(json, 'query'),
      priorityIndex: _int(json, 'priorityIndex'),
      layoutRows: _int(json, 'layoutRows'),
      layoutCols: _int(json, 'layoutCols'),
      pageCount: _int(json, 'pageCount'),
      doubleSided: _bool(json, 'doubleSided'),
      groupBy: json['groupBy'] == null
          ? null
          : _enum(BinderAxis.values, json, 'groupBy'),
      sortBy: _enum(BinderAxis.values, json, 'sortBy'),
      sortDir: _enum(SortDirection.values, json, 'sortDir'),
      isVirtual: _bool(json, 'isVirtual'),
      createdAt: _dateTime(json, 'createdAt'),
      updatedAt: _dateTime(json, 'updatedAt'),
    );

Map<String, dynamic> _slotToJson(BinderSlotRow slot) => {
      'id': slot.id,
      'binderId': slot.binderId,
      'scryfallId': slot.scryfallId,
      'finish': slot.finish.name,
      'quantity': slot.quantity,
      'page': slot.page,
      'side': slot.side.name,
      'pocket': slot.pocket,
      'isPinned': slot.isPinned,
      'createdAt': slot.createdAt.toUtc().toIso8601String(),
      'updatedAt': slot.updatedAt.toUtc().toIso8601String(),
    };

BinderSlotRow _slotFromJson(Map<String, dynamic> json) => BinderSlotRow(
      id: _string(json, 'id'),
      binderId: _string(json, 'binderId'),
      scryfallId: _string(json, 'scryfallId'),
      finish: _enum(Finish.values, json, 'finish'),
      quantity: _int(json, 'quantity'),
      page: _int(json, 'page'),
      side: _enum(PageSide.values, json, 'side'),
      pocket: _int(json, 'pocket'),
      isPinned: _bool(json, 'isPinned'),
      createdAt: _dateTime(json, 'createdAt'),
      updatedAt: _dateTime(json, 'updatedAt'),
    );

// --- strict field readers -------------------------------------------------

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('expected a JSON object, got $value');
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('field "$key" must be a string, got $value');
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('field "$key" must be an integer, got $value');
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('field "$key" must be a boolean, got $value');
}

DateTime _dateTime(Map<String, dynamic> json, String key) {
  return DateTime.parse(_string(json, key));
}

T _enum<T extends Enum>(List<T> values, Map<String, dynamic> json, String key) {
  final name = _string(json, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('field "$key" has unknown value "$name"');
}
