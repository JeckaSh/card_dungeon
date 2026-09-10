import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
  });

  testWidgets('InventoryScreen has AppBar and full SingleChildScrollView', (tester) async {
    // Phone size screen
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Consistent AppBar exists with title
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Инвентарь'), findsOneWidget);

    // 2. Entire body is wrapped in SingleChildScrollView
    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    // 3. Sections exist inside the scroll view
    expect(find.text('Монеты'), findsOneWidget);
    expect(find.text('Прокачка персонажа'), findsOneWidget);
    expect(find.text('Открытые карты предметов'), findsOneWidget);

    // 4. Scrolling down works smoothly on the entire screen
    await tester.drag(scrollViewFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling down, bottom section is still visible / reached
    expect(find.text('Открытые карты предметов'), findsOneWidget);
  });
}
