/// Категории событий, встречающихся в подземелье.
///
/// Каждая категория имеет своё оформление (цвет, иконку) в `event_style.dart`:
/// * [monster] — схватки с врагами и монстрами;
/// * [trap] — ловушки, опасные механизмы, препятствия;
/// * [treasure] — сундуки, тайники и сокровищницы;
/// * [merchant] — торговцы снаряжением и услугами;
/// * [rest] — привалы, исцеляющие святилища, фонтаны;
/// * [mystery] — загадки, алтари, странные сущности;
/// * [boss] — финальный босс этажа (каждые 20 карт).
enum EventType {
  /// Монстр / враг
  monster,

  /// Ловушка
  trap,

  /// Сокровище
  treasure,

  /// Торговец
  merchant,

  /// Привал / отдых
  rest,

  /// Тайна / алтарь / магия
  mystery,

  /// Босс уровня
  boss,
}

/// Периодические негативные эффекты (DoT / дебаффы), накладываемые на героя.
///
/// Каждый эффект действует 3 хода:
/// * [poison] — отравление (-1 ❤ каждый ход);
/// * [bleed] — сильное кровотечение (-2 ❤ каждый ход);
/// * [blindness] — скрывает числовые последствия карточек от игрока;
/// * [midasCurse] — проклятие золота: получаемые за выбор монеты обращаются в пыль (0 🪙).
enum StatusEffectType {
  /// Отравление (-1 HP в ход)
  poison,

  /// Кровотечение (-2 HP в ход)
  bleed,

  /// Слепота (скрыты исходы свайпов)
  blindness,

  /// Проклятие Мидаса (блокирует получение золота)
  midasCurse,
}

/// Вспомогательное расширение для отображения названий и эмодзи статусов.
extension StatusEffectTypeExtension on StatusEffectType {
  /// Читаемое название статуса на русском языке
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

  /// Эмодзи-иконка статуса
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

/// Описание одного из вариантов выбора на карточке события (влево или вправо).
///
/// Задаёт текст действия на плашке выбора и числовые изменения параметров героя.
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

  /// Текст действия (например, «Атаковать», «Убежать», «Купить зелье»)
  final String label;

  /// Изменение здоровья героя (положительное = лечение, отрицательное = урон)
  final int healthDelta;

  /// Изменение силы атаки (положительное = бафф, отрицательное = потеря силы)
  final int attackDelta;

  /// Изменение баланса монет (положительное = награда, отрицательное = стоимость)
  final int coinsDelta;

  /// Выдавать ли случайный предмет из открытых в коллекции при совершении выбора
  final bool givesRandomItem;

  /// Статус-эффект, который может быть наложен на героя при выборе
  final StatusEffectType? statusEffect;

  /// Вероятность наложения статуса [statusEffect] от 0.0 до 1.0 (например, 0.5 = 50%)
  final double statusChance;
}

/// Модель карточки игрового события или босса.
///
/// Каждая карточка представляет собой отдельную встречу в подземелье:
/// игрок выбирает между [leftChoice] (свайп влево) и [rightChoice] (свайп вправо).
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
