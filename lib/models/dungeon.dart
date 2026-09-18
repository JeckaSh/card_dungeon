import 'package:flutter/material.dart';

/// Модель игрового подземелья (локации приключения).
///
/// Каждое подземелье состоит из нескольких этажей ([levelsCount]).
/// В конце каждого этажа (каждые 20 пройденных карт) игрока ожидает босс.
///
/// Чтобы добавить новое подземелье:
/// 1. Создайте строковый идентификатор в [DungeonId] (`lib/models/event_card.dart`).
/// 2. Объявите экземпляр [Dungeon] в `lib/data/dungeons.dart` и добавьте в `allDungeons`.
/// 3. Наполните подземелье картами событий в `lib/data/events.dart` с указанием `dungeonId`
///    и уровней `level: 1..levelsCount`.
/// 4. Добавьте боссов для каждого уровня в список `allBossCards` с соответствующим `dungeonId`.
class Dungeon {
  const Dungeon({
    required this.id,
    required this.name,
    required this.description,
    required this.levelsCount,
    required this.icon,
    this.accentColor = const Color(0xFF4CAF50),
    this.isAvailable = true,
  });

  /// Уникальный идентификатор подземелья (например, 'cursed_forest')
  final String id;

  /// Отображаемое название (например, 'Проклятый лес')
  final String name;

  /// Описание подземелья с особенностями и опасностями
  final String description;

  /// Количество уровней (этажей) в подземелье
  final int levelsCount;

  /// Иконка подземелья для интерфейса выбора
  final IconData icon;

  /// Цветовой акцент подземелья
  final Color accentColor;

  /// Доступно ли подземелье для выбора прямо сейчас
  final bool isAvailable;
}
