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

    // Dismiss ItemUsedDialog
    final dismissButton = find.text('Отлично');
    expect(dismissButton, findsOneWidget);
    await tester.tap(dismissButton);
    await tester.pumpAndSettle();
  }

  testWidgets('potion_heal and elixir_life restore health correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final potionHeal = allItemCards.firstWhere((i) => i.id == 'potion_heal');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [potionHeal])),
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    await openInventoryAndUse(tester);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('elixir_life restores +8 health correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final elixir = allItemCards.firstWhere((i) => i.id == 'elixir_life');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [elixir])),
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    await openInventoryAndUse(tester);
    expect(find.text('18'), findsOneWidget);
  });

  testWidgets('potion_attack increases attack correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final potionAttack = allItemCards.firstWhere((i) => i.id == 'potion_attack');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [potionAttack])),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    await openInventoryAndUse(tester);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('runic_shield activates shield charge', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shield = allItemCards.firstWhere((i) => i.id == 'runic_shield');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [shield])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('Щит ×1'), findsOneWidget);
  });

  testWidgets('mirror_distortion activates inversion buff', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mirror = allItemCards.firstWhere((i) => i.id == 'mirror_distortion');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [mirror])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.text('🪞 Зеркало'), findsOneWidget);
  });

  testWidgets('charged_mirror_distortion activates inversion buff for 3 turns', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mirror = allItemCards.firstWhere((i) => i.id == 'charged_mirror_distortion');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [mirror])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.text('🪞 Зеркало ×3'), findsOneWidget);
  });

  testWidgets('thornmail activates thorn buff', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final thorn = allItemCards.firstWhere((i) => i.id == 'thornmail');
    expect(thorn.description, contains('×10'));
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [thorn])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('Шипы'), findsOneWidget);
  });

  testWidgets('greed_magnet activates 2x coins buff', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final magnet = allItemCards.firstWhere((i) => i.id == 'greed_magnet');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [magnet])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('x2 монеты'), findsOneWidget);
  });

  testWidgets('shadow_pact sacrifices half health and doubles coins', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shadowPact = allItemCards.firstWhere((i) => i.id == 'shadow_pact');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [shadowPact])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    // HP was 10, halved -> 5
    expect(find.textContaining('5 ❤'), findsWidgets);
  });

  testWidgets('dice_of_fate executes and shows dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final dice = allItemCards.firstWhere((i) => i.id == 'dice_of_fate');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [dice])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
  });

  testWidgets('smoke_bomb escapes encounter', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final bomb = allItemCards.firstWhere((i) => i.id == 'smoke_bomb');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [bomb])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
  });

  testWidgets('philosophers_stone converts coins to attack and health, preserves card when < 10 coins', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final stone = allItemCards.firstWhere((i) => i.id == 'philosophers_stone');

    // Player has 0 coins (< 10)
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [stone])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);

    // Item should NOT be consumed, still in inventory!
    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.text('Применить'), findsOneWidget);
    expect(find.text('Философский камень'), findsOneWidget);
  });

  testWidgets('gold_bribe retains item when player has < 50 coins', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final bribe = allItemCards.firstWhere((i) => i.id == 'gold_bribe');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [bribe], initialCoins: 40)),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);

    // Card is retained in inventory because 40 < 50!
    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    expect(find.text('Применить'), findsOneWidget);
    expect(find.text('Золотой подкуп'), findsOneWidget);
  });

  testWidgets('gold_bribe spends 50 coins and consumes item when player has >= 50 coins', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final bribe = allItemCards.firstWhere((i) => i.id == 'gold_bribe');

    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [bribe], initialCoins: 60)),
    );
    await tester.pumpAndSettle();

    final inventoryButton = find.widgetWithIcon(OutlinedButton, Icons.backpack_outlined);
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();

    final useButton = find.text('Применить');
    expect(useButton, findsOneWidget);
    await tester.tap(useButton);
    await tester.pumpAndSettle();

    // Dialog showing success
    expect(find.textContaining('За 50 монет'), findsOneWidget);

    final dismissButton = find.text('Отлично');
    expect(dismissButton, findsOneWidget);
    await tester.tap(dismissButton);
    await tester.pumpAndSettle();

    // Item was consumed from inventory
    await tester.tap(inventoryButton);
    await tester.pumpAndSettle();
    expect(find.text('Золотой подкуп'), findsNothing);
  });

  testWidgets('philosophers_stone caps conversion at 50 coins (max 5 bundles)', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final stone = allItemCards.firstWhere((i) => i.id == 'philosophers_stone');

    // Player starts with 150 coins, initial HP 10, initial ATK 5
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [stone], initialCoins: 150)),
    );
    await tester.pumpAndSettle();

    // Stats before: 10 HP, 5 ATK, 150 Coins
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);

    await openInventoryAndUse(tester);

    // After transmutation: capped at 50 coins (5 bundles)
    // Health: 10 + 10 = 20, Attack: 5 + 5 = 10, Coins: 150 - 50 = 100
    expect(find.text('20'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('great_philosophers_stone caps conversion at 100 coins (max 10 bundles)', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final stone = allItemCards.firstWhere((i) => i.id == 'great_philosophers_stone');

    // Player starts with 150 coins, initial HP 10, initial ATK 5
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [stone], initialCoins: 150)),
    );
    await tester.pumpAndSettle();

    // Stats before: 10 HP, 5 ATK, 150 Coins
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);

    await openInventoryAndUse(tester);

    // After transmutation: capped at 100 coins (10 bundles)
    // Health: 10 + 20 = 30, Attack: 5 + 10 = 15, Coins: 150 - 100 = 50
    expect(find.text('30'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('divine_runic_shield activates divine shield charge', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final divineShield = allItemCards.firstWhere((i) => i.id == 'divine_runic_shield');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [divineShield])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('Бож. щит ×1'), findsOneWidget);
  });

  testWidgets('potion_stoneskin activates stoneskin buff', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final stoneskin = allItemCards.firstWhere((i) => i.id == 'potion_stoneskin');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [stoneskin])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('Каменная кожа ×3'), findsOneWidget);
  });

  testWidgets('potion_antidote can be used from inventory', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final antidote = allItemCards.firstWhere((i) => i.id == 'potion_antidote');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [antidote])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
  });

  testWidgets('potion_regeneration activates regen buff', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final regen = allItemCards.firstWhere((i) => i.id == 'potion_regeneration');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [regen])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
    expect(find.textContaining('Регенерация ×3'), findsOneWidget);
  });

  testWidgets('scroll_teleport can be used from inventory on non-boss card', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final teleport = allItemCards.firstWhere((i) => i.id == 'scroll_teleport');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [teleport])),
    );
    await tester.pumpAndSettle();

    await openInventoryAndUse(tester);
  });

  testWidgets('sweet_roll heals +3 health', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final roll = allItemCards.firstWhere((i) => i.id == 'sweet_roll');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [roll])),
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    await openInventoryAndUse(tester);
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('strong_regeneration_potion activates 3 turns of +3 HP regen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final strongRegen = allItemCards.firstWhere((i) => i.id == 'strong_regeneration_potion');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [strongRegen])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.regenerationTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.regenerationTurns, equals(3));
    expect(state.regenerationHpPerTurn, equals(3));
    expect(find.textContaining('Регенерация ×3 (+3❤)'), findsOneWidget);
  });

  testWidgets('powerful_regeneration_potion activates 5 turns of +3 HP regen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final powerfulRegen = allItemCards.firstWhere((i) => i.id == 'powerful_regeneration_potion');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [powerfulRegen])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.regenerationTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.regenerationTurns, equals(5));
    expect(state.regenerationHpPerTurn, equals(3));
    expect(find.textContaining('Регенерация ×5 (+3❤)'), findsOneWidget);
  });

  testWidgets('great_regeneration_potion activates 3 turns of +5 HP regen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final greatRegen = allItemCards.firstWhere((i) => i.id == 'great_regeneration_potion');
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(initialInventory: [greatRegen])),
    );
    await tester.pumpAndSettle();

    final state = tester.state<GameScreenState>(find.byType(GameScreen));
    expect(state.regenerationTurns, equals(0));

    await openInventoryAndUse(tester);

    expect(state.regenerationTurns, equals(3));
    expect(state.regenerationHpPerTurn, equals(5));
    expect(find.textContaining('Регенерация ×3 (+5❤)'), findsOneWidget);
  });
}


