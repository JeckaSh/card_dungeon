import 'package:flutter/material.dart';

/// Модель подземелья.
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
