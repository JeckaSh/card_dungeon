import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Запись об одном завершённом забеге.
class RunRecord {
  RunRecord({
    required this.endedAt,
    required this.cardsPassed,
    required this.dungeonLevel,
    required this.coins,
    required this.isVictory,
    required this.journal,
  });

  /// Время окончания забега (Unix ms)
  final DateTime endedAt;

  /// Сколько карточек пройдено
  final int cardsPassed;

  /// На каком уровне подземелья закончился забег
  final int dungeonLevel;

  /// Монеты, заработанные за забег
  final int coins;

  /// true — победа, false — поражение
  final bool isVictory;

  /// Записи дневника героя за забег
  final List<String> journal;

  Map<String, dynamic> toJson() => {
        'endedAt': endedAt.millisecondsSinceEpoch,
        'cardsPassed': cardsPassed,
        'dungeonLevel': dungeonLevel,
        'coins': coins,
        'isVictory': isVictory,
        'journal': journal,
      };

  factory RunRecord.fromJson(Map<String, dynamic> json) => RunRecord(
        endedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['endedAt'] as int?) ?? 0,
        ),
        cardsPassed: (json['cardsPassed'] as int?) ?? 0,
        dungeonLevel: (json['dungeonLevel'] as int?) ?? 1,
        coins: (json['coins'] as int?) ?? 0,
        isVictory: (json['isVictory'] as bool?) ?? false,
        journal:
            (json['journal'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}

/// Сервис хроники — хранит последние [maxRuns] записей о забегах.
class RunChronicleService {
  RunChronicleService._();
  static final RunChronicleService instance = RunChronicleService._();

  static const _storageKey = 'run_chronicle';
  static const maxRuns = 5;

  final List<RunRecord> _records = [];
  bool _loaded = false;

  /// Последние забеги (от новейшего к старейшему).
  List<RunRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _records.addAll(
          list.map((e) => RunRecord.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        // игнорируем повреждённые данные
      }
    }
    _loaded = true;
  }

  /// Добавляет запись о завершённом забеге и сохраняет на диск.
  Future<void> addRecord(RunRecord record) async {
    await load();
    _records.insert(0, record);
    if (_records.length > maxRuns) {
      _records.removeRange(maxRuns, _records.length);
    }
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Сброс хроники (для тестов / отладки).
  Future<void> clear() async {
    _records.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
