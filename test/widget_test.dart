import 'package:flutter_test/flutter_test.dart';
import 'package:memco_iot_app/main.dart';

void main() {
  testWidgets('shows the login screen without a restored session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MemcoApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
