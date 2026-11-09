import 'package:flutter_test/flutter_test.dart';
import 'package:hundred_block/main.dart';

void main() {
  testWidgets('app shows its title', (tester) async {
    await tester.pumpWidget(const HundredBlockApp());
    expect(find.text('Hundred Block'), findsOneWidget);
  });
}
