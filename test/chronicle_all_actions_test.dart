import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/run_chronicle_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
    await RunChronicleService.instance.clear();
  });

  testWidgets('Every swipe action and item usage is recorded into the run chronicle', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Provide initial item in inventory
    final testPotion = allItemCards.first; // Зелье лечения

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialInventory: [testPotion],
          initialCoins: 20,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. First swipe action on a card
    final swipeCardFinder = find.byType(SwipeCard);
    expect(swipeCardFinder, findsOneWidget);

    // Swipe right
    await tester.drag(swipeCardFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // 2. Open inventory and use potion
    final inventoryBtn = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    expect(inventoryBtn, findsOneWidget);
    await tester.tap(inventoryBtn);
    await tester.pumpAndSettle();

    // Tap 'Применить' on potion
    final applyBtn = find.text('Применить');
    expect(applyBtn, findsOneWidget);
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();

    // Close ItemUsedDialog with 'Отлично'
    final closeBtn = find.text('Отлично');
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // 3. Second swipe action on another card
    expect(find.byType(SwipeCard), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // 4. Surrender to end the run and verify chronicle saving
    final surrenderBtn = find.text('Сдаться');
    expect(surrenderBtn, findsOneWidget);
    await tester.tap(surrenderBtn);
    await tester.pumpAndSettle();

    final confirmSurrender = find.text('Сдаться и выйти');
    expect(confirmSurrender, findsOneWidget);
    await tester.tap(confirmSurrender);
    await tester.pumpAndSettle();

    // Verify chronicle records
    final records = RunChronicleService.instance.records;
    expect(records, isNotEmpty);
    final lastRun = records.first;

    // Must contain dungeon entrance
    expect(lastRun.journal.any((line) => line.contains('Герой вошёл в подземелье')), isTrue);
    // Must contain item use
    expect(lastRun.journal.any((line) => line.contains('Зелье лечения')), isTrue);
    // Must contain surrender
    expect(lastRun.journal.any((line) => line.contains('Герой сдался и покинул подземелье')), isTrue);
    // Total journal entries should include every action taken (at least 4 entries)
    expect(lastRun.journal.length, greaterThanOrEqualTo(4));
  });
}
