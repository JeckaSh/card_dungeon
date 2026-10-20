import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/services/daily_quests_service.dart';
import 'package:kki_cardgame/services/daily_reward_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/world_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    WorldTimeService.instance.resetForTest();
    await PlayerCoinsService.instance.load();
    PlayerCoinsService.instance.restoreBalance(0);
    await DailyRewardService.instance.debugResetStreak();
  });

  group('WorldTimeService Tests', () {
    test('Calculates UTC and MSK time (UTC+3) correctly', () {
      final timeService = WorldTimeService.instance;
      // 2026-10-16 12:00:00 UTC -> 15:00:00 MSK
      final testUtc = DateTime.utc(2026, 10, 16, 12, 0, 0);
      timeService.setMockTime(testUtc);

      expect(timeService.nowUtc, testUtc);
      expect(timeService.nowMsk, DateTime.utc(2026, 10, 16, 15, 0, 0));
      expect(timeService.todayMskKey, '2026-10-16');
      expect(timeService.todayMskDate, DateTime.utc(2026, 10, 16));
    });

    test('Midnight MSK rollover advances todayMskKey at 00:00:00 MSK', () {
      final timeService = WorldTimeService.instance;
      // 2026-10-16 20:59:59 UTC = 23:59:59 MSK -> still 2026-10-16
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 20, 59, 59));
      expect(timeService.todayMskKey, '2026-10-16');

      // 2026-10-16 21:00:00 UTC = 00:00:00 MSK on 2026-10-17 -> new day!
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 21, 0, 0));
      expect(timeService.todayMskKey, '2026-10-17');
    });

    test('timeUntilNextMskMidnight counts down correctly', () {
      final timeService = WorldTimeService.instance;
      // 2026-10-16 18:00:00 UTC = 21:00:00 MSK -> 3 hours until midnight
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 18, 0, 0));
      final remaining = timeService.timeUntilNextMskMidnight;
      expect(remaining.inHours, 3);
      expect(remaining.inMinutes, 180);
    });

    test('Detects time rollback when local clock is moved backwards', () {
      final timeService = WorldTimeService.instance;
      timeService.setRollbackForTest(true);
      expect(timeService.isRollbackDetected, isTrue);
      timeService.setRollbackForTest(false);
      expect(timeService.isRollbackDetected, isFalse);
    });
  });

  group('Daily Reward Anti-Cheat & Rewind Protection', () {
    test('Cannot repeatedly claim reward on the same day', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final rewardService = DailyRewardService.instance;
      await rewardService.load();
      expect(rewardService.canClaimToday, isTrue);

      // Claim Day 1
      final reward = await rewardService.claimToday();
      expect(reward, 100);
      expect(rewardService.isClaimedToday, isTrue);
      expect(rewardService.canClaimToday, isFalse);

      // Repeated claim on the same day gives 0
      final repeated = await rewardService.claimToday();
      expect(repeated, 0);
    });

    test('Rewinding clock backward blocks duplicate claim (Anti-Rewind)', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final rewardService = DailyRewardService.instance;
      await rewardService.load();
      await rewardService.claimToday();
      expect(rewardService.isClaimedToday, isTrue);

      // Player rewinds time back to yesterday: 2026-10-15
      timeService.setMockTime(DateTime.utc(2026, 10, 15, 12, 0, 0));
      expect(rewardService.isRollbackDetected, isTrue);
      expect(rewardService.canClaimToday, isFalse);

      final claimAttempt = await rewardService.claimToday();
      expect(claimAttempt, 0);
      expect(rewardService.lastErrorMessage, contains('перевод времени назад'));
    });

    test('Playing offline allows claiming daily reward when no rollback is detected', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final rewardService = DailyRewardService.instance;
      await rewardService.load();
      await rewardService.claimToday();
      expect(rewardService.streak, 1);

      // Device goes offline on the next day
      timeService.setOfflineForTest(true);
      timeService.setMockTime(DateTime.utc(2026, 10, 17, 12, 0, 0));

      // Player can claim next day offline without needing internet
      expect(rewardService.canClaimToday, isTrue);
      final claimOffline = await rewardService.claimToday();
      expect(claimOffline, 200);
      expect(rewardService.streak, 2);
      expect(rewardService.lastErrorMessage, isNull);
    });

    test('When verified world time advances to next day, player claims next streak day', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final rewardService = DailyRewardService.instance;
      await rewardService.load();
      await rewardService.claimToday();
      expect(rewardService.streak, 1);

      // Legitimate world time advance to next day
      timeService.setMockTime(DateTime.utc(2026, 10, 17, 12, 0, 0));
      expect(rewardService.isClaimedToday, isFalse);
      expect(rewardService.canClaimToday, isTrue);
      expect(rewardService.todayStreakDay, 2);
      expect(rewardService.todayRewardAmount, 200);

      final rewardDay2 = await rewardService.claimToday();
      expect(rewardDay2, 200);
      expect(rewardService.streak, 2);
      expect(PlayerCoinsService.instance.balance, 300); // 100 + 200
    });
  });

  group('Daily Quests Anti-Cheat & Rewind Protection', () {
    test('Daily quests do not reset or duplicate when rewinding time backward', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final questsService = DailyQuestsService.instance;
      await questsService.load();
      final originalQuestIds = questsService.quests.map((q) => q.id).toList();
      expect(originalQuestIds.length, 2);

      // Player rewinds clock back to 2026-10-15
      timeService.setMockTime(DateTime.utc(2026, 10, 15, 12, 0, 0));
      await questsService.checkDayTransition();

      // Quests must NOT be reset or replaced with past day quests!
      expect(questsService.quests.map((q) => q.id).toList(), originalQuestIds);
      expect(questsService.dateKey, '2026-10-16');
    });

    test('Daily quests do not reset offline when clock is forwarded without world time sync', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final questsService = DailyQuestsService.instance;
      await questsService.load();
      final originalQuestIds = questsService.quests.map((q) => q.id).toList();

      // Player goes offline and jumps date forward to 2026-10-17
      timeService.setOfflineForTest(true);
      timeService.setMockTime(DateTime.utc(2026, 10, 17, 12, 0, 0));

      await questsService.checkDayTransition();
      // Quests remain unchanged because world time cannot be verified offline!
      expect(questsService.quests.map((q) => q.id).toList(), originalQuestIds);
    });

    test('Daily quests regenerate when verified world time reaches the next day', () async {
      final timeService = WorldTimeService.instance;
      timeService.setMockTime(DateTime.utc(2026, 10, 16, 12, 0, 0));

      final questsService = DailyQuestsService.instance;
      await questsService.load();
      expect(questsService.dateKey, '2026-10-16');

      // Real world time reaches next day and is verified
      timeService.setOfflineForTest(false);
      timeService.setMockTime(DateTime.utc(2026, 10, 17, 12, 0, 0));

      await questsService.checkDayTransition();
      expect(questsService.dateKey, '2026-10-17');
    });
  });
}
