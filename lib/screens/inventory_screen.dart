import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/item_card.dart';
import '../services/player_coins_service.dart';
import '../services/player_stats_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/item_details_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = true;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Инвентарь',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                      ),
                    )
                  else ...[
                    // ── Монеты ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    ),

                    // ── Прокачка характеристик персонажа ───────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: Column(
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
                        ],
                      ),
                    ),

                    // ── Открытые карты ────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Открытые карты предметов',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
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
                            const SizedBox(height: 4),
                            Text(
                              'Эти карты могут быть куплены у торговца реликвиями в подземелье.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (unlockedItems.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.04),
                                        ),
                                        child: Icon(
                                          Icons.card_giftcard_outlined,
                                          size: 54,
                                          color: Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Нет открытых карт',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Открывайте сундуки в магазине,\nчтобы разблокировать карты предметов!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: GridView.builder(
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
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
            child: isMax
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

