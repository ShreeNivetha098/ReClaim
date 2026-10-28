// Walks through the main screens so they can be screenshotted for UI review.
// Run against the Firebase emulators with seeded data (see README), e.g.
//   flutter test integration_test/screen_tour_test.dart -d <simulator> \
//     --dart-define=USE_FIREBASE_EMULATORS=true
// Each "SHOT:<name>" line marks a screen that is ready to capture.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reclaim/main.dart' as app;
import 'package:reclaim/shared/widgets/item_card.dart';

Future<void> wait(WidgetTester tester, double seconds) async {
  final steps = (seconds * 10).round();
  for (var i = 0; i < steps; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  await wait(tester, 1.5);
  // ignore: avoid_print
  print('SHOT:$name');
  await wait(tester, 3);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screen tour', (tester) async {
    await app.main();
    await wait(tester, 5);

    if (find.text('Log In').evaluate().isNotEmpty) {
      await shot(tester, 'login');
      await tester.tap(find.text('Register Now'));
      await wait(tester, 2);
      await shot(tester, 'register');
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -1400));
      await shot(tester, 'register-scrolled');
      await tester.pageBack();
      await wait(tester, 2);
      await tester.enterText(find.byType(TextFormField).at(0), 'priya@psgtech.ac.in');
      await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rd!x');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(find.text('Log In'));
      await wait(tester, 6);
    }

    await shot(tester, 'home');
    await tester.tap(find.text('Possible match!'));
    await wait(tester, 2);
    await shot(tester, 'matches');
    await tester.pageBack();
    await wait(tester, 2);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await shot(tester, 'home-scrolled');

    await tester.tap(find.byType(ItemCard).first);
    await wait(tester, 2);
    await shot(tester, 'item-details');
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
    await shot(tester, 'item-details-scrolled');
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await wait(tester, 2);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await wait(tester, 1.5);
    await shot(tester, 'report-sheet');
    // The Home tile behind the sheet has the same text, so tap the sheet's.
    await tester.tap(find.text('I lost\nsomething').last);
    await wait(tester, 2);
    await shot(tester, 'report-lost');
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -700));
    await shot(tester, 'report-lost-scrolled');
    await tester.pageBack();
    await wait(tester, 2);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await wait(tester, 1.5);
    await tester.tap(find.text('I found\nsomething').last);
    await wait(tester, 2);
    await shot(tester, 'report-found');
    await tester.pageBack();
    await wait(tester, 2);

    await tester.tap(find.text('Search'));
    await shot(tester, 'search');

    await tester.tap(find.text('Alerts'));
    await shot(tester, 'alerts');

    await tester.tap(find.text('Profile'));
    await shot(tester, 'profile');

    await tester.tap(find.text('My reports'));
    await wait(tester, 2);
    await shot(tester, 'my-reports');
  });
}
