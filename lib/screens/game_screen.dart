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
/// Номер карточки (1-indexed), на которой появляется босс
const _bossEvery = 20;
/// Максимальный уровень сложности (зацикливаемся на нём)
const _maxDungeonLevel = 3;

enum GameResult { playing, gameOver }

class _TurnSnapshot {
  const _TurnSnapshot({
    required this.health,
    required this.attack,
    required this.coins,
    required this.cardsPassed,
    required this.cardKey,
    required this.inventory,
    required this.deckPosition,
    required this.dungeonLevel,
  });

  final int health;
  final int attack;
  final int coins;
  final int cardsPassed;
  final int cardKey;
  final List<ItemCard> inventory;
  final int deckPosition;
  final int dungeonLevel;
}

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
  int _coins = 0;
  int _dungeonLevel = 1;

  /// Позиция внутри текущей колоды уровня (не считая боссов).
  int _deckPosition = 0;

  final List<ItemCard> _inventoryItems = [];
  GameResult _result = GameResult.playing;
  String? _lastFeedback;
  int _cardKey = 0;

  // Активные статусы
  int _shieldCharges = 0;
  bool _invertNextChoice = false;
  bool _isRevealingChoices = false;
  int _greedMagnetTurns = 0;
  bool _thornmailActive = false;
  _TurnSnapshot? _lastTurnSnapshot;

  // ─── Геттеры ────────────────────────────────

  /// true, если текущая карточка (0-indexed _cardsPassed) должна быть боссом.
  /// Босс на позициях 19, 39, 59... (т.е. каждая 20-я карта).
  bool get _isCurrentBoss => (_cardsPassed + 1) % _bossEvery == 0;

  EventCard get _currentCard {
    if (_isCurrentBoss) return _selectBoss();
    return _deck[_deckPosition % _deck.length];
  }

  /// Сколько карточек до следующего босса (null — показывать только когда ≤5).
  int? get _nextBossIn {
    final remaining = _bossEvery - ((_cardsPassed + 1) % _bossEvery);
    return remaining <= 5 && remaining > 0 ? remaining : null;
  }

  // ─── Инициализация ──────────────────────────

  @override
  void initState() {
    super.initState();
    _initGame();
    _loadData();
  }

  void _initGame() {
    _health = _initialHealth;
    _attack = _initialAttack;
    _cardsPassed = 0;
    _deckPosition = 0;
    _dungeonLevel = 1;
    _coins = 0;
    _inventoryItems.clear();
    _result = GameResult.playing;
    _lastFeedback = null;
    _cardKey = 0;
    _shieldCharges = 0;
    _invertNextChoice = false;
    _isRevealingChoices = false;
    _greedMagnetTurns = 0;
    _thornmailActive = false;
    _lastTurnSnapshot = null;
    _rebuildDeck();
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

  // ─── Работа с колодой ───────────────────────

  /// Строит колоду из карточек текущего уровня и сбрасывает позицию.
  void _rebuildDeck() {
    final level = _dungeonLevel.clamp(1, _maxDungeonLevel);
    _deck = allEvents.where((e) => e.level == level).toList()..shuffle(_random);
    _deckPosition = 0;
  }

  /// Выбирает боссовую карточку по номеру встреченного босса.
  EventCard _selectBoss() {
    final bossNumber = (_cardsPassed + 1) ~/ _bossEvery;
    return allBossCards[(bossNumber - 1) % allBossCards.length];
  }

  void _discoverCurrentCard() {
    DiscoveredEventsService.instance.markDiscovered(_currentCard.id);
  }

  /// Переходит к следующей карточке.
  /// [wasBoss] — была ли текущая карточка боссом (для повышения уровня).
  void _advanceCard({bool wasBoss = false}) {
    _cardsPassed++;
    _cardKey++;
    if (wasBoss) {
      // Победа над боссом → повышаем уровень подземелья
      if (_dungeonLevel < _maxDungeonLevel) {
        _dungeonLevel++;
        _rebuildDeck();
      }
      // На максимальном уровне просто перемешиваем колоду
      else {
        _deck.shuffle(_random);
        _deckPosition = 0;
      }
    } else {
      _deckPosition++;
      if (_deck.isNotEmpty && _deckPosition % _deck.length == 0) {
        _deck.shuffle(_random);
      }
    }
    if (_health > 0) _discoverCurrentCard();
  }

  // ─── Обработка свайпа ───────────────────────

  void _onSwipe(bool isRight) {
    if (_result != GameResult.playing) return;

    final choice = isRight ? _currentCard.rightChoice : _currentCard.leftChoice;
    final wasBoss = _isCurrentBoss;

    // Проверяем доступность выбора
    if (choice.coinsDelta < 0 && _coins < choice.coinsDelta.abs()) return;
    if (choice.attackDelta < 0 && _attack < choice.attackDelta.abs()) return;
    if (choice.givesRandomItem && UnlockedItemsService.instance.count == 0) return;

    // Сохраняем снимок для возможного отката (Песочные часы)
    _lastTurnSnapshot = _TurnSnapshot(
      health: _health,
      attack: _attack,
      coins: _coins,
      cardsPassed: _cardsPassed,
      cardKey: _cardKey,
      inventory: List.of(_inventoryItems),
      deckPosition: _deckPosition,
      dungeonLevel: _dungeonLevel,
    );

    ItemCard? receivedItem;
    if (choice.givesRandomItem) {
      receivedItem = getRandomUnlockedItemCard(
        _random,
        UnlockedItemsService.instance.unlockedIds,
      );
      if (receivedItem != null) _inventoryItems.add(receivedItem);
    }

    var effectiveHealthDelta = choice.healthDelta;
    var effectiveAttackDelta = choice.attackDelta;
    var effectiveCoinsDelta = choice.coinsDelta;
    final triggeredBuffs = <String>[];

    // 1. Зеркало искажения
    if (_invertNextChoice) {
      _invertNextChoice = false;
      if (effectiveHealthDelta < 0) effectiveHealthDelta = -effectiveHealthDelta;
      if (effectiveAttackDelta < 0) effectiveAttackDelta = -effectiveAttackDelta;
      if (effectiveCoinsDelta < 0) effectiveCoinsDelta = -effectiveCoinsDelta;
      triggeredBuffs.add('🫞 Зеркало сработало');
    }

    // 2. Рунический щит
    if (effectiveHealthDelta < 0 && _shieldCharges > 0) {
      _shieldCharges--;
      effectiveHealthDelta = 0;
      triggeredBuffs.add('🛡️ Щит поглотил урон');
    }

    // 3. Шипы
    if (effectiveHealthDelta < 0 && _thornmailActive) {
      _thornmailActive = false;
      final bonusGold = effectiveHealthDelta.abs() * 2;
      effectiveCoinsDelta += bonusGold;
      triggeredBuffs.add('🌵 Шипы дали +$bonusGold 🪙');
    }

    // 4. Магнит жадности
    if (effectiveCoinsDelta > 0 && _greedMagnetTurns > 0) {
      effectiveCoinsDelta *= 2;
      triggeredBuffs.add('🧲 x2 золото');
    }
    if (_greedMagnetTurns > 0) _greedMagnetTurns--;

    _isRevealingChoices = false;

    setState(() {
      _health = (_health + effectiveHealthDelta).clamp(0, 999);
      _attack = (_attack + effectiveAttackDelta).clamp(0, 99);
      _coins = (_coins + effectiveCoinsDelta).clamp(0, 999999);
      _lastFeedback = _buildFeedback(
        choice,
        receivedItem: receivedItem,
        buffsNote: triggeredBuffs.isNotEmpty ? triggeredBuffs.join(', ') : null,
        wasBoss: wasBoss,
      );

      _advanceCard(wasBoss: wasBoss);

      if (_health <= 0) {
        _result = GameResult.gameOver;
        if (_coins > 0) PlayerCoinsService.instance.applyDelta(_coins);
      }
    });
  }

  String _buildFeedback(
    CardChoice choice, {
    ItemCard? receivedItem,
    String? buffsNote,
    bool wasBoss = false,
  }) {
    final parts = <String>[];
    if (wasBoss) parts.add('⚔ Босс повержен!');
    if (buffsNote != null) parts.add(buffsNote);
    if (receivedItem != null) parts.add('Получено: ${receivedItem.title}');
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

  // ─── Использование предметов ─────────────────

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
          // Пропуск карточки не засчитывается как победа над боссом
          _advanceCard(wasBoss: false);
          _lastFeedback = 'Событие пропущено!';
          break;
        case ItemEffectType.shield:
          _shieldCharges += item.value;
          _lastFeedback = 'Рунический щит активирован! (+${item.value} заряд) 🛡️';
          break;
        case ItemEffectType.invertNext:
          _invertNextChoice = true;
          _lastFeedback = 'Зеркало искажения: потери станут выгодой! 🫞';
          break;
        case ItemEffectType.revealChoice:
          _isRevealingChoices = true;
          _lastFeedback = 'Око провидца раскрыло тайны карты! 👁️';
          break;
        case ItemEffectType.rewind:
          if (_lastTurnSnapshot != null) {
            _health = _lastTurnSnapshot!.health;
            _attack = _lastTurnSnapshot!.attack;
            _coins = _lastTurnSnapshot!.coins;
            _cardsPassed = _lastTurnSnapshot!.cardsPassed;
            _cardKey = _lastTurnSnapshot!.cardKey;
            _deckPosition = _lastTurnSnapshot!.deckPosition;
            // Восстанавливаем уровень и перестраиваем колоду если нужно
            if (_dungeonLevel != _lastTurnSnapshot!.dungeonLevel) {
              _dungeonLevel = _lastTurnSnapshot!.dungeonLevel;
              _rebuildDeck();
              _deckPosition = _lastTurnSnapshot!.deckPosition;
            }
            _inventoryItems
              ..clear()
              ..addAll(_lastTurnSnapshot!.inventory);
            _lastTurnSnapshot = null;
            _discoverCurrentCard();
            _lastFeedback = 'Время отмотано назад! ⏳';
          } else {
            _health = (_health + 3).clamp(0, 999);
            _lastFeedback = 'Песочные часы восстановили +3 ❤ (нет прошлого хода)';
          }
          break;
        case ItemEffectType.thornmail:
          _thornmailActive = true;
          _lastFeedback = 'Шипованная броня готова! 🌵';
          break;
        case ItemEffectType.transmute:
          if (_coins >= 10) {
            final bundles = _coins ~/ 10;
            final usedCoins = bundles * 10;
            _coins -= usedCoins;
            _attack = (_attack + bundles).clamp(0, 99);
            _health = (_health + bundles * 2).clamp(0, 999);
            _lastFeedback = 'Алхимия: -$usedCoins 🪙 → +$bundles ⚡, +${bundles * 2} ❤ ⚗️';
          } else {
            _lastFeedback = 'Недостаточно монет (нужно 10 🪙)!';
          }
          break;
        case ItemEffectType.shadowPact:
          final hpLoss = (_health / 2).ceil();
          _health = (_health - hpLoss).clamp(1, 999);
          final bonusCoins = _coins;
          _coins = (_coins * 2).clamp(0, 999999);
          final shadowItem = getRandomUnlockedItemCard(
            _random,
            UnlockedItemsService.instance.unlockedIds,
          );
          if (shadowItem != null) _inventoryItems.add(shadowItem);
          _lastFeedback =
              'Пакт: -$hpLoss ❤, +$bonusCoins 🪙${shadowItem != null ? ', +${shadowItem.title}' : ''} 📜';
          break;
        case ItemEffectType.greedMagnet:
          _greedMagnetTurns += 3;
          _lastFeedback = 'Магнит жадности: +3 хода удвоения золота! 🧲';
          break;
        case ItemEffectType.diceOfFate:
          final roll = _random.nextInt(6) + 1;
          if (roll <= 2) {
            if (_coins >= 10 && _random.nextBool()) {
              _coins = (_coins - 10).clamp(0, 999999);
              _lastFeedback = '🎲 Кубик [$roll]: Потеряно 10 🪙';
            } else {
              _health = (_health - 3).clamp(1, 999);
              _lastFeedback = '🎲 Кубик [$roll]: Потеряно 3 ❤';
            }
          } else if (roll <= 4) {
            final diceCard = getRandomUnlockedItemCard(_random, UnlockedItemsService.instance.unlockedIds) ??
                allItemCards[_random.nextInt(allItemCards.length)];
            _inventoryItems.add(diceCard);
            _lastFeedback = '🎲 Кубик [$roll]: Артефакт "${diceCard.title}"! 🎁';
          } else {
            _health = (_health + 5).clamp(0, 999);
            _attack = (_attack + 2).clamp(0, 99);
            _coins = (_coins + 25).clamp(0, 999999);
            _lastFeedback = '🎲 Кубик [$roll]: ДЖЕКПОТ! +5 ❤, +2 ⚡, +25 🪙 🎉';
          }
          break;
        case ItemEffectType.smokeBomb:
          final bestCoins = max(0, max(
            _currentCard.leftChoice.coinsDelta,
            _currentCard.rightChoice.coinsDelta,
          )).toInt();
          if (bestCoins > 0) _coins = (_coins + bestCoins).clamp(0, 999999);
          _advanceCard(wasBoss: false);
          _lastFeedback = '💨 Дымовая шашка: чистый побег!${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}';
          break;
        case ItemEffectType.bribery:
          if (_coins >= 15) {
            final wasBoss = _isCurrentBoss;
            _coins -= 15;
            final leftScore = _currentCard.leftChoice.coinsDelta +
                _currentCard.leftChoice.healthDelta +
                _currentCard.leftChoice.attackDelta;
            final rightScore = _currentCard.rightChoice.coinsDelta +
                _currentCard.rightChoice.healthDelta +
                _currentCard.rightChoice.attackDelta;
            final bestChoice =
                rightScore >= leftScore ? _currentCard.rightChoice : _currentCard.leftChoice;
            _health = (_health + max(0, bestChoice.healthDelta).toInt()).clamp(0, 999);
            _attack = (_attack + max(0, bestChoice.attackDelta).toInt()).clamp(0, 99);
            _coins = (_coins + max(0, bestChoice.coinsDelta).toInt()).clamp(0, 999999);
            if (bestChoice.givesRandomItem) {
              final bribeItem = getRandomUnlockedItemCard(
                _random,
                UnlockedItemsService.instance.unlockedIds,
              );
              if (bribeItem != null) _inventoryItems.add(bribeItem);
            }
            _advanceCard(wasBoss: wasBoss);
            _lastFeedback = '💰 Подкуп удался (-15 🪙): угроза нейтрализована!';
          } else {
            _lastFeedback = 'Недостаточно монет (нужно 15 🪙)!';
          }
          break;
      }
    });
  }

  // ─── UI ─────────────────────────────────────

  void _openInventory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: InventorySheet(items: _inventoryItems, onUseItem: _useItem),
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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoss = _isCurrentBoss;
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
                    dungeonLevel: _dungeonLevel,
                    nextBossIn: _result == GameResult.playing ? _nextBossIn : null,
                  ),
                  if (_result == GameResult.playing)
                    _ActiveBuffsBar(
                      shieldCharges: _shieldCharges,
                      invertNextChoice: _invertNextChoice,
                      isRevealingChoices: _isRevealingChoices,
                      greedMagnetTurns: _greedMagnetTurns,
                      thornmailActive: _thornmailActive,
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
                  // Предупреждение о боссе
                  if (_result == GameResult.playing && isBoss)
                    _BossWarningBanner(dungeonLevel: _dungeonLevel),
                  Expanded(
                    child: Center(
                      child: _result == GameResult.playing
                          ? SwipeCard(
                              key: ValueKey(_cardKey),
                              event: _currentCard,
                              currentCoins: _coins,
                              currentAttack: _attack,
                              hasUnlockedItems: UnlockedItemsService.instance.count > 0,
                              isRevealingChoices: _isRevealingChoices,
                              isBoss: isBoss,
                              dungeonLevel: _dungeonLevel,
                              onSwipe: _onSwipe,
                            )
                          : _ResultOverlay(
                              cardsPassed: _cardsPassed,
                              health: _health,
                              attack: _attack,
                              dungeonLevel: _dungeonLevel,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
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

// ─── Баннер появления босса ─────────────────────────────────

class _BossWarningBanner extends StatelessWidget {
  const _BossWarningBanner({required this.dungeonLevel});

  final int dungeonLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B0000), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.crisis_alert, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '⚔ БОСС · Уровень $dungeonLevel — готовься к бою!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Панель активных баффов ─────────────────────────────────

class _ActiveBuffsBar extends StatelessWidget {
  const _ActiveBuffsBar({
    required this.shieldCharges,
    required this.invertNextChoice,
    required this.isRevealingChoices,
    required this.greedMagnetTurns,
    required this.thornmailActive,
  });

  final int shieldCharges;
  final bool invertNextChoice;
  final bool isRevealingChoices;
  final int greedMagnetTurns;
  final bool thornmailActive;

  bool get _hasAnyBuff =>
      shieldCharges > 0 ||
      invertNextChoice ||
      isRevealingChoices ||
      greedMagnetTurns > 0 ||
      thornmailActive;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyBuff) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            if (shieldCharges > 0)
              _BuffChip(emoji: '🛡️', label: 'Щит ×$shieldCharges', color: const Color(0xFF29B6F6)),
            if (invertNextChoice)
              const _BuffChip(emoji: '🪞', label: 'Зеркало', color: Color(0xFFAB47BC)),
            if (isRevealingChoices)
              const _BuffChip(emoji: '👁️', label: 'Ясновидение', color: Color(0xFF26A69A)),
            if (greedMagnetTurns > 0)
              _BuffChip(emoji: '🧲', label: 'x2 монеты ×$greedMagnetTurns', color: const Color(0xFFFF7043)),
            if (thornmailActive)
              const _BuffChip(emoji: '🌵', label: 'Шипы', color: Color(0xFF8D6E63)),
          ],
        ),
      ),
    );
  }
}

class _BuffChip extends StatelessWidget {
  const _BuffChip({required this.emoji, required this.label, required this.color});

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Экран итогов ───────────────────────────────────────────

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.cardsPassed,
    required this.health,
    required this.attack,
    required this.dungeonLevel,
    required this.runCoins,
    required this.totalCoins,
    required this.onRestart,
    required this.onMenu,
  });

  final int cardsPassed;
  final int health;
  final int attack;
  final int dungeonLevel;
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
                'Вы выдержали $cardsPassed событий!\nДобрались до уровня: $dungeonLevel',
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
                    child: _ResultStat(
                      label: 'За забег',
                      value: '+$runCoins 🪙',
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultStat(
                      label: 'Итого',
                      value: '$totalCoins 🪙',
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: const Text('Снова в бой'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMenu,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('В главное меню'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
