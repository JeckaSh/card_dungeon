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

/// Второе подземелье: «Заброшенные катакомбы»
const Dungeon catacombsDungeon = Dungeon(
  id: 'catacombs',
  name: 'Заброшенные катакомбы',
  description:
      'Мрачные подземные лабиринты забытого некрополя. На первом этаже рыщут чумные крысы, летучие мыши и скелеты. Глубже поджидают кровожадные вампиры и ядовитые зомби, а в самой бездне таятся их чудовищные усиленные формы. 3 уровня испытаний.',
  levelsCount: 3,
  icon: Icons.castle_rounded,
  accentColor: Color(0xFFAB47BC),
  isAvailable: true,
);

/// Третье подземелье: Древние пещеры»
const Dungeon elderCavesDungeon = Dungeon(
  id: 'elderCaves',
  name: 'Древние пещеры',
  description: 'Древние пещеры, населённые гоблинами и орками',
  levelsCount: 3,
  icon: Icons.castle_rounded,
  accentColor: Color.fromARGB(255, 193, 126, 20),
  isAvailable: false,
);

/// Список всех подземелий игры.
///
/// Отображается на экране выбора локации ([DungeonSelectScreen]).
/// Чтобы открыть доступ к локации, установите `isAvailable: true`.
const List<Dungeon> allDungeons = [
  cursedForestDungeon,
  catacombsDungeon,
  elderCavesDungeon,
];

/// Возвращает подземелье по его строковому [id].
///
/// Если подземелье с таким идентификатором не найдено,
/// возвращается подземелье по умолчанию — [cursedForestDungeon].
Dungeon getDungeonById(String id) {
  return allDungeons.firstWhere(
    (d) => d.id == id,
    orElse: () => cursedForestDungeon,
  );
}
