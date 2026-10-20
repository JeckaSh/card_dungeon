import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/data/shop_chests.dart';
import 'package:kki_cardgame/models/item_card.dart';
import 'package:kki_cardgame/models/shop_chest.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/item_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UnlockedItemsService.instance.reset();
  });

  test('getRandomLockedItemCard only returns locked cards and returns null when full', () {
    final random = Random();
    final allIds = allItemCards.map((c) => c.id).toSet();

    // With no cards unlocked, picks from all
    final card1 = getRandomLockedItemCard(random, {});
    expect(card1, isNotNull);
    expect(allIds.contains(card1!.id), isTrue);

    // With all except last unlocked, picks the only remaining card
    final almostAll = allItemCards.take(allItemCards.length - 1).map((c) => c.id).toSet();
    final card2 = getRandomLockedItemCard(random, almostAll);
    expect(card2, isNotNull);
    expect(card2!.id, equals(allItemCards.last.id));

    // With all unlocked, returns null
    final card3 = getRandomLockedItemCard(random, allIds);
    expect(card3, isNull);
  });

  testWidgets('Tapping on an unlocked card in ShopScreen opens item details sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Unlock the first item
    await UnlockedItemsService.instance.load();
    await UnlockedItemsService.instance.unlock(allItemCards.first.id);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final firstItem = allItemCards.first;
    expect(find.text(firstItem.title), findsWidgets);

    // Tap on the first item card
    await tester.tap(find.text(firstItem.title).first);
    await tester.pumpAndSettle();

    // The details sheet should now be open
    expect(find.byType(ItemDetailsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ItemDetailsSheet),
        matching: find.text(firstItem.description),
      ),
      findsOneWidget,
    );
    expect(find.text('Открыта'), findsOneWidget);
  });

  testWidgets('Tapping on a locked card in ShopScreen does NOT open details sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find locked item widget
    final lockedFinder = find.text('В сундуке');
    expect(lockedFinder, findsWidgets);

    // Tap on the first locked card container
    await tester.tap(lockedFinder.first);
    await tester.pumpAndSettle();

    // The details sheet should NOT be opened
    expect(find.byType(ItemDetailsSheet), findsNothing);
  });

  testWidgets('Opening chest drops unknown card, increases price and deducts coins', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    PlayerCoinsService.instance.restoreBalance(200);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 3 chests: Novice (50), Adventurer (75), Hero (100)
    expect(find.textContaining('Открыть сундук (50 🪙)'), findsOneWidget);
    expect(find.textContaining('Открыть сундук (75 🪙)'), findsOneWidget);
    expect(find.textContaining('Открыть сундук (100 🪙)'), findsOneWidget);

    // Open novice chest (costs 50)
    await tester.tap(find.textContaining('Открыть сундук (50 🪙)'));
    await tester.pumpAndSettle();

    // Reward dialog should appear
    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(UnlockedItemsService.instance.count, equals(1));
    expect(PlayerCoinsService.instance.balance, equals(150));

    // The dropped card must be level 1
    final droppedCardId = UnlockedItemsService.instance.unlockedIds.first;
    final droppedCard = allItemCards.firstWhere((c) => c.id == droppedCardId);
    expect(droppedCard.level, equals(1));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Novice chest now costs 50 + 25 = 75, Adventurer chest also costs 75
    expect(find.textContaining('Открыть сундук (75 🪙)'), findsNWidgets(2));

    // Open novice chest again (first of the 75 coin chests)
    await tester.tap(find.textContaining('Открыть сундук (75 🪙)').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(UnlockedItemsService.instance.count, equals(2));
    expect(PlayerCoinsService.instance.balance, equals(75));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Novice chest now costs 100, but player has 75 -> "Не хватает монет (100 🪙)"
    expect(find.textContaining('Не хватает монет (100 🪙)'), findsWidgets);
  });

  testWidgets('Chest is blocked and shows message when all cards are unlocked', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Unlock all cards
    await UnlockedItemsService.instance.load();
    await UnlockedItemsService.instance.unlockAll(allItemCards.map((c) => c.id).toList());
    PlayerCoinsService.instance.restoreBalance(1000);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Should display that all cards are collected (for all 3 chests)
    expect(find.text('Все карты получены'), findsNWidgets(3));
    expect(find.textContaining('Все предметы новичка собраны!'), findsOneWidget);
    expect(find.textContaining('Все предметы приключенца собраны!'), findsOneWidget);
    expect(find.textContaining('Все предметы героя собраны!'), findsOneWidget);

    // All buttons must be disabled
    final buttons = tester.widgetList<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Все карты получены'),
    );
    for (final button in buttons) {
      expect(button.onPressed, isNull);
    }
  });

  group('ShopChest model & thematic chests tests', () {
    test('Default shop chests pool filters match card levels', () {
      final noviceChest = defaultShopChests.firstWhere((c) => c.id == 'novice_chest');
      final adventurerChest = defaultShopChests.firstWhere((c) => c.id == 'adventurer_chest');
      final heroChest = defaultShopChests.firstWhere((c) => c.id == 'hero_chest');

      final novicePool = noviceChest.getPool();
      final adventurerPool = adventurerChest.getPool();
      final heroPool = heroChest.getPool();

      expect(novicePool.isNotEmpty, isTrue);
      expect(novicePool.every((i) => i.level == 1), isTrue);

      expect(adventurerPool.isNotEmpty, isTrue);
      expect(adventurerPool.every((i) => i.level == 2), isTrue);

      expect(heroPool.isNotEmpty, isTrue);
      expect(heroPool.every((i) => i.level == 3), isTrue);

      // Check total unique cards match all items
      final combined = {...novicePool, ...adventurerPool, ...heroPool};
      expect(combined.length, equals(allItemCards.length));
    });

    test('Thematic chest with mixed levels (1 and 3)', () {
      final mixedChest = ShopChest(
        id: 'mixed_1_3',
        titleBuilder: (_) => 'Смешанный',
        descriptionBuilder: (_) => 'Карты 1 и 3 уровней',
        icon: Icons.auto_awesome,
        levels: const [1, 3],
      );

      final pool = mixedChest.getPool();
      expect(pool.every((i) => i.level == 1 || i.level == 3), isTrue);
      expect(pool.any((i) => i.level == 2), isFalse);
    });

    test('Thematic chest with specific item IDs', () {
      final specificChest = ShopChest(
        id: 'specific_chest',
        titleBuilder: (_) => 'Тематический',
        descriptionBuilder: (_) => 'Только 2 конкретных предмета',
        icon: Icons.science,
        itemIds: const ['potion_heal', 'philosophers_stone'],
      );

      final pool = specificChest.getPool();
      expect(pool.length, equals(2));
      expect(pool.map((i) => i.id).toSet(), equals({'potion_heal', 'philosophers_stone'}));
    });

    test('Thematic chest combining levels and specific card ID', () {
      // Level 1 cards PLUS philosophers_stone (level 3)
      final comboChest = ShopChest(
        id: 'combo_chest',
        titleBuilder: (_) => 'Комбо',
        descriptionBuilder: (_) => 'Уровень 1 + Философский камень',
        icon: Icons.science,
        levels: const [1],
        itemIds: const ['philosophers_stone'],
      );

      final pool = comboChest.getPool();
      expect(pool.any((i) => i.id == 'philosophers_stone'), isTrue);
      for (final item in pool) {
        expect(item.level == 1 || item.id == 'philosophers_stone', isTrue);
      }
    });

    test('Thematic chest with custom predicate filter', () {
      final attackChest = ShopChest(
        id: 'attack_chest',
        titleBuilder: (_) => 'Сундук атаки',
        descriptionBuilder: (_) => 'Только предметы атаки',
        icon: Icons.flash_on,
        filter: (item) => item.effectType == ItemEffectType.attack,
      );

      final pool = attackChest.getPool();
      expect(pool.isNotEmpty, isTrue);
      expect(pool.every((i) => i.effectType == ItemEffectType.attack), isTrue);
    });

    testWidgets('Custom chest passed to ShopScreen renders and can be purchased', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PlayerCoinsService.instance.restoreBalance(150);

      final customChest = ShopChest(
        id: 'custom_thematic',
        titleBuilder: (_) => 'Тематический сундук алхимии',
        descriptionBuilder: (_) => 'Зелья и эликсиры всех уровней',
        icon: Icons.science,
        basePrice: 30,
        priceStep: 15,
        itemIds: const ['potion_heal', 'potion_regeneration', 'elixir_life'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShopScreen(chests: [customChest]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Тематический сундук алхимии'), findsWidgets);
      expect(find.textContaining('Открыть сундук (30 🪙)'), findsOneWidget);

      await tester.tap(find.textContaining('Открыть сундук (30 🪙)'));
      await tester.pumpAndSettle();

      expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
      expect(UnlockedItemsService.instance.count, equals(1));
      expect(PlayerCoinsService.instance.balance, equals(120));

      final droppedId = UnlockedItemsService.instance.unlockedIds.first;
      expect(['potion_heal', 'potion_regeneration', 'elixir_life'].contains(droppedId), isTrue);
    });
  });
}
