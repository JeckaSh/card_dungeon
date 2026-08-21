import 'dart:math';

import 'package:flutter/material.dart';

import '../data/events.dart';
import '../services/discovered_events.dart';
import '../services/player_coins_service.dart';
import '../models/event_card.dart';
import '../widgets/stats_bar.dart';
import '../widgets/swipe_card.dart';

const _cardsToWin = 10;
const _initialHealth = 10;
const _initialAttack = 3;

enum GameResult { playing, won, lost }

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
  // Общий баланс монет игрока (инвентарь)
  int _coins = 0;
  // Баланс до начала игры (для отката при поражении/выходе)
  int _balanceAtStart = 0;
  // Монеты, собранные за эту сессию
  int _sessionCoins = 0;
  GameResult _result = GameResult.playing;
  String? _lastFeedback;
  int _cardKey = 0;

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  Future<void> _loadAndStart() async {
    await PlayerCoinsService.instance.load();
    setState(() {
      _coins = PlayerCoinsService.instance.balance;
      _balanceAtStart = _coins;
    });
    _startNewGame();
  }

  void _startNewGame() {
    _deck = List.of(allEvents)..shuffle(_random);
    _balanceAtStart = PlayerCoinsService.instance.balance;
    setState(() {
      _health = _initialHealth;
      _attack = _initialAttack;
      _cardsPassed = 0;
      _coins = _balanceAtStart;
      _sessionCoins = 0;
      _result = GameResult.playing;
      _lastFeedback = null;
      _cardKey = 0;
    });
    _discoverCurrentCard();
  }

  void _discoverCurrentCard() {
    DiscoveredEventsService.instance.markDiscovered(_currentCard.id);
  }

  EventCard get _currentCard => _deck[_cardsPassed % _deck.length];

  void _onSwipe(bool isRight) {
    if (_result != GameResult.playing) return;

    final choice = isRight ? _currentCard.rightChoice : _currentCard.leftChoice;

    // Проверяем доступность выбора (монеты и атака)
    if (choice.coinsDelta < 0 && _coins < choice.coinsDelta.abs()) return;
    if (choice.attackDelta < 0 && _attack < choice.attackDelta.abs()) return;

    // Применяем изменения монет к балансу синхронно
    PlayerCoinsService.instance.applyDelta(choice.coinsDelta);

    setState(() {
      _health = (_health + choice.healthDelta).clamp(0, 999);
      _attack = (_attack + choice.attackDelta).clamp(0, 99);
      _coins = PlayerCoinsService.instance.balance;
      if (choice.coinsDelta > 0) _sessionCoins += choice.coinsDelta;
      _lastFeedback = _buildFeedback(choice);
      _cardsPassed++;
      _cardKey++;

      if (_health <= 0) {
        _result = GameResult.lost;
        // При проигрыше откатываем баланс до начала игры
        PlayerCoinsService.instance.restoreBalance(_balanceAtStart);
        _coins = _balanceAtStart;
      } else if (_cardsPassed >= _cardsToWin) {
        _result = GameResult.won;
      } else {
        _discoverCurrentCard();
      }
    });
  }

  String _buildFeedback(CardChoice choice) {
    final parts = <String>[];
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

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Покинуть подземелье?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Накопленные монеты за этот забег будут потеряны.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Остаться',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Откатываем баланс до начала игры
      PlayerCoinsService.instance.restoreBalance(_balanceAtStart);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            StatsBar(
              health: _health,
              attack: _attack,
              cardsPassed: _cardsPassed,
              cardsTotal: _cardsToWin,
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
                        onSwipe: _onSwipe,
                      )
                    : _ResultOverlay(
                        won: _result == GameResult.won,
                        cardsPassed: _cardsPassed,
                        health: _health,
                        attack: _attack,
                        coins: _coins,
                        sessionCoins: _sessionCoins,
                        onRestart: _startNewGame,
                        onMenu: () => Navigator.of(context).pop(),
                      ),
              ),
            ),
            if (_result == GameResult.playing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
                    TextButton.icon(
                      onPressed: _confirmLeave,
                      icon: Icon(
                        Icons.exit_to_app,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      label: Text(
                        'Покинуть подземелье',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.won,
    required this.cardsPassed,
    required this.health,
    required this.attack,
    required this.coins,
    required this.sessionCoins,
    required this.onRestart,
    required this.onMenu,
  });

  final bool won;
  final int cardsPassed;
  final int health;
  final int attack;
  final int coins;
  final int sessionCoins;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            won ? Icons.emoji_events : Icons.heart_broken,
            size: 72,
            color: won ? const Color(0xFFF5A623) : const Color(0xFFE94560),
          ),
          const SizedBox(height: 24),
          Text(
            won ? 'Победа!' : 'Поражение',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            won
                ? 'Вы прошли все $cardsPassed событий!\nЗдоровье: $health  ·  Атака: $attack'
                : 'Здоровье упало до нуля на $cardsPassed-й карточке.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
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
                        '+$sessionCoins',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'за игру',
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
                        '$coins',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'всего',
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
    );
  }
}
