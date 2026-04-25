import 'package:flutter_test/flutter_test.dart';
import 'package:commit_lock/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommitLockApp());

    // Verify that our initial state is correct.
    // Since the original test was for the counter app, we just check if the app builds.
    expect(find.text('Login'), findsOneWidget);
  });
}
