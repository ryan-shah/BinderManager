import 'package:flutter_test/flutter_test.dart';
import 'package:binder_manager/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BinderManagerApp());
    await tester.pumpAndSettle();
    expect(find.text('Binders'), findsOneWidget);
  });
}
