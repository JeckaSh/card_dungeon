import 'package:flutter_test/flutter_test.dart';

import 'package:kki_cardgame/main.dart';

void main() {
  testWidgets('Menu screen shows dungeon button', (WidgetTester tester) async {
    await tester.pumpWidget(const DungeonCardsApp());

    expect(find.text('Подземелье'), findsOneWidget);
    expect(find.text('В подземелье'), findsOneWidget);
    expect(find.text('Глоссарий'), findsOneWidget);
  });
}
