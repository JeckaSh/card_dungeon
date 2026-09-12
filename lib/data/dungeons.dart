import 'package:flutter/material.dart';

import '../models/dungeon.dart';

/// Подземелье по умолчанию: «Проклятый лес»
const Dungeon cursedForestDungeon = Dungeon(
  id: 'cursed_forest',
  name: 'Проклятый лес',
  description:
      'Мрачная чаща, окутанная древней магией и кишащая опасными тварями. Ветви шепчут зловещие заклятия, а тропы меняются с каждым шагом. В этом подземелье ровно 3 уровня испытаний с могущественными боссами в конце каждого уровня.',
  levelsCount: 3,
  icon: Icons.forest_rounded,
  accentColor: Color(0xFF4CAF50),
  isAvailable: true,
);

/// Будущее подземелье (в разработке) для демонстрации расширяемости
const Dungeon catacombsDungeon = Dungeon(
  id: 'catacombs',
  name: 'Заброшенные катакомбы',
  description:
      'Древние подземные лабиринты забытого склепа. Полны скелетов, ядовитых ловушек и древних тайн. 4 уровня испытаний.',
  levelsCount: 4,
  icon: Icons.castle_rounded,
  accentColor: Color(0xFFAB47BC),
  isAvailable: false,
);

/// Список всех подземелий игры
const List<Dungeon> allDungeons = [
  cursedForestDungeon,
  catacombsDungeon,
];

/// Возвращает подземелье по его id или [cursedForestDungeon] по умолчанию
Dungeon getDungeonById(String id) {
  return allDungeons.firstWhere(
    (d) => d.id == id,
    orElse: () => cursedForestDungeon,
  );
}
