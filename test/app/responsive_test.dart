import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/app/responsive.dart';
import 'package:binder_manager/app/theme.dart';

void main() {
  group('layoutModeOf', () {
    Widget buildTestWidget({
      required double width,
      required ValueSetter<BuildContext> onBuild,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: Builder(
          builder: (context) {
            onBuild(context);
            return const SizedBox();
          },
        ),
      );
    }

    testWidgets('returns desktop when width >= kDesktopBreakpoint',
        (tester) async {
      late LayoutMode result;
      await tester.pumpWidget(
        buildTestWidget(
          width: 1024,
          onBuild: (ctx) => result = layoutModeOf(ctx),
        ),
      );
      expect(result, LayoutMode.desktop);
    });

    testWidgets('returns mobile when width < kDesktopBreakpoint',
        (tester) async {
      late LayoutMode result;
      await tester.pumpWidget(
        buildTestWidget(
          width: 400,
          onBuild: (ctx) => result = layoutModeOf(ctx),
        ),
      );
      expect(result, LayoutMode.mobile);
    });

    testWidgets('edge case: exactly 808px is desktop', (tester) async {
      late LayoutMode result;
      await tester.pumpWidget(
        buildTestWidget(
          width: kDesktopBreakpoint,
          onBuild: (ctx) => result = layoutModeOf(ctx),
        ),
      );
      expect(result, LayoutMode.desktop);
    });

    testWidgets('returns mobile at 807px (one below breakpoint)',
        (tester) async {
      late LayoutMode result;
      await tester.pumpWidget(
        buildTestWidget(
          width: 807,
          onBuild: (ctx) => result = layoutModeOf(ctx),
        ),
      );
      expect(result, LayoutMode.mobile);
    });
  });
}
