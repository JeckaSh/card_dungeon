import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/screens/glossary_screen.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/services/discovered_events.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/item_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DiscoveredEventsService.instance.resetAll();
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
  });

  testWidgets('GlossaryScreen card detail sheet has a working close button', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Discover at least one event so it is tapable and visible in glossary
    DiscoveredEventsService.instance.markDiscovered('forest_wolf_lone');

    await tester.pumpWidget(
      const MaterialApp(home: GlossaryScreen()),
    );
    await tester.pumpAndSettle();

    // Find and tap the card tile/text for wolf ('Одичавший лютоволк')
    final cardFinder = find.text('Одичавший лютоволк');
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Close button ('Закрыть') should be present
    final closeButtonFinder = find.widgetWithText(ElevatedButton, 'Закрыть');
    expect(closeButtonFinder, findsOneWidget);

    // Tap 'Закрыть' button
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Detail sheet should now be closed
    expect(closeButtonFinder, findsNothing);
  });

  testWidgets('InventoryScreen card detail sheet has a working close button', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Unlock at least 1 item
    await UnlockedItemsService.instance.unlock('potion_heal');

    await tester.pumpWidget(
      const MaterialApp(home: InventoryScreen()),
    );
    await tester.pumpAndSettle();

    // Tap the potion_heal card
    final cardFinder = find.text('Зелье лечения');
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Close button ('Закрыть') should be present
    final closeButtonFinder = find.widgetWithText(ElevatedButton, 'Закрыть');
    expect(closeButtonFinder, findsOneWidget);

    // Tap 'Закрыть'
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Sheet is closed
    expect(find.byType(ItemDetailsSheet), findsNothing);
  });

  testWidgets('ShopScreen card detail sheet has a working close button', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await UnlockedItemsService.instance.unlock('medicinal_herbs');

    await tester.pumpWidget(
      const MaterialApp(home: ShopScreen()),
    );
    await tester.pumpAndSettle();

    // Tap on unlocked card in shop
    final unlockedCardFinder = find.text('Лечебные травы');
    expect(unlockedCardFinder, findsOneWidget);
    await tester.ensureVisible(unlockedCardFinder);
    await tester.pumpAndSettle();
    await tester.tap(unlockedCardFinder);
    await tester.pumpAndSettle();

    // Verify close button
    expect(find.widgetWithText(ElevatedButton, 'Закрыть'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Закрыть'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailsSheet), findsNothing);
  });

  testWidgets('In-game InventorySheet and item details both have working close buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final item = allItemCards.firstWhere((i) => i.id == 'potion_heal');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [item])),
    );
    await tester.pumpAndSettle();

    // Open inventory backpack
    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    // Verify in-game inventory sheet has 'Закрыть'
    expect(find.widgetWithText(ElevatedButton, 'Закрыть'), findsOneWidget);

    // Tap item card to open ItemDetailsSheet
    await tester.tap(find.text('Зелье лечения'));
    await tester.pumpAndSettle();

    // ItemDetailsSheet is open with 'Закрыть'
    expect(find.byType(ItemDetailsSheet), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Закрыть').last);
    await tester.pumpAndSettle();

    // ItemDetailsSheet closed, back to inventory sheet
    expect(find.byType(ItemDetailsSheet), findsNothing);

    // Close inventory sheet
    await tester.tap(find.widgetWithText(ElevatedButton, 'Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Инвентарь забега'), findsNothing);
  });
}
