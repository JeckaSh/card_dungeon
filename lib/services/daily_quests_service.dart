import 'dart:convert';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_card.dart';
import 'daily_reward_service.dart';
import 'player_coins_service.dart';

/// Типы ежедневных заданий.
enum DailyQuestType {
  /// Сыграть 1-3 подземелий (до проигрыша или победы)
  dungeonRuns,

  /// Убить 3-5 боссов
  killBosses,

  /// Пройти 1 подземелье (победа)
  clearDungeon,

  /// Встретить 30 карт определенного типа
  encounterCards,
}

/// Модель ежедневного задания.
class DailyQuest {
  DailyQuest({
    required this.id,
    required this.type,
    required this.target,
    this.progress = 0,
    this.isClaimed = false,
    this.targetEventType,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      type: DailyQuestType.values.byName(json['type'] as String),
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
      targetEventType: json['targetEventType'] != null
          ? EventType.values.byName(json['targetEventType'] as String)
          : null,
    );
  }

  final String id;
  final DailyQuestType type;
  final int target;
  int progress;
  bool isClaimed;
  final EventType? targetEventType;

  /// Награда в монетах за выполнение задания
  static const int rewardCoins = 150;

  bool get isCompleted => progress >= target;
  bool get canClaim => isCompleted && !isClaimed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'target': target,
        'progress': progress,
        'isClaimed': isClaimed,
        'targetEventType': targetEventType?.name,
      };
}

/// Сервис управления ежедневными заданиями.
///
/// Правила:
/// * Каждый день случайно выбираются 2 уникальных задания из 4 возможных типов:
///   1. Сыграть 1-3 подземелий (до проигрыша или победы);
///   2. Убить 3-5 боссов;
///   3. Пройти 1 подземелье;
///   4. Встретить 30 карт определенного типа (монстры, ловушки, сокровища и т.д.).
/// * Награда за каждое выполненное задание — 150 монет.
/// * Задания обновляются в полночь по московскому времени (UTC+3, MSK).
class DailyQuestsService extends ChangeNotifier {
  DailyQuestsService._();

  /// Глобальный синглтон сервиса
  static final DailyQuestsService instance = DailyQuestsService._();

  static const _storageKeyDate = 'daily_quests_date';
  static const _storageKeyList = 'daily_quests_list';

  String? _dateKey;
  List<DailyQuest> _quests = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<DailyQuest> get quests => List.unmodifiable(_quests);
  String? get dateKey => _dateKey;

  /// Есть ли хотя бы одно завершённое задание, награда за которое ещё не забрана
  bool get hasUnclaimedCompletedQuests => _quests.any((q) => q.canClaim);

  /// Загружает сохранённые задания или генерирует новые, если наступил новый день
  Future<void> load() async {
    final todayKey = DailyRewardService.todayMskKey;

    if (_loaded && _dateKey == todayKey) return;

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_storageKeyDate);
    final savedJson = prefs.getString(_storageKeyList);

    if (savedDate == todayKey && savedJson != null) {
      try {
        final decoded = jsonDecode(savedJson) as List<dynamic>;
        _quests = decoded
            .map((item) => DailyQuest.fromJson(item as Map<String, dynamic>))
            .toList();
        _dateKey = todayKey;
        _loaded = true;
        notifyListeners();
        return;
      } catch (_) {
        // Ошибка десериализации — генерируем заново
      }
    }

    // Если дата не совпадает или данных нет — генерируем 2 задания на сегодня
    _generateDailyQuests(todayKey);
    await _save();
    _loaded = true;
    notifyListeners();
  }

  /// Проверяет наступление нового дня и при необходимости обновляет список заданий
  Future<void> checkDayTransition() async {
    final todayKey = DailyRewardService.todayMskKey;
    if (_dateKey != todayKey) {
      _generateDailyQuests(todayKey);
      await _save();
      notifyListeners();
    }
  }

  /// Генерация 2 случайных уникальных заданий
  void _generateDailyQuests(String todayKey, {Random? customRandom}) {
    final rng = customRandom ?? Random();
    final availableTypes = List<DailyQuestType>.from(DailyQuestType.values)..shuffle(rng);
    final chosenTypes = availableTypes.take(2).toList();

    _quests = chosenTypes.map((type) => _createQuest(type, rng)).toList();
    _dateKey = todayKey;
  }

  DailyQuest _createQuest(DailyQuestType type, Random rng) {
    switch (type) {
      case DailyQuestType.dungeonRuns:
        // Сыграть 1-3 подземелий
        final target = 1 + rng.nextInt(3);
        return DailyQuest(
          id: 'runs_$target',
          type: type,
          target: target,
        );
      case DailyQuestType.killBosses:
        // Убить 3-5 боссов
        final target = 3 + rng.nextInt(3);
        return DailyQuest(
          id: 'bosses_$target',
          type: type,
          target: target,
        );
      case DailyQuestType.clearDungeon:
        // Пройти 1 подземелье
        return DailyQuest(
          id: 'clear_1',
          type: type,
          target: 1,
        );
      case DailyQuestType.encounterCards:
        // Встретить 30 карт определенного типа
        const possibleEventTypes = [
          EventType.monster,
          EventType.trap,
          EventType.treasure,
          EventType.merchant,
          EventType.rest,
          EventType.mystery,
        ];
        final eventType = possibleEventTypes[rng.nextInt(possibleEventTypes.length)];
        return DailyQuest(
          id: 'cards_${eventType.name}',
          type: type,
          target: 30,
          targetEventType: eventType,
        );
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dateKey != null) {
      await prefs.setString(_storageKeyDate, _dateKey!);
    }
    final encoded = jsonEncode(_quests.map((q) => q.toJson()).toList());
    await prefs.setString(_storageKeyList, encoded);
  }

  // ─── События игрового процесса ─────────────────────────────────────────────

  /// Вызывается при завершении подземелья (победа или поражение)
  void onDungeonFinished({required bool isVictory}) {
    bool changed = false;
    for (final q in _quests) {
      if (q.type == DailyQuestType.dungeonRuns && !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
      }
      if (isVictory && q.type == DailyQuestType.clearDungeon && !q.isCompleted) {
        q.progress = (q.progress + 1).clamp(0, q.target);
        changed = true;
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
    for (final q in _quests) {
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
    for (final q in _quests) {
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

  /// Получить награду за выполненное задание (150 монет)
  Future<int> claimQuest(String questId) async {
    DailyQuest? quest;
    for (final q in _quests) {
      if (q.id == questId) {
        quest = q;
        break;
      }
    }

    if (quest == null || !quest.canClaim) return 0;

    await PlayerCoinsService.instance.load();
    quest.isClaimed = true;
    PlayerCoinsService.instance.applyDelta(DailyQuest.rewardCoins);

    await _save();
    notifyListeners();
    return DailyQuest.rewardCoins;
  }

  // ─── Дебаг методы для тестирования ────────────────────────────────────────

  /// Сгенерировать новые задания для тестирования
  Future<void> debugRerollQuests() async {
    _generateDailyQuests(DailyRewardService.todayMskKey);
    await _save();
    notifyListeners();
  }

  /// Мгновенно выполнить все задания (для проверки кнопок сбора наград)
  Future<void> debugCompleteAll() async {
    for (final q in _quests) {
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
    await _save();
    notifyListeners();
  }

  /// Установить кастомный список заданий для тестов
  void setQuestsForTesting(List<DailyQuest> quests) {
    _quests = quests;
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
