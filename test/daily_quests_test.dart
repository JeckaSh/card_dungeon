import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/services/daily_quests_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerCoinsService.instance.load();
    PlayerCoinsService.instance.restoreBalance(0);
    await DailyQuestsService.instance.load();
  });

  group('DailyQuestsService logic', () {
    test('generates exactly 2 distinct daily quests', () async {
      final quests = DailyQuestsService.instance.quests;
      expect(quests.length, 2);
      expect(quests[0].type, isNot(equals(quests[1].type)));
    });

    test('targets are within specified ranges', () async {
      // Test over 50 iterations
      for (int i = 0; i < 50; i++) {
        await DailyQuestsService.instance.debugRerollQuests();
        final quests = DailyQuestsService.instance.quests;
        expect(quests.length, 2);

        for (final q in quests) {
          switch (q.type) {
            case DailyQuestType.dungeonRuns:
              expect(q.target, inInclusiveRange(1, 3));
              break;
            case DailyQuestType.killBosses:
              expect(q.target, inInclusiveRange(3, 5));
              break;
            case DailyQuestType.clearDungeon:
              expect(q.target, 1);
              break;
            case DailyQuestType.encounterCards:
              expect(q.target, 30);
              expect(q.targetEventType, isNotNull);
              break;
            case DailyQuestType.specificDungeonRuns:
              expect(q.target, inInclusiveRange(1, 3));
              expect(q.targetDungeonId, isNotNull);
              break;
          }
        }
      }
    });

    test('onDungeonFinished increments dungeonRuns and clearDungeon (on victory)', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(id: 'test_runs', type: DailyQuestType.dungeonRuns, target: 2),
        DailyQuest(id: 'test_clear', type: DailyQuestType.clearDungeon, target: 1),
      ]);

      // Finish with loss
      service.onDungeonFinished(isVictory: false);
      expect(service.quests[0].progress, 1);
      expect(service.quests[1].progress, 0);

      // Finish with victory
      service.onDungeonFinished(isVictory: true);
      expect(service.quests[0].progress, 2);
      expect(service.quests[0].isCompleted, isTrue);
      expect(service.quests[1].progress, 1);
      expect(service.quests[1].isCompleted, isTrue);
    });

    test('onBossKilled increments killBosses quest progress', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(id: 'test_bosses', type: DailyQuestType.killBosses, target: 4),
        DailyQuest(id: 'test_clear', type: DailyQuestType.clearDungeon, target: 1),
      ]);

      service.onBossKilled();
      service.onBossKilled();
      expect(service.quests[0].progress, 2);
      expect(service.quests[1].progress, 0);

      service.onBossKilled();
      service.onBossKilled();
      expect(service.quests[0].progress, 4);
      expect(service.quests[0].isCompleted, isTrue);
      expect(service.quests[0].canClaim, isTrue);
    });

    test('onCardEncountered increments only matching card type quest', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(
          id: 'test_monsters',
          type: DailyQuestType.encounterCards,
          target: 30,
          targetEventType: EventType.monster,
        ),
        DailyQuest(id: 'test_clear', type: DailyQuestType.clearDungeon, target: 1),
      ]);

      // Encounter other types
      service.onCardEncountered(EventType.trap);
      service.onCardEncountered(EventType.treasure);
      expect(service.quests[0].progress, 0);

      // Encounter monster
      service.onCardEncountered(EventType.monster);
      service.onCardEncountered(EventType.monster);
      expect(service.quests[0].progress, 2);
    });

    test('claimQuest grants 150 coins and marks quest as claimed', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(
          id: 'test_claimable',
          type: DailyQuestType.dungeonRuns,
          target: 1,
          progress: 1,
        ),
        DailyQuest(id: 'test_other', type: DailyQuestType.clearDungeon, target: 1),
      ]);

      expect(service.hasUnclaimedCompletedQuests, isTrue);
      expect(PlayerCoinsService.instance.balance, 0);

      final reward = await service.claimQuest('test_claimable');
      expect(reward, 150);
      expect(PlayerCoinsService.instance.balance, 150);
      expect(service.quests[0].isClaimed, isTrue);
      expect(service.quests[0].canClaim, isFalse);
      expect(service.hasUnclaimedCompletedQuests, isFalse);

      // Claiming again does nothing
      final secondClaim = await service.claimQuest('test_claimable');
      expect(secondClaim, 0);
      expect(PlayerCoinsService.instance.balance, 150);
    });

    test('onDungeonFinished increments specificDungeonRuns only when dungeonId matches', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(
          id: 'test_cursed',
          type: DailyQuestType.specificDungeonRuns,
          target: 2,
          targetDungeonId: 'cursed_forest',
        ),
      ]);

      // Finish catacombs -> should not increment
      service.onDungeonFinished(isVictory: false, dungeonId: 'catacombs');
      expect(service.quests[0].progress, 0);

      // Finish cursed_forest with loss -> increments
      service.onDungeonFinished(isVictory: false, dungeonId: 'cursed_forest');
      expect(service.quests[0].progress, 1);

      // Finish cursed_forest with win -> increments and completes
      service.onDungeonFinished(isVictory: true, dungeonId: 'cursed_forest');
      expect(service.quests[0].progress, 2);
      expect(service.quests[0].isCompleted, isTrue);
    });

    test('weekly quests generate 2 distinct quests with 3-5x difficulty and 500 coins reward', () async {
      final service = DailyQuestsService.instance;
      for (int i = 0; i < 30; i++) {
        await service.debugRerollWeeklyQuests();
        final weekly = service.weeklyQuests;
        expect(weekly.length, 2);
        final types = weekly.map((q) => q.type).toSet();
        expect(types.length, 2, reason: 'All 2 weekly quests must be distinct types');

        for (final q in weekly) {
          expect(q.isWeekly, isTrue);
          expect(q.rewardCoins, 500);

          switch (q.type) {
            case DailyQuestType.dungeonRuns:
              // Daily is 1-3. Weekly is 3-5x (5-10)
              expect(q.target, inInclusiveRange(5, 10));
              break;
            case DailyQuestType.killBosses:
              // Daily is 3-5. Weekly is 3-5x (12-20)
              expect(q.target, inInclusiveRange(12, 20));
              break;
            case DailyQuestType.clearDungeon:
              // Daily is 1. Weekly is 3-5x (3-5)
              expect(q.target, inInclusiveRange(3, 5));
              break;
            case DailyQuestType.encounterCards:
              // Daily is 30. Weekly is 3-5x (90-150)
              expect(q.target, inInclusiveRange(90, 150));
              expect(q.targetEventType, isNotNull);
              break;
            case DailyQuestType.specificDungeonRuns:
              // Daily is 1-3. Weekly is 3-5x (5-10)
              expect(q.target, inInclusiveRange(5, 10));
              expect(q.targetDungeonId, isNotNull);
              break;
          }
        }
      }
    });

    test('weekly quests claim awards 500 coins', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting(
        [
          DailyQuest(id: 'daily_1', type: DailyQuestType.clearDungeon, target: 1),
        ],
        weeklyQuests: [
          DailyQuest(
            id: 'weekly_claimable',
            type: DailyQuestType.clearDungeon,
            target: 3,
            progress: 3,
            isWeekly: true,
            rewardCoins: 500,
          ),
          DailyQuest(
            id: 'weekly_pending',
            type: DailyQuestType.killBosses,
            target: 15,
            progress: 0,
            isWeekly: true,
            rewardCoins: 500,
          ),
        ],
      );

      expect(service.hasUnclaimedCompletedQuests, isTrue);
      expect(PlayerCoinsService.instance.balance, 0);

      final reward = await service.claimQuest('weekly_claimable');
      expect(reward, 500);
      expect(PlayerCoinsService.instance.balance, 500);
      expect(service.weeklyQuests[0].isClaimed, isTrue);
      expect(service.weeklyQuests[0].canClaim, isFalse);
      expect(service.hasUnclaimedCompletedQuests, isFalse);
    });

    test('gameplay events progress both daily and weekly quests simultaneously', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting(
        [
          DailyQuest(id: 'daily_boss', type: DailyQuestType.killBosses, target: 3),
          DailyQuest(id: 'daily_monster', type: DailyQuestType.encounterCards, target: 30, targetEventType: EventType.monster),
        ],
        weeklyQuests: [
          DailyQuest(id: 'weekly_boss', type: DailyQuestType.killBosses, target: 15, isWeekly: true, rewardCoins: 500),
          DailyQuest(id: 'weekly_monster', type: DailyQuestType.encounterCards, target: 100, targetEventType: EventType.monster, isWeekly: true, rewardCoins: 500),
        ],
      );

      service.onBossKilled();
      expect(service.quests[0].progress, 1);
      expect(service.weeklyQuests[0].progress, 1);

      service.onCardEncountered(EventType.monster);
      expect(service.quests[1].progress, 1);
      expect(service.weeklyQuests[1].progress, 1);
    });

    test('completing all daily quests allows claiming 2 silver keys bonus', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting([
        DailyQuest(id: 'd1', type: DailyQuestType.clearDungeon, target: 1, progress: 1),
        DailyQuest(id: 'd2', type: DailyQuestType.killBosses, target: 3, progress: 2),
      ]);

      expect(service.areAllDailyQuestsCompleted, isFalse);
      expect(service.canClaimDailyBonus, isFalse);
      expect(PlayerCoinsService.instance.silverKeys, 0);

      // Complete second quest
      service.onBossKilled();
      expect(service.areAllDailyQuestsCompleted, isTrue);
      expect(service.canClaimDailyBonus, isTrue);
      expect(service.hasUnclaimedCompletedQuests, isTrue);

      // Claim individual quests first
      await service.claimQuest('d1');
      await service.claimQuest('d2');
      // Even though both individual quests are claimed, bonus can still be claimed!
      expect(service.hasUnclaimedCompletedQuests, isTrue);
      expect(service.canClaimDailyBonus, isTrue);

      // Claim daily bonus
      final keys = await service.claimDailyAllCompletedBonus();
      expect(keys, 2);
      expect(PlayerCoinsService.instance.silverKeys, 2);
      expect(service.isDailyBonusClaimed, isTrue);
      expect(service.canClaimDailyBonus, isFalse);
      expect(service.hasUnclaimedCompletedQuests, isFalse);

      // Second claim returns 0 and does not change balance
      final secondClaim = await service.claimDailyAllCompletedBonus();
      expect(secondClaim, 0);
      expect(PlayerCoinsService.instance.silverKeys, 2);
    });

    test('completing all weekly quests allows claiming 2 gold keys bonus', () async {
      final service = DailyQuestsService.instance;
      service.setQuestsForTesting(
        [
          DailyQuest(id: 'daily_1', type: DailyQuestType.clearDungeon, target: 1),
        ],
        weeklyQuests: [
          DailyQuest(id: 'w1', type: DailyQuestType.dungeonRuns, target: 5, progress: 5, isWeekly: true),
          DailyQuest(id: 'w2', type: DailyQuestType.killBosses, target: 15, progress: 14, isWeekly: true),
        ],
      );

      expect(service.areAllWeeklyQuestsCompleted, isFalse);
      expect(service.canClaimWeeklyBonus, isFalse);
      expect(PlayerCoinsService.instance.goldKeys, 0);

      // Complete w2
      service.onBossKilled();
      expect(service.areAllWeeklyQuestsCompleted, isTrue);
      expect(service.canClaimWeeklyBonus, isTrue);
      expect(service.hasUnclaimedCompletedQuests, isTrue);

      // Claim weekly bonus
      final keys = await service.claimWeeklyAllCompletedBonus();
      expect(keys, 2);
      expect(PlayerCoinsService.instance.goldKeys, 2);
      expect(service.isWeeklyBonusClaimed, isTrue);
      expect(service.canClaimWeeklyBonus, isFalse);

      // Second claim returns 0
      final secondClaim = await service.claimWeeklyAllCompletedBonus();
      expect(secondClaim, 0);
      expect(PlayerCoinsService.instance.goldKeys, 2);
    });
  });
}
