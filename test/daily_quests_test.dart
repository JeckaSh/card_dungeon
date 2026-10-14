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
  });
}
