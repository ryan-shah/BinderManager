import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/shared/widgets/commit_rollback_bar.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 7, 4);

  BinderDiffEntry entry(DiffType type, {String scryfallId = 'bolt'}) {
    const position = BinderPosition(page: 1, side: PageSide.front, pocket: 1);
    const other = BinderPosition(page: 2, side: PageSide.back, pocket: 3);
    return BinderDiffEntry(
      type: type,
      binderId: 'binder-a',
      identity: CardIdentity(scryfallId, Finish.nonfoil),
      quantity: 1,
      from: type == DiffType.add ? null : position,
      to: type == DiffType.remove ? null : other,
    );
  }

  StagedDiff diffWith(List<BinderDiffEntry> entries) => StagedDiff(
        trigger: ChangeTrigger.ruleEdit,
        entries: entries,
        createdAt: fixedNow,
      );

  Widget build({
    required StagedDiff diff,
    VoidCallback? onCommit,
    VoidCallback? onRollback,
    bool busy = false,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: const SizedBox.shrink(),
        bottomNavigationBar: CommitRollbackBar(
          diff: diff,
          onCommit: onCommit ?? () {},
          onRollback: onRollback ?? () {},
          busy: busy,
        ),
      ),
    );
  }

  group('summaryText', () {
    test('pluralizes and joins non-zero counts', () {
      final diff = diffWith([
        entry(DiffType.add, scryfallId: 'a'),
        entry(DiffType.add, scryfallId: 'b'),
        entry(DiffType.add, scryfallId: 'c'),
        entry(DiffType.add, scryfallId: 'd'),
        entry(DiffType.remove, scryfallId: 'e'),
        entry(DiffType.move, scryfallId: 'f'),
        entry(DiffType.move, scryfallId: 'g'),
      ]);

      expect(CommitRollbackBar.summaryText(diff), '4 adds · 1 remove · 2 moves');
    });

    test('omits zero counts', () {
      final diff = diffWith([entry(DiffType.add)]);

      expect(CommitRollbackBar.summaryText(diff), '1 add');
    });

    test('overflow-only diff reads as no placement changes', () {
      final diff = StagedDiff(
        trigger: ChangeTrigger.collectionImport,
        entries: const [],
        overflowChanges: const [
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('urza', Finish.foil),
            quantity: 1,
          ),
        ],
        createdAt: fixedNow,
      );

      expect(CommitRollbackBar.summaryText(diff), 'No placement changes');
    });
  });

  group('CommitRollbackBar', () {
    testWidgets('shows the summary and both actions', (tester) async {
      await tester.pumpWidget(build(
        diff: diffWith([entry(DiffType.add), entry(DiffType.move)]),
      ));

      expect(find.text('1 add · 1 move'), findsOneWidget);
      expect(find.text('Commit'), findsOneWidget);
      expect(find.text('Roll back'), findsOneWidget);
    });

    testWidgets('fires callbacks on tap', (tester) async {
      var committed = 0;
      var rolledBack = 0;
      await tester.pumpWidget(build(
        diff: diffWith([entry(DiffType.add)]),
        onCommit: () => committed++,
        onRollback: () => rolledBack++,
      ));

      await tester.tap(find.text('Commit'));
      await tester.tap(find.text('Roll back'));

      expect(committed, 1);
      expect(rolledBack, 1);
    });

    testWidgets('busy disables both buttons and shows a spinner',
        (tester) async {
      var committed = 0;
      await tester.pumpWidget(build(
        diff: diffWith([entry(DiffType.add)]),
        onCommit: () => committed++,
        busy: true,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Commit'), findsNothing);

      final rollbackButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Roll back'),
      );
      expect(rollbackButton.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(committed, 0);
    });
  });
}
