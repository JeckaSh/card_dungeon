enum EventType {
  monster,
  trap,
  treasure,
  merchant,
  rest,
  mystery,
  boss,
}

enum StatusEffectType {
  poison,
  bleed,
  blindness,
  midasCurse,
}

extension StatusEffectTypeExtension on StatusEffectType {
  String get label {
    switch (this) {
      case StatusEffectType.poison:
        return 'Отравление';
      case StatusEffectType.bleed:
        return 'Кровотечение';
      case StatusEffectType.blindness:
        return 'Слепота';
      case StatusEffectType.midasCurse:
        return 'Проклятие Мидаса';
    }
  }

  String get icon {
    switch (this) {
      case StatusEffectType.poison:
        return '🧪';
      case StatusEffectType.bleed:
        return '🩸';
      case StatusEffectType.blindness:
        return '👁️';
      case StatusEffectType.midasCurse:
        return '💰';
    }
  }
}

/// Идентификаторы подземелий для привязки карточек событий.
class DungeonId {
  /// Карты, доступные в любом подземелье (сокровища, торговцы и т.д.)
  static const String common = 'common';

  /// Проклятый лес
  static const String cursedForest = 'cursed_forest';

  /// Проверка, является ли карточка общей для всех подземелий
  static bool isCommon(String id) =>
      id == common || id == 'общий' || id == 'all';

  /// Читаемое название подземелья для интерфейса
  static String getLabel(String id) {
    if (isCommon(id)) return 'Общий';
    if (id == cursedForest) return 'Проклятый лес';
    return id;
  }
}

class CardChoice {
  const CardChoice({
    required this.label,
    this.healthDelta = 0,
    this.attackDelta = 0,
    this.coinsDelta = 0,
    this.givesRandomItem = false,
    this.statusEffect,
    this.statusChance = 0.0,
  });

  final String label;
  final int healthDelta;
  final int attackDelta;
  final int coinsDelta;
  final bool givesRandomItem;
  final StatusEffectType? statusEffect;
  final double statusChance;
}

class EventCard {
  const EventCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.leftChoice,
    required this.rightChoice,
    this.level = 1,
    this.dungeonId = DungeonId.cursedForest,
  });

  final String id;
  final EventType type;
  final String title;
  final String description;
  final CardChoice leftChoice;
  final CardChoice rightChoice;

  /// Уровень подземелья, на котором встречается карточка (1-3).
  /// Для боссов — номер уровня, на котором они появляются.
  final int level;

  /// Третий атрибут: идентификатор подземелья, в котором может встретиться карта.
  /// [DungeonId.common] ('common' или 'общий') означает, что карта встречается в любом подземелье.
  final String dungeonId;

  /// Алиас для [dungeonId]
  String get dungeon => dungeonId;

  /// Является ли карта общей для всех подземелий
  bool get isCommonDungeon => DungeonId.isCommon(dungeonId);

  /// Читаемое отображение типа подземелья
  String get dungeonLabel => DungeonId.getLabel(dungeonId);

  /// Доступна ли карточка в указанном подземелье
  bool isAvailableInDungeon(String targetDungeonId) {
    return isCommonDungeon || dungeonId == targetDungeonId;
  }

  bool get isBoss => type == EventType.boss;
}
