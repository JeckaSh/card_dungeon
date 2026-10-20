import 'dart:math';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/items.dart';
import '../models/item_card.dart';

/// Модель сундука в магазине артефактов.
///
/// Позволяет гибко настраивать содержимое сундука:
/// - [levels]: фильтрация по уровням карт (например, `[1]` для карт 1 уровня, `[1, 2, 3]` для смешанного сундука);
/// - [itemIds]: конкретные ID карт предметов (например, `['potion_heal', 'runic_shield']`);
/// - [explicitItems]: прямой список объектов [ItemCard];
/// - [filter]: пользовательский предикат фильтрации `bool Function(ItemCard item)`.
///
/// Если указано несколько параметров фильтрации (например, [levels] и [itemIds]),
/// в сундук попадают карты, удовлетворяющие любому из условий (объединение пулов без дубликатов).
class ShopChest {
  final String id;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) descriptionBuilder;
  final String Function(AppLocalizations l10n)? allCollectedDescBuilder;
  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final int basePrice;
  final int priceStep;

  /// Уровни карт, входящих в этот сундук (например, `[1]`, `[2]`, `[3]` или `[1, 2, 3]`).
  final List<int>? levels;

  /// Список конкретных идентификаторов карт предметов, входящих в сундук.
  final List<String>? itemIds;

  /// Явно переданный список карт предметов.
  final List<ItemCard>? explicitItems;

  /// Пользовательский предикат фильтрации для отбора карт.
  final bool Function(ItemCard item)? filter;

  const ShopChest({
    required this.id,
    required this.titleBuilder,
    required this.descriptionBuilder,
    this.allCollectedDescBuilder,
    required this.icon,
    this.iconColor = const Color(0xFFFFD700),
    this.accentColor = const Color(0xFFE94560),
    this.gradientColors = const [Color(0xFF2C1B4D), Color(0xFF1A1A2E)],
    this.basePrice = 50,
    this.priceStep = 25,
    this.levels,
    this.itemIds,
    this.explicitItems,
    this.filter,
  });

  /// Возвращает пул всех уникальных карт предметов, доступных в этом сундуке.
  List<ItemCard> getPool([List<ItemCard>? allItems]) {
    final source = allItems ?? allItemCards;
    final result = <ItemCard>[];
    final seenIds = <String>{};

    // 1. Явно переданные карты
    if (explicitItems != null) {
      for (final item in explicitItems!) {
        if (seenIds.add(item.id)) {
          result.add(item);
        }
      }
    }

    final hasCriteria = levels != null || itemIds != null || filter != null;

    for (final item in source) {
      if (seenIds.contains(item.id)) continue;

      if (hasCriteria) {
        final matchesLevel = levels != null && levels!.contains(item.level);
        final matchesId = itemIds != null && itemIds!.contains(item.id);
        final matchesFilter = filter != null && filter!(item);

        if (matchesLevel || matchesId || matchesFilter) {
          seenIds.add(item.id);
          result.add(item);
        }
      } else if (explicitItems == null) {
        // Если никаких критериев не задано вовсе, сундук содержит все карты из источника
        seenIds.add(item.id);
        result.add(item);
      }
    }

    return result;
  }

  /// Текущая стоимость открытия сундука с учётом количества уже открытых карт из его пула.
  int getPrice(Set<String> unlockedIds, [List<ItemCard>? allItems]) {
    final pool = getPool(allItems);
    final unlockedCount =
        pool.where((item) => unlockedIds.contains(item.id)).length;
    return basePrice + (unlockedCount * priceStep);
  }

  /// Проверяет, собраны ли все карты из пула этого сундука.
  bool isAllUnlocked(Set<String> unlockedIds, [List<ItemCard>? allItems]) {
    final pool = getPool(allItems);
    return pool.isNotEmpty &&
        pool.every((item) => unlockedIds.contains(item.id));
  }

  /// Возвращает случайную ещё не открытую карту из пула этого сундука.
  ItemCard? getRandomLockedItem(
    Random random,
    Set<String> unlockedIds, [
    List<ItemCard>? allItems,
  ]) {
    final pool = getPool(allItems);
    final locked =
        pool.where((item) => !unlockedIds.contains(item.id)).toList();
    if (locked.isEmpty) return null;
    return locked[random.nextInt(locked.length)];
  }
}
