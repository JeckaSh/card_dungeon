import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_coins_service.dart';

/// Сервис ежедневной награды за вход в игру.
///
/// Правила:
/// * Цикл состоит из 7 дней.
/// * Награда за 1-й день — 100 монет, каждый следующий день +100 монет (до 700 монет на 7-й день).
/// * После получения награды 7-го дня счётчик сбрасывается снова на 1-й день.
/// * День обновляется ровно в полночь по московскому времени (UTC+3, MSK).
/// * Если игрок пропускает день, серия сбрасывается на 1-й день.
class DailyRewardService extends ChangeNotifier {
  DailyRewardService._();

  /// Глобальный синглтон сервиса
  static final DailyRewardService instance = DailyRewardService._();

  static const _storageKeyLastClaimDate = 'daily_reward_last_claim_date';
  static const _storageKeyStreak = 'daily_reward_streak';

  String? _lastClaimDate; // формат: 'YYYY-MM-DD'
  int _streak = 0; // последний зафиксированный день (0..7)
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Последний зафиксированный день в стрике (0..7)
  int get streak => _streak;

  /// Дата последнего получения награды ('YYYY-MM-DD')
  String? get lastClaimDate => _lastClaimDate;

  /// Текущее время по Московскому часовому поясу (UTC+3, без перехода на летнее время)
  static DateTime get nowMsk {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  /// Ключ сегодняшнего дня по МСК в формате 'YYYY-MM-DD'
  static String get todayMskKey {
    final msk = nowMsk;
    final y = msk.year.toString().padLeft(4, '0');
    final m = msk.month.toString().padLeft(2, '0');
    final d = msk.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Дата сегодняшнего дня по МСК (00:00:00 UTC) для корректного вычисления разницы в днях
  static DateTime get todayMskDate {
    final msk = nowMsk;
    return DateTime.utc(msk.year, msk.month, msk.day);
  }

  /// Время до полуночи по Московскому времени
  static Duration get timeUntilNextMskMidnight {
    final msk = nowMsk;
    final nextMidnight = DateTime(msk.year, msk.month, msk.day + 1);
    final duration = nextMidnight.difference(DateTime(msk.year, msk.month, msk.day, msk.hour, msk.minute, msk.second));
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Загружает сохранённые данные из SharedPreferences
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _lastClaimDate = prefs.getString(_storageKeyLastClaimDate);
    _streak = prefs.getInt(_storageKeyStreak) ?? 0;
    _loaded = true;
  }

  /// Получена ли награда за сегодняшний день
  bool get isClaimedToday {
    return _lastClaimDate == todayMskKey;
  }

  /// Доступна ли награда для получения сегодня
  bool get canClaimToday => !isClaimedToday;

  /// Номер дня в стрике (1..7), который соответствует сегодняшней награде.
  ///
  /// * Если сегодня награда уже получена — возвращает день, который был получен.
  /// * Если вчера была получена награда — серия продолжается: (streak % 7) + 1.
  /// * Если пропущен день или первый вход — возвращает 1.
  int get todayStreakDay {
    if (_lastClaimDate == null) {
      return 1;
    }

    try {
      final parts = _lastClaimDate!.split('-');
      final lastYear = int.parse(parts[0]);
      final lastMonth = int.parse(parts[1]);
      final lastDay = int.parse(parts[2]);
      final lastDateUtc = DateTime.utc(lastYear, lastMonth, lastDay);

      final diffDays = todayMskDate.difference(lastDateUtc).inDays;

      if (diffDays == 0) {
        // Уже получена сегодня
        return _streak == 0 ? 1 : _streak.clamp(1, 7);
      } else if (diffDays == 1) {
        // Вход на следующий день подряд — продолжаем стрик!
        // После 7-го дня счётчик сбрасывается снова на 1-й день.
        if (_streak >= 7) {
          return 1;
        }
        return (_streak + 1).clamp(1, 7);
      } else {
        // diffDays > 1 (пропущен день) или часы были переведены назад
        return 1;
      }
    } catch (_) {
      return 1;
    }
  }

  /// Возвращает сумму награды в монетах за указанный день (1-й: 100, 2-й: 200, ..., 7-й: 700)
  static int getRewardForDay(int day) {
    final clamped = day.clamp(1, 7);
    return clamped * 100;
  }

  /// Награда в монетах за сегодняшний день
  int get todayRewardAmount => getRewardForDay(todayStreakDay);

  /// Получить награду за сегодняшний день.
  ///
  /// Начисляет монеты в [PlayerCoinsService], обновляет стрик и дату, сохраняет данные.
  /// Возвращает количество начисленных монет (0, если уже получено).
  Future<int> claimToday() async {
    if (!canClaimToday) return 0;

    await load();
    await PlayerCoinsService.instance.load();

    final dayToClaim = todayStreakDay;
    final reward = getRewardForDay(dayToClaim);

    _streak = dayToClaim;
    _lastClaimDate = todayMskKey;

    PlayerCoinsService.instance.applyDelta(reward);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    await prefs.setInt(_storageKeyStreak, _streak);

    notifyListeners();
    return reward;
  }

  // ── Дебаг-методы для тестирования ──────────────────────────────────────────

  /// Сбросить получение за сегодня (чтобы снова можно было забрать награду)
  Future<void> debugResetTodayClaim() async {
    final prefs = await SharedPreferences.getInstance();
    // Устанавливаем дату получения на вчера
    final yesterday = todayMskDate.subtract(const Duration(days: 1));
    final y = yesterday.year.toString().padLeft(4, '0');
    final m = yesterday.month.toString().padLeft(2, '0');
    final d = yesterday.day.toString().padLeft(2, '0');
    _lastClaimDate = '$y-$m-$d';
    // Если стрика не было, ставим 0
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    notifyListeners();
  }

  /// Сбросить стрик полностью в начальное состояние
  Future<void> debugResetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _lastClaimDate = null;
    _streak = 0;
    await prefs.remove(_storageKeyLastClaimDate);
    await prefs.remove(_storageKeyStreak);
    notifyListeners();
  }

  /// Задать конкретный день стрика (1..7)
  Future<void> debugSetStreak(int streakDay, {bool claimedToday = true}) async {
    final prefs = await SharedPreferences.getInstance();
    _streak = streakDay.clamp(1, 7);
    if (claimedToday) {
      _lastClaimDate = todayMskKey;
    } else {
      final yesterday = todayMskDate.subtract(const Duration(days: 1));
      final y = yesterday.year.toString().padLeft(4, '0');
      final m = yesterday.month.toString().padLeft(2, '0');
      final d = yesterday.day.toString().padLeft(2, '0');
      _lastClaimDate = '$y-$m-$d';
    }
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    await prefs.setInt(_storageKeyStreak, _streak);
    notifyListeners();
  }
}
