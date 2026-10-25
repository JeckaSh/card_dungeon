import 'dart:math';

import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item Levels & Merchant Filtering Tests', () {
    test('All items have levels between 1 and 3', () {
      final allItems = allItemCards;
      expect(allItems.length, 32);

      for (final item in allItems) {
        expect(
          item.level,
          inInclusiveRange(1, 3),
          reason: 'Item ${item.id} must have level 1..3',
        );
      }

      final lvl1 = allItems.where((i) => i.level == 1).toList();
      final lvl2 = allItems.where((i) => i.level == 2).toList();
      final lvl3 = allItems.where((i) => i.level == 3).toList();

      expect(lvl1.isNotEmpty, isTrue);
      expect(lvl2.isNotEmpty, isTrue);
      expect(lvl3.isNotEmpty, isTrue);
    });

    test('hasUnlockedItemCardsForLevel filters correctly', () {
      // Unlocked only lvl 1 items (e.g. medicinal_herbs, whetstone)
      final lvl1Unlocked = {'medicinal_herbs', 'whetstone'};

      expect(hasUnlockedItemCardsForLevel(lvl1Unlocked, 1), isTrue);
      expect(hasUnlockedItemCardsForLevel(lvl1Unlocked, 2), isFalse);
      expect(hasUnlockedItemCardsForLevel(lvl1Unlocked, 3), isFalse);
      expect(hasUnlockedItemCardsForLevel(lvl1Unlocked), isTrue);

      // Unlocked lvl 2 item (e.g. thornmail)
      final withLvl2 = {'medicinal_herbs', 'thornmail'};
      expect(hasUnlockedItemCardsForLevel(withLvl2, 2), isTrue);
      expect(hasUnlockedItemCardsForLevel(withLvl2, 3), isFalse);

      // Unlocked lvl 3 item (e.g. scroll_teleport)
      final withLvl3 = {'scroll_teleport'};
      expect(hasUnlockedItemCardsForLevel(withLvl3, 1), isFalse);
      expect(hasUnlockedItemCardsForLevel(withLvl3, 2), isFalse);
      expect(hasUnlockedItemCardsForLevel(withLvl3, 3), isTrue);
    });

    test('getRandomUnlockedItemCard filters by level strictly', () {
      final random = Random(42);
      final allUnlocked = {
        'medicinal_herbs', // lvl 1
        'whetstone', // lvl 1
        'potion_heal', // lvl 2
        'dice_of_fate', // lvl 2
        'scroll_teleport', // lvl 3
        'enhanced_runic_shield', // lvl 3
      };

      for (var i = 0; i < 20; i++) {
        final itemLvl1 = getRandomUnlockedItemCard(
          random,
          allUnlocked,
          level: 1,
        );
        expect(itemLvl1, isNotNull);
        expect(itemLvl1!.level, 1);

        final itemLvl2 = getRandomUnlockedItemCard(
          random,
          allUnlocked,
          level: 2,
        );
        expect(itemLvl2, isNotNull);
        expect(itemLvl2!.level, 2);

        final itemLvl3 = getRandomUnlockedItemCard(
          random,
          allUnlocked,
          level: 3,
        );
        expect(itemLvl3, isNotNull);
        expect(itemLvl3!.level, 3);
      }

      // If level has no unlocked items, returns null
      final itemLvl3Missing = getRandomUnlockedItemCard(
        random,
        {'medicinal_herbs', 'thornmail'},
        level: 3,
      );
      expect(itemLvl3Missing, isNull);
    });

    test('UnlockedItemsService hasUnlockedForLevel reflects stored unlocked ids', () async {
      SharedPreferences.setMockInitialValues({
        'unlocked_item_ids': ['medicinal_herbs'], // only level 1
      });

      final service = UnlockedItemsService.instance;
      await service.load();

      expect(service.hasUnlockedForLevel(1), isTrue);
      expect(service.hasUnlockedForLevel(2), isFalse);
      expect(service.hasUnlockedForLevel(3), isFalse);

      final lvl1Items = service.getUnlockedItems(1);
      expect(lvl1Items.every((i) => i.level == 1), isTrue);
      expect(lvl1Items.any((i) => i.id == 'medicinal_herbs'), isTrue);

      expect(service.getUnlockedItems(2), isEmpty);
      expect(service.getUnlockedItems(3), isEmpty);

      // Unlock a level 2 item
      await service.unlock('thornmail');
      expect(service.hasUnlockedForLevel(2), isTrue);
      expect(service.getUnlockedItems(2).map((i) => i.id), contains('thornmail'));
      expect(service.hasUnlockedForLevel(3), isFalse);
    });

    test('getRandomMerchantItemCard respects upgradeChancePercent and fallbacks', () {
      final random = Random(123);
      final unlocked = {
        'medicinal_herbs', // lvl 1
        'thornmail', // lvl 2
        'scroll_teleport', // lvl 3
      };

      // 0% chance always gives base level
      for (var i = 0; i < 15; i++) {
        final itemLvl1 = getRandomMerchantItemCard(
          random: random,
          unlockedIds: unlocked,
          baseLevel: 1,
          upgradeChancePercent: 0,
        );
        expect(itemLvl1!.level, 1);
      }

      // 100% chance upgrades level 1 -> level 2
      for (var i = 0; i < 15; i++) {
        final itemUpgraded = getRandomMerchantItemCard(
          random: random,
          unlockedIds: unlocked,
          baseLevel: 1,
          upgradeChancePercent: 100,
        );
        expect(itemUpgraded!.level, 2);
      }

      // 100% chance upgrades level 2 -> level 3
      for (var i = 0; i < 15; i++) {
        final itemUpgraded = getRandomMerchantItemCard(
          random: random,
          unlockedIds: unlocked,
          baseLevel: 2,
          upgradeChancePercent: 100,
        );
        expect(itemUpgraded!.level, 3);
      }

      // 100% chance on level 3 stays level 3 (capped)
      for (var i = 0; i < 15; i++) {
        final itemLvl3 = getRandomMerchantItemCard(
          random: random,
          unlockedIds: unlocked,
          baseLevel: 3,
          upgradeChancePercent: 100,
        );
        expect(itemLvl3!.level, 3);
      }

      // 100% chance falls back to base level if higher level has no unlocked items
      final onlyLvl1 = {'medicinal_herbs'};
      final itemFallback = getRandomMerchantItemCard(
        random: random,
        unlockedIds: onlyLvl1,
        baseLevel: 1,
        upgradeChancePercent: 100,
      );
      expect(itemFallback!.level, 1);
    });

    test('PlayerStatsService merchantCardUpgradeLevel scales from 5% to 30%', () {
      final stats = PlayerStatsService.instance;
      stats.resetForTest();

      expect(stats.merchantCardUpgradeLevel, 0);
      expect(stats.merchantCardUpgradeChance, 5);
      expect(stats.isMerchantCardUpgradeMax, isFalse);
      expect(stats.merchantCardUpgradeCost, 50);

      stats.setLevelsForTest(merchantCardUpgrade: 1);
      expect(stats.merchantCardUpgradeChance, 10);
      expect(stats.merchantCardUpgradeCost, 80);

      stats.setLevelsForTest(merchantCardUpgrade: 2);
      expect(stats.merchantCardUpgradeChance, 15);
      expect(stats.merchantCardUpgradeCost, 110);

      stats.setLevelsForTest(merchantCardUpgrade: 3);
      expect(stats.merchantCardUpgradeChance, 20);
      expect(stats.merchantCardUpgradeCost, 140);

      stats.setLevelsForTest(merchantCardUpgrade: 4);
      expect(stats.merchantCardUpgradeChance, 25);
      expect(stats.merchantCardUpgradeCost, 170);

      stats.setLevelsForTest(merchantCardUpgrade: 5);
      expect(stats.merchantCardUpgradeChance, 30);
      expect(stats.isMerchantCardUpgradeMax, isTrue);

      // Clamping beyond max
      stats.setLevelsForTest(merchantCardUpgrade: 99);
      expect(stats.merchantCardUpgradeLevel, 5);
      expect(stats.merchantCardUpgradeChance, 30);
    });
  });
}
