import 'package:flutter/material.dart';

enum ItemEffectType {
  heal,
  attack,
  skip,
  shield,
  invertNext,
  revealChoice,
  rewind,
  thornmail,
  transmute,
  shadowPact,
  greedMagnet,
  diceOfFate,
  smokeBomb,
  bribery,
}

class ItemCard {
  const ItemCard({
    required this.id,
    required this.title,
    required this.description,
    required this.effectType,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final ItemEffectType effectType;
  final int value;
  final IconData icon;
  final Color color;
}
