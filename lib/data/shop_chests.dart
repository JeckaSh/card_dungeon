import 'package:flutter/material.dart';

import '../models/shop_chest.dart';

/// Стандартный набор сундуков в магазине.
///
/// 1. **Сундук новичка** — содержит только карты предметов 1 уровня.
/// 2. **Сундук приключенца** — содержит только карты предметов 2 уровня.
/// 3. **Сундук героя** — содержит только карты предметов 3 уровня.
///
/// ### Создание тематических сундуков:
/// Модель [ShopChest] поддерживает гибкую настройку:
/// - Можно указать уровни карт: `levels: [1, 2, 3]`
/// - Можно указать конкретные карты по ID: `itemIds: ['potion_heal', 'thornmail']`
/// - Можно передать предикат фильтрации: `filter: (item) => item.effectType == ItemEffectType.attack`
/// - Можно комбинировать: `levels: [1], itemIds: ['philosophers_stone']` (карты 1 уровня + философский камень)
final List<ShopChest> defaultShopChests = [
  ShopChest(
    id: 'novice_chest',
    titleBuilder: (l10n) => l10n.shopNoviceChest,
    descriptionBuilder: (l10n) => l10n.shopNoviceChestDesc,
    allCollectedDescBuilder: (l10n) => l10n.shopNoviceChestDescAllCollected,
    icon: Icons.backpack_outlined,
    iconColor: const Color(0xFF81C784),
    accentColor: const Color(0xFF388E3C),
    gradientColors: const [
      Color(0xFF1B3B2B),
      Color(0xFF1A1A2E),
    ],
    basePrice: 50,
    priceStep: 25,
    levels: const [1],
  ),
  ShopChest(
    id: 'adventurer_chest',
    titleBuilder: (l10n) => l10n.shopAdventurerChest,
    descriptionBuilder: (l10n) => l10n.shopAdventurerChestDesc,
    allCollectedDescBuilder: (l10n) => l10n.shopAdventurerChestDescAllCollected,
    icon: Icons.explore_outlined,
    iconColor: const Color(0xFF4FC3F7),
    accentColor: const Color(0xFF0288D1),
    gradientColors: const [
      Color(0xFF102A45),
      Color(0xFF1A1A2E),
    ],
    basePrice: 75,
    priceStep: 35,
    levels: const [2],
  ),
  ShopChest(
    id: 'hero_chest',
    titleBuilder: (l10n) => l10n.shopHeroChest,
    descriptionBuilder: (l10n) => l10n.shopHeroChestDesc,
    allCollectedDescBuilder: (l10n) => l10n.shopHeroChestDescAllCollected,
    icon: Icons.military_tech_outlined,
    iconColor: const Color(0xFFFFD700),
    accentColor: const Color(0xFFFFA000),
    gradientColors: const [
      Color(0xFF3D2314),
      Color(0xFF1A1A2E),
    ],
    basePrice: 100,
    priceStep: 50,
    levels: const [3],
  ),
];
