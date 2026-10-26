import 'dart:convert';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dungeons.dart';
import '../models/event_card.dart';
import 'daily_reward_service.dart';
import 'player_coins_service.dart';
import 'world_time_service.dart';

/// Типы заданий (ежедневных и еженедельных).
enum DailyQuestType {
  /// Сыграть подземелья (до проигрыша или победы)
  dungeonRuns,

  /// Убить боссов
  killBosses,

  /// Пройти подземелье (победа)
  clearDungeon,

  /// Встретить карты определенного типа
  encounterCards,

  /// Сыграть определенное подземелье (до проигрыша или победы)
  specificDungeonRuns,
}

/// Модель задания (ежедневного или еженедельного).
class DailyQuest {
  DailyQuest({
    required this.id,
    required this.type,
    required this.target,
    this.progress = 0,
    this.isClaimed = false,
    this.targetEventType,
    this.targetDungeonId,
    this.isWeekly = false,
    int? rewardCoins,
  }) : rewardCoins =
           rewardCoins ??
           (isWeekly ? defaultWeeklyRewardCoins : defaultDailyRewardCoins);

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final isWeekly = json['isWeekly'] as bool? ?? false;
    return DailyQuest(
      id: json['id'] as String,
      type: DailyQuestType.values.byName(json['type'] as String),
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
      targetEventType: json['targetEventType'] != null
          ? EventType.values.byName(json['targetEventType'] as String)
          : null,
      targetDungeonId: json['targetDungeonId'] as String?,
      isWeekly: isWeekly,
      rewardCoins:
          json['rewardCoins'] as int? ??
          (isWeekly ? defaultWeeklyRewardCoins : defaultDailyRewardCoins),
    );
  }

  final String id;
  final DailyQuestType type;
  final int target;
  int progress;
  bool isClaimed;
  final EventType? targetEventType;
  final String? targetDungeonId;
  final bool isWeekly;
  final int rewardCoins;

  /// Базовые награды
  static const int defaultDailyRewardCoins = 150;
  static const int defaultWeeklyRewardCoins = 500;

  bool get isCompleted => progress >= target;
  bool get canClaim => isCompleted && !isClaimed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'target': target,
    'progress': progress,
    'isClaimed': isClaimed,
    'targetEventType': targetEventType?.name,
    'targetDungeonId': targetDungeonId,
    'isWeekly': isWeekly,
    'rewardCoins': rewardCoins,
  };
}

/// Сервис управления ежедневными и еженедельными заданиями.
///
/// Правила:
/// * Ежедневные задания (2 шт.):
///   1. Сыграть 1-3 подземелий;
///   2. Убить 3-5 боссов;
///   3. Пройти 1 подземелье;
///   4. Встретить 30 карт определенного типа;
///   5. Сыграть определенное подземелье 1-3 раза.
///   Награда: 150 монет за каждое. Обновление в 00:00 (МСК).
///
/// * Еженедельные задания (2 шт.):
///   Повторяют типы ежедневных заданий, но усложнены в 3-5 раз.
///   Награда: 500 монет за каждое задание.
///   Обновление каждый понедельник в 00:00 (МСК).
class DailyQuestsService extends ChangeNotifier {
  DailyQuestsService._();

  /// Глобальный синглтон сервиса
  static final DailyQuestsService instance = DailyQuestsService._();

  static const _storageKeyDate = 'daily_quests_date';
  static const _storageKeyList = 'daily_quests_list';
  static const _storageKeyDailyBonusClaimed = 'daily_quests_bonus_claimed';
  static const _storageKeyWeeklyDate = 'weekly_quests_date';
  static const _storageKeyWeeklyList = 'weekly_quests_list';
  static const _storageKeyWeeklyBonusClaimed = 'weekly_quests_bonus_claimed';

  /// Количество серебряных ключей за выполнение всех ежедневных заданий дня
  static const int allDailyQuestsSilverKeysReward = 2;

  /// Количество золотых ключей за выполнение всех еженедельных заданий недели
  static const int allWeeklyQuestsGoldKeysReward = 3;

  String? _dateKey;
  String? _weeklyDateKey;
  List<DailyQuest> _quests = [];
  List<DailyQuest> _weeklyQuests = [];
  bool _isDailyBonusClaimed = false;
  bool _isWeeklyBonusClaimed = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<DailyQuest> get quests => List.unmodifiable(_quests);
  List<DailyQuest> get weeklyQuests => List.unmodifiable(_weeklyQuests);
  String? get dateKey => _dateKey;
  String? get weeklyDateKey => _weeklyDateKey;

  /// Получена ли награда за выполнение всех ежедневных заданий
  bool get isDailyBonusClaimed => _isDailyBonusClaimed;

  /// Получена ли награда за выполнение всех еженедельных заданий
  bool get isWeeklyBonusClaimed => _isWeeklyBonusClaimed;

  /// Выполнены ли все ежедневные задания
  bool get areAllDailyQuestsCompleted =>
      _quests.isNotEmpty && _quests.every((q) => q.isCompleted);

  /// Можно ли забрать награду за выполнение всех ежедневных заданий (2 серебряных ключа)
  bool get canClaimDailyBonus =>
      areAllDailyQuestsCompleted && !_isDailyBonusClaimed;

  /// Выполнены ли все еженедельные задания
  bool get areAllWeeklyQuestsCompleted =>
      _weeklyQuests.isNotEmpty && _weeklyQuests.every((q) => q.isCompleted);

  /// Можно ли забрать супер-награду за выполнение всех еженедельных заданий (2 золотых ключа)
  bool get canClaimWeeklyBonus =>
      areAllWeeklyQuestsCompleted && !_isWeeklyBonusClaimed;

  /// Есть ли хотя бы одно завершённое задание или бонус за все задания,
  /// награда за которое ещё не забрана
  bool get hasUnclaimedCompletedQuests =>
      _quests.any((q) => q.canClaim) ||
      _weeklyQuests.any((q) => q.canClaim) ||
      canClaimDailyBonus ||
      canClaimWeeklyBonus;

  /// Загружает сохранённые задания или генерирует новые
  Future<void> load() async {
    final todayKey = DailyRewardService.todayMskKey;
    final thisWeekKey = WorldTimeService.instance.thisWeekMskKey;

    if (_loaded && _dateKey == todayKey && _weeklyDateKey == thisWeekKey) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // ── Загрузка ежедневных заданий ──────────────────────────────────────────
    final savedDate = prefs.getString(_storageKeyDate);
    final savedJson = prefs.getString(_storageKeyList);

    if (savedDate != null && savedJson != null) {
      try {
        final decoded = jsonDecode(savedJson) as List<dynamic>;
        final parsedQuests = decoded
            .map((item) => DailyQuest.fromJson(item as Map<String, dynamic>))
            .toList();

        if (savedDate == todayKey) {
          _quests = parsedQuests;
          _dateKey = todayKey;
          _isDailyBonusClaimed =
              prefs.getBool(_storageKeyDailyBonusClaimed) ?? false;
        } else if (todayKey.compareTo(savedDate) < 0 ||
            WorldTimeService.instance.isRollbackDetected) {
          _quests = parsedQuests;
          _dateKey = savedDate;
          _isDailyBonusClaimed =
              prefs.getBool(_storageKeyDailyBonusClaimed) ?? false;
        } else {
          // Переход на новый день
          if (!WorldTimeService.instance.isSynchronized) {
            await WorldTimeService.instance.sync();
          }
          if (WorldTimeService.instance.isSynchronized) {
            _generateDailyQuests(todayKey);
          } else {
            _quests = parsedQuests;
            _dateKey = savedDate;
            _isDailyBonusClaimed =
                prefs.getBool(_storageKeyDailyBonusClaimed) ?? false;
          }
        }
      } catch (_) {
        _generateDailyQuests(todayKey);
      }
    } else {
      _generateDailyQuests(todayKey);
    }

    // ── Загрузка еженедельных заданий ─────────────────────────────────────────
    final savedWeeklyDate = prefs.getString(_storageKeyWeeklyDate);
    final savedWeeklyJson = prefs.getString(_storageKeyWeeklyList);

    if (savedWeeklyDate != null && savedWeeklyJson != null) {
      try {
        final decoded = jsonDecode(savedWeeklyJson) as List<dynamic>;
        final parsedWeekly = decoded
            .map((item) => DailyQuest.fromJson(item as Map<String, dynamic>))
            .toList();

        if (savedWeeklyDate == thisWeekKey) {
          _weeklyQuests = parsedWeekly;
          _weeklyDateKey = thisWeekKey;
          _isWeeklyBonusClaimed =
              prefs.getBool(_storageKeyWeeklyBonusClaimed) ?? false;
        } else if (thisWeekKey.compareTo(savedWeeklyDate) < 0 ||
            WorldTimeService.instance.isRollbackDetected) {
          _weeklyQuests = parsedWeekly;
          _weeklyDateKey = savedWeeklyDate;
          _isWeeklyBonusClaimed =
              prefs.getBool(_storageKeyWeeklyBonusClaimed) ?? false;
        } else {
          // Переход на новую неделю
          if (!WorldTimeService.instance.isSynchronized) {
            await WorldTimeService.instance.sync();
          }
          if (WorldTimeService.instance.isSynchronized) {
            _generateWeeklyQuests(thisWeekKey);
          } else {
            _weeklyQuests = parsedWeekly;
            _weeklyDateKey = savedWeeklyDate;
            _isWeeklyBonusClaimed =
                prefs.getBool(_storageKeyWeeklyBonusClaimed) ?? false;
          }
        }
      } catch (_) {
        _generateWeeklyQuests(thisWeekKey);
      }
    } else {
      _generateWeeklyQuests(thisWeekKey);
    }

    await _save();
    _loaded = true;
    notifyListeners();
  }

  /// Проверяет наступление нового дня / недели и при необходимости обновляет список
  Future<void> checkDayTransition() async {
    final todayKey = DailyRewardService.todayMskKey;
    final thisWeekKey = WorldTimeService.instance.thisWeekMskKey;

    bool needsDailyUpdate = _dateKey != null && _dateKey != todayKey;
    bool needsWeeklyUpdate =
        _weeklyDateKey != null && _weeklyDateKey != thisWeekKey;

    if (!needsDailyUpdate && !needsWeeklyUpdate) return;

    if (WorldTimeService.instance.isRollbackDetected) return;

    if (needsDailyUpdate && todayKey.compareTo(_dateKey!) < 0) return;
    if (needsWeeklyUpdate && thisWeekKey.compareTo(_weeklyDateKey!) < 0) return;

    if (!WorldTimeService.instance.isSynchronized) {
      await WorldTimeService.instance.sync();
    }

    if (WorldTimeService.instance.isSynchronized) {
      if (needsDailyUpdate) {
        _generateDailyQuests(todayKey);
      }
      if (needsWeeklyUpdate) {
        _generateWeeklyQuests(thisWeekKey);
      }
      await _save();
      notifyListeners();
    }
  }

  // ── Генерация ежедневных заданий ───────────────────────────────────────────

  void _generateDailyQuests(String todayKey, {Random? customRandom}) {
    final rng = customRandom ?? Random();
    final availableTypes = List<DailyQuestType>.from(DailyQuestType.values)
      ..shuffle(rng);
    final chosenTypes = availableTypes.take(2).toList();

    _quests = chosenTypes.map((type) => _createDailyQuest(type, rng)).toList();
    _dateKey = todayKey;
    _isDailyBonusClaimed = false;
  }

  DailyQuest _createDailyQuest(DailyQuestType type, Random rng) {
    switch (type) {
      case DailyQuestType.dungeonRuns:
        final target = 1 + rng.nextInt(3);
        return DailyQuest(
          id: 'runs_$target',
          type: type,
          target: target,
          isWeekly: false,
          rewardCoins: DailyQuest.defaultDailyRewardCoins,
        );
      case DailyQuestType.killBosses:
        final target = 1 + rng.nextInt(3);
        return DailyQuest(
          id: 'bosses_$target',
          type: type,
          target: target,
          isWeekly: false,
          rewardCoins: DailyQuest.defaultDailyRewardCoins,
        );
      case DailyQuestType.clearDungeon:
        return DailyQuest(
          id: 'clear_1',
          type: type,
          target: 1,
          isWeekly: false,
          rewardCoins: DailyQuest.defaultDailyRewardCoins,
        );
      case DailyQuestType.encounterCards:
        const possibleEventTypes = [
          EventType.monster,
          EventType.trap,
          EventType.treasure,
          EventType.merchant,
          EventType.rest,
          EventType.mystery,
        ];
        final eventType =
            possibleEventTypes[rng.nextInt(possibleEventTypes.length)];
        return DailyQuest(
          id: 'cards_${eventType.name}',
          type: type,
          target: 30,
          targetEventType: eventType,
          isWeekly: false,
          rewardCoins: DailyQuest.defaultDailyRewardCoins,
        );
      case DailyQuestType.specificDungeonRuns:
        final available = allDungeons.where((d) => d.isAvailable).toList();
        final dungeon = available[rng.nextInt(available.length)];
        final target = 1 + rng.nextInt(3);
        return DailyQuest(
          id: 'dungeon_${dungeon.id}_$target',
          type: type,
          target: target,
          targetDungeonId: dungeon.id,
          isWeekly: false,
          rewardCoins: DailyQuest.defaultDailyRewardCoins,
        );
    }
  }

  // ── Генерация еженедельных заданий ─────────────────────────────────────────

  void _generateWeeklyQuests(String weekKey, {Random? customRandom}) {
    final rng = customRandom ?? Random();
    final availableTypes = List<DailyQuestType>.from(DailyQuestType.values)
      ..shuffle(rng);
    final chosenTypes = availableTypes.take(2).toList();

    _weeklyQuests = chosenTypes
        .map((type) => _createWeeklyQuest(type, rng))
        .toList();
    _weeklyDateKey = weekKey;
    _isWeeklyBonusClaimed = false;
  }

  DailyQuest _createWeeklyQuest(DailyQuestType type, Random rng) {
    switch (type) {
      case DailyQuestType.dungeonRuns:
        // В 3-5 раз сложнее: 5-10 забегов
        final target = 3 + rng.nextInt(5);
        return DailyQuest(
          id: 'weekly_runs_$target',
          type: type,
          target: target,
          isWeekly: true,
          rewardCoins: DailyQuest.defaultWeeklyRewardCoins,
        );
      case DailyQuestType.killBosses:
        // В 3-5 раз сложнее: 12-20 боссов
        final target = 3 + rng.nextInt(5);
        return DailyQuest(
          id: 'weekly_bosses_$target',
          type: type,
          target: target,
          isWeekly: true,
          rewardCoins: DailyQuest.defaultWeeklyRewardCoins,
        );
      case DailyQuestType.clearDungeon:
        // В 3-5 раз сложнее: 3-5 прохождений
        final target = 3 + rng.nextInt(3);
        return DailyQuest(
          id: 'weekly_clear_$target',
          type: type,
          target: target,
          isWeekly: true,
          rewardCoins: DailyQuest.defaultWeeklyRewardCoins,
        );
      case DailyQuestType.encounterCards:
        // В 3-5 раз сложнее: 90-150 карт
        const possibleEventTypes = [
          EventType.monster,
          EventType.trap,
          EventType.treasure,
          EventType.merchant,
          EventType.rest,
          EventType.mystery,
        ];
        final eventType =
            possibleEventTypes[rng.nextInt(possibleEventTypes.length)];
        const cardTargets = [90, 120, 150];
        final target = cardTargets[rng.nextInt(cardTargets.length)];
        return DailyQuest(
          id: 'weekly_cards_${eventType.name}_$target',
          type: type,
          target: target,
          targetEventType: eventType,
          isWeekly: true,
          rewardCoins: DailyQuest.defaultWeeklyRewardCoins,
        );
      case DailyQuestType.specificDungeonRuns:
        // В 3-5 раз сложнее: 5-10 забегов в указанном подземелье
        final available = allDungeons.where((d) => d.isAvailable).toList();
        final dungeon = available[rng.nextInt(available.length)];
        final target = 3 + rng.nextInt(5);
        return DailyQuest(
          id: 'weekly_dungeon_${dungeon.id}_$target',
          type: type,
          target: target,
          targetDungeonId: dungeon.id,
          isWeekly: true,
          rewardCoins: DailyQuest.defaultWeeklyRewardCoins,
        );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dateKey != null) {
      await prefs.setString(_storageKeyDate, _dateKey!);
    }
    final encodedDaily = jsonEncode(_quests.map((q) => q.toJson()).toList());
    await prefs.setString(_storageKeyList, encodedDaily);
    await prefs.setBool(_storageKeyDailyBonusClaimed, _isDailyBonusClaimed);

    if (_weeklyDateKey != null) {
      await prefs.setString(_storageKeyWeeklyDate, _weeklyDateKey!);
    }
    final encodedWeekly = jsonEncode(
      _weeklyQuests.map((q) => q.toJson()).toList(),
    );
    await prefs.setString(_storageKeyWeeklyList, encodedWeekly);
    await prefs.setBool(_storageKeyWeeklyBonusClaimed, _isWeeklyBonusClaimed);
  }

  // ─── События игрового процесса ─────────────────────────────────────────────

  /// Вызывается при завершении подземелья (победа или поражение)
  void onDungeonFinished({required bool isVictory, String? dungeonId}) {
    bool changed = false;
    for (final q in [..._quests, ..._weeklyQuests]) {
      if (q.type == DailyQuestType.dungeonRuns && !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
      }
      if (isVictory &&
          q.type == DailyQuestType.clearDungeon &&
          !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
      }
      if (q.type == DailyQuestType.specificDungeonRuns && !q.isCompleted) {
        if (q.targetDungeonId == null || q.targetDungeonId == dungeonId) {
          q.progress = (q.progress + 1).clamp(0, q.target);
          changed = true;
        }
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  /// Вызывается при победе над боссом
  void onBossKilled() {
    bool changed = false;
    for (final q in [..._quests, ..._weeklyQuests]) {
      if (q.type == DailyQuestType.killBosses && !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  /// Вызывается при открытии/встрече карты события
  void onCardEncountered(EventType cardType) {
    bool changed = false;
    for (final q in [..._quests, ..._weeklyQuests]) {
      if (q.type == DailyQuestType.encounterCards &&
          q.targetEventType == cardType &&
          !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  /// Получить награду за выполненное задание (150 монет за ежедневное, 500 за еженедельное)
  Future<int> claimQuest(String questId) async {
    DailyQuest? quest;
    for (final q in _quests) {
      if (q.id == questId) {
        quest = q;
        break;
      }
    }
    if (quest == null) {
      for (final q in _weeklyQuests) {
        if (q.id == questId) {
          quest = q;
          break;
        }
      }
    }

    if (quest == null || !quest.canClaim) return 0;

    await PlayerCoinsService.instance.load();
    quest.isClaimed = true;
    final reward = quest.rewardCoins;
    PlayerCoinsService.instance.applyDelta(reward);

    await _save();
    notifyListeners();
    return reward;
  }

  /// Забрать награду за выполнение всех ежедневных заданий (2 серебряных ключа).
  /// Возвращает количество выданных ключей (2 или 0 если забрать нельзя).
  Future<int> claimDailyAllCompletedBonus() async {
    if (!canClaimDailyBonus) return 0;

    await PlayerCoinsService.instance.load();
    _isDailyBonusClaimed = true;
    PlayerCoinsService.instance.applySilverKeysDelta(
      allDailyQuestsSilverKeysReward,
    );

    await _save();
    notifyListeners();
    return allDailyQuestsSilverKeysReward;
  }

  /// Забрать награду за выполнение всех еженедельных заданий (2 золотых ключа).
  /// Возвращает количество выданных ключей (2 или 0 если забрать нельзя).
  Future<int> claimWeeklyAllCompletedBonus() async {
    if (!canClaimWeeklyBonus) return 0;

    await PlayerCoinsService.instance.load();
    _isWeeklyBonusClaimed = true;
    PlayerCoinsService.instance.applyGoldKeysDelta(
      allWeeklyQuestsGoldKeysReward,
    );

    await _save();
    notifyListeners();
    return allWeeklyQuestsGoldKeysReward;
  }

  // ─── Дебаг методы для тестирования ────────────────────────────────────────

  /// Сгенерировать новые ежедневные задания для тестирования
  Future<void> debugRerollQuests() async {
    _generateDailyQuests(DailyRewardService.todayMskKey);
    await _save();
    notifyListeners();
  }

  /// Сгенерировать новые еженедельные задания для тестирования
  Future<void> debugRerollWeeklyQuests() async {
    _generateWeeklyQuests(WorldTimeService.instance.thisWeekMskKey);
    await _save();
    notifyListeners();
  }

  /// Мгновенно выполнить все задания (для проверки кнопок сбора наград)
  Future<void> debugCompleteAll() async {
    for (final q in _quests) {
      q.progress = q.target;
    }
    for (final q in _weeklyQuests) {
      q.progress = q.target;
    }
    await _save();
    notifyListeners();
  }

  /// Сбросить прогресс всех заданий в 0
  Future<void> debugResetProgress() async {
    for (final q in _quests) {
      q.progress = 0;
      q.isClaimed = false;
    }
    for (final q in _weeklyQuests) {
      q.progress = 0;
      q.isClaimed = false;
    }
    _isDailyBonusClaimed = false;
    _isWeeklyBonusClaimed = false;
    await _save();
    notifyListeners();
  }

  /// Установить кастомный список заданий для тестов
  void setQuestsForTesting(
    List<DailyQuest> quests, {
    List<DailyQuest>? weeklyQuests,
    bool dailyBonusClaimed = false,
    bool weeklyBonusClaimed = false,
  }) {
    _quests = quests;
    _isDailyBonusClaimed = dailyBonusClaimed;
    if (weeklyQuests != null) {
      _weeklyQuests = weeklyQuests;
      _weeklyDateKey = WorldTimeService.instance.thisWeekMskKey;
    }
    _isWeeklyBonusClaimed = weeklyBonusClaimed;
    _dateKey = DailyRewardService.todayMskKey;
    _loaded = true;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    final binding = WidgetsBinding.instance;
    if (binding.buildOwner?.debugBuilding == true ||
        binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        super.notifyListeners();
      });
    } else {
      super.notifyListeners();
    }
  }
}
