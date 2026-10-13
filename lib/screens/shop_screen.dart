import 'dart:math';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/items.dart';
import '../models/item_card.dart';
import '../services/locale_service.dart';
import '../services/player_coins_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/item_details_sheet.dart';

/// Базовая стоимость первого лутбокса с новой картой
const int _baseLootboxPrice = 50;

/// Увеличение стоимости за каждую уже открытую карту в коллекции
const int _lootboxPriceStep = 25;

/// Тип сундука в магазине.
enum _ChestType { magic, hero }

/// Экран Магазина артефактов.
///
/// Позволяет игроку открывать новые карты предметов за накопленные монеты:
/// * Магический сундук — магические артефакты и свитки;
/// * Сундук героя — элексиры, рунический щит, дымовая шашка;
/// * Стоимость растёт с каждой открытой картой: `50 + (N_unlocked * 25)`;
/// * Гарантирует выпадение карты, которой ещё нет в коллекции;
/// * Отображает прогресс коллекции и каталог всех предметов.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _random = Random();
  bool _loading = true;
  bool _isOpeningMagic = false;
  bool _isOpeningHero = false;
  bool _isCollectionExpanded = true;

  int _lootboxPriceFor(List<ItemCard> pool) {
    final unlockedCount = UnlockedItemsService.instance.unlockedIds
        .where((id) => pool.any((item) => item.id == id))
        .length;
    return _baseLootboxPrice + (unlockedCount * _lootboxPriceStep);
  }

  bool _allUnlockedFor(List<ItemCard> pool) {
    final unlockedIds = UnlockedItemsService.instance.unlockedIds;
    return pool.every((item) => unlockedIds.contains(item.id));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openChest(_ChestType type) async {
    final pool = type == _ChestType.magic ? magicChestItems : heroChestItems;
    final isOpening =
        type == _ChestType.magic ? _isOpeningMagic : _isOpeningHero;
    if (isOpening) return;

    final unlockedService = UnlockedItemsService.instance;
    final price = _lootboxPriceFor(pool);
    final balance = PlayerCoinsService.instance.balance;

    if (_allUnlockedFor(pool) || balance < price) return;

    final item = getRandomLockedItemFromPool(
      _random,
      pool,
      unlockedService.unlockedIds,
    );
    if (item == null) return;

    setState(() {
      if (type == _ChestType.magic) {
        _isOpeningMagic = true;
      } else {
        _isOpeningHero = true;
      }
    });

    // Списываем золото
    PlayerCoinsService.instance.applyDelta(-price);

    // Разблокируем новую карту
    await unlockedService.unlock(item.id);

    if (!mounted) return;
    setState(() {
      if (type == _ChestType.magic) {
        _isOpeningMagic = false;
      } else {
        _isOpeningHero = false;
      }
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

  @override
  Widget build(BuildContext context) {
    final balance = PlayerCoinsService.instance.balance;
    final unlockedService = UnlockedItemsService.instance;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);

        // Magic chest
        final magicAllUnlocked = _allUnlockedFor(magicChestItems);
        final magicPrice = _lootboxPriceFor(magicChestItems);
        final canBuyMagic = !magicAllUnlocked && balance >= magicPrice;

        // Hero chest
        final heroAllUnlocked = _allUnlockedFor(heroChestItems);
        final heroPrice = _lootboxPriceFor(heroChestItems);
        final canBuyHero = !heroAllUnlocked && balance >= heroPrice;

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
                        // Баланс монет
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.monetization_on,
                                  color: Color(0xFFFFD700),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.shopYourBalance,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '$balance 🪙',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Магический сундук ────────────────────────────────
                        _ChestBlock(
                          title: l10n.shopMagicChest,
                          description: magicAllUnlocked
                              ? l10n.shopChestDescAllCollected
                              : l10n.shopChestDesc,
                          icon: magicAllUnlocked
                              ? Icons.check_circle_outline
                              : Icons.card_giftcard,
                          iconColor: magicAllUnlocked
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFE040FB),
                          accentColor: const Color(0xFF9C27B0),
                          gradientColors: const [
                            Color(0xFF2C1B4D),
                            Color(0xFF1A1A2E),
                          ],
                          buttonLabel: magicAllUnlocked
                              ? l10n.shopAllCardsObtained
                              : (canBuyMagic
                                    ? l10n.shopOpenChestPrice(magicPrice)
                                    : l10n.shopNotEnoughCoinsPrice(magicPrice)),
                          canBuy: canBuyMagic,
                          isOpening: _isOpeningMagic,
                          onOpen: () => _openChest(_ChestType.magic),
                        ),
                        const SizedBox(height: 16),

                        // ── Сундук героя ─────────────────────────────────────
                        _ChestBlock(
                          title: l10n.shopHeroChest,
                          description: heroAllUnlocked
                              ? l10n.shopHeroChestDescAllCollected
                              : l10n.shopHeroChestDesc,
                          icon: heroAllUnlocked
                              ? Icons.check_circle_outline
                              : Icons.shield,
                          iconColor: heroAllUnlocked
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF29B6F6),
                          accentColor: const Color(0xFF1565C0),
                          gradientColors: const [
                            Color(0xFF0D2744),
                            Color(0xFF1A1A2E),
                          ],
                          buttonLabel: heroAllUnlocked
                              ? l10n.shopAllCardsObtained
                              : (canBuyHero
                                    ? l10n.shopOpenChestPrice(heroPrice)
                                    : l10n.shopNotEnoughCoinsPrice(heroPrice)),
                          canBuy: canBuyHero,
                          isOpening: _isOpeningHero,
                          onOpen: () => _openChest(_ChestType.hero),
                        ),
                        const SizedBox(height: 28),

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

                          // Magic chest section label
                          _CollectionSectionLabel(
                            icon: Icons.auto_fix_high,
                            label: l10n.shopMagicChest,
                            color: const Color(0xFFE040FB),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 170,
                                  childAspectRatio: 0.72,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                ),
                            itemCount: magicChestItems.length,
                            itemBuilder: (context, index) {
                              final item = magicChestItems[index];
                              final isUnlocked = unlockedService.isUnlocked(
                                item.id,
                              );
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
                          ),
                          const SizedBox(height: 20),

                          // Hero chest section label
                          _CollectionSectionLabel(
                            icon: Icons.shield,
                            label: l10n.shopHeroChest,
                            color: const Color(0xFF29B6F6),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 170,
                                  childAspectRatio: 0.72,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                ),
                            itemCount: heroChestItems.length,
                            itemBuilder: (context, index) {
                              final item = heroChestItems[index];
                              final isUnlocked = unlockedService.isUnlocked(
                                item.id,
                              );
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
                          ),
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
          ],
        ),
      ),
    );
  }
}
