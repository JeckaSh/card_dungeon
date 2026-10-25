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

// ─── Магический сундук ──────────────────────────────────────────────────────
// Содержит магические артефакты, свитки и экзотические предметы.
const List<ItemCard> magicChestItems = [
  ItemCard(
    id: 'potion_heal',
    title: 'Зелье лечения',
    description: 'Восстанавливает +4 здоровья',
    effectType: ItemEffectType.heal,
    value: 4,
    icon: Icons.healing,
    color: Color(0xFFE94560),
    level: 2,
  ),
  ItemCard(
    id: 'medicinal_herbs',
    title: 'Лечебные травы',
    description: 'Восстанавливает +2 здоровья',
    effectType: ItemEffectType.heal,
    value: 2,
    icon: Icons.healing,
    color: Color(0xFFE94560),
    level: 1,
  ),
  ItemCard(
    id: 'potion_attack',
    title: 'Зелье атаки',
    description: 'Увеличивает атаку на +4',
    effectType: ItemEffectType.attack,
    value: 4,
    icon: Icons.flash_on,
    color: Color(0xFFF5A623),
    level: 2,
  ),
  ItemCard(
    id: 'whetstone',
    title: 'Точильный камень',
    description: 'Увеличивает атаку на +2',
    effectType: ItemEffectType.attack,
    value: 2,
    icon: Icons.architecture,
    color: Color(0xFF78909C),
    level: 1,
  ),
  ItemCard(
    id: 'scroll_skip',
    title: 'Пропуск хода',
    description: 'Пропускает текущую карточку без последствий',
    effectType: ItemEffectType.skip,
    value: 0,
    icon: Icons.fast_forward_rounded,
    color: Color(0xFF9C27B0),
    level: 1,
  ),
  ItemCard(
    id: 'mirror_distortion',
    title: 'Зеркало искажения',
    description: 'Следующий ход: все потери превратятся в приобретения.',
    effectType: ItemEffectType.invertNext,
    value: 0,
    icon: Icons.auto_fix_high,
    color: Color(0xFFAB47BC),
    level: 3,
  ),
  ItemCard(
    id: 'thornmail',
    title: 'Шипованная броня',
    description: 'Следующий удар: конвертирует урон в двойное золото.',
    effectType: ItemEffectType.thornmail,
    value: 0,
    icon: Icons.pest_control,
    color: Color(0xFF8D6E63),
    level: 2,
  ),
  ItemCard(
    id: 'philosophers_stone',
    title: 'Философский камень',
    description:
        'Конвертирует монеты (×10, макс. 50🪙) в атаку (+1) и здоровье (+2).',
    effectType: ItemEffectType.transmute,
    value: 0,
    icon: Icons.science,
    color: Color(0xFFFF7043),
    level: 3,
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
    level: 3,
  ),
  ItemCard(
    id: 'greed_magnet',
    title: 'Магнит жадности',
    description: 'На 3 хода удваивает все монеты, полученные в событиях.',
    effectType: ItemEffectType.greedMagnet,
    value: 3,
    icon: Icons.attach_money,
    color: Color(0xFFFFD54F),
    level: 2,
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
    level: 2,
  ),
  ItemCard(
    id: 'gold_bribe',
    title: 'Золотой подкуп',
    description: 'Трать 15🪙, чтобы выбрать лучший исход без последствий.',
    effectType: ItemEffectType.bribery,
    value: 15,
    icon: Icons.monetization_on,
    color: Color(0xFFF9A825),
    level: 2,
  ),
  ItemCard(
    id: 'scroll_teleport',
    title: 'Свиток телепортации',
    description:
        'Перемещает вперёд на случайное количество карт (от 1 до 3). Нельзя использовать на боссе.',
    effectType: ItemEffectType.teleport,
    value: 0,
    icon: Icons.explore_rounded,
    color: Color(0xFF5C6BC0),
    level: 3,
  ),
  ItemCard(
    id: 'handful_of_gold',
    title: 'Горсть золота',
    description: 'Даёт +50 золота',
    effectType: ItemEffectType.coins,
    value: 50,
    icon: Icons.savings_outlined,
    color: Color(0xFFFFD54F),
    level: 1,
  ),
  ItemCard(
    id: 'small_gold_pouch',
    title: 'Маленький мешочек золота',
    description: 'Даёт +100 золота',
    effectType: ItemEffectType.coins,
    value: 100,
    icon: Icons.paid_outlined,
    color: Color(0xFFFFC107),
    level: 2,
  ),
];

// ─── Сундук героя ───────────────────────────────────────────────────────────
// Содержит мощные расходники и защитные предметы для бойца.
const List<ItemCard> heroChestItems = [
  ItemCard(
    id: 'elixir_attack',
    title: 'Элексир атаки',
    description: 'Увеличивает атаку на +8',
    effectType: ItemEffectType.attack,
    value: 8,
    icon: Icons.flash_on,
    color: Color(0xFFF5A623),
    level: 3,
  ),
  ItemCard(
    id: 'elixir_life',
    title: 'Эликсир жизни',
    description: 'Восстанавливает +8 здоровья',
    effectType: ItemEffectType.heal,
    value: 8,
    icon: Icons.healing,
    color: Color(0xFF4CAF50),
    level: 3,
  ),
  ItemCard(
    id: 'potion_regeneration',
    title: 'Зелье регенерации',
    description:
        'Восстанавливает 2 очка здоровья каждый ход в течение 3 ходов.',
    effectType: ItemEffectType.regeneration,
    value: 3,
    icon: Icons.spa_rounded,
    color: Color(0xFF66BB6A),
    level: 2,
  ),
  ItemCard(
    id: 'runic_shield',
    title: 'Рунический щит',
    description:
        'Следующий урон по здоровью уменьшается на 50% (поглощает половину урона).',
    effectType: ItemEffectType.shield,
    value: 1,
    icon: Icons.shield_outlined,
    color: Color(0xFF29B6F6),
    level: 1,
  ),
  ItemCard(
    id: 'divine_runic_shield',
    title: 'Божественный рунический щит',
    description:
        'Следующий урон по здоровью будет полностью поглощён (100% защита).',
    effectType: ItemEffectType.divineShield,
    value: 1,
    icon: Icons.shield,
    color: Color(0xFFFFD700),
    level: 2,
  ),
  ItemCard(
    id: 'enhanced_runic_shield',
    title: 'Усиленный рунический щит',
    description:
        'Уменьшает входящий урон по здоровью на 50% в течение 3 ходов.',
    effectType: ItemEffectType.shieldTurns,
    value: 3,
    icon: Icons.shield,
    color: Color(0xFF0288D1),
    level: 3,
  ),
  ItemCard(
    id: 'potion_stoneskin',
    title: 'Зелье каменной кожи',
    description:
        'На 3 хода защищает от получения кровотечения, яда или слепоты.',
    effectType: ItemEffectType.stoneskin,
    value: 3,
    icon: Icons.health_and_safety,
    color: Color(0xFF78909C),
    level: 2,
  ),
  ItemCard(
    id: 'potion_antidote',
    title: 'Противоядие',
    description:
        'Снимает временные эффекты яда, кровотечения и слепоты с персонажа.',
    effectType: ItemEffectType.antidote,
    value: 0,
    icon: Icons.sanitizer,
    color: Color(0xFF26A69A),
    level: 1,
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
    level: 2,
  ),
  ItemCard(
    id: 'bag_of_gold',
    title: 'Мешок золота',
    description: 'Даёт +250 золота',
    effectType: ItemEffectType.coins,
    value: 250,
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFFFA000),
    level: 3,
  ),
  ItemCard(
    id: 'huge_bag_of_gold',
    title: 'Огромный мешок золота',
    description: 'Даёт +500 золота',
    effectType: ItemEffectType.coins,
    value: 500,
    icon: Icons.work_outline,
    color: Color(0xFFFF8F00),
    level: 3,
  ),
  ItemCard(
    id: 'wormhole',
    title: 'Червоточина',
    description:
        'Перемещает вперёд на 2–4 карты. Нельзя использовать на боссе.',
    effectType: ItemEffectType.teleport,
    value: 4,
    icon: Icons.blur_circular,
    color: Color(0xFF7E57C2),
    level: 3,
  ),
];

// ─── Золотой сундук ─────────────────────────────────────────────────────────
// Содержит легендарные божественные артефакты величайшей силы.
const List<ItemCard> goldChestItems = [
  ItemCard(
    id: 'divine_healing',
    title: 'Божественное исцеление',
    description: 'Восстанавливает +12 здоровья',
    effectType: ItemEffectType.heal,
    value: 12,
    icon: Icons.healing,
    color: Color(0xFF4CAF50),
    level: 3,
  ),
  ItemCard(
    id: 'divine_power',
    title: 'Божественная сила',
    description: 'Увеличивает атаку на +12',
    effectType: ItemEffectType.attack,
    value: 12,
    icon: Icons.flash_on,
    color: Color(0xFFF5A623),
    level: 3,
  ),
  ItemCard(
    id: 'enhanced_divine_runic_shield',
    title: 'Усиленный божественный рунический щит',
    description:
        'Даёт 3 заряда божественного щита (следующие 3 удара по здоровью будут полностью поглощены).',
    effectType: ItemEffectType.divineShield,
    value: 3,
    icon: Icons.shield,
    color: Color(0xFFFFD700),
    level: 3,
  ),
  ItemCard(
    id: 'chest_of_gold',
    title: 'Сундук золота',
    description: 'Даёт +1000 золота',
    effectType: ItemEffectType.coins,
    value: 1000,
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFFFD700),
    level: 3,
  ),
  ItemCard(
    id: 'black_hole',
    title: 'Чёрная дыра',
    description:
        'Перемещает вперёд на 5 карт. Нельзя использовать на боссе.',
    effectType: ItemEffectType.teleport,
    value: 5,
    icon: Icons.adjust,
    color: Color(0xFF311B92),
    level: 3,
  ),
];

/// Все предметы игры (магический, герой и золотой сундуки объединены).
final List<ItemCard> allItemCards = [
  ...magicChestItems,
  ...heroChestItems,
  ...goldChestItems,
];

/// Карты предметов 1 уровня (Сундук новичка).
List<ItemCard> get noviceChestItems =>
    allItemCards.where((item) => item.level == 1).toList();

/// Карты предметов 2 уровня (Сундук приключенца).
List<ItemCard> get adventurerChestItems =>
    allItemCards.where((item) => item.level == 2).toList();

/// Карты предметов 3 уровня (Сундук героя).
List<ItemCard> get heroChestItemsLevel3 =>
    allItemCards.where((item) => item.level == 3).toList();

/// Возвращает случайный предмет из полного списка [allItemCards].
ItemCard getRandomItemCard(Random random) {
  return allItemCards[random.nextInt(allItemCards.length)];
}

/// Возвращает случайный предмет только из тех, которые уже разблокированы игроком ([unlockedIds]).
///
/// Если указан [level], возвращает только разблокированные предметы указанного уровня (1..3).
/// Если у игрока ещё нет открытых карт (соответствующего уровня), возвращает `null`.
ItemCard? getRandomUnlockedItemCard(
  Random random,
  Set<String> unlockedIds, {
  int? level,
}) {
  final unlockedCards = allItemCards
      .where(
        (item) =>
            unlockedIds.contains(item.id) &&
            (level == null || item.level == level),
      )
      .toList();
  if (unlockedCards.isEmpty) return null;
  return unlockedCards[random.nextInt(unlockedCards.length)];
}

/// Проверяет, есть ли среди открытых карт предметы указанного [level] (или любые, если null).
bool hasUnlockedItemCardsForLevel(Set<String> unlockedIds, [int? level]) {
  return allItemCards.any(
    (item) =>
        unlockedIds.contains(item.id) && (level == null || item.level == level),
  );
}

/// Выбирает случайную открытую карту предмета для торговца с учётом шанса выпадения карты более высокого уровня.
///
/// Если срабатывает шанс [upgradeChancePercent] (базово 5%, до 30%) и у игрока открыты карты более высокого уровня,
/// выдаётся карта уровня `baseLevel + 1` (до максимума 3). Иначе выдаётся карта базового уровня [baseLevel].
ItemCard? getRandomMerchantItemCard({
  required Random random,
  required Set<String> unlockedIds,
  required int baseLevel,
  int upgradeChancePercent = 5,
}) {
  final rolledHigher = random.nextInt(100) < upgradeChancePercent;
  if (rolledHigher && baseLevel < 3) {
    final higherLevel = min(3, baseLevel + 1);
    if (hasUnlockedItemCardsForLevel(unlockedIds, higherLevel)) {
      final higherItem = getRandomUnlockedItemCard(
        random,
        unlockedIds,
        level: higherLevel,
      );
      if (higherItem != null) return higherItem;
    }
  }

  return getRandomUnlockedItemCard(random, unlockedIds, level: baseLevel);
}

/// Возвращает случайный предмет среди ещё закрытых карт из [pool] для конкретного сундука.
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

/// Возвращает случайный незакрытый предмет из конкретного [pool].
ItemCard? getRandomLockedItemFromPool(
  Random random,
  List<ItemCard> pool,
  Set<String> unlockedIds,
) {
  final locked = pool.where((item) => !unlockedIds.contains(item.id)).toList();
  if (locked.isEmpty) return null;
  return locked[random.nextInt(locked.length)];
}
