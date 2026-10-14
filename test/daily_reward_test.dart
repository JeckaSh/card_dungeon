import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/services/daily_reward_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerCoinsService.instance.load();
    PlayerCoinsService.instance.restoreBalance(0);
    await DailyRewardService.instance.debugResetStreak();
  });

  group('DailyRewardService rewards & calculations', () {
    test('rewards scale from 100 on day 1 to 700 on day 7 (+100 each day)', () {
      expect(DailyRewardService.getRewardForDay(1), 100);
      expect(DailyRewardService.getRewardForDay(2), 200);
      expect(DailyRewardService.getRewardForDay(3), 300);
      expect(DailyRewardService.getRewardForDay(4), 400);
      expect(DailyRewardService.getRewardForDay(5), 500);
      expect(DailyRewardService.getRewardForDay(6), 600);
      expect(DailyRewardService.getRewardForDay(7), 700);
    });

    test('first time user starts at day 1 with 100 coins reward available', () {
      final service = DailyRewardService.instance;
      expect(service.canClaimToday, isTrue);
      expect(service.todayStreakDay, 1);
      expect(service.todayRewardAmount, 100);
    });

    test('claiming today grants coins and marks today as claimed', () async {
      final service = DailyRewardService.instance;
      final reward = await service.claimToday();

      expect(reward, 100);
      expect(PlayerCoinsService.instance.balance, 100);
      expect(service.isClaimedToday, isTrue);
      expect(service.canClaimToday, isFalse);
      expect(service.streak, 1);

      // Attempting to claim again today does nothing
      final secondClaim = await service.claimToday();
      expect(secondClaim, 0);
      expect(PlayerCoinsService.instance.balance, 100);
    });

    test('consecutive login increments streak up to 7', () async {
      final service = DailyRewardService.instance;

      // Simulate day 3 was claimed yesterday
      await service.debugSetStreak(3, claimedToday: false);
      expect(service.canClaimToday, isTrue);
      expect(service.todayStreakDay, 4);
      expect(service.todayRewardAmount, 400);

      final reward = await service.claimToday();
      expect(reward, 400);
      expect(service.streak, 4);
      expect(service.isClaimedToday, isTrue);
    });

    test('after day 7 streak resets back to day 1', () async {
      final service = DailyRewardService.instance;

      // Simulate day 7 was claimed yesterday
      await service.debugSetStreak(7, claimedToday: false);
      expect(service.canClaimToday, isTrue);
      // After 7th day, next is day 1!
      expect(service.todayStreakDay, 1);
      expect(service.todayRewardAmount, 100);

      final reward = await service.claimToday();
      expect(reward, 100);
      expect(service.streak, 1);
    });

    test('skipping a day breaks streak and resets to day 1', () async {
      final service = DailyRewardService.instance;

      // Set last claim date to 3 days ago
      final prefs = await SharedPreferences.getInstance();
      final threeDaysAgo = DailyRewardService.todayMskDate.subtract(const Duration(days: 3));
      final y = threeDaysAgo.year.toString().padLeft(4, '0');
      final m = threeDaysAgo.month.toString().padLeft(2, '0');
      final d = threeDaysAgo.day.toString().padLeft(2, '0');
      await prefs.setString('daily_reward_last_claim_date', '$y-$m-$d');
      await prefs.setInt('daily_reward_streak', 5);

      // Reload
      await service.debugResetTodayClaim();
      // Now streak day should reset to 1
      expect(service.todayStreakDay, 1);
      expect(service.todayRewardAmount, 100);
    });

    test('time until Moscow midnight is positive and less than or equal to 24 hours', () {
      final timeLeft = DailyRewardService.timeUntilNextMskMidnight;
      expect(timeLeft.isNegative, isFalse);
      expect(timeLeft.inHours, lessThanOrEqualTo(24));
    });
  });
}
