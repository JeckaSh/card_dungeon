import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
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

  testWidgets('ItemUsedDialog renders details and can be dismissed', (tester) async {
    final potion = allItemCards.first; // Зелье лечения (+2)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemUsedDialog(
            item: potion,
            resultTitle: '+2 ❤',
            resultDescription: 'Здоровье героя восстановлено на +2 ❤.\nТекущее здоровье: 12 ❤.',
          ),
        ),
      ),
    );

    expect(find.text('Карта использована'), findsOneWidget);
    expect(find.text('Зелье лечения'), findsOneWidget);
    expect(find.text('+2 ❤'), findsOneWidget);
    expect(find.textContaining('Здоровье героя восстановлено'), findsOneWidget);
    expect(find.text('Отлично'), findsOneWidget);

    // Tap dismiss button
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();
  });

  testWidgets('Using an item from inventory shows ItemUsedDialog in GameScreen', (tester) async {
    final potion = allItemCards.first; // Зелье лечения (+2)
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialInventory: [potion],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Inventory button should exist
    final inventoryButtonFinder =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    expect(inventoryButtonFinder, findsOneWidget);

    // Open inventory
    await tester.tap(inventoryButtonFinder);
    await tester.pumpAndSettle();

    // Inventory sheet should be visible with the item
    expect(find.text('Инвентарь забега'), findsOneWidget);
    expect(find.text('Зелье лечения'), findsOneWidget);
    expect(find.text('Применить'), findsOneWidget);

    // Use the item
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    // Now ItemUsedDialog must be displayed!
    expect(find.byType(ItemUsedDialog), findsOneWidget);
    expect(find.text('Карта использована'), findsOneWidget);
    expect(find.text('Зелье лечения'), findsOneWidget);
    expect(find.text('+4 ❤'), findsOneWidget);
    expect(find.textContaining('Здоровье героя восстановлено'), findsOneWidget);

    // Close the dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Dialog is closed and game is visible
    expect(find.byType(ItemUsedDialog), findsNothing);
  });

  testWidgets('Using smoke bomb on boss advances dungeon level', (tester) async {
    final smokeBomb = allItemCards.firstWhere((item) => item.id == 'smoke_bomb');
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 1,
          initialCardsPassed: 19, // 20th card is 1st boss
          initialInventory: [smokeBomb],
        ),
      ),
    );
    // Pump frames for repeating pulse animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Boss is present
    expect(find.text('Альфа-вожак Ночной Стаи'), findsOneWidget);
    expect(find.textContaining('готовься к бою!'), findsOneWidget);

    // Open inventory
    final inventoryButtonFinder =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Use smoke bomb
    await tester.tap(find.text('Применить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ItemUsedDialog is shown with boss escape description
    expect(find.byType(ItemUsedDialog), findsOneWidget);
    expect(find.text('Побег от босса 💨'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level should now be 2!
    expect(find.textContaining('Уровень 2'), findsOneWidget);
  });

  testWidgets('Using skip turn on boss advances dungeon level', (tester) async {
    final scrollSkip = allItemCards.firstWhere((item) => item.id == 'scroll_skip');
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 1,
          initialCardsPassed: 19, // 20th card is 1st boss
          initialInventory: [scrollSkip],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Boss is present
    expect(find.text('Альфа-вожак Ночной Стаи'), findsOneWidget);

    // Open inventory
    final inventoryButtonFinder =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Use scroll skip
    await tester.tap(find.text('Применить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ItemUsedDialog is shown with boss skip description
    expect(find.byType(ItemUsedDialog), findsOneWidget);
    expect(find.text('Босс пропущен ⏩'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level should now be 2!
    expect(find.textContaining('Уровень 2'), findsOneWidget);
  });
}

