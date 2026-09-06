import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
  });

  test('PlayerStatsService upgrades health and attack and deducts coins', () {
    final stats = PlayerStatsService.instance;
    final coins = PlayerCoinsService.instance;

    expect(stats.startingHealth, 10);
    expect(stats.startingAttack, 3);
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
    expect(stats.startingAttack, 4);
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
    expect(find.text('3 ⚡'), findsOneWidget);

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
    PlayerStatsService.instance.upgradeAttack(); // 4 ATK

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // StatsBar should reflect the upgraded starting stats
    expect(find.text('14'), findsOneWidget); // HP
    expect(find.text('4'), findsOneWidget);  // ATK
  });
}
