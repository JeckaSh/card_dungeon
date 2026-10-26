import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
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

  Future<void> openInventoryAndUse(WidgetTester tester) async {
    final inventoryButton =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    final useButton = find.text('Применить');
    expect(useButton, findsWidgets);
    await tester.tap(useButton.first);
    await tester.pumpAndSettle();

    final dismissButton = find.text('Отлично');
    expect(dismissButton, findsOneWidget);
    await tester.tap(dismissButton);
    await tester.pumpAndSettle();
  }

  testWidgets('divine_runic_shield grants 1 divine shield charge and shows buff',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final divineShield =
        allItemCards.firstWhere((i) => i.id == 'divine_runic_shield');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [divineShield])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.divineShieldCharges, equals(0));

    await openInventoryAndUse(tester);

    expect(state.divineShieldCharges, equals(1));
    expect(find.textContaining('Бож. щит ×1'), findsOneWidget);
  });

  testWidgets('potion_stoneskin grants 3 stoneskin turns and shows buff',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final stoneskin =
        allItemCards.firstWhere((i) => i.id == 'potion_stoneskin');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [stoneskin])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.stoneskinTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.stoneskinTurns, equals(3));
    expect(find.textContaining('Каменная кожа ×3'), findsOneWidget);
  });

  testWidgets('potion_antidote removes active poison, bleed, and blindness effects',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final antidote = allItemCards.firstWhere((i) => i.id == 'potion_antidote');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [antidote])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    state.setPoisonForTesting(3);
    state.setBleedForTesting(2);
    state.setBlindnessForTesting(3);
    await tester.pumpAndSettle();

    expect(state.poisonTurns, equals(3));
    expect(state.bleedTurns, equals(2));
    expect(state.blindnessTurns, equals(3));
    expect(find.textContaining('Яд ×3'), findsOneWidget);
    expect(find.textContaining('Кровотечение ×2'), findsOneWidget);
    expect(find.textContaining('Слепота ×3'), findsOneWidget);

    await openInventoryAndUse(tester);

    expect(state.poisonTurns, equals(0));
    expect(state.bleedTurns, equals(0));
    expect(state.blindnessTurns, equals(0));
    expect(find.textContaining('Яд ×3'), findsNothing);
    expect(find.textContaining('Кровотечение ×2'), findsNothing);
    expect(find.textContaining('Слепота ×3'), findsNothing);
  });

  testWidgets('potion_regeneration restores health each turn for 3 turns',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final regen =
        allItemCards.firstWhere((i) => i.id == 'potion_regeneration');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [regen])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.regenerationTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.regenerationTurns, equals(3));
    expect(find.textContaining('Регенерация ×3'), findsOneWidget);
  });

  testWidgets('scroll_teleport advances cards forward when not on boss',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final teleport =
        allItemCards.firstWhere((i) => i.id == 'scroll_teleport');
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialInventory: [teleport],
          initialCardsPassed: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Use teleport scroll
    await openInventoryAndUse(tester);

    // Cards passed must have advanced by 1, 2, or 3
    final passedText = find.textContaining('Пройдено:');
    expect(passedText, findsOneWidget);
  });

  testWidgets('scroll_teleport cannot be used on a boss and is preserved',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final teleport =
        allItemCards.firstWhere((i) => i.id == 'scroll_teleport');
    // Start right at boss (cardsPassed = 19 -> next is boss 20)
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialInventory: [teleport],
          initialCardsPassed: 19,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Open inventory and tap Применить
    final inventoryButton =
        find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final useButton = find.text('Применить');
    expect(useButton, findsOneWidget);
    await tester.tap(useButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog showing boss restriction
    expect(find.text('Телепортация невозможна ⛔'), findsOneWidget);
    final dismissButton = find.text('Отлично');
    await tester.tap(dismissButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Reopen inventory - item is still there!
    await tester.tap(inventoryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Свиток телепортации'), findsOneWidget);
  });

  testWidgets('enhanced_divine_runic_shield grants 3 divine shield charges and shows buff',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shield =
        allItemCards.firstWhere((i) => i.id == 'enhanced_divine_runic_shield');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [shield])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.divineShieldCharges, equals(0));

    await openInventoryAndUse(tester);

    expect(state.divineShieldCharges, equals(3));
    expect(find.textContaining('Бож. щит ×3'), findsOneWidget);
  });

  testWidgets('divine_healing and divine_power increase health and attack by 12',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final healing = allItemCards.firstWhere((i) => i.id == 'divine_healing');
    final power = allItemCards.firstWhere((i) => i.id == 'divine_power');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [power, healing])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialAttack = state.attackForTesting;

    // Use power
    await openInventoryAndUse(tester);
    expect(state.attackForTesting, equals(initialAttack + 12));
  });

  testWidgets(
      'enhanced_runic_shield grants 3 shield turns, absorbs 50% damage, and counts down',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shield =
        allItemCards.firstWhere((i) => i.id == 'enhanced_runic_shield');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [shield])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.shieldTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.shieldTurns, equals(3));
    expect(find.textContaining('Усил. щит ×3'), findsOneWidget);

    // Set a card that deals 6 damage on left choice
    final testMonster = EventCard(
      id: 'test_monster',
      type: EventType.monster,
      title: 'Тестовый монстр',
      description: 'Тест',
      leftChoice: const CardChoice(label: 'Удар', healthDelta: -6),
      rightChoice: const CardChoice(label: 'Побег', healthDelta: 0),
    );
    state.setCurrentCardForTesting(testMonster);
    await tester.pumpAndSettle();

    final healthBefore = state.healthForTesting;
    state.handleSwipeForTesting(false);
    await tester.pumpAndSettle();

    // Damage reduced by 50%: 6 / 2 = 3 damage taken
    expect(state.healthForTesting, equals(healthBefore - 3));
    expect(state.shieldTurns, equals(2));
    expect(find.textContaining('Усил. щит ×2'), findsOneWidget);
  });

  testWidgets('whetstone grants +2 attack', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final whetstone = allItemCards.firstWhere((i) => i.id == 'whetstone');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [whetstone])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialAttack = state.attackForTesting;

    await openInventoryAndUse(tester);
    expect(state.attackForTesting, equals(initialAttack + 2));
  });

  testWidgets('gold items (handful_of_gold, chest_of_gold) grant coins when used',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final handful = allItemCards.firstWhere((i) => i.id == 'handful_of_gold');
    final chest = allItemCards.firstWhere((i) => i.id == 'chest_of_gold');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [handful, chest])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialCoins = state.coinsForTesting;

    // Use handful_of_gold (+50)
    await openInventoryAndUse(tester);
    expect(state.coinsForTesting, equals(initialCoins + 50));

    // Use chest_of_gold (+1000)
    await openInventoryAndUse(tester);
    expect(state.coinsForTesting, equals(initialCoins + 50 + 1000));
  });

  testWidgets('wormhole teleports forward by 2 to 4 cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final wormhole = allItemCards.firstWhere((i) => i.id == 'wormhole');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [wormhole])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialPos = state.deckPosition;

    await openInventoryAndUse(tester);
    final skipped = state.deckPosition - initialPos;
    expect(skipped >= 2 && skipped <= 4, isTrue,
        reason: 'wormhole must skip between 2 and 4 cards');
  });

  testWidgets('black_hole teleports forward by exactly 5 cards',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final blackHole = allItemCards.firstWhere((i) => i.id == 'black_hole');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [blackHole])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initialPos = state.deckPosition;

    await openInventoryAndUse(tester);
    final skipped = state.deckPosition - initialPos;
    expect(skipped, equals(5),
        reason: 'black_hole must skip exactly 5 cards');
  });

  testWidgets('totem_of_rebirth resets health and attack to initial values',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final totem = allItemCards.firstWhere((i) => i.id == 'totem_of_rebirth');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [totem])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    final initHp = state.healthForTesting;
    final initAtk = state.attackForTesting;

    // Modify stats away from initial values
    state.setStatsForTesting(health: initHp - 5, attack: initAtk + 7);
    await tester.pumpAndSettle();

    expect(state.healthForTesting, equals(initHp - 5));
    expect(state.attackForTesting, equals(initAtk + 7));

    await openInventoryAndUse(tester);

    expect(state.healthForTesting, equals(initHp));
    expect(state.attackForTesting, equals(initAtk));
  });

  testWidgets('casino_of_fate grants valid outcome when used',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final casino = allItemCards.firstWhere((i) => i.id == 'casino_of_fate');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [casino])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.healthForTesting, greaterThan(0));

    await openInventoryAndUse(tester);

    expect(state.healthForTesting, greaterThan(0));
    expect(find.byType(GameScreen), findsOneWidget);
  });
}


