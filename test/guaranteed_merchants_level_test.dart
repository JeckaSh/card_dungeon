import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
  });

  testWidgets(
      'Guaranteed merchants on level 2 only spawn level 2 merchant cards',
      (tester) async {
    // 2 guaranteed merchants per level
    PlayerStatsService.instance.setMerchantLevel(2);
    expect(PlayerStatsService.instance.guaranteedMerchants, 2);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gameState = tester.state<GameScreenState>(find.byType(GameScreen));
    final deck = gameState.deck;

    // All cards in level 2 deck must be level 2
    for (final card in deck) {
      expect(card.level, equals(2),
          reason: 'Card "${card.title}" has level ${card.level}, expected 2');
    }

    // Check visible cards before boss (first 19 cards)
    final visibleCards = deck.take(19).toList();
    final merchantsBeforeBoss =
        visibleCards.where((c) => c.type == EventType.merchant).toList();

    // Exactly 2 guaranteed merchants
    expect(merchantsBeforeBoss.length, equals(2));

    for (final merchant in merchantsBeforeBoss) {
      expect(merchant.level, equals(2),
          reason: 'Merchant "${merchant.title}" must be level 2');
      expect(merchant.id, isNot(equals('merchant')),
          reason: 'Level 1 merchant should not appear on level 2');
      expect(merchant.id, isNot(equals('item_merchant')),
          reason: 'Level 1 item_merchant should not appear on level 2');
    }
  });

  testWidgets(
      'Guaranteed merchants on level 3 only spawn level 3 merchant cards',
      (tester) async {
    // 2 guaranteed merchants per level
    PlayerStatsService.instance.setMerchantLevel(2);
    expect(PlayerStatsService.instance.guaranteedMerchants, 2);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 3,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gameState = tester.state<GameScreenState>(find.byType(GameScreen));
    final deck = gameState.deck;

    // All cards in level 3 deck must be level 3
    for (final card in deck) {
      expect(card.level, equals(3),
          reason: 'Card "${card.title}" has level ${card.level}, expected 3');
    }

    final visibleCards = deck.take(19).toList();
    final merchantsBeforeBoss =
        visibleCards.where((c) => c.type == EventType.merchant).toList();

    // Exactly 2 guaranteed merchants
    expect(merchantsBeforeBoss.length, equals(2));

    for (final merchant in merchantsBeforeBoss) {
      expect(merchant.level, equals(3),
          reason: 'Merchant "${merchant.title}" must be level 3');
      expect(merchant.id, isNot(equals('merchant')),
          reason: 'Level 1 merchant should not appear on level 3');
      expect(merchant.id, isNot(equals('item_merchant')),
          reason: 'Level 1 item_merchant should not appear on level 3');
      expect(merchant.id, isNot(equals('black_market')),
          reason: 'Level 2 black_market should not appear on level 3');
      expect(merchant.id, isNot(equals('dungeon_smuggler')),
          reason: 'Level 2 dungeon_smuggler should not appear on level 3');
    }
  });
}
