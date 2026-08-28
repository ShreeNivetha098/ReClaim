import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclaim/main.dart';

void main() {
  testWidgets('ReClaim App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ReClaimApp(),
      ),
    );

    // Verify initial splash screen renders ReClaim logo
    expect(find.text('ReClaim'), findsOneWidget);

    // Advance time beyond splash delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // App navigates to Home (since repository initial state seeds currentUser)
    expect(find.textContaining('ReClaim'), findsWidgets);
  });
}
