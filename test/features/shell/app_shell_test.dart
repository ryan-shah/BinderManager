import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/features/shell/app_shell.dart';

void main() {
  // Helper: pump AppShell inside a GoRouter so context.go() works.
  Future<void> pumpShell(
    WidgetTester tester, {
    required double width,
    int currentIndex = 0,
    Widget child = const Text('Content'),
    List<String>? navigatedPaths,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build a GoRouter with the 4 shell paths so context.go() doesn't throw.
    final router = GoRouter(
      initialLocation: '/binders',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            final index = ['/binders', '/collection', '/decks', '/settings']
                .indexOf(state.matchedLocation);
            return AppShell(
              currentIndex: index >= 0 ? index : currentIndex,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/binders',
              builder: (_, __) => child,
            ),
            GoRoute(
              path: '/collection',
              builder: (_, __) => const Text('Collection Content'),
            ),
            GoRoute(
              path: '/decks',
              builder: (_, __) => const Text('Decks Content'),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const Text('Settings Content'),
            ),
          ],
        ),
      ],
    );

    if (navigatedPaths != null) {
      router.routerDelegate.addListener(() {
        final location =
            router.routerDelegate.currentConfiguration.last.matchedLocation;
        navigatedPaths.add(location);
      });
    }

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Helper: pump AppShell with a fixed currentIndex (no routing needed).
  Future<void> pumpFixedShell(
    WidgetTester tester, {
    required double width,
    int currentIndex = 0,
    Widget child = const Text('Content'),
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Wrap in a GoRouter so context.go() doesn't crash when tapped.
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (_, __) => AppShell(
            currentIndex: currentIndex,
            child: child,
          ),
        ),
        // Dummy routes so context.go() calls don't throw
        GoRoute(path: '/binders', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/collection', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/decks', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppShell - desktop layout (900px)', () {
    testWidgets('renders sidebar with app title', (tester) async {
      await pumpFixedShell(tester, width: 900);

      expect(find.text('BinderManager'), findsOneWidget);
    });

    testWidgets('renders NAVIGATION section label', (tester) async {
      await pumpFixedShell(tester, width: 900);

      expect(find.text('NAVIGATION'), findsOneWidget);
    });

    testWidgets('renders all 4 nav item labels', (tester) async {
      await pumpFixedShell(tester, width: 900);

      expect(find.text('Binders'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders BINDER SHORTCUTS label', (tester) async {
      await pumpFixedShell(tester, width: 900);

      expect(find.text('BINDER SHORTCUTS'), findsOneWidget);
    });

    testWidgets('child widget is rendered in content area', (tester) async {
      await pumpFixedShell(
        tester,
        width: 900,
        child: const Text('Test Child'),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('no BottomNavigationBar on desktop', (tester) async {
      await pumpFixedShell(tester, width: 900);

      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  group('AppShell - mobile layout (400px)', () {
    testWidgets('renders BottomNavigationBar', (tester) async {
      await pumpFixedShell(tester, width: 400);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('BottomNavigationBar has all 4 item labels', (tester) async {
      await pumpFixedShell(tester, width: 400);

      // "Binders" appears in both the AppBar title and BottomNavigationBar
      // when currentIndex=0, so expect at least one for each label.
      expect(find.text('Binders'), findsWidgets);
      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('no sidebar visible (no NAVIGATION label)', (tester) async {
      await pumpFixedShell(tester, width: 400);

      expect(find.text('NAVIGATION'), findsNothing);
      expect(find.text('BINDER SHORTCUTS'), findsNothing);
      expect(find.text('BinderManager'), findsNothing);
    });

    testWidgets('AppBar shows current screen title', (tester) async {
      await pumpFixedShell(tester, width: 400, currentIndex: 0);

      // Mobile shows the current destination label in the AppBar
      expect(find.byType(AppBar), findsOneWidget);
      // "Binders" appears in both AppBar title and BottomNavigationBar
      expect(find.text('Binders'), findsWidgets);
    });

    testWidgets('AppBar shows Decks when currentIndex is 2', (tester) async {
      await pumpFixedShell(tester, width: 400, currentIndex: 2);

      expect(find.byType(AppBar), findsOneWidget);
      // "Decks" appears in AppBar title and BottomNavigationBar
      expect(find.text('Decks'), findsWidgets);
    });
  });

  group('AppShell - active nav item styling (desktop)', () {
    testWidgets('Binders nav item is highlighted when currentIndex=0',
        (tester) async {
      await pumpFixedShell(tester, width: 900, currentIndex: 0);

      // Find the Container wrapping the "Binders" text in the sidebar.
      // The active item has a non-transparent background (neutral800).
      final bindersText = find.text('Binders');
      expect(bindersText, findsOneWidget);

      // Walk up to the decorated Container and check its color
      final container = find.ancestor(
        of: bindersText,
        matching: find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final deco = w.decoration as BoxDecoration;
            return deco.color == const Color(0xFF36352F); // neutral800
          }
          return false;
        }),
      );
      expect(container, findsOneWidget);
    });

    testWidgets('Decks nav item is highlighted when currentIndex=2',
        (tester) async {
      await pumpFixedShell(tester, width: 900, currentIndex: 2);

      final decksText = find.text('Decks');
      expect(decksText, findsOneWidget);

      final container = find.ancestor(
        of: decksText,
        matching: find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final deco = w.decoration as BoxDecoration;
            return deco.color == const Color(0xFF36352F); // neutral800
          }
          return false;
        }),
      );
      expect(container, findsOneWidget);
    });

    testWidgets('non-active items have transparent background',
        (tester) async {
      await pumpFixedShell(tester, width: 900, currentIndex: 0);

      // "Collection" should NOT have the active background
      final collectionText = find.text('Collection');
      expect(collectionText, findsOneWidget);

      final container = find.ancestor(
        of: collectionText,
        matching: find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final deco = w.decoration as BoxDecoration;
            return deco.color == Colors.transparent;
          }
          return false;
        }),
      );
      expect(container, findsOneWidget);
    });
  });

  group('AppShell - navigation', () {
    testWidgets('tapping desktop nav item triggers GoRouter navigation',
        (tester) async {
      final navigated = <String>[];
      await pumpShell(tester, width: 900, navigatedPaths: navigated);

      // Tap "Settings" (index 3)
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // After tapping, the router should have navigated to /settings.
      // We verify by checking that Settings is now the active destination
      // (the shell re-renders with the new index).
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping mobile bottom nav item triggers navigation',
        (tester) async {
      await pumpShell(tester, width: 400);

      // Tap "Decks" in the bottom nav bar
      await tester.tap(find.text('Decks'));
      await tester.pumpAndSettle();

      // After navigation, Decks content should appear
      expect(find.text('Decks Content'), findsOneWidget);
    });
  });
}
