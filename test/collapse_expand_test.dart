import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/glossary_screen.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/services/discovered_events.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DiscoveredEventsService.instance.resetAll();
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    UnlockedItemsService.instance.reset();
  });

  testWidgets('GlossaryScreen allows collapsing and expanding categories', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: GlossaryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Category header 'Монстр' exists
    expect(find.text('Монстр'), findsOneWidget);

    // Tap on category header 'Монстр' to collapse it
    await tester.tap(find.text('Монстр'));
    await tester.pumpAndSettle();

    // Tap 'Свернуть/Развернуть все' in AppBar
    final toggleAllFinder = find.widgetWithIcon(IconButton, Icons.unfold_more_rounded);
    expect(toggleAllFinder, findsOneWidget);
    await tester.tap(toggleAllFinder);
    await tester.pumpAndSettle();

    // Now all are expanded, icon changes to unfold_less_rounded
    expect(find.widgetWithIcon(IconButton, Icons.unfold_less_rounded), findsOneWidget);

    // Tap to collapse all
    await tester.tap(find.widgetWithIcon(IconButton, Icons.unfold_less_rounded));
    await tester.pumpAndSettle();

    // Now all are collapsed, 'Боссы' is in view
    expect(find.text('Боссы'), findsOneWidget);
  });

  testWidgets('InventoryScreen allows collapsing and expanding unlocked cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Section exists
    expect(find.text('Открытые карты предметов'), findsOneWidget);
    expect(find.text('Нет открытых карт'), findsOneWidget);

    // Tap on 'Открытые карты предметов' to collapse
    await tester.tap(find.text('Открытые карты предметов'));
    await tester.pumpAndSettle();

    // List/empty state is collapsed
    expect(find.text('Нет открытых карт'), findsNothing);

    // Tap again to expand
    await tester.tap(find.text('Открытые карты предметов'));
    await tester.pumpAndSettle();

    expect(find.text('Нет открытых карт'), findsOneWidget);
  });

  testWidgets('ShopScreen allows collapsing and expanding available cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Section exists
    expect(find.text('Доступные карты'), findsOneWidget);
    // Locked card widget exists in the grid
    expect(find.text('В сундуке'), findsWidgets);

    // Tap on 'Доступные карты' to collapse
    await tester.tap(find.text('Доступные карты'));
    await tester.pumpAndSettle();

    // Cards in grid are now collapsed
    expect(find.text('В сундуке'), findsNothing);

    // Tap again to expand
    await tester.tap(find.text('Доступные карты'));
    await tester.pumpAndSettle();

    expect(find.text('В сундуке'), findsWidgets);
  });
}
