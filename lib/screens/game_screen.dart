import 'dart:math';

import 'package:flutter/material.dart';

import '../data/events.dart';
import '../data/items.dart';
import '../models/event_card.dart';
import '../models/item_card.dart';
import '../services/discovered_events.dart';
import '../services/player_coins_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/inventory_sheet.dart';
import '../widgets/stats_bar.dart';
import '../widgets/swipe_card.dart';

const _initialHealth = 10;
const _initialAttack = 3;

enum GameResult { playing, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = Random();
  late List<EventCard> _deck;
  int _health = _initialHealth;
  int _attack = _initialAttack;
  int _cardsPassed = 0;
  // Монеты, собранные за текущий забег (начинаются с 0)
  int _coins = 0;
  // Предметы, собранные за текущий забег
  final List<ItemCard> _inventoryItems = [];
  GameResult _result = GameResult.playing;
  String? _lastFeedback;
  int _cardKey = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
    _loadData();
  }

  void _initGame() {
    _deck = List.of(allEvents)..shuffle(_random);
    _health = _initialHealth;
    _attack = _initialAttack;
    _cardsPassed = 0;
    _coins = 0;
    _inventoryItems.clear();
    _result = GameResult.playing;
    _lastFeedback = null;
    _cardKey = 0;
    _discoverCurrentCard();
  }

  Future<void> _loadData() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
    ]);
    if (mounted) setState(() {});
  }

  void _startNewGame() {
    setState(() {
      _initGame();
    });
  }

  void _discoverCurrentCard() {
    DiscoveredEventsService.instance.markDiscovered(_currentCard.id);
  }

  EventCard get _currentCard => _deck[_cardsPassed % _deck.length];

  void _onSwipe(bool isRight) {
    if (_result != GameResult.playing) return;

    final choice = isRight ? _currentCard.rightChoice : _currentCard.leftChoice;

    // Проверяем доступность выбора (монеты, атака и наличие открытых карт)
    if (choice.coinsDelta < 0 && _coins < choice.coinsDelta.abs()) return;
    if (choice.attackDelta < 0 && _attack < choice.attackDelta.abs()) return;
    if (choice.givesRandomItem && UnlockedItemsService.instance.count == 0) return;

    ItemCard? receivedItem;
    if (choice.givesRandomItem) {
      receivedItem = getRandomUnlockedItemCard(
        _random,
        UnlockedItemsService.instance.unlockedIds,
      );
      if (receivedItem != null) {
        _inventoryItems.add(receivedItem);
      }
    }

    setState(() {
      _health = (_health + choice.healthDelta).clamp(0, 999);
      _attack = (_attack + choice.attackDelta).clamp(0, 99);
      _coins = (_coins + choice.coinsDelta).clamp(0, 999999);
      _lastFeedback = _buildFeedback(choice, receivedItem: receivedItem);
      _cardsPassed++;
      _cardKey++;

      // При новом цикле колоды перемешиваем события
      if (_cardsPassed % _deck.length == 0) {
        _deck.shuffle(_random);
      }

      if (_health <= 0) {
        _result = GameResult.gameOver;
        // Всё золото с баланса забега добавляем в инвентарь
        if (_coins > 0) {
          PlayerCoinsService.instance.applyDelta(_coins);
        }
      } else {
        _discoverCurrentCard();
      }
    });
  }

  String _buildFeedback(CardChoice choice, {ItemCard? receivedItem}) {
    final parts = <String>[];
    if (receivedItem != null) {
      parts.add('Получено: ${receivedItem.title}');
    }
    if (choice.healthDelta != 0) {
      parts.add('Здоровье ${choice.healthDelta > 0 ? '+' : ''}${choice.healthDelta}');
    }
    if (choice.attackDelta != 0) {
      parts.add('Атака ${choice.attackDelta > 0 ? '+' : ''}${choice.attackDelta}');
    }
    if (choice.coinsDelta != 0) {
      parts.add('Монеты ${choice.coinsDelta > 0 ? '+' : ''}${choice.coinsDelta}');
    }
    return parts.isEmpty ? choice.label : parts.join(', ');
  }

  void _useItem(int index, ItemCard item) {
    if (index < 0 || index >= _inventoryItems.length) return;

    setState(() {
      _inventoryItems.removeAt(index);
      switch (item.effectType) {
        case ItemEffectType.heal:
          _health = (_health + item.value).clamp(0, 999);
          _lastFeedback = '${item.title}: +${item.value} ❤';
          break;
        case ItemEffectType.attack:
          _attack = (_attack + item.value).clamp(0, 99);
          _lastFeedback = '${item.title}: +${item.value} ⚡';
          break;
        case ItemEffectType.skip:
          _cardsPassed++;
          _cardKey++;
          if (_cardsPassed % _deck.length == 0) {
            _deck.shuffle(_random);
          }
          _discoverCurrentCard();
          _lastFeedback = 'Событие пропущено!';
          break;
      }
    });
  }

  void _openInventory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: InventorySheet(
            items: _inventoryItems,
            onUseItem: _useItem,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE94560), size: 26),
            SizedBox(width: 10),
            Text(
              'Сдаться?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'При досрочном выходе из подземелья весь прогресс и накопленные за этот забег монеты ($_coins 🪙) будут потеряны.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Продолжить',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Сдаться и выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // При досрочном выходе золото не начисляется
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_result == GameResult.playing) {
          _confirmLeave();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                children: [
                  StatsBar(
                    health: _health,
                    attack: _attack,
                    cardsPassed: _cardsPassed,
                    coins: _coins,
                  ),
                  if (_lastFeedback != null && _result == GameResult.playing)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_lastFeedback),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _lastFeedback!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: _result == GameResult.playing
                          ? SwipeCard(
                              key: ValueKey(_cardKey),
                              event: _currentCard,
                              currentCoins: _coins,
                              currentAttack: _attack,
                              hasUnlockedItems: UnlockedItemsService.instance.count > 0,
                              onSwipe: _onSwipe,
                            )
                          : _ResultOverlay(
                              cardsPassed: _cardsPassed,
                              health: _health,
                              attack: _attack,
                              runCoins: _coins,
                              totalCoins: PlayerCoinsService.instance.balance,
                              onRestart: _startNewGame,
                              onMenu: () => Navigator.of(context).pop(),
                            ),
                    ),
                  ),
                  if (_result == GameResult.playing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                      child: Column(
                        children: [
                          Text(
                            '← свайп влево  ·  свайп вправо →',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openInventory,
                                icon: Badge(
                                  isLabelVisible: _inventoryItems.isNotEmpty,
                                  label: Text('${_inventoryItems.length}'),
                                  backgroundColor: const Color(0xFFE94560),
                                  child: const Icon(
                                    Icons.backpack_outlined,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                label: Text(
                                  'Инвентарь${_inventoryItems.isNotEmpty ? ' (${_inventoryItems.length})' : ''}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _inventoryItems.isNotEmpty
                                        ? const Color(0xFFE94560).withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: _confirmLeave,
                                icon: Icon(
                                  Icons.exit_to_app,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                                label: Text(
                                  'Сдаться',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.cardsPassed,
    required this.health,
    required this.attack,
    required this.runCoins,
    required this.totalCoins,
    required this.onRestart,
    required this.onMenu,
  });

  final int cardsPassed;
  final int health;
  final int attack;
  final int runCoins;
  final int totalCoins;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                cardsPassed >= 20 ? Icons.emoji_events : Icons.heart_broken,
                size: 72,
                color: cardsPassed >= 20 ? const Color(0xFFF5A623) : const Color(0xFFE94560),
              ),
              const SizedBox(height: 24),
              const Text(
                'Конец приключения',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Вы выдержали $cardsPassed событий!\nФинальная атака: $attack',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700), size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '+$runCoins',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'в инвентарь',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 22),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCoins',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'всего монет',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Играть снова', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onMenu,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('В меню', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
