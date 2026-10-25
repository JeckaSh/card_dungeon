import 'dart:math';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/items.dart';
import '../data/shop_chests.dart';
import '../models/item_card.dart';
import '../models/shop_chest.dart';
import '../services/locale_service.dart';
import '../services/player_coins_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/currencies_bar.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/item_details_sheet.dart';

/// Экран Магазина артефактов.
///
/// Позволяет игроку открывать новые карты предметов за накопленные монеты:
/// * Сундук новичка — карты предметов 1 уровня;
/// * Сундук приключенца — карты предметов 2 уровня;
/// * Сундук героя — карты предметов 3 уровня;
/// * Поддерживает кастомные и тематические сундуки [ShopChest];
/// * Стоимость растёт с каждой открытой картой пула: `basePrice + (unlockedCount * priceStep)`;
/// * Гарантирует выпадение карты, которой ещё нет в коллекции;
/// * Отображает прогресс коллекции и каталог всех предметов.
class ShopScreen extends StatefulWidget {
  /// Список сундуков, отображаемых в магазине. Если не передан, используется [defaultShopChests].
  final List<ShopChest>? chests;

  const ShopScreen({super.key, this.chests});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _random = Random();
  bool _loading = true;
  String? _openingChestId;
  bool _isCollectionExpanded = true;

  List<ShopChest> get _chests => widget.chests ?? defaultShopChests;

  @override
  void initState() {
    super.initState();
    PlayerCoinsService.instance.addListener(_onCoinsChanged);
    _load();
  }

  @override
  void dispose() {
    PlayerCoinsService.instance.removeListener(_onCoinsChanged);
    super.dispose();
  }

  void _onCoinsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  int _getBalance(ChestCurrency currency) {
    switch (currency) {
      case ChestCurrency.coins:
        return PlayerCoinsService.instance.balance;
      case ChestCurrency.silverKeys:
        return PlayerCoinsService.instance.silverKeys;
      case ChestCurrency.goldKeys:
        return PlayerCoinsService.instance.goldKeys;
    }
  }

  void _deductCurrency(ChestCurrency currency, int amount) {
    switch (currency) {
      case ChestCurrency.coins:
        PlayerCoinsService.instance.applyDelta(-amount);
        break;
      case ChestCurrency.silverKeys:
        PlayerCoinsService.instance.applySilverKeysDelta(-amount);
        break;
      case ChestCurrency.goldKeys:
        PlayerCoinsService.instance.applyGoldKeysDelta(-amount);
        break;
    }
  }

  Future<void> _openChest(ShopChest chest) async {
    if (_openingChestId != null) return;

    final unlockedService = UnlockedItemsService.instance;
    final balance = _getBalance(chest.currency);
    final price = chest.getPrice(unlockedService.unlockedIds);

    if (chest.isAllUnlocked(unlockedService.unlockedIds) || balance < price) {
      return;
    }

    final item = chest.getRandomLockedItem(_random, unlockedService.unlockedIds);
    if (item == null) return;

    setState(() {
      _openingChestId = chest.id;
    });

    // Списываем валюту
    _deductCurrency(chest.currency, price);

    // Разблокируем новую карту
    await unlockedService.unlock(item.id);

    if (!mounted) return;
    setState(() {
      _openingChestId = null;
    });

    // Показываем диалог с выпавшей картой
    _showRewardDialog(item);
  }

  void _showRewardDialog(ItemCard item) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Text(
                l10n.shopNewCardUnlocked,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 170,
                  height: 236,
                  child: ItemCardWidget(
                    item: item,
                    onTap: () =>
                        showItemDetailsSheet(context, item, isUnlocked: true),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.shopNewCardHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  l10n.great,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChestWidget(
    ShopChest chest,
    AppLocalizations l10n,
    UnlockedItemsService unlockedService,
  ) {
    final balance = _getBalance(chest.currency);
    final allUnlocked = chest.isAllUnlocked(unlockedService.unlockedIds);
    final price = chest.getPrice(unlockedService.unlockedIds);
    final canBuy = !allUnlocked && balance >= price;

    final String buttonLabel;
    if (allUnlocked) {
      buttonLabel = l10n.shopAllCardsObtained;
    } else if (canBuy) {
      buttonLabel = switch (chest.currency) {
        ChestCurrency.coins => l10n.shopOpenChestPrice(price),
        ChestCurrency.silverKeys => l10n.shopOpenChestSilverKeysPrice(price),
        ChestCurrency.goldKeys => l10n.shopOpenChestGoldKeysPrice(price),
      };
    } else {
      buttonLabel = switch (chest.currency) {
        ChestCurrency.coins => l10n.shopNotEnoughCoinsPrice(price),
        ChestCurrency.silverKeys => l10n.shopNotEnoughSilverKeysPrice(price),
        ChestCurrency.goldKeys => l10n.shopNotEnoughGoldKeysPrice(price),
      };
    }

    final String description;
    if (allUnlocked) {
      description = chest.allCollectedDescBuilder?.call(l10n) ??
          l10n.shopChestDescAllCollected;
    } else {
      description = chest.descriptionBuilder(l10n);
    }

    return _ChestBlock(
      title: chest.titleBuilder(l10n),
      description: description,
      icon: allUnlocked ? Icons.check_circle_outline : chest.icon,
      iconColor: allUnlocked ? const Color(0xFFFFD700) : chest.iconColor,
      accentColor: chest.accentColor,
      gradientColors: chest.gradientColors,
      buttonLabel: buttonLabel,
      canBuy: canBuy,
      isOpening: _openingChestId == chest.id,
      onOpen: () => _openChest(chest),
    );
  }

  Widget _buildChestGrid(
    ShopChest chest,
    UnlockedItemsService unlockedService,
  ) {
    final pool = chest.getPool();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        childAspectRatio: 0.72,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: pool.length,
      itemBuilder: (context, index) {
        final item = pool[index];
        final isUnlocked = unlockedService.isUnlocked(item.id);
        if (isUnlocked) {
          return ItemCardWidget(
            item: item,
            onTap: () => showItemDetailsSheet(
              context,
              item,
              isUnlocked: true,
            ),
          );
        }
        return _LockedItemCard(item: item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedService = UnlockedItemsService.instance;
    final chests = _chests;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            title: Text(l10n.shopTitle),
            elevation: 0,
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560)),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Панель валют (монеты, серебряные и золотые ключи)
                        const PlayerCurrenciesBar(),
                        const SizedBox(height: 24),

                        // ── Список сундуков ─────────────────────────────────
                        for (final chest in chests) ...[
                          _buildChestWidget(
                            chest,
                            l10n,
                            unlockedService,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 12),

                        // Прогресс коллекции
                        InkWell(
                          onTap: () => setState(
                            () =>
                                _isCollectionExpanded = !_isCollectionExpanded,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  l10n.shopAvailableCards,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isCollectionExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_right_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${l10n.shopCollectionUnlocked}: ${unlockedService.count} / ${allItemCards.length}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isCollectionExpanded) ...[
                          const SizedBox(height: 14),
                          for (final chest in chests) ...[
                            _CollectionSectionLabel(
                              icon: chest.icon,
                              label: chest.titleBuilder(l10n),
                              color: chest.iconColor,
                            ),
                            const SizedBox(height: 10),
                            _buildChestGrid(chest, unlockedService),
                            const SizedBox(height: 20),
                          ],
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Блок-виджет для одного сундука.
class _ChestBlock extends StatelessWidget {
  const _ChestBlock({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.gradientColors,
    required this.buttonLabel,
    required this.canBuy,
    required this.isOpening,
    required this.onOpen,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final String buttonLabel;
  final bool canBuy;
  final bool isOpening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.25),
              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: iconColor, size: 48),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: canBuy && !isOpening ? onOpen : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: canBuy ? 6 : 0,
              ),
              child: isOpening
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canBuy
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Заголовок секции коллекции.
class _CollectionSectionLabel extends StatelessWidget {
  const _CollectionSectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: color.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _LockedItemCard extends StatelessWidget {
  const _LockedItemCard({required this.item});

  final ItemCard item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 28,
                ),
              ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.itemTitle(item.id, item.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.shopInChest,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.invLvl(item.level),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
