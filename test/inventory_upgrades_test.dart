import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
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

  test('PlayerStatsService upgrades health and attack and deducts coins', () {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;

    expect(stats.startingHealth, 10);
    expect(stats.startingAttack, 5);
    expect(stats.healthLevel, 0);
    expect(stats.attackLevel, 0);
    expect(stats.healthUpgradeCost, 25);
    expect(stats.attackUpgradeCost, 30);

    // Upgrade health (costs 25)
    final upgradedHp = stats.upgradeHealth();
    expect(upgradedHp, isTrue);
    expect(stats.healthLevel, 1);
    expect(stats.startingHealth, 12);
    expect(coins.balance, 75);
    expect(stats.healthUpgradeCost, 50);

    // Upgrade attack (costs 30)
    final upgradedAtk = stats.upgradeAttack();
    expect(upgradedAtk, isTrue);
    expect(stats.attackLevel, 1);
    expect(stats.startingAttack, 6);
    expect(coins.balance, 45);
    expect(stats.attackUpgradeCost, 60);

    // Cannot upgrade attack with insufficient coins (45 < 60)
    expect(stats.upgradeAttack(), isFalse);
  });

  testWidgets('InventoryScreen shows character upgrade section and allows upgrading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sections exist
    expect(find.text('Монеты'), findsOneWidget);
    expect(find.text('Прокачка персонажа'), findsOneWidget);
    expect(find.text('Открытые карты предметов'), findsOneWidget);

    // Verify stat cards
    expect(find.text('Здоровье'), findsOneWidget);
    expect(find.text('10 ❤'), findsOneWidget);
    expect(find.text('Атака'), findsOneWidget);
    expect(find.text('5 ⚡'), findsOneWidget);

    // Tap upgrade health button (+2 ❤ · 25 🪙)
    final hpUpgradeButton = find.text('+2 ❤ · 25 🪙');
    expect(hpUpgradeButton, findsOneWidget);
    await tester.tap(hpUpgradeButton);
    await tester.pumpAndSettle();

    // Health is now 12 ❤, coins became 75
    expect(find.text('12 ❤'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(find.text('Ур. 1'), findsOneWidget);
  });

  testWidgets('GameScreen starts with upgraded stats', (tester) async {
    PlayerCoinsService.instance.restoreBalance(500);
    // Give 2 upgrades to HP and 1 to ATK
    PlayerStatsService.instance.upgradeHealth(); // 12 HP
    PlayerStatsService.instance.upgradeHealth(); // 14 HP
    PlayerStatsService.instance.upgradeAttack(); // 6 ATK

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // StatsBar should reflect the upgraded starting stats
    expect(find.text('14'), findsOneWidget); // HP
    expect(find.text('6'), findsOneWidget);  // ATK
  });

  test('PlayerStatsService requires at least 3 unlocked cards to upgrade starting cards', () async {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;
    coins.restoreBalance(500);

    // Initially 0 cards unlocked: locked!
    expect(stats.isStartingCardsUnlocked, isFalse);
    expect(stats.upgradeStartingCards(), isFalse);

    // Unlock 2 cards: still locked!
    await UnlockedItemsService.instance.unlockAll(['potion_heal', 'potion_attack']);
    expect(stats.isStartingCardsUnlocked, isFalse);
    expect(stats.upgradeStartingCards(), isFalse);

    // Unlock 3rd card: now unlocked!
    await UnlockedItemsService.instance.unlock('scroll_skip');
    expect(stats.isStartingCardsUnlocked, isTrue);

    expect(stats.startingCardsLevel, 0);
    expect(stats.startingCardsCount, 0);
    expect(stats.startingCardsUpgradeCost, 50);
    expect(stats.isStartingCardsMax, isFalse);

    // Level 1 (costs 50)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 1);
    expect(stats.startingCardsCount, 1);
    expect(coins.balance, 450);
    expect(stats.startingCardsUpgradeCost, 100);

    // Level 2 (costs 100)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 2);
    expect(stats.startingCardsCount, 2);
    expect(coins.balance, 350);
    expect(stats.startingCardsUpgradeCost, 150);

    // Level 3 (costs 150)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 3);
    expect(stats.startingCardsCount, 3);
    expect(coins.balance, 200);
    expect(stats.isStartingCardsMax, isTrue);

    // Level 4 cannot be purchased (max level reached)
    expect(stats.upgradeStartingCards(), isFalse);
    expect(stats.startingCardsLevel, 3);
  });

  testWidgets('InventoryScreen displays locked starting cards upgrade when < 3 cards unlocked, and allows upgrade when >= 3 cards unlocked', (tester) async {
    PlayerCoinsService.instance.restoreBalance(200);

    // With 0 unlocked cards: locked
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Стартовые карты'), findsOneWidget);
    expect(find.text('закрыто'), findsOneWidget);
    expect(find.text('Нужно 3 карты (0/3)'), findsOneWidget);
    expect(find.text('+1 🃏 · 50 🪙'), findsNothing);

    // Now unlock 3 cards
    await UnlockedItemsService.instance.unlockAll(['potion_heal', 'potion_attack', 'scroll_skip']);

    // Rebuild screen
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Now unlocked!
    expect(find.text('0 карт'), findsOneWidget);
    final upgradeButton = find.text('+1 🃏 · 50 🪙');
    expect(upgradeButton, findsOneWidget);

    await tester.tap(upgradeButton);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.startingCardsLevel, 1);
    expect(find.text('1 карта'), findsOneWidget);
    expect(PlayerCoinsService.instance.balance, 150);
  });

  testWidgets('GameScreen excludes unopened cards at start if 0 cards are unlocked', (tester) async {
    PlayerStatsService.instance.setStartingCardsLevel(3);
    // 0 cards unlocked in UnlockedItemsService
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Open inventory
    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    expect(inventoryButton, findsOneWidget);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    // No cards should be in inventory because none are unlocked!
    expect(find.text('Применить'), findsNothing);
  });

  testWidgets('GameScreen starts with 1 random unlocked card on level 1', (tester) async {
    await UnlockedItemsService.instance.unlockAll(['potion_heal', 'potion_attack', 'scroll_skip']);
    PlayerStatsService.instance.setStartingCardsLevel(1);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    expect(inventoryButton, findsOneWidget);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.text('Применить'), findsOneWidget);
  });

  testWidgets('GameScreen starts with 2 random unlocked cards on level 2', (tester) async {
    await UnlockedItemsService.instance.unlockAll(['potion_heal', 'potion_attack', 'scroll_skip']);
    PlayerStatsService.instance.setStartingCardsLevel(2);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.text('Применить'), findsNWidgets(2));
  });

  testWidgets('GameScreen starts with 3 random unlocked cards on level 3', (tester) async {
    await UnlockedItemsService.instance.unlockAll(['potion_heal', 'potion_attack', 'scroll_skip']);
    PlayerStatsService.instance.setStartingCardsLevel(3);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.text('Применить'), findsNWidgets(3));
  });
}
