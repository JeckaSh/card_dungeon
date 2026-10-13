import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
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

    // Initial price with 0 unlocked cards is 50 (for both chests)
    expect(find.textContaining('Открыть сундук (50 🪙)'), findsNWidgets(2));

    // Open first chest (magic chest)
    await tester.tap(find.textContaining('Открыть сундук (50 🪙)').first);
    await tester.pumpAndSettle();

    // Reward dialog should appear
    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(UnlockedItemsService.instance.count, equals(1));
    expect(PlayerCoinsService.instance.balance, equals(150));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Price for first chest should now be 75
    expect(find.textContaining('Открыть сундук (75 🪙)'), findsOneWidget);

    // Open first chest again
    await tester.tap(find.textContaining('Открыть сундук (75 🪙)'));
    await tester.pumpAndSettle();

    expect(find.text('🎉 НОВАЯ КАРТА!'), findsOneWidget);
    expect(UnlockedItemsService.instance.count, equals(2));
    expect(PlayerCoinsService.instance.balance, equals(75));

    // Close dialog
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // Next price is 100, but player only has 75 coins left -> "Не хватает монет (100 🪙)"
    expect(find.textContaining('Не хватает монет (100 🪙)'), findsOneWidget);
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

    // Should display that all cards are collected (for both chests)
    expect(find.text('Все карты получены'), findsNWidgets(2));
    expect(find.textContaining('Все доступные карты собраны! Сундук больше недоступен.'), findsOneWidget);
    expect(find.textContaining('Все предметы героя собраны! Сундук больше недоступен.'), findsOneWidget);

    // The button must be disabled
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Все карты получены').first,
    );
    expect(button.onPressed, isNull);
  });
}

