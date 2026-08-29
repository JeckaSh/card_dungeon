import 'dart:math';

import 'package:flutter/material.dart';

import '../data/items.dart';
import '../models/item_card.dart';
import '../services/player_coins_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/item_card_widget.dart';

const int _lootboxPrice = 50;
const int _duplicateRefund = 20;

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _random = Random();
  bool _loading = true;
  bool _isOpening = false;

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

  Future<void> _openLootbox() async {
    final balance = PlayerCoinsService.instance.balance;
    if (balance < _lootboxPrice || _isOpening) return;

    setState(() => _isOpening = true);

    // Списываем золото
    PlayerCoinsService.instance.applyDelta(-_lootboxPrice);

    // Выбираем случайную карту
    final item = getRandomItemCard(_random);
    final isNew = await UnlockedItemsService.instance.unlock(item.id);

    // Если дубликат — начисляем небольшую компенсацию
    if (!isNew) {
      PlayerCoinsService.instance.applyDelta(_duplicateRefund);
    }

    if (!mounted) return;
    setState(() => _isOpening = false);

    // Показываем диалог с анимацией выпавшей карты
    _showRewardDialog(item, isNew: isNew);
  }

  void _showRewardDialog(ItemCard item, {required bool isNew}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text(
              isNew ? '🎉 НОВАЯ КАРТА!' : '✨ КАРТА ИЗ СУНДУКА',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isNew ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            if (!isNew)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Уже есть в коллекции (+$_duplicateRefund 🪙)',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                  ),
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
                child: ItemCardWidget(item: item),
              ),
              const SizedBox(height: 16),
              Text(
                isNew
                  ? 'Теперь эту карту можно встретить у торговца в подземелье!'
                  : 'Эта карта уже доступна для покупки в подземелье.',
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Отлично', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = PlayerCoinsService.instance.balance;
    final unlockedService = UnlockedItemsService.instance;
    final canBuy = balance >= _lootboxPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Магазин'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Баланс монет
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
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
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ваш баланс',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
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

                        // Блок Лутбокса
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2C1B4D), Color(0xFF1A1A2E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
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
                                  color: const Color(0xFF9C27B0).withValues(alpha: 0.25),
                                  border: Border.all(
                                    color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  color: Color(0xFFE040FB),
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Магический сундук',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Открывает 1 случайную карту предмета для использования в подземелье.',
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
                                  onPressed: canBuy && !_isOpening ? _openLootbox : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9C27B0),
                                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: _isOpening
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          canBuy
                                              ? 'Открыть сундук ($_lootboxPrice 🪙)'
                                              : 'Не хватает монет ($_lootboxPrice 🪙)',
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
                        ),
                        const SizedBox(height: 28),

                        // Прогресс коллекции
                        Row(
                          children: [
                            const Text(
                              'Доступные карты',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                'Открыто: ${unlockedService.count} / ${allItemCards.length}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Сетка карт (открытые vs закрытые)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            childAspectRatio: 0.72,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: allItemCards.length,
                          itemBuilder: (context, index) {
                            final item = allItemCards[index];
                            final isUnlocked = unlockedService.isUnlocked(item.id);

                            if (isUnlocked) {
                              return ItemCardWidget(item: item);
                            }

                            return _LockedItemCard(item: item);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
              item.title,
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
              'В сундуке',
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
