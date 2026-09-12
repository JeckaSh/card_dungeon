import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/dungeons.dart';
import 'package:kki_cardgame/data/events.dart';
import 'package:kki_cardgame/main.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/chronicle_screen.dart';
import 'package:kki_cardgame/screens/dungeon_select_screen.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/screens/glossary_screen.dart';
import 'package:kki_cardgame/services/discovered_events.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/run_chronicle_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/glossary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DiscoveredEventsService.instance.resetAll();
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
    await RunChronicleService.instance.clear();
  });

  test('All event cards have valid 3rd attribute dungeonId', () {
    expect(allEvents, isNotEmpty);
    expect(allBossCards, isNotEmpty);

    for (final card in allEvents) {
      expect(card.dungeonId, isNotEmpty);
      if (card.type == EventType.treasure || card.type == EventType.merchant) {
        expect(card.isCommonDungeon, isTrue, reason: '${card.id} must be common');
        expect(card.dungeonLabel, 'Общий');
      } else {
        expect(card.dungeonId, DungeonId.cursedForest, reason: '${card.id} must belong to cursed forest');
        expect(card.dungeonLabel, 'Проклятый лес');
      }
    }

    for (final boss in allBossCards) {
      expect(boss.dungeonId, DungeonId.cursedForest, reason: '${boss.id} must belong to cursed forest');
      expect(boss.dungeonLabel, 'Проклятый лес');
    }
  });

  testWidgets('Tapping "В подземелье" opens DungeonSelectScreen with levels description', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DungeonCardsApp());
    await tester.pumpAndSettle();

    // Tap "В подземелье"
    final dungeonBtn = find.text('В подземелье');
    expect(dungeonBtn, findsOneWidget);
    await tester.tap(dungeonBtn);
    await tester.pumpAndSettle();

    // Verify DungeonSelectScreen is pushed
    expect(find.byType(DungeonSelectScreen), findsOneWidget);
    expect(find.text('Проклятый лес'), findsOneWidget);
    expect(find.textContaining('Количество уровней: 3'), findsOneWidget);
    expect(find.text('3 уровня'), findsOneWidget);

    // Tap "Войти в подземелье"
    final enterBtn = find.text('Войти в подземелье');
    expect(enterBtn, findsOneWidget);
    await tester.tap(enterBtn);
    await tester.pumpAndSettle();

    // Verify GameScreen is open with current dungeon indicator
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Проклятый лес'), findsOneWidget);
    expect(find.textContaining('Этаж 1 / 3'), findsOneWidget);
  });

  testWidgets('ChronicleScreen records and displays dungeon name', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await RunChronicleService.instance.addRecord(
      RunRecord(
        endedAt: DateTime.now(),
        cardsPassed: 10,
        dungeonLevel: 2,
        coins: 45,
        isVictory: false,
        journal: ['🗡️ [1] Герой вошёл в подземелье: Проклятый лес'],
        dungeonId: 'cursed_forest',
        dungeonName: 'Проклятый лес',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ChronicleScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Проклятый лес'), findsOneWidget);
    expect(find.text('Забег #1'), findsOneWidget);
  });

  testWidgets('GlossaryCard shows dungeon type badge next to level badge', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const forestCard = EventCard(
      id: 'test_forest',
      type: EventType.monster,
      title: 'Лесной монстр',
      description: 'Мрачная чаща',
      leftChoice: CardChoice(label: 'Бой'),
      rightChoice: CardChoice(label: 'Бежать'),
      level: 2,
      dungeonId: DungeonId.cursedForest,
    );

    const commonCard = EventCard(
      id: 'test_common',
      type: EventType.treasure,
      title: 'Древний сундук',
      description: 'Сокровища',
      leftChoice: CardChoice(label: 'Открыть'),
      rightChoice: CardChoice(label: 'Уйти'),
      level: 1,
      dungeonId: DungeonId.common,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 200,
                height: 280,
                child: GlossaryCard(event: forestCard, isDiscovered: true),
              ),
              SizedBox(
                width: 200,
                height: 280,
                child: GlossaryCard(event: commonCard, isDiscovered: true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ур. 2'), findsOneWidget);
    expect(find.text('Проклятый лес'), findsOneWidget);

    expect(find.text('Ур. 1'), findsOneWidget);
    expect(find.text('Общий'), findsOneWidget);
  });
}
