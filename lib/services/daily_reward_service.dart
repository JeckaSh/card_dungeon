import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_coins_service.dart';
import 'world_time_service.dart';

/// Сервис ежедневной награды за вход в игру.
///
/// Правила:
/// * Цикл состоит из 7 дней.
/// * Награда за 1-й день — 100 монет, каждый следующий день +100 монет (до 700 монет на 7-й день).
/// * Бонусы за стрик: 3-й день — 1 серебряный ключ, 5-й день — 3 серебряных ключа, 7-й день — 1 золотой ключ.
/// * После получения награды 7-го дня счётчик сбрасывается снова на 1-й день.
/// * День обновляется ровно в полночь по московскому времени (UTC+3, MSK).
/// * Время строго валидируется через [WorldTimeService] для защиты от перемотки часов назад или вперёд.
/// * Если игрок пропускает день, серия сбрасывается на 1-й день.
class DailyRewardService extends ChangeNotifier {
  DailyRewardService._();

  /// Глобальный синглтон сервиса
  static final DailyRewardService instance = DailyRewardService._();

  static const _storageKeyLastClaimDate = 'daily_reward_last_claim_date';
  static const _storageKeyStreak = 'daily_reward_streak';
  static const _storageKeyLastClaimTimestamp =
      'daily_reward_last_claim_timestamp';

  String? _lastClaimDate; // формат: 'YYYY-MM-DD'
  int _streak = 0; // последний зафиксированный день (0..7)
  int? _lastClaimTimestampMs;
  bool _loaded = false;
  String? _lastErrorMessage;

  bool get isLoaded => _loaded;

  /// Последний зафиксированный день в стрике (0..7)
  int get streak => _streak;

  /// Дата последнего получения награды ('YYYY-MM-DD')
  String? get lastClaimDate => _lastClaimDate;

  /// Время последнего получения награды в миллисекундах (UTC)
  int? get lastClaimTimestampMs => _lastClaimTimestampMs;

  /// Сообщение о последней ошибке (например, при попытке перемотки времени)
  String? get lastErrorMessage => _lastErrorMessage;

  /// Текущее время по Московскому часовому поясу (UTC+3, MSK) на базе мирового времени
  static DateTime get nowMsk => WorldTimeService.instance.nowMsk;

  /// Ключ сегодняшнего дня по МСК в формате 'YYYY-MM-DD'
  static String get todayMskKey => WorldTimeService.instance.todayMskKey;

  /// Дата сегодняшнего дня по МСК (00:00:00 UTC) для корректного вычисления разницы в днях
  static DateTime get todayMskDate => WorldTimeService.instance.todayMskDate;

  /// Время до полуночи по Московскому времени
  static Duration get timeUntilNextMskMidnight =>
      WorldTimeService.instance.timeUntilNextMskMidnight;

  /// Обнаружен ли откат системного времени назад
  bool get isRollbackDetected {
    if (WorldTimeService.instance.isRollbackDetected) return true;
    if (_lastClaimTimestampMs != null) {
      final currentUtcMs =
          WorldTimeService.instance.nowUtc.millisecondsSinceEpoch;
      // Если текущее время меньше времени последнего получения более чем на 2 минуты
      if (currentUtcMs < _lastClaimTimestampMs! - 120000) {
        return true;
      }
    }
    return false;
  }

  /// Загружает сохранённые данные из SharedPreferences
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _lastClaimDate = prefs.getString(_storageKeyLastClaimDate);
    _streak = prefs.getInt(_storageKeyStreak) ?? 0;
    _lastClaimTimestampMs = prefs.getInt(_storageKeyLastClaimTimestamp);
    _loaded = true;
  }

  /// Получена ли награда за сегодняшний день
  bool get isClaimedToday {
    return _lastClaimDate == todayMskKey;
  }

  /// Доступна ли награда для получения сегодня
  bool get canClaimToday {
    if (isClaimedToday) return false;
    if (isRollbackDetected) return false;
    return true;
  }

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
    if (clamped == 7) return 1000;
    return clamped * 150;
  }

  /// Возвращает количество серебряных ключей за указанный день:
  /// * 3-й день: 1 серебряный ключ;
  /// * 5-й день: 3 серебряных ключа;
  /// * остальные дни: 0.
  static int getSilverKeysForDay(int day) {
    final clamped = day.clamp(1, 7);
    if (clamped == 3) return 2;
    if (clamped == 5) return 3;
    return 0;
  }

  /// Возвращает количество золотых ключей за указанный день:
  /// * 7-й день: 1 золотой ключ;
  /// * остальные дни: 0.
  static int getGoldKeysForDay(int day) {
    final clamped = day.clamp(1, 7);
    if (clamped == 7) return 3;
    return 0;
  }

  /// Награда в монетах за сегодняшний день
  int get todayRewardAmount => getRewardForDay(todayStreakDay);

  /// Серебряные ключи за сегодняшний день
  int get todaySilverKeysAmount => getSilverKeysForDay(todayStreakDay);

  /// Золотые ключи за сегодняшний день
  int get todayGoldKeysAmount => getGoldKeysForDay(todayStreakDay);

  /// Получить награду за сегодняшний день.
  ///
  /// Проверяет мировое время и защиту от отката, начисляет монеты и ключи в [PlayerCoinsService],
  /// обновляет стрик и дату, сохраняет данные.
  /// Возвращает количество начисленных монет (0, если уже получено или время скомпрометировано).
  Future<int> claimToday() async {
    _lastErrorMessage = null;

    // 1. Попытка фоновой синхронизации мирового времени, если доступно
    if (!WorldTimeService.instance.isSynchronized) {
      await WorldTimeService.instance.sync();
    }

    // 2. Защита от перевода часов назад
    if (isRollbackDetected) {
      _lastErrorMessage =
          'Обнаружен перевод времени назад. Пожалуйста, восстановите правильное время на устройстве.';
      notifyListeners();
      return 0;
    }

    // 3. Если награда уже забрана сегодня
    if (!canClaimToday) return 0;

    await load();
    await PlayerCoinsService.instance.load();

    final dayToClaim = todayStreakDay;
    final reward = getRewardForDay(dayToClaim);
    final silverKeys = getSilverKeysForDay(dayToClaim);
    final goldKeys = getGoldKeysForDay(dayToClaim);
    final claimTimeUtc = WorldTimeService.instance.nowUtc;

    _streak = dayToClaim;
    _lastClaimDate = todayMskKey;
    _lastClaimTimestampMs = claimTimeUtc.millisecondsSinceEpoch;
    _lastErrorMessage = null;

    PlayerCoinsService.instance.applyDelta(reward);
    if (silverKeys > 0) {
      PlayerCoinsService.instance.applySilverKeysDelta(silverKeys);
    }
    if (goldKeys > 0) {
      PlayerCoinsService.instance.applyGoldKeysDelta(goldKeys);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    await prefs.setInt(_storageKeyStreak, _streak);
    await prefs.setInt(_storageKeyLastClaimTimestamp, _lastClaimTimestampMs!);

    await WorldTimeService.instance.recordKnownWorldTime(claimTimeUtc);

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
    _lastClaimTimestampMs = yesterday.millisecondsSinceEpoch;
    _lastErrorMessage = null;
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    await prefs.setInt(_storageKeyLastClaimTimestamp, _lastClaimTimestampMs!);
    notifyListeners();
  }

  /// Сбросить стрик полностью в начальное состояние
  Future<void> debugResetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _lastClaimDate = null;
    _streak = 0;
    _lastClaimTimestampMs = null;
    _lastErrorMessage = null;
    await prefs.remove(_storageKeyLastClaimDate);
    await prefs.remove(_storageKeyStreak);
    await prefs.remove(_storageKeyLastClaimTimestamp);
    notifyListeners();
  }

  /// Задать конкретный день стрика (1..7)
  Future<void> debugSetStreak(int streakDay, {bool claimedToday = true}) async {
    final prefs = await SharedPreferences.getInstance();
    _streak = streakDay.clamp(1, 7);
    _lastErrorMessage = null;
    if (claimedToday) {
      _lastClaimDate = todayMskKey;
      _lastClaimTimestampMs =
          WorldTimeService.instance.nowUtc.millisecondsSinceEpoch;
    } else {
      final yesterday = todayMskDate.subtract(const Duration(days: 1));
      final y = yesterday.year.toString().padLeft(4, '0');
      final m = yesterday.month.toString().padLeft(2, '0');
      final d = yesterday.day.toString().padLeft(2, '0');
      _lastClaimDate = '$y-$m-$d';
      _lastClaimTimestampMs = yesterday.millisecondsSinceEpoch;
    }
    await prefs.setString(_storageKeyLastClaimDate, _lastClaimDate!);
    await prefs.setInt(_storageKeyStreak, _streak);
    await prefs.setInt(_storageKeyLastClaimTimestamp, _lastClaimTimestampMs!);
    notifyListeners();
  }
}
