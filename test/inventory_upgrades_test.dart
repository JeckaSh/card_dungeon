import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedTestRandom implements Random {
  _FixedTestRandom(this.nextIntValue, {this.nextDoubleValue = 0.0});
  final int nextIntValue;
  final double nextDoubleValue;

  @override
  int nextInt(int max) => nextIntValue % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => nextDoubleValue;
}

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
    coins.restoreBalance(300);

    expect(stats.startingHealth, 10);
    expect(stats.startingAttack, 5);
    expect(stats.healthLevel, 0);
    expect(stats.attackLevel, 0);
    expect(stats.healthUpgradeCost, 100);
    expect(stats.attackUpgradeCost, 120);

    // Upgrade health (costs 100)
    final upgradedHp = stats.upgradeHealth();
    expect(upgradedHp, isTrue);
    expect(stats.healthLevel, 1);
    expect(stats.startingHealth, 12);
    expect(coins.balance, 200);
    expect(stats.healthUpgradeCost, 200);

    // Upgrade attack (costs 120)
    final upgradedAtk = stats.upgradeAttack();
    expect(upgradedAtk, isTrue);
    expect(stats.attackLevel, 1);
    expect(stats.startingAttack, 6);
    expect(coins.balance, 80);
    expect(stats.attackUpgradeCost, 240);

    // Cannot upgrade attack with insufficient coins (80 < 240)
    expect(stats.upgradeAttack(), isFalse);
  });

  testWidgets('InventoryScreen shows character upgrade section and allows upgrading', (tester) async {
    PlayerCoinsService.instance.restoreBalance(200);
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

    // Tap upgrade health button (+2 ❤ · 100 🪙)
    final hpUpgradeButton = find.text('+2 ❤ · 100 🪙');
    expect(hpUpgradeButton, findsOneWidget);
    await tester.tap(hpUpgradeButton);
    await tester.pumpAndSettle();

    // Health is now 12 ❤, coins became 100
    expect(find.text('12 ❤'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
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
    coins.restoreBalance(4000);

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
    expect(stats.startingCardsUpgradeCost, 200);
    expect(stats.isStartingCardsMax, isFalse);

    // Level 1 (costs 200)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 1);
    expect(stats.startingCardsCount, 1);
    expect(coins.balance, 3800);
    expect(stats.startingCardsUpgradeCost, 400);

    // Level 2 (costs 400)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 2);
    expect(stats.startingCardsCount, 2);
    expect(coins.balance, 3400);
    expect(stats.startingCardsUpgradeCost, 600);

    // Level 3 (costs 600)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 3);
    expect(stats.startingCardsCount, 3);
    expect(coins.balance, 2800);
    expect(stats.startingCardsUpgradeCost, 800);

    // Level 4 (costs 800)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 4);
    expect(stats.startingCardsCount, 4);
    expect(coins.balance, 2000);
    expect(stats.startingCardsUpgradeCost, 1000);

    // Level 5 (costs 1000)
    expect(stats.upgradeStartingCards(), isTrue);
    expect(stats.startingCardsLevel, 5);
    expect(stats.startingCardsCount, 5);
    expect(coins.balance, 1000);
    expect(stats.isStartingCardsMax, isTrue);

    // Level 6 cannot be purchased (max level reached)
    expect(stats.upgradeStartingCards(), isFalse);
    expect(stats.startingCardsLevel, 5);
  });

  testWidgets('InventoryScreen displays locked starting cards upgrade when < 3 cards unlocked, and allows upgrade when >= 3 cards unlocked', (tester) async {
    PlayerCoinsService.instance.restoreBalance(500);

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
    expect(find.text('+1 🃏 · 200 🪙'), findsNothing);

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
    final upgradeButton = find.text('+1 🃏 · 200 🪙');
    expect(upgradeButton, findsOneWidget);

    await tester.tap(upgradeButton);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.startingCardsLevel, 1);
    expect(find.text('1 карта'), findsOneWidget);
    expect(PlayerCoinsService.instance.balance, 300);
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

  testWidgets('InventoryScreen displays Merchant Luck upgrade card and allows upgrading', (tester) async {
    PlayerCoinsService.instance.restoreBalance(300);

    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Удача торговца'), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
    final upgradeBtn = find.text('+5% ⭐ · 160 🪙');
    expect(upgradeBtn, findsOneWidget);

    await tester.ensureVisible(upgradeBtn);
    await tester.pumpAndSettle();
    await tester.tap(upgradeBtn);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.merchantCardUpgradeLevel, 1);
    expect(PlayerStatsService.instance.merchantCardUpgradeChance, 10);
    expect(find.text('10%'), findsOneWidget);
    expect(PlayerCoinsService.instance.balance, 140);
  });

  test('PlayerStatsService monster gold skill upgrades up to 5 levels (+5% per level, start 0%)', () {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;
    coins.restoreBalance(2000);

    expect(stats.monsterGoldLevel, 0);
    expect(stats.monsterGoldChance, 0);
    expect(stats.isMonsterGoldMax, isFalse);
    expect(stats.monsterGoldUpgradeCost, 140);

    // Level 1: 0% -> 5% (cost 140)
    expect(stats.upgradeMonsterGold(), isTrue);
    expect(stats.monsterGoldLevel, 1);
    expect(stats.monsterGoldChance, 5);
    expect(stats.monsterGoldUpgradeCost, 240);
    expect(coins.balance, 1860);

    // Level 2: 5% -> 10% (cost 240)
    expect(stats.upgradeMonsterGold(), isTrue);
    expect(stats.monsterGoldLevel, 2);
    expect(stats.monsterGoldChance, 10);
    expect(stats.monsterGoldUpgradeCost, 340);
    expect(coins.balance, 1620);

    // Level 3: 10% -> 15% (cost 340)
    expect(stats.upgradeMonsterGold(), isTrue);
    expect(stats.monsterGoldLevel, 3);
    expect(stats.monsterGoldChance, 15);
    expect(stats.monsterGoldUpgradeCost, 440);
    expect(coins.balance, 1280);

    // Level 4: 15% -> 20% (cost 440)
    expect(stats.upgradeMonsterGold(), isTrue);
    expect(stats.monsterGoldLevel, 4);
    expect(stats.monsterGoldChance, 20);
    expect(stats.monsterGoldUpgradeCost, 540);
    expect(coins.balance, 840);

    // Level 5: 20% -> 25% (cost 540) - Max level reached
    expect(stats.upgradeMonsterGold(), isTrue);
    expect(stats.monsterGoldLevel, 5);
    expect(stats.monsterGoldChance, 25);
    expect(stats.isMonsterGoldMax, isTrue);
    expect(coins.balance, 300);

    // Cannot upgrade beyond max
    expect(stats.upgradeMonsterGold(), isFalse);
    expect(stats.monsterGoldLevel, 5);
    expect(stats.monsterGoldChance, 25);
  });

  testWidgets('InventoryScreen displays Monster Gold upgrade card and allows upgrading', (tester) async {
    PlayerCoinsService.instance.restoreBalance(300);

    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Трофеи с монстров'), findsOneWidget);
    // Monster Gold, Dodge, and Resistance all start at 0%
    expect(find.text('0%'), findsNWidgets(3));
    final upgradeBtn = find.text('+5% 🪙 · 140 🪙');
    expect(upgradeBtn, findsOneWidget);

    await tester.ensureVisible(upgradeBtn);
    await tester.pumpAndSettle();
    await tester.tap(upgradeBtn);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.monsterGoldLevel, 1);
    expect(PlayerStatsService.instance.monsterGoldChance, 5);
    // Merchant luck is 5% and Monster bounty is now 5% (2 widgets)
    expect(find.text('5%'), findsNWidgets(2));
    expect(PlayerCoinsService.instance.balance, 160);
  });

  testWidgets('GameScreen gives bonus gold when defeating monster with monster gold skill active', (tester) async {
    PlayerStatsService.instance.setLevelsForTest(monsterGold: 5);
    final mockRandom = _FixedTestRandom(0);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          random: mockRandom,
          initialCoins: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    const monsterCard = EventCard(
      id: 'test_goblin',
      type: EventType.monster,
      title: 'Гоблин',
      description: 'Тестовый гоблин',
      leftChoice: CardChoice(label: 'Сражаться', healthDelta: -2),
      rightChoice: CardChoice(label: 'Обойти', healthDelta: 0),
      level: 1,
    );
    state.setCurrentCardForTesting(monsterCard);
    await tester.pump();

    expect(state.coinsForTesting, 0);

    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // Got +5 coins from monster bounty (minimum of 5..20 range when random is 0)
    expect(state.coinsForTesting, 5);
  });

  testWidgets('GameScreen awards up to 20 bonus gold when random rolls maximum in 5..20 range', (tester) async {
    PlayerStatsService.instance.setLevelsForTest(monsterGold: 5);
    // 15 % 100 = 15 (< 25 -> proc), 15 % 16 = 15 -> dropGold = 5 + 15 = 20
    final mockRandom = _FixedTestRandom(15);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          random: mockRandom,
          initialCoins: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    const monsterCard = EventCard(
      id: 'test_goblin',
      type: EventType.monster,
      title: 'Гоблин',
      description: 'Тестовый гоблин',
      leftChoice: CardChoice(label: 'Сражаться', healthDelta: -2),
      rightChoice: CardChoice(label: 'Обойти', healthDelta: 0),
      level: 1,
    );
    state.setCurrentCardForTesting(monsterCard);
    await tester.pump();

    expect(state.coinsForTesting, 0);

    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // Got +20 coins from monster bounty (maximum of 5..20 range)
    expect(state.coinsForTesting, 20);
  });

  testWidgets('GameScreen does not give bonus gold when monster gold skill level is 0', (tester) async {
    PlayerStatsService.instance.setLevelsForTest(monsterGold: 0);
    final mockRandom = _FixedTestRandom(0);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          random: mockRandom,
          initialCoins: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    const monsterCard = EventCard(
      id: 'test_goblin',
      type: EventType.monster,
      title: 'Гоблин',
      description: 'Тестовый гоблин',
      leftChoice: CardChoice(label: 'Сражаться', healthDelta: -2),
      rightChoice: CardChoice(label: 'Обойти', healthDelta: 0),
      level: 1,
    );
    state.setCurrentCardForTesting(monsterCard);
    await tester.pump();

    expect(state.coinsForTesting, 0);

    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // 0 bonus coins
    expect(state.coinsForTesting, 0);
  });

  test('PlayerStatsService dodge skill upgrades up to 10 levels (+2% per level, start 0%)', () {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;
    coins.restoreBalance(10000);

    expect(stats.dodgeLevel, 0);
    expect(stats.dodgeChance, 0);
    expect(stats.isDodgeMax, isFalse);
    expect(stats.dodgeUpgradeCost, 160);

    // Level 1: 0% -> 2% (cost 160)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 1);
    expect(stats.dodgeChance, 2);
    expect(stats.dodgeUpgradeCost, 260);
    expect(coins.balance, 9840);

    // Level 2: 2% -> 4% (cost 260)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 2);
    expect(stats.dodgeChance, 4);
    expect(stats.dodgeUpgradeCost, 360);
    expect(coins.balance, 9580);

    // Level 3: 4% -> 6% (cost 360)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 3);
    expect(stats.dodgeChance, 6);
    expect(stats.dodgeUpgradeCost, 460);
    expect(coins.balance, 9220);

    // Level 4: 6% -> 8% (cost 460)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 4);
    expect(stats.dodgeChance, 8);
    expect(stats.dodgeUpgradeCost, 560);
    expect(coins.balance, 8760);

    // Level 5: 8% -> 10% (cost 560)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 5);
    expect(stats.dodgeChance, 10);
    expect(stats.dodgeUpgradeCost, 660);
    expect(coins.balance, 8200);

    // Level 6: 10% -> 12% (cost 660)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 6);
    expect(stats.dodgeChance, 12);
    expect(stats.dodgeUpgradeCost, 760);
    expect(coins.balance, 7540);

    // Level 7: 12% -> 14% (cost 760)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 7);
    expect(stats.dodgeChance, 14);
    expect(stats.dodgeUpgradeCost, 860);
    expect(coins.balance, 6780);

    // Level 8: 14% -> 16% (cost 860)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 8);
    expect(stats.dodgeChance, 16);
    expect(stats.dodgeUpgradeCost, 960);
    expect(coins.balance, 5920);

    // Level 9: 16% -> 18% (cost 960)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 9);
    expect(stats.dodgeChance, 18);
    expect(stats.dodgeUpgradeCost, 1060);
    expect(coins.balance, 4960);

    // Level 10: 18% -> 20% (cost 1060, max)
    expect(stats.upgradeDodge(), isTrue);
    expect(stats.dodgeLevel, 10);
    expect(stats.dodgeChance, 20);
    expect(stats.isDodgeMax, isTrue);
    expect(coins.balance, 3900);

    // Cannot upgrade beyond max
    expect(stats.upgradeDodge(), isFalse);
  });

  test('PlayerStatsService resistance skill upgrades up to 5 levels (+5% per level, start 0%)', () {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;
    coins.restoreBalance(3000);

    expect(stats.resistanceLevel, 0);
    expect(stats.resistanceChance, 0);
    expect(stats.isResistanceMax, isFalse);
    expect(stats.resistanceUpgradeCost, 160);

    // Level 1: 0% -> 5% (cost 160)
    expect(stats.upgradeResistance(), isTrue);
    expect(stats.resistanceLevel, 1);
    expect(stats.resistanceChance, 5);
    expect(stats.resistanceUpgradeCost, 260);
    expect(coins.balance, 2840);

    // Level 2: 5% -> 10% (cost 260)
    expect(stats.upgradeResistance(), isTrue);
    expect(stats.resistanceLevel, 2);
    expect(stats.resistanceChance, 10);
    expect(stats.resistanceUpgradeCost, 360);
    expect(coins.balance, 2580);

    // Level 3: 10% -> 15% (cost 360)
    expect(stats.upgradeResistance(), isTrue);
    expect(stats.resistanceLevel, 3);
    expect(stats.resistanceChance, 15);
    expect(stats.resistanceUpgradeCost, 460);
    expect(coins.balance, 2220);

    // Level 4: 15% -> 20% (cost 460)
    expect(stats.upgradeResistance(), isTrue);
    expect(stats.resistanceLevel, 4);
    expect(stats.resistanceChance, 20);
    expect(stats.resistanceUpgradeCost, 560);
    expect(coins.balance, 1760);

    // Level 5: 20% -> 25% (cost 560, max)
    expect(stats.upgradeResistance(), isTrue);
    expect(stats.resistanceLevel, 5);
    expect(stats.resistanceChance, 25);
    expect(stats.isResistanceMax, isTrue);
    expect(coins.balance, 1200);

    // Cannot upgrade beyond max
    expect(stats.upgradeResistance(), isFalse);
  });

  testWidgets('InventoryScreen displays Dodge and Resistance upgrade cards and allows upgrading', (tester) async {
    PlayerCoinsService.instance.restoreBalance(500);

    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Уклонение'), findsOneWidget);
    expect(find.text('Сопротивление'), findsOneWidget);

    final dodgeUpgradeBtn = find.text('+2% 💨 · 160 🪙');
    expect(dodgeUpgradeBtn, findsOneWidget);
    await tester.ensureVisible(dodgeUpgradeBtn);
    await tester.pumpAndSettle();
    await tester.tap(dodgeUpgradeBtn);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.dodgeLevel, 1);
    expect(PlayerStatsService.instance.dodgeChance, 2);
    expect(find.text('2%'), findsOneWidget);

    final resUpgradeBtn = find.text('+5% 🛡️ · 160 🪙');
    expect(resUpgradeBtn, findsOneWidget);
    await tester.ensureVisible(resUpgradeBtn);
    await tester.pumpAndSettle();
    await tester.tap(resUpgradeBtn);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.resistanceLevel, 1);
    expect(PlayerStatsService.instance.resistanceChance, 5);
  });

  testWidgets('GameScreen dodge avoids losing health and attack on card swipe', (tester) async {
    // 5 levels -> 10% chance
    PlayerStatsService.instance.setLevelsForTest(dodge: 5);
    final mockRandom = _FixedTestRandom(0); // 0 < 10 -> dodge procs!

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          random: mockRandom,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialHp = state.healthForTesting;
    final initialAtk = state.attackForTesting;

    // Card with negative health and attack
    const trapCard = EventCard(
      id: 'test_trap',
      type: EventType.trap,
      title: 'Опасность',
      description: 'Ловушка',
      leftChoice: CardChoice(label: 'Пройти', healthDelta: -3, attackDelta: -2),
      rightChoice: CardChoice(label: 'Обойти'),
      level: 1,
    );
    state.setCurrentCardForTesting(trapCard);
    await tester.pump();

    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // Health and attack were not lost because dodge triggered
    expect(state.healthForTesting, initialHp);
    expect(state.attackForTesting, initialAtk);
  });

  testWidgets('GameScreen resistance avoids gaining poison, bleed, or blindness', (tester) async {
    // 4 levels -> 20% chance
    PlayerStatsService.instance.setLevelsForTest(resistance: 4);
    final mockRandom = _FixedTestRandom(0, nextDoubleValue: 0.1); // statusChance 1.0 > 0.1, resistance 0 < 20 -> procs!

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          random: mockRandom,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));

    const poisonCard = EventCard(
      id: 'test_poison_snake',
      type: EventType.monster,
      title: 'Гадюка',
      description: 'Ядовитая змея',
      leftChoice: CardChoice(
        label: 'Атаковать',
        statusEffect: StatusEffectType.poison,
        statusChance: 1.0,
      ),
      rightChoice: CardChoice(label: 'Бежать'),
      level: 1,
    );
    state.setCurrentCardForTesting(poisonCard);
    await tester.pump();

    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // Poison was avoided due to resistance
    expect(state.poisonTurns, 0);
  });
}
