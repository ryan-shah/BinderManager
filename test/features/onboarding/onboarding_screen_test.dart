import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/features/onboarding/onboarding_screen.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';

/// A fake [CorpusImportNotifier] that does not depend on a real database.
class FakeImportNotifier extends StateNotifier<CorpusImportState>
    implements CorpusImportNotifier {
  FakeImportNotifier([CorpusImportState? initial])
      : super(initial ?? const CorpusImportState());

  bool runImportCalled = false;

  @override
  Future<void> runImport() async {
    runImportCalled = true;
  }
}

void main() {
  /// Pump the OnboardingScreen with the given notifier overriding the provider.
  Future<FakeImportNotifier> pumpOnboarding(
    WidgetTester tester, {
    CorpusImportState? initialState,
    FakeImportNotifier? notifier,
  }) async {
    final fakeNotifier =
        notifier ?? FakeImportNotifier(initialState);

    // Wrap in a GoRouter so context.go('/binders') on completion doesn't crash.
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/binders',
          builder: (_, __) => const Text('Binders Screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corpusImportProvider.overrideWith((_) => fakeNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
        ),
      ),
    );

    return fakeNotifier;
  }

  group('OnboardingScreen', () {
    testWidgets('renders welcome text and download button in idle state',
        (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('Welcome to BinderManager'), findsOneWidget);
      expect(
        find.text('Download card data to get started'),
        findsOneWidget,
      );
      expect(
        find.text('~150 MB of card data from Scryfall'),
        findsOneWidget,
      );
      expect(find.text('Download Card Data'), findsOneWidget);
    });

    testWidgets('download button triggers import', (tester) async {
      final notifier = await pumpOnboarding(tester);

      expect(notifier.runImportCalled, isFalse);

      await tester.tap(find.text('Download Card Data'));
      await tester.pump();

      expect(notifier.runImportCalled, isTrue);
    });

    testWidgets('shows progress bar during download', (tester) async {
      await pumpOnboarding(
        tester,
        initialState: const CorpusImportState(
          phase: 'downloading',
          progress: 0.5,
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // The status text is "downloading... 50%"
      expect(find.textContaining('50%'), findsOneWidget);
      // The download button should NOT be visible during progress
      expect(find.text('Download Card Data'), findsNothing);
    });

    testWidgets('shows indeterminate progress when progress is null',
        (tester) async {
      await pumpOnboarding(
        tester,
        initialState: const CorpusImportState(
          phase: 'clearing',
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('clearing...'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await pumpOnboarding(
        tester,
        initialState: const CorpusImportState(
          phase: 'error',
          error: 'Network error',
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry Download'), findsOneWidget);
      // No progress bar in error state
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('retry button triggers import after error', (tester) async {
      final notifier = FakeImportNotifier(
        const CorpusImportState(
          phase: 'error',
          error: 'Network error',
        ),
      );
      await pumpOnboarding(tester, notifier: notifier);

      expect(notifier.runImportCalled, isFalse);

      await tester.tap(find.text('Retry Download'));
      await tester.pump();

      expect(notifier.runImportCalled, isTrue);
    });

    testWidgets('shows completion state with check icon', (tester) async {
      await pumpOnboarding(
        tester,
        initialState: const CorpusImportState(
          phase: 'complete (1000 cards)',
          complete: true,
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('complete (1000 cards)'), findsOneWidget);
      // No download button when complete
      expect(find.text('Download Card Data'), findsNothing);
      // No progress bar
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
