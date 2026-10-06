import 'package:flutter_test/flutter_test.dart';

import 'package:beemview_app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const BeemViewApp());

    // Verify the app renders
    expect(find.text('BeemView'), findsWidgets);
  });
}
