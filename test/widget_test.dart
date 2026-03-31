import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doboard/app.dart';

void main() {
  testWidgets('doboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DoboardApp()),
    );
    expect(find.byType(DoboardApp), findsOneWidget);
  });
}