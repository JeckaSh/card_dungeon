import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/discovered_events.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DiscoveredEventsService.instance.resetAll();
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(0);
    await UnlockedItemsService.instance.reset();
  });

  test('CardChoice preserves statusEffect and statusChance', () {
    const choice = CardChoice(
      label: 'Тест',
      healthDelta: -2,
      statusEffect: StatusEffectType.poison,
      statusChance: 0.3,
    );
    expect(choice.statusEffect, equals(StatusEffectType.poison));
    expect(choice.statusChance, equals(0.3));
  });

  testWidgets('Blindness hides delta numbers in SwipeCard choice hints', (tester) async {
    const event = EventCard(
      id: 'test_card',
      type: EventType.monster,
      title: 'Монстр для теста',
      description: 'Описание',
      leftChoice: CardChoice(label: 'Сражаться', healthDelta: -2, attackDelta: 1),
      rightChoice: CardChoice(label: 'Бежать', coinsDelta: -5),
    );

    // Render with isBlind = false
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeCard(
            event: event,
            currentCoins: 10,
            currentAttack: 5,
            isRevealingChoices: true,
            isBlind: false,
            onSwipe: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Numbers are visible
    expect(find.textContaining('❤ -2'), findsOneWidget);
    expect(find.textContaining('🪙 -5'), findsOneWidget);

    // Now render with isBlind = true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeCard(
            event: event,
            currentCoins: 10,
            currentAttack: 5,
            isRevealingChoices: true,
            isBlind: true,
            onSwipe: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Specific numbers are hidden and replaced with question marks
    expect(find.textContaining('❤ -2'), findsNothing);
    expect(find.textContaining('🪙 -5'), findsNothing);
    expect(find.textContaining('❤ ?  ⚡ ?  🪙 ?'), findsWidgets);
  });

  testWidgets('GameScreen renders without errors with status system integrated', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial game screen renders
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
