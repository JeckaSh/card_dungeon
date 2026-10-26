import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/events.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
  });

  group('New Treasure Cards (Levels 1, 2, 3) Configuration', () {
    test('Cards exist in allEvents with correct levels, types, and choices', () {
      final lvl1 = allEvents.firstWhere((e) => e.id == 'treasure_scout_cache');
      final lvl2 = allEvents.firstWhere((e) => e.id == 'treasure_mage_cache');
      final lvl3 = allEvents.firstWhere((e) => e.id == 'treasure_royal_vault');

      expect(lvl1.type, equals(EventType.treasure));
      expect(lvl1.level, equals(1));
      expect(lvl1.leftChoice.givesRandomItem, isTrue);
      expect(lvl1.leftChoice.randomItemsCount, equals(1));
      expect(lvl1.rightChoice.coinsDelta, greaterThan(0));

      expect(lvl2.type, equals(EventType.treasure));
      expect(lvl2.level, equals(2));
      expect(lvl2.leftChoice.givesRandomItem, isTrue);
      expect(lvl2.leftChoice.randomItemsCount, equals(1));
      expect(lvl2.rightChoice.coinsDelta, greaterThan(0));

      expect(lvl3.type, equals(EventType.treasure));
      expect(lvl3.level, equals(3));
      expect(lvl3.leftChoice.givesRandomItem, isTrue);
      expect(lvl3.leftChoice.randomItemsCount, equals(2));
      expect(lvl3.rightChoice.coinsDelta, greaterThan(0));
    });

    testWidgets('SwipeCard displays correct item count hints for 1 and 2 cards', (tester) async {
      final lvl1 = allEvents.firstWhere((e) => e.id == 'treasure_scout_cache');
      final lvl2 = allEvents.firstWhere((e) => e.id == 'treasure_mage_cache');
      final lvl3 = allEvents.firstWhere((e) => e.id == 'treasure_royal_vault');

      // Test level 1 card displays +1 карта
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              event: lvl1,
              currentCoins: 10,
              currentAttack: 5,
              isRevealingChoices: true,
              onSwipe: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('🎒 +1 карта'), findsOneWidget);

      // Test level 2 card displays +1 карта
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              event: lvl2,
              currentCoins: 10,
              currentAttack: 5,
              isRevealingChoices: true,
              onSwipe: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('🎒 +1 карта'), findsOneWidget);

      // Test level 3 card displays +2 карты
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              event: lvl3,
              currentCoins: 10,
              currentAttack: 5,
              isRevealingChoices: true,
              onSwipe: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('🎒 +2 карты'), findsOneWidget);
    });

    testWidgets('Swiping left on treasure cards grants cards to inventory', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Unlock at least 1 item per level
      await UnlockedItemsService.instance.unlock('medicinal_herbs'); // lvl 1
      await UnlockedItemsService.instance.unlock('potion_heal'); // lvl 2
      await UnlockedItemsService.instance.unlock('divine_runic_shield'); // lvl 3

      // Level 3 treasure card: swipe left grants 2 items
      final lvl3 = allEvents.firstWhere((e) => e.id == 'treasure_royal_vault');
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            customDeck: [lvl3],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left
      final swipeCard = find.byType(SwipeCard);
      await tester.drag(swipeCard, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Open inventory and verify 2 items received
      final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
      expect(inventoryButton, findsOneWidget);
      expect(find.textContaining('(2)'), findsOneWidget);

      await tester.tap(inventoryButton);
      await tester.pumpAndSettle();
      expect(find.text('Инвентарь забега'), findsOneWidget);
    });

    testWidgets('Swiping right on treasure cards grants coins', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final lvl3 = allEvents.firstWhere((e) => e.id == 'treasure_royal_vault');
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            customDeck: [lvl3],
            initialCoins: 50,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50'), findsOneWidget);

      // Swipe right to take royal treasury (+90 coins)
      final swipeCard = find.byType(SwipeCard);
      await tester.drag(swipeCard, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Coins: 50 + 90 = 140
      expect(find.text('140'), findsOneWidget);
    });
  });
}
