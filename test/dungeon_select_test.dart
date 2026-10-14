import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/events.dart';
import 'package:kki_cardgame/main.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/chronicle_screen.dart';
import 'package:kki_cardgame/screens/dungeon_select_screen.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/discovered_events.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/run_chronicle_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/glossary_card.dart';
import 'package:kki_cardgame/services/daily_reward_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DiscoveredEventsService.instance.resetAll();
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
    await UnlockedItemsService.instance.reset();
    await RunChronicleService.instance.clear();
    await DailyRewardService.instance.debugSetStreak(1, claimedToday: true);
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
        expect(
          card.dungeonId == DungeonId.cursedForest ||
              card.dungeonId == DungeonId.catacombs,
          isTrue,
          reason: '${card.id} must belong to cursed forest or catacombs',
        );
        expect(
          card.dungeonLabel == 'Проклятый лес' ||
              card.dungeonLabel == 'Заброшенные катакомбы',
          isTrue,
        );
      }
    }

    for (final boss in allBossCards) {
      expect(
        boss.dungeonId == DungeonId.cursedForest ||
            boss.dungeonId == DungeonId.catacombs,
        isTrue,
        reason: '${boss.id} must belong to cursed forest or catacombs',
      );
      expect(
        boss.dungeonLabel == 'Проклятый лес' ||
            boss.dungeonLabel == 'Заброшенные катакомбы',
        isTrue,
      );
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
    expect(find.textContaining('Количество уровней: 3'), findsWidgets);
    expect(find.text('3 уровня'), findsWidgets);

    // Tap "Войти в подземелье" on first dungeon
    final enterBtn = find.text('Войти в подземелье').first;
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

  test('Catacombs card pool has correct level distribution and themes', () {
    final catacombsEvents = allEvents
        .where((e) => e.dungeonId == DungeonId.catacombs)
        .toList();
    expect(catacombsEvents.isNotEmpty, isTrue);

    // Level 1: rats, bats, skeletons
    final lvl1 = catacombsEvents.where((e) => e.level == 1).toList();
    expect(lvl1.length, greaterThanOrEqualTo(8));
    final lvl1Ids = lvl1.map((e) => e.id).toSet();
    expect(lvl1Ids.contains('catacombs_plague_rat'), isTrue);
    expect(lvl1Ids.contains('catacombs_hungry_rat_swarm'), isTrue);
    expect(lvl1Ids.contains('catacombs_cave_bats'), isTrue);
    expect(lvl1Ids.contains('catacombs_vampire_bat'), isTrue);
    expect(lvl1Ids.contains('catacombs_skeleton_warrior'), isTrue);
    expect(lvl1Ids.contains('catacombs_skeleton_archer'), isTrue);
    expect(lvl1Ids.contains('catacombs_skeleton_halberdier'), isTrue);

    // Level 2: vampires, zombies, ghouls
    final lvl2 = catacombsEvents.where((e) => e.level == 2).toList();
    expect(lvl2.length, greaterThanOrEqualTo(8));
    final lvl2Ids = lvl2.map((e) => e.id).toSet();
    expect(lvl2Ids.contains('catacombs_rot_zombie'), isTrue);
    expect(lvl2Ids.contains('catacombs_zombie_berserker'), isTrue);
    expect(lvl2Ids.contains('catacombs_crawling_ghoul'), isTrue);
    expect(lvl2Ids.contains('catacombs_fledgling_vampire'), isTrue);
    expect(lvl2Ids.contains('catacombs_vampire_noble'), isTrue);
    expect(lvl2Ids.contains('catacombs_vampire_huntress'), isTrue);

    // Level 3: empowered variants
    final lvl3 = catacombsEvents.where((e) => e.level == 3).toList();
    expect(lvl3.length, greaterThanOrEqualTo(8));
    final lvl3Ids = lvl3.map((e) => e.id).toSet();
    expect(lvl3Ids.contains('catacombs_empowered_rat_matriarch'), isTrue);
    expect(lvl3Ids.contains('catacombs_empowered_shadow_bats'), isTrue);
    expect(lvl3Ids.contains('catacombs_empowered_bone_juggernaut'), isTrue);
    expect(lvl3Ids.contains('catacombs_empowered_zombie_titan'), isTrue);
    expect(lvl3Ids.contains('catacombs_empowered_nosferatu_elder'), isTrue);
    expect(lvl3Ids.contains('catacombs_empowered_vampire_archon'), isTrue);

    // Bosses for Catacombs: 3 bosses with 3 phases each
    final catacombsBosses = allBossCards
        .where((e) => e.dungeonId == DungeonId.catacombs)
        .toList();
    expect(catacombsBosses.length, 3);
    for (final boss in catacombsBosses) {
      expect(boss.isMultiPhase, isTrue);
      expect(boss.bossPhases?.length, 3);
    }
    expect(catacombsBosses[0].id, 'catacombs_boss_bone_colossus');
    expect(catacombsBosses[0].level, 1);
    expect(catacombsBosses[1].id, 'catacombs_boss_vampire_lord');
    expect(catacombsBosses[1].level, 2);
    expect(catacombsBosses[2].id, 'catacombs_boss_archlich');
    expect(catacombsBosses[2].level, 3);
  });

  testWidgets('Can select and enter Заброшенные катакомбы', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DungeonCardsApp());
    await tester.pumpAndSettle();

    // Open dungeon select screen
    await tester.tap(find.text('В подземелье'));
    await tester.pumpAndSettle();

    // Verify both dungeons are present
    expect(find.text('Проклятый лес'), findsOneWidget);
    expect(find.text('Заброшенные катакомбы'), findsOneWidget);

    // Tap on Catacombs card (InkWell calls _enterDungeon)
    await tester.tap(find.text('Заброшенные катакомбы'));
    await tester.pumpAndSettle();

    // Verify GameScreen launched in Catacombs
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Заброшенные катакомбы'), findsOneWidget);
    expect(find.textContaining('Этаж 1 / 3'), findsOneWidget);
  });
}
