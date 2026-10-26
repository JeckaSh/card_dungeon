import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
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

  testWidgets('Using smoke bomb on multi-phase boss skips only phase 1, and phase 3 advances level', (tester) async {
    final smokeBomb1 = allItemCards.firstWhere((item) => item.id == 'smoke_bomb');
    final smokeBomb2 = allItemCards.firstWhere((item) => item.id == 'smoke_bomb');
    final smokeBomb3 = allItemCards.firstWhere((item) => item.id == 'smoke_bomb');
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 1,
          initialCardsPassed: 19, // 20th card is 1st boss
          initialInventory: [smokeBomb1, smokeBomb2, smokeBomb3],
        ),
      ),
    );
    // Pump frames for repeating pulse animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Boss is present
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          [
            'Альфа-вожак Ночной Стаи',
            'Ткачиха Скверны Арахна',
            'Проклятый Древобород',
          ].contains(w.data)),
      findsOneWidget,
    );

    // Open inventory
    final inventoryButtonFinder =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Use 1st smoke bomb on phase 1
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ItemUsedDialog is shown with phase 1 escape description
    expect(find.byType(ItemUsedDialog), findsOneWidget);
    expect(find.text('Побег от фазы 1 💨'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level is still 1, but next phase (Фаза II) is now active!
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.textContaining('Фаза II'),
      ),
      findsOneWidget,
    );

    // Use 2nd smoke bomb on phase 2
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Побег от фазы 2 💨'), findsOneWidget);
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Still level 1, now phase 3
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.textContaining('Фаза III'),
      ),
      findsOneWidget,
    );

    // Use 3rd smoke bomb on phase 3
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // On phase 3, boss is fully passed!
    expect(find.text('Побег от босса 💨'), findsOneWidget);
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level should now be 2!
    expect(find.text('Уровень 2'), findsOneWidget);
  });

  testWidgets('Using skip turn on multi-phase boss skips only current phase', (tester) async {
    final scrollSkip1 = allItemCards.firstWhere((item) => item.id == 'scroll_skip');
    final scrollSkip2 = allItemCards.firstWhere((item) => item.id == 'scroll_skip');
    final scrollSkip3 = allItemCards.firstWhere((item) => item.id == 'scroll_skip');
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 1,
          initialCardsPassed: 19, // 20th card is 1st boss
          initialInventory: [scrollSkip1, scrollSkip2, scrollSkip3],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Boss is present
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          [
            'Альфа-вожак Ночной Стаи',
            'Ткачиха Скверны Арахна',
            'Проклятый Древобород',
          ].contains(w.data)),
      findsOneWidget,
    );

    // Open inventory
    final inventoryButtonFinder =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Use 1st scroll skip
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ItemUsedDialog is shown with phase 1 skip description
    expect(find.byType(ItemUsedDialog), findsOneWidget);
    expect(find.text('Фаза 1 пропущена ⏩'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level is still 1, but Phase II is active
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.textContaining('Фаза II'),
      ),
      findsOneWidget,
    );

    // Use 2nd scroll skip on phase 2
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Фаза 2 пропущена ⏩'), findsOneWidget);
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Still level 1, now Phase III
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SwipeCard),
        matching: find.textContaining('Фаза III'),
      ),
      findsOneWidget,
    );

    // Use 3rd scroll skip on phase 3
    await tester.tap(inventoryButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Применить').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Boss is fully skipped!
    expect(find.text('Босс пропущен ⏩'), findsOneWidget);
    await tester.tap(find.text('Отлично'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dungeon level should now be 2!
    expect(find.text('Уровень 2'), findsOneWidget);
  });
}

