import 'dart:math';
import 'package:flutter/material.dart';

import '../models/item_card.dart';

/// Полный каталог всех доступных в игре расходуемых предметов и реликвий.
///
/// Игрок открывает эти предметы в Магазине ([ShopScreen]) за накопленные монеты.
/// Открытые предметы могут:
/// 1. Выпадать в событиях торговцев и тайников (`givesRandomItem: true`).
/// 2. Выдаваться герою на старте забега при прокачке навыка «Стартовые карты» ([PlayerStatsService.startingCardsCount]).
/// 3. Появляться в инвентаре от эффектов кубика или сделок.
const List<ItemCard> allItemCards = [
  ItemCard(
    id: 'potion_heal',
    title: 'Зелье лечения',
    description: 'Восстанавливает +4 здоровья',
    effectType: ItemEffectType.heal,
    value: 4,
    icon: Icons.healing,
    color: Color(0xFFE94560),
  ),
  ItemCard(
    id: 'potion_attack',
    title: 'Зелье атаки',
    description: 'Увеличивает атаку на +4',
    effectType: ItemEffectType.attack,
    value: 4,
    icon: Icons.flash_on,
    color: Color(0xFFF5A623),
  ),
  ItemCard(
    id: 'elixir_attack',
    title: 'Элексир атаки',
    description: 'Увеличивает атаку на +8',
    effectType: ItemEffectType.attack,
    value: 8,
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
    description: 'Восстанавливает +8 здоровья',
    effectType: ItemEffectType.heal,
    value: 8,
    icon: Icons.healing,
    color: Color(0xFF4CAF50),
  ),
  // === НОВЫЕ УНИКАЛЬНЫЕ КАРТЫ ===
  ItemCard(
    id: 'runic_shield',
    title: 'Рунический щит',
    description: 'Следующий урон по здоровью будет полностью поглощён.',
    effectType: ItemEffectType.shield,
    value: 1,
    icon: Icons.shield_outlined,
    color: Color(0xFF29B6F6),
  ),
  ItemCard(
    id: 'mirror_distortion',
    title: 'Зеркало искажения',
    description: 'Следующий ход: все потери превратятся в приобретения.',
    effectType: ItemEffectType.invertNext,
    value: 0,
    icon: Icons.auto_fix_high,
    color: Color(0xFFAB47BC),
  ),

  ItemCard(
    id: 'thornmail',
    title: 'Шипованная броня',
    description: 'Следующий удар: конвертирует урон в двойное золото.',
    effectType: ItemEffectType.thornmail,
    value: 0,
    icon: Icons.pest_control,
    color: Color(0xFF8D6E63),
  ),
  ItemCard(
    id: 'philosophers_stone',
    title: 'Философский камень',
    description:
        'Конвертирует монеты (×10, макс. 100🪙) в атаку (+1) и здоровье (+2).',
    effectType: ItemEffectType.transmute,
    value: 0,
    icon: Icons.science,
    color: Color(0xFFFF7043),
  ),
  ItemCard(
    id: 'shadow_pact',
    title: 'Теневой пакт',
    description:
        'Жертвуешь половиной HP → удваиваешь монеты + случайная карта.',
    effectType: ItemEffectType.shadowPact,
    value: 0,
    icon: Icons.dark_mode,
    color: Color(0xFF37474F),
  ),
  ItemCard(
    id: 'greed_magnet',
    title: 'Магнит жадности',
    description: 'На 3 хода удваивает все монеты, полученные в событиях.',
    effectType: ItemEffectType.greedMagnet,
    value: 3,
    icon: Icons.attach_money,
    color: Color(0xFFFFD54F),
  ),
  ItemCard(
    id: 'dice_of_fate',
    title: 'Кубик судьбы',
    description:
        'Случайный эффект: потери, артефакт, или джекпот (+5❤ +2⚡ +25🪙).',
    effectType: ItemEffectType.diceOfFate,
    value: 0,
    icon: Icons.casino,
    color: Color(0xFFEF5350),
  ),
  ItemCard(
    id: 'smoke_bomb',
    title: 'Дымовая шашка',
    description:
        'Мгновенный побег: карта пропускается, лучшие монеты сохраняются.',
    effectType: ItemEffectType.smokeBomb,
    value: 0,
    icon: Icons.cloud,
    color: Color(0xFF607D8B),
  ),
  ItemCard(
    id: 'gold_bribe',
    title: 'Золотой подкуп',
    description: 'Трать 15🪙, чтобы выбрать лучший исход без последствий.',
    effectType: ItemEffectType.bribery,
    value: 15,
    icon: Icons.monetization_on,
    color: Color(0xFFF9A825),
  ),
];

/// Возвращает случайный предмет из полного списка [allItemCards].
ItemCard getRandomItemCard(Random random) {
  return allItemCards[random.nextInt(allItemCards.length)];
}

/// Возвращает случайный предмет только из тех, которые уже разблокированы игроком ([unlockedIds]).
///
/// Если у игрока ещё нет открытых карт, возвращает `null`.
ItemCard? getRandomUnlockedItemCard(Random random, Set<String> unlockedIds) {
  final unlockedCards = allItemCards
      .where((item) => unlockedIds.contains(item.id))
      .toList();
  if (unlockedCards.isEmpty) return null;
  return unlockedCards[random.nextInt(unlockedCards.length)];
}

/// Возвращает случайный предмет среди ещё закрытых карт игрока.
///
/// Используется в лутбоксах Магазина ([ShopScreen._openLootbox]) для гарантированного
/// выпадения новой неизведанной карты. Если все карты уже открыты, возвращает `null`.
ItemCard? getRandomLockedItemCard(Random random, Set<String> unlockedIds) {
  final lockedCards = allItemCards
      .where((item) => !unlockedIds.contains(item.id))
      .toList();
  if (lockedCards.isEmpty) return null;
  return lockedCards[random.nextInt(lockedCards.length)];
}

