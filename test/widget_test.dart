import 'package:flutter_test/flutter_test.dart';
import 'package:my_farm/app.dart';

void main() {
  testWidgets('FarmApp builds its root widget', (tester) async {
    await tester.pumpWidget(const FarmApp());
    await tester.pump();
    expect(find.byType(FarmApp), findsOneWidget);
  });
}
