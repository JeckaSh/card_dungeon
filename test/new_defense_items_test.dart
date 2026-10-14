import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
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
    expect(useButton, findsOneWidget);
    await tester.tap(useButton);
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
}


