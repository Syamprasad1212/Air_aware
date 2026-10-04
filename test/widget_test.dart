import 'package:flutter_test/flutter_test.dart';
import 'package:air_aware/main.dart';

void main() {
  testWidgets('AirAware app initial widget smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AirAwareApp());

    // Verify that the title is rendered
    expect(find.text('AirAware'), findsOneWidget);
  });
}
