import 'package:flutter/material.dart';

/// Тип действия или эффекта расходуемой карты предмета (артефакта).
///
/// Каждый эффект имеет свою механику обработки в `GameScreen._useItem`:
/// * [heal] — мгновенно восстанавливает здоровье на величину [ItemCard.value].
/// * [attack] — навсегда (в рамках забега) увеличивает атаку героя на [ItemCard.value].
/// * [skip] — безопасно пропускает текущую карточку события или босса без потерь.
/// * [shield] — даёт [ItemCard.value] зарядов рунического щита, поглощающего урон.
/// * [invertNext] — активирует искажение: следующий выбор обращает потери в выгоду.
/// * [thornmail] — следующий полученный урон конвертируется в золото ×10.
/// * [transmute] — тратит монеты (кратно 10, до 100) и даёт здоровье и атаку.
/// * [shadowPact] — жертвует 50% текущего HP, взамен удваивает монеты и даёт случайную карту.
/// * [greedMagnet] — удваивает золото от выборов на протяжении следующих 3 ходов.
/// * [diceOfFate] — бросок кубика d6 со случайным исходом (потеря, карта или джекпот).
/// * [smokeBomb] — мгновенный побег от карты/босса с подбором доступных монет.
/// * [bribery] — за 50 монет позволяет выбрать наилучший исход без боя.
enum ItemEffectType {
  /// Восстановление здоровья героя
  heal,

  /// Увеличение силы атаки
  attack,

  /// Пропуск хода без негативных последствий
  skip,

  /// Защитный рунический щит от входящего урона
  shield,

  /// Зеркало искажения: потери на следующем шаге станут приобретениями
  invertNext,

  /// Шипованная броня: контратака золотом при получении урона
  thornmail,

  /// Алхимическая трансмутация: превращение монет в здоровье и атаку
  transmute,

  /// Тёмная сделка: жертва HP ради золота и артефакта
  shadowPact,

  /// Магнит жадности: временное удвоение добычи монет
  greedMagnet,

  /// Кубик судьбы: случайный исход (риск vs большая награда)
  diceOfFate,

  /// Дымовая шашка: тактическое отступление с сохранением монет
  smokeBomb,

  /// Золотой подкуп: нейтрализация угрозы за фиксированную плату
  bribery,

  /// Божественный рунический щит: полное поглощение входящего урона (100%)
  divineShield,

  /// Зелье каменной кожи: защита от получения яда и кровотечения
  stoneskin,

  /// Противоядие: мгновенное снятие временных эффектов яда и кровотечения
  antidote,

  /// Зелье регенерации: восстановление здоровья каждый ход
  regeneration,

  /// Свиток телепортации: перемещение вперёд на случайное число карт
  teleport,

  /// Усиленный рунический щит: поглощение 50% урона в течение нескольких ходов
  shieldTurns,

  /// Мгновенное получение золотых монет
  coins,

  /// Возврат здоровья и атаки к исходному стартовому значению
  rebirth,

  /// Казино судьбы: усиленная версия кубика судьбы с повышенными ставками и мега-джекпотом
  casinoOfFate,
}

/// Расширение для работы с категориями и отображением эффектов предметов.
extension ItemEffectTypeExtension on ItemEffectType {
  /// Читаемое название категории предмета на русском языке
  String get categoryLabel => switch (this) {
        ItemEffectType.heal => 'Исцеление',
        ItemEffectType.attack => 'Усиление',
        ItemEffectType.skip => 'Свиток',
        ItemEffectType.shield => 'Защита',
        ItemEffectType.invertNext => 'Искажение',
        ItemEffectType.thornmail => 'Контратака',
        ItemEffectType.transmute => 'Алхимия',
        ItemEffectType.shadowPact => 'Тёмная сделка',
        ItemEffectType.greedMagnet => 'Экономика',
        ItemEffectType.diceOfFate => 'Удача',
        ItemEffectType.smokeBomb => 'Побег',
        ItemEffectType.bribery => 'Дипломатия',
        ItemEffectType.divineShield => 'Защита',
        ItemEffectType.stoneskin => 'Защита',
        ItemEffectType.antidote => 'Очищение',
        ItemEffectType.regeneration => 'Исцеление',
        ItemEffectType.teleport => 'Телепортация',
        ItemEffectType.shieldTurns => 'Защита',
        ItemEffectType.coins => 'Золото',
        ItemEffectType.rebirth => 'Перерождение',
        ItemEffectType.casinoOfFate => 'Удача',
      };

  /// Формирует компактный бейдж эффекта с учётом числового параметра [value]
  String getBadge(int value) => switch (this) {
        ItemEffectType.heal => '+$value ❤',
        ItemEffectType.attack => '+$value ⚡',
        ItemEffectType.skip => 'Пропуск',
        ItemEffectType.shield => '🛡️ 50%',
        ItemEffectType.invertNext =>
            value > 1 ? '🪞 Инверсия ($value х.)' : '🪞 Инверсия',
        ItemEffectType.thornmail => '🌵 Шипы',
        ItemEffectType.transmute => '⚗️ Алхимия',
        ItemEffectType.shadowPact => '📜 Пакт',
        ItemEffectType.greedMagnet => '🧲 x2 монеты',
        ItemEffectType.diceOfFate => '🎲 Кубик',
        ItemEffectType.smokeBomb => '💨 Побег',
        ItemEffectType.bribery => '💰 Подкуп',
        ItemEffectType.divineShield => '✨🛡️ 100%',
        ItemEffectType.stoneskin => '🪨 Кожа',
        ItemEffectType.antidote => '🧪 Противоядие',
        ItemEffectType.regeneration => '🌿 +$value❤/ход',
        ItemEffectType.teleport => value == 5
            ? '🕳️ +5 карт'
            : value == 4
                ? '🌀 +2-4 к.'
                : '🌀 +1-3 к.',
        ItemEffectType.shieldTurns => '🛡️ 50% ($value х.)',
        ItemEffectType.coins => '+$value 🪙',
        ItemEffectType.rebirth => '🔄 Исходные',
        ItemEffectType.casinoOfFate => '🎰 Казино',
      };
}

/// Модель расходуемой карточки предмета (артефакта/зелья/свитка).
///
/// Карточки предметов хранятся в инвентаре героя во время забега и могут быть
/// активированы в любой момент через нижний лист инвентаря ([InventorySheet]).
///
/// Для добавления нового предмета в игру:
/// 1. Создайте экземпляр `ItemCard` в списке `allItemCards` в `lib/data/items.dart`.
/// 2. Если требуется новая игровая механика, добавьте значение в [ItemEffectType]
///    и обработайте его в методе `_useItem` в `lib/screens/game_screen.dart`.
class ItemCard {
  const ItemCard({
    required this.id,
    required this.title,
    required this.description,
    required this.effectType,
    required this.value,
    this.duration = 0,
    required this.icon,
    required this.color,
    this.level = 1,
  }) : assert(level >= 1 && level <= 3, 'Item level must be between 1 and 3');

  /// Уровень карты предмета (от 1 до 3).
  /// Определяет, торговцы какого этажа могут продавать эту карту.
  final int level;

  /// Уникальный строковый идентификатор предмета (например, 'potion_heal')
  final String id;

  /// Отображаемое название карточки на русском языке
  final String title;

  /// Подробное описание действия предмета для игрока
  final String description;

  /// Тип механики, вызываемой при использовании карточки
  final ItemEffectType effectType;

  /// Числовой модификатор эффекта (например, количество восстанавливаемого HP,
  /// прирост атаки, заряды щита или ходы действия)
  final int value;

  /// Длительность действия эффекта в ходах (для эффектов с двумя параметрами,
  /// например регенерации: value = HP за ход, duration = количество ходов)
  final int duration;

  /// Иконка для визуального отображения карточки
  final IconData icon;

  /// Цветовая гамма карточки (градиент и тени)
  final Color color;

  /// Категория предмета для UI
  String get categoryLabel => effectType.categoryLabel;

  /// Текст компактного бейджа эффекта для карточки
  String get effectBadge => effectType.getBadge(value);
}
