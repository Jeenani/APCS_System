import 'package:flutter_test/flutter_test.dart';
import 'package:apcs_system/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AsutpTasksApp());
    expect(find.text('АСУТП Tasks'), findsOneWidget);
  });
}
