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
import 'package:kki_cardgame/widgets/item_card_widget.dart';
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
    tester.view.physicalSize = const Size(800, 3000);
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
    final itemWidget = find.byType(ItemCardWidget);
    await tester.ensureVisible(itemWidget);
    await tester.pumpAndSettle();

    // Tap on the unlocked item card
    await tester.tap(itemWidget);
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
    tester.view.physicalSize = const Size(800, 2400);
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
    tester.view.physicalSize = const Size(800, 2400);
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
    tester.view.physicalSize = const Size(800, 2400);
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

    // Should display that all cards are collected (for all 5 chests)
    expect(find.text('Все карты получены'), findsNWidgets(5));
    expect(find.textContaining('Все предметы новичка собраны!'), findsOneWidget);
    expect(find.textContaining('Все предметы приключенца собраны!'), findsOneWidget);
    expect(find.textContaining('Все предметы героя собраны!'), findsOneWidget);
    expect(find.textContaining('Все эликсиры получены!'), findsOneWidget);
    expect(find.textContaining('Все божественные реликвии получены!'), findsOneWidget);

    // All buttons must be disabled
    final buttons = tester.widgetList<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Все карты получены'),
    );
    for (final button in buttons) {
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('Silver chest requires silver keys, increases price by 2 (1, 3), and grants elixirs', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await UnlockedItemsService.instance.load();
    PlayerCoinsService.instance.setSilverKeys(0);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check silver chest is rendered with not enough keys button (initial price 1)
    expect(find.text('Серебряный сундук'), findsWidgets);
    expect(find.textContaining('Не хватает ключей (1'), findsWidgets);
    expect(find.widgetWithIcon(ElevatedButton, Icons.vpn_key_rounded), findsWidgets);

    // Give 64 silver keys (1 + 3 + 5 + 7 + 9 + 11 + 13 + 15 = 64 keys)
    PlayerCoinsService.instance.setSilverKeys(64);
    await tester.pumpAndSettle();

    // First card: price is 1 key
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (1 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (1 ').first);
    await tester.pumpAndSettle();

    // Reward dialog
    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    final dropped1 = UnlockedItemsService.instance.unlockedIds.first;
    expect(['elixir_life', 'elixir_attack', 'huge_bag_of_gold', 'wormhole', 'shadow_pact', 'powerful_regeneration_potion', 'charged_mirror_distortion', 'casino_of_fate'].contains(dropped1), isTrue);
    expect(PlayerCoinsService.instance.silverKeys, equals(63));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Second card: price increased by 2 -> now costs 3 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (3 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (3 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(60));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Third card: price increased by 2 -> now costs 5 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (5 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (5 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(55));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Fourth card: price increased by 2 -> now costs 7 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (7 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (7 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(48));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Fifth card: price increased by 2 -> now costs 9 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (9 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (9 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(39));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Sixth card: price increased by 2 -> now costs 11 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (11 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (11 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(28));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Seventh card: price increased by 2 -> now costs 13 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (13 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (13 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.silverKeys, equals(15));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Eighth card: price increased by 2 -> now costs 15 keys!
    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (15 '), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (15 ').first);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(UnlockedItemsService.instance.isUnlocked('elixir_life'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('elixir_attack'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('huge_bag_of_gold'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('wormhole'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('shadow_pact'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('powerful_regeneration_potion'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('charged_mirror_distortion'), isTrue);
    expect(UnlockedItemsService.instance.isUnlocked('casino_of_fate'), isTrue);
    expect(PlayerCoinsService.instance.silverKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Now silver chest is completed
    expect(find.textContaining('Все эликсиры получены!'), findsOneWidget);
  });

  testWidgets('Gold chest requires gold keys, increases price by 2 (1, 3, 5, 7, 9), and grants divine cards & gold & black hole', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await UnlockedItemsService.instance.load();
    PlayerCoinsService.instance.setGoldKeys(0);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check gold chest is rendered with not enough keys button (initial price 1)
    expect(find.text('Золотой сундук'), findsWidgets);

    // Give 1 gold key for first card
    PlayerCoinsService.instance.setGoldKeys(1);
    await tester.pumpAndSettle();

    // Open first card (1 key)
    final openButtons1 = find.widgetWithText(ElevatedButton, 'Открыть сундук (1 ');
    expect(openButtons1, findsWidgets);
    expect(find.widgetWithIcon(ElevatedButton, Icons.key_rounded), findsWidgets);
    await tester.tap(openButtons1.last);
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 3 keys -> not enough keys (3
    expect(find.textContaining('Не хватает ключей (3 '), findsOneWidget);

    // Give 3 gold keys for second card
    PlayerCoinsService.instance.setGoldKeys(3);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (3 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (3 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 5 keys -> not enough keys (5
    expect(find.textContaining('Не хватает ключей (5 '), findsOneWidget);

    // Give 5 gold keys for third card
    PlayerCoinsService.instance.setGoldKeys(5);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (5 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (5 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 7 keys -> not enough keys (7
    expect(find.textContaining('Не хватает ключей (7 '), findsOneWidget);

    // Give 7 gold keys for fourth card
    PlayerCoinsService.instance.setGoldKeys(7);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (7 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (7 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 9 keys -> not enough keys (9
    expect(find.textContaining('Не хватает ключей (9 '), findsOneWidget);

    // Give 9 gold keys for fifth card
    PlayerCoinsService.instance.setGoldKeys(9);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (9 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (9 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 11 keys -> not enough keys (11
    expect(find.textContaining('Не хватает ключей (11 '), findsOneWidget);

    // Give 11 gold keys for sixth card
    PlayerCoinsService.instance.setGoldKeys(11);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (11 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (11 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 13 keys -> not enough keys (13
    expect(find.textContaining('Не хватает ключей (13 '), findsOneWidget);

    // Give 13 gold keys for seventh card
    PlayerCoinsService.instance.setGoldKeys(13);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (13 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (13 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price is now 15 keys -> not enough keys (15
    expect(find.textContaining('Не хватает ключей (15 '), findsOneWidget);

    // Give 15 gold keys for eighth card
    PlayerCoinsService.instance.setGoldKeys(15);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Открыть сундук (15 '), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Открыть сундук (15 '));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(PlayerCoinsService.instance.goldKeys, equals(0));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // All gold chest cards collected
    expect(find.textContaining('Все божественные реликвии получены!'), findsOneWidget);
  });

  group('ShopChest model & thematic chests tests', () {
    test('Default shop chests pool filters match card levels and exclusions', () {
      final noviceChest = defaultShopChests.firstWhere((c) => c.id == 'novice_chest');
      final adventurerChest = defaultShopChests.firstWhere((c) => c.id == 'adventurer_chest');
      final heroChest = defaultShopChests.firstWhere((c) => c.id == 'hero_chest');
      final silverChest = defaultShopChests.firstWhere((c) => c.id == 'silver_chest');
      final goldChest = defaultShopChests.firstWhere((c) => c.id == 'gold_chest');

      final novicePool = noviceChest.getPool();
      final adventurerPool = adventurerChest.getPool();
      final heroPool = heroChest.getPool();
      final silverPool = silverChest.getPool();
      final goldPool = goldChest.getPool();

      expect(novicePool.isNotEmpty, isTrue);
      expect(novicePool.every((i) => i.level == 1), isTrue);
      expect(novicePool.length, equals(8));
      expect(
        novicePool.map((i) => i.id).toSet(),
        equals({
          'medicinal_herbs',
          'whetstone',
          'runic_shield',
          'potion_antidote',
          'scroll_skip',
          'handful_of_gold',
          'gold_bribe',
          'sweet_roll',
        }),
      );

      expect(adventurerPool.isNotEmpty, isTrue);
      expect(adventurerPool.every((i) => i.level == 2), isTrue);
      expect(adventurerPool.length, equals(9));
      expect(
        adventurerPool.map((i) => i.id).toSet(),
        equals({
          'potion_heal',
          'potion_attack',
          'potion_regeneration',
          'potion_stoneskin',
          'smoke_bomb',
          'thornmail',
          'greed_magnet',
          'dice_of_fate',
          'small_gold_pouch',
        }),
      );

      expect(heroPool.isNotEmpty, isTrue);
      expect(heroPool.every((i) => i.level == 3), isTrue);
      expect(heroPool.length, equals(7));
      expect(
        heroPool.map((i) => i.id).toSet(),
        equals({
          'enhanced_runic_shield',
          'mirror_distortion',
          'scroll_teleport',
          'philosophers_stone',
          'divine_runic_shield',
          'bag_of_gold',
          'strong_regeneration_potion',
        }),
      );
      expect(heroPool.any((i) => i.id == 'shadow_pact'), isFalse);
      expect(heroPool.any((i) => i.id == 'powerful_regeneration_potion'), isFalse);
      expect(heroPool.any((i) => i.id == 'great_regeneration_potion'), isFalse);
      expect(heroPool.any((i) => i.id == 'charged_mirror_distortion'), isFalse);
      expect(heroPool.any((i) => i.id == 'great_philosophers_stone'), isFalse);
      expect(heroPool.any((i) => i.id == 'elixir_life'), isFalse);
      expect(heroPool.any((i) => i.id == 'elixir_attack'), isFalse);
      expect(heroPool.any((i) => i.id == 'divine_healing'), isFalse);
      expect(heroPool.any((i) => i.id == 'divine_power'), isFalse);
      expect(heroPool.any((i) => i.id == 'enhanced_divine_runic_shield'), isFalse);
      expect(heroPool.any((i) => i.id == 'huge_bag_of_gold'), isFalse);
      expect(heroPool.any((i) => i.id == 'chest_of_gold'), isFalse);
      expect(heroPool.any((i) => i.id == 'wormhole'), isFalse);
      expect(heroPool.any((i) => i.id == 'black_hole'), isFalse);
      expect(heroPool.any((i) => i.id == 'casino_of_fate'), isFalse);

      expect(silverPool.length, equals(8));
      expect(
        silverPool.map((i) => i.id).toSet(),
        equals({
          'elixir_life',
          'elixir_attack',
          'huge_bag_of_gold',
          'wormhole',
          'shadow_pact',
          'powerful_regeneration_potion',
          'charged_mirror_distortion',
          'casino_of_fate',
        }),
      );
      expect(silverChest.currency, equals(ChestCurrency.silverKeys));
      expect(silverChest.basePrice, equals(1));
      expect(silverChest.priceStep, equals(2));

      expect(goldPool.length, equals(8));
      expect(
        goldPool.map((i) => i.id).toSet(),
        equals({
          'divine_healing',
          'divine_power',
          'enhanced_divine_runic_shield',
          'chest_of_gold',
          'black_hole',
          'great_regeneration_potion',
          'great_philosophers_stone',
          'totem_of_rebirth',
        }),
      );
      expect(goldChest.currency, equals(ChestCurrency.goldKeys));
      expect(goldChest.basePrice, equals(1));
      expect(goldChest.priceStep, equals(2));

      // Check total unique cards match all items
      final combined = {...novicePool, ...adventurerPool, ...heroPool, ...silverPool, ...goldPool};
      expect(combined.length, equals(allItemCards.length));
      expect(combined.length, equals(40));
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
