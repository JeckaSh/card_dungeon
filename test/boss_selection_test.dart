import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/dungeons.dart';
import 'package:kki_cardgame/data/events.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dungeon Boss Pool & Random Selection Tests', () {
    test('Both dungeons have multiple bosses on levels 1, 2, and 3 for random selection', () {
      // Cursed Forest
      final forestLvl1 = getBossesForDungeonAndLevel(cursedForestDungeon.id, 1);
      expect(forestLvl1.length, 3);
      expect(forestLvl1.map((b) => b.id).toSet(), {
        'forest_boss_packleader',
        'forest_boss_broodmother',
        'forest_boss_corrupted_treant',
      });

      final forestLvl2 = getBossesForDungeonAndLevel(cursedForestDungeon.id, 2);
      expect(forestLvl2.length, 3);
      expect(forestLvl2.map((b) => b.id).toSet(), {
        'forest_boss_swamp_hag',
        'forest_boss_mire_leviathan',
        'forest_boss_shadow_crow',
      });

      final forestLvl3 = getBossesForDungeonAndLevel(cursedForestDungeon.id, 3);
      expect(forestLvl3.length, 3);
      expect(forestLvl3.map((b) => b.id).toSet(), {
        'forest_boss_ancient_leshy',
        'forest_boss_blight_dragon',
        'forest_boss_abyssal_treant',
      });

      // Abandoned Catacombs
      final catacombsLvl1 = getBossesForDungeonAndLevel(catacombsDungeon.id, 1);
      expect(catacombsLvl1.length, 3);
      expect(catacombsLvl1.map((b) => b.id).toSet(), {
        'catacombs_boss_bone_colossus',
        'catacombs_boss_rat_king',
        'catacombs_boss_crypt_banshee',
      });

      final catacombsLvl2 = getBossesForDungeonAndLevel(catacombsDungeon.id, 2);
      expect(catacombsLvl2.length, 3);
      expect(catacombsLvl2.map((b) => b.id).toSet(), {
        'catacombs_boss_vampire_lord',
        'catacombs_boss_flesh_necromancer',
        'catacombs_boss_blood_countess',
      });

      final catacombsLvl3 = getBossesForDungeonAndLevel(catacombsDungeon.id, 3);
      expect(catacombsLvl3.length, 3);
      expect(catacombsLvl3.map((b) => b.id).toSet(), {
        'catacombs_boss_archlich',
        'catacombs_boss_death_knight',
        'catacombs_boss_bone_dragon',
      });
    });

    test('All bosses on levels 1, 2, and 3 are multi-phase with 3 phases and balanced choices', () {
      final allBosses = [
        ...getBossesForDungeonAndLevel(cursedForestDungeon.id, 1),
        ...getBossesForDungeonAndLevel(cursedForestDungeon.id, 2),
        ...getBossesForDungeonAndLevel(cursedForestDungeon.id, 3),
        ...getBossesForDungeonAndLevel(catacombsDungeon.id, 1),
        ...getBossesForDungeonAndLevel(catacombsDungeon.id, 2),
        ...getBossesForDungeonAndLevel(catacombsDungeon.id, 3),
      ];
      expect(allBosses.length, 18);

      for (final boss in allBosses) {
        expect(boss.type, EventType.boss);
        expect(boss.level, inInclusiveRange(1, 3));
        expect(boss.isMultiPhase, isTrue, reason: '${boss.id} must be multi-phase');
        expect(boss.bossPhases?.length, 3, reason: '${boss.id} must have 3 phases');

        // Main card check
        final left = boss.leftChoice;
        final right = boss.rightChoice;
        expect(
          left.healthDelta < 0 || right.healthDelta < 0,
          isTrue,
          reason: '${boss.id} must inflict health damage',
        );
        expect(
          left.attackDelta < 0 || right.attackDelta < 0,
          isTrue,
          reason: '${boss.id} must consume attack',
        );
      }
    });

    testWidgets('GameScreen picks random level 1 boss for Cursed Forest at card 20', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final forestBosses = getBossesForDungeonAndLevel(cursedForestDungeon.id, 1);
      final encounteredBossIds = <String>{};

      // Test with several fixed random seeds to ensure different level 1 bosses appear
      for (int seed = 0; seed < 15; seed++) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey('forest_$seed'),
              dungeon: cursedForestDungeon,
              initialCardsPassed: 19, // Next card (card 20) is the level 1 boss!
              random: Random(seed),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<GameScreenState>(find.byType(GameScreen));
        final activeBoss = state.currentCardForTesting;
        expect(activeBoss.type, EventType.boss);
        expect(activeBoss.level, 1);
        expect(forestBosses.map((b) => b.id).contains(activeBoss.id), isTrue);

        encounteredBossIds.add(activeBoss.id);
      }

      // Over 15 different seeds, more than 1 distinct level 1 boss must have been selected
      expect(
        encounteredBossIds.length,
        greaterThan(1),
        reason: 'Multiple different level 1 bosses must be selected across runs',
      );
    });

    testWidgets('GameScreen picks random level 1 boss for Catacombs at card 20', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final catacombsBosses = getBossesForDungeonAndLevel(catacombsDungeon.id, 1);
      final encounteredBossIds = <String>{};

      for (int seed = 0; seed < 15; seed++) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey('catacombs_$seed'),
              dungeon: catacombsDungeon,
              initialCardsPassed: 19,
              random: Random(seed),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<GameScreenState>(find.byType(GameScreen));
        final activeBoss = state.currentCardForTesting;
        expect(activeBoss.type, EventType.boss);
        expect(activeBoss.level, 1);
        expect(catacombsBosses.map((b) => b.id).contains(activeBoss.id), isTrue);

        encounteredBossIds.add(activeBoss.id);
      }

      expect(
        encounteredBossIds.length,
        greaterThan(1),
        reason: 'Multiple different level 1 bosses must be selected across runs in Catacombs',
      );
    });

    testWidgets('GameScreen picks random level 2 boss at card 40', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final forestLvl2Bosses = getBossesForDungeonAndLevel(cursedForestDungeon.id, 2);
      final encountered = <String>{};

      for (int seed = 0; seed < 15; seed++) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey('forest_lvl2_$seed'),
              dungeon: cursedForestDungeon,
              initialDungeonLevel: 2,
              initialCardsPassed: 39, // Next card (card 40) is level 2 boss!
              random: Random(seed),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<GameScreenState>(find.byType(GameScreen));
        final activeBoss = state.currentCardForTesting;
        expect(activeBoss.type, EventType.boss);
        expect(activeBoss.level, 2);
        expect(forestLvl2Bosses.map((b) => b.id).contains(activeBoss.id), isTrue);

        encountered.add(activeBoss.id);
      }

      expect(encountered.length, greaterThan(1));
    });

    testWidgets('GameScreen picks random level 3 boss at card 60 in Catacombs', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final catacombsLvl3Bosses = getBossesForDungeonAndLevel(catacombsDungeon.id, 3);
      final encountered = <String>{};

      for (int seed = 0; seed < 15; seed++) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey('catacombs_lvl3_$seed'),
              dungeon: catacombsDungeon,
              initialDungeonLevel: 3,
              initialCardsPassed: 59, // Next card (card 60) is level 3 boss!
              random: Random(seed),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final state = tester.state<GameScreenState>(find.byType(GameScreen));
        final activeBoss = state.currentCardForTesting;
        expect(activeBoss.type, EventType.boss);
        expect(activeBoss.level, 3);
        expect(catacombsLvl3Bosses.map((b) => b.id).contains(activeBoss.id), isTrue);

        encountered.add(activeBoss.id);
      }

      expect(encountered.length, greaterThan(1));
    });

    testWidgets('Selected boss remains consistent across all 3 phases of the fight', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            dungeon: cursedForestDungeon,
            initialCardsPassed: 19,
            random: Random(42),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<GameScreenState>(find.byType(GameScreen));
      final bossId = state.currentCardForTesting.id;

      // Phase 1 is active
      expect(state.bossPhaseForTesting, 1);
      expect(state.currentCardForTesting.id, bossId);

      // Defeat phase 1 (swipe right)
      state.handleSwipeForTesting(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 2 is active, still the SAME boss
      expect(state.bossPhaseForTesting, 2);
      expect(state.currentCardForTesting.id, bossId);

      // Defeat phase 2 (swipe right)
      state.handleSwipeForTesting(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Phase 3 is active, still the SAME boss
      expect(state.bossPhaseForTesting, 3);
      expect(state.currentCardForTesting.id, bossId);
    });
  });
}
