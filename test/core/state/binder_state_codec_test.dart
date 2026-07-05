import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';
import 'package:binder_manager/core/state/binder_state_codec.dart';

void main() {
  final created = DateTime.utc(2026, 7, 1, 8, 30);
  final updated = DateTime.utc(2026, 7, 4, 12, 15);

  Binder makeBinder({
    String id = 'binder-1',
    int priorityIndex = 0,
    BinderAxis? groupBy = BinderAxis.cardType,
  }) =>
      Binder(
        id: id,
        name: 'Trade binder',
        query: 'unused:true usd>5',
        priorityIndex: priorityIndex,
        layoutRows: 3,
        layoutCols: 3,
        pageCount: 20,
        doubleSided: true,
        groupBy: groupBy,
        sortBy: BinderAxis.price,
        sortDir: SortDirection.desc,
        isVirtual: false,
        createdAt: created,
        updatedAt: updated,
      );

  BinderSlotRow makeSlot({
    String id = 'slot-1',
    String binderId = 'binder-1',
    bool isPinned = false,
  }) =>
      BinderSlotRow(
        id: id,
        binderId: binderId,
        scryfallId: 'bolt-1',
        finish: Finish.foil,
        quantity: 4,
        page: 3,
        side: PageSide.back,
        pocket: 5,
        isPinned: isPinned,
        createdAt: created,
        updatedAt: updated,
      );

  group('encodeBinderState', () {
    test('writes the schema version and both sections', () {
      final json = encodeBinderState(binders: [], slots: []);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['version'], binderStateSchemaVersion);
      expect(decoded['binders'], isEmpty);
      expect(decoded['binderSlots'], isEmpty);
    });

    test('serializes enums by name and timestamps as UTC ISO-8601', () {
      final json = encodeBinderState(
        binders: [makeBinder()],
        slots: [makeSlot()],
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      final binder =
          (decoded['binders'] as List).single as Map<String, dynamic>;
      expect(binder['groupBy'], 'cardType');
      expect(binder['sortBy'], 'price');
      expect(binder['sortDir'], 'desc');
      expect(binder['createdAt'], '2026-07-01T08:30:00.000Z');

      final slot =
          (decoded['binderSlots'] as List).single as Map<String, dynamic>;
      expect(slot['finish'], 'foil');
      expect(slot['side'], 'back');
      expect(slot['updatedAt'], '2026-07-04T12:15:00.000Z');
    });
  });

  group('round-trip', () {
    test('binders and slots survive encode → decode exactly', () {
      final binders = [
        makeBinder(),
        makeBinder(id: 'binder-2', priorityIndex: 1, groupBy: null),
      ];
      final slots = [
        makeSlot(),
        makeSlot(id: 'slot-2', binderId: 'binder-2', isPinned: true),
      ];

      final snapshot =
          decodeBinderState(encodeBinderState(binders: binders, slots: slots));

      expect(snapshot.binders, binders);
      expect(snapshot.slots, slots);
      expect(snapshot.binders[1].groupBy, isNull);
      expect(snapshot.slots[1].isPinned, isTrue);
    });

    test('priority order survives via priorityIndex', () {
      final binders = [
        makeBinder(id: 'second', priorityIndex: 1),
        makeBinder(id: 'first', priorityIndex: 0),
      ];

      final snapshot =
          decodeBinderState(encodeBinderState(binders: binders, slots: []));

      final byPriority = [...snapshot.binders]
        ..sort((a, b) => a.priorityIndex.compareTo(b.priorityIndex));
      expect(byPriority.map((b) => b.id).toList(), ['first', 'second']);
    });
  });

  group('decodeBinderState validation', () {
    test('rejects an unknown schema version', () {
      final json = jsonEncode({
        'version': 999,
        'binders': <Object>[],
        'binderSlots': <Object>[],
      });

      expect(
        () => decodeBinderState(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('unsupported snapshot schema version: 999'),
        )),
      );
    });

    test('rejects a missing version', () {
      final json = jsonEncode({
        'binders': <Object>[],
        'binderSlots': <Object>[],
      });

      expect(() => decodeBinderState(json), throwsFormatException);
    });

    test('rejects malformed JSON', () {
      expect(() => decodeBinderState('not json'), throwsFormatException);
      expect(() => decodeBinderState('[1,2]'), throwsFormatException);
    });

    test('rejects missing sections', () {
      final json = jsonEncode({'version': binderStateSchemaVersion});

      expect(() => decodeBinderState(json), throwsFormatException);
    });

    test('rejects unknown enum values', () {
      final json = jsonEncode({
        'version': binderStateSchemaVersion,
        'binders': <Object>[],
        'binderSlots': [
          {
            'id': 's1',
            'binderId': 'b1',
            'scryfallId': 'bolt',
            'finish': 'holographic',
            'quantity': 1,
            'page': 1,
            'side': 'front',
            'pocket': 1,
            'isPinned': false,
            'createdAt': '2026-07-01T08:30:00.000Z',
            'updatedAt': '2026-07-01T08:30:00.000Z',
          }
        ],
      });

      expect(
        () => decodeBinderState(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('holographic'),
        )),
      );
    });

    test('rejects wrongly-typed fields', () {
      final json = jsonEncode({
        'version': binderStateSchemaVersion,
        'binders': [
          {
            'id': 'b1',
            'name': 'Trade binder',
            'query': '',
            'priorityIndex': 'zero', // wrong type
            'layoutRows': 3,
            'layoutCols': 3,
            'pageCount': 20,
            'doubleSided': true,
            'groupBy': null,
            'sortBy': 'price',
            'sortDir': 'desc',
            'isVirtual': false,
            'createdAt': '2026-07-01T08:30:00.000Z',
            'updatedAt': '2026-07-01T08:30:00.000Z',
          }
        ],
        'binderSlots': <Object>[],
      });

      expect(() => decodeBinderState(json), throwsFormatException);
    });
  });
}
