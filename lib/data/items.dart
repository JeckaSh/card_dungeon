import 'dart:math';
import 'package:flutter/material.dart';

import '../models/item_card.dart';

const List<ItemCard> allItemCards = [
  ItemCard(
    id: 'potion_heal',
    title: 'Зелье лечения',
    description: 'Восстанавливает +2 здоровья',
    effectType: ItemEffectType.heal,
    value: 2,
    icon: Icons.favorite,
    color: Color(0xFFE94560),
  ),
  ItemCard(
    id: 'potion_attack',
    title: 'Зелье атаки',
    description: 'Увеличивает атаку на +2',
    effectType: ItemEffectType.attack,
    value: 2,
    icon: Icons.flash_on,
    color: Color(0xFFF5A623),
  ),
  ItemCard(
    id: 'scroll_skip',
    title: 'Пропуск хода',
    description: 'Пропускает текущую карточку без последствий',
    effectType: ItemEffectType.skip,
    value: 0,
    icon: Icons.fast_forward_rounded,
    color: Color(0xFF9C27B0),
  ),
  ItemCard(
    id: 'elixir_life',
    title: 'Эликсир жизни',
    description: 'Восстанавливает +4 здоровья',
    effectType: ItemEffectType.heal,
    value: 4,
    icon: Icons.healing,
    color: Color(0xFF4CAF50),
  ),
];

ItemCard getRandomItemCard(Random random) {
  return allItemCards[random.nextInt(allItemCards.length)];
}

ItemCard? getRandomUnlockedItemCard(Random random, Set<String> unlockedIds) {
  final unlockedCards = allItemCards.where((item) => unlockedIds.contains(item.id)).toList();
  if (unlockedCards.isEmpty) return null;
  return unlockedCards[random.nextInt(unlockedCards.length)];
}
