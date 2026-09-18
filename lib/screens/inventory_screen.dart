import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/item_card.dart';
import '../services/player_coins_service.dart';
import '../services/player_stats_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/item_details_sheet.dart';

/// Экран инвентаря и прокачки персонажа.
///
/// Предоставляет:
/// * Просмотр общего баланса монет ([PlayerCoinsService]);
/// * Прокачку постоянных характеристик героя (здоровье, атака, торговцы, стартовые карты);
/// * Просмотр каталога уже открытых артефактов с возможностью изучения их свойств.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = true;
  bool _isCardsExpanded = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
      PlayerStatsService.instance.load(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  void _showItemDetails(ItemCard item) {
    showItemDetailsSheet(context, item, isUnlocked: true);
  }

  @override
  Widget build(BuildContext context) {
    final coins = PlayerCoinsService.instance.balance;
    final unlockedService = UnlockedItemsService.instance;
    final stats = PlayerStatsService.instance;
    final unlockedItems = allItemCards.where((item) => unlockedService.isUnlocked(item.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Инвентарь'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
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
                    // ── Монеты ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Color(0xFFFFD700),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Монеты',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$coins',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Прокачка характеристик персонажа ───────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Прокачка персонажа',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                'Стартовые статы',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _StatUpgradeCard(
                                title: 'Здоровье',
                                icon: Icons.favorite,
                                color: const Color(0xFFE94560),
                                currentValue: '${stats.startingHealth} ❤',
                                level: stats.healthLevel,
                                maxLevel: PlayerStatsService.maxHealthLevel,
                                bonusText: '+${PlayerStatsService.healthPerLevel} ❤',
                                cost: stats.healthUpgradeCost,
                                isMax: stats.isHealthMax,
                                canAfford: coins >= stats.healthUpgradeCost,
                                onUpgrade: () {
                                  if (stats.upgradeHealth()) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatUpgradeCard(
                                title: 'Атака',
                                icon: Icons.flash_on,
                                color: const Color(0xFFFFD700),
                                currentValue: '${stats.startingAttack} ⚡',
                                level: stats.attackLevel,
                                maxLevel: PlayerStatsService.maxAttackLevel,
                                bonusText: '+${PlayerStatsService.attackPerLevel} ⚡',
                                cost: stats.attackUpgradeCost,
                                isMax: stats.isAttackMax,
                                canAfford: coins >= stats.attackUpgradeCost,
                                onUpgrade: () {
                                  if (stats.upgradeAttack()) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // ── Прокачка торговцев и стартовых карт ─────────
                        Row(
                          children: [
                            Expanded(
                              child: _StatUpgradeCard(
                                title: 'Торговцы',
                                icon: Icons.storefront_rounded,
                                color: const Color(0xFF26A69A),
                                currentValue: stats.guaranteedMerchants == 0
                                    ? 'случайно'
                                    : '${stats.guaranteedMerchants} за ур.',
                                level: stats.merchantLevel,
                                maxLevel: PlayerStatsService.maxMerchantLevel,
                                bonusText: '+1 🏪',
                                cost: stats.merchantUpgradeCost,
                                isMax: stats.isMerchantMax,
                                canAfford: coins >= stats.merchantUpgradeCost,
                                onUpgrade: () {
                                  if (stats.upgradeMerchant()) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatUpgradeCard(
                                title: 'Стартовые карты',
                                icon: !stats.isStartingCardsUnlocked
                                    ? Icons.lock_outline
                                    : Icons.auto_awesome_motion_rounded,
                                color: !stats.isStartingCardsUnlocked
                                    ? Colors.white38
                                    : const Color(0xFFAB47BC),
                                currentValue: !stats.isStartingCardsUnlocked
                                    ? 'закрыто'
                                    : (stats.startingCardsCount == 0
                                        ? '0 карт'
                                        : '${stats.startingCardsCount} ${stats.startingCardsCount == 1 ? "карта" : "карты"}'),
                                level: stats.startingCardsLevel,
                                maxLevel: PlayerStatsService.maxStartingCardsLevel,
                                bonusText: '+1 🃏',
                                cost: stats.startingCardsUpgradeCost,
                                isMax: stats.isStartingCardsMax,
                                canAfford: coins >= stats.startingCardsUpgradeCost,
                                isLocked: !stats.isStartingCardsUnlocked,
                                lockedText: 'Нужно 3 карты (${unlockedItems.length}/3)',
                                onUpgrade: () {
                                  if (stats.upgradeStartingCards()) {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Открытые карты предметов ────────────────────────
                    InkWell(
                      onTap: () => setState(() => _isCardsExpanded = !_isCardsExpanded),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Открытые карты предметов',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isCardsExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${unlockedItems.length} / ${allItemCards.length}',
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
                    if (_isCardsExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Эти карты могут быть куплены у торговца реликвиями в подземелье.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (unlockedItems.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.04),
                                  ),
                                  child: Icon(
                                    Icons.card_giftcard_outlined,
                                    size: 46,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Нет открытых карт',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Открывайте сундуки в магазине,\nчтобы разблокировать карты предметов!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            childAspectRatio: 0.72,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: unlockedItems.length,
                          itemBuilder: (context, index) {
                            final item = unlockedItems[index];
                            return ItemCardWidget(
                              item: item,
                              onTap: () => _showItemDetails(item),
                            );
                          },
                        ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatUpgradeCard extends StatelessWidget {
  const _StatUpgradeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.level,
    required this.maxLevel,
    required this.bonusText,
    required this.cost,
    required this.isMax,
    required this.canAfford,
    required this.onUpgrade,
    this.isLocked = false,
    this.lockedText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String currentValue;
  final int level;
  final int maxLevel;
  final String bonusText;
  final int cost;
  final bool isMax;
  final bool canAfford;
  final VoidCallback onUpgrade;
  final bool isLocked;
  final String? lockedText;

  @override
  Widget build(BuildContext context) {
    final isGoldColor = color == const Color(0xFFFFD700);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currentValue,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ур. $level',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: maxLevel > 0 ? level / maxLevel : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: isLocked
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            lockedText ?? 'ЗАБЛОКИРОВАНО',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : isMax
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'МАКС. УРОВЕНЬ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: canAfford ? onUpgrade : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: isGoldColor ? Colors.black87 : Colors.white,
                          elevation: canAfford ? 2 : 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '$bonusText · $cost 🪙',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: canAfford
                                ? (isGoldColor ? Colors.black87 : Colors.white)
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

