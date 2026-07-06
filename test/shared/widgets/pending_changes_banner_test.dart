import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/shared/providers/change_staging_provider.dart';
import 'package:binder_manager/shared/providers/user_database_provider.dart';
import 'package:binder_manager/shared/widgets/pending_changes_banner.dart';

void main() {
  late UserDatabase userDb;
  late ProviderContainer container;

  setUp(() {
    userDb = UserDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      userDatabaseProvider.overrideWithValue(userDb),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await userDb.close();
  });

  Future<void> pumpScope(WidgetTester tester, {required String location}) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PendingChangesScope(
            location: location,
            child: const Text('content'),
          ),
        ),
      ),
    );
  }

  Future<void> stageOneAdd() {
    return container.read(changeStagingProvider.notifier).stage(
      trigger: ChangeTrigger.ruleEdit,
      planned: const [
        PlannedPlacement(
          binderId: 'b1',
          identity: CardIdentity('x', Finish.nonfoil),
          quantity: 1,
          position:
              BinderPosition(page: 1, side: PageSide.front, pocket: 1),
        ),
      ],
    );
  }

  testWidgets('hidden when nothing is staged', (tester) async {
    await pumpScope(tester, location: '/binders');
    expect(find.text('content'), findsOneWidget);
    expect(find.textContaining('Pending changes'), findsNothing);
  });

  testWidgets('shows the summary when a diff is staged', (tester) async {
    await stageOneAdd();
    await pumpScope(tester, location: '/binders');

    expect(find.textContaining('Pending changes — 1 add'), findsOneWidget);
    expect(find.text('Review →'), findsOneWidget);
  });

  testWidgets('suppressed on the review screen itself', (tester) async {
    await stageOneAdd();
    await pumpScope(tester, location: '/changes');

    expect(find.textContaining('Pending changes'), findsNothing);
  });
}
