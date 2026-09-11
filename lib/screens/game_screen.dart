import 'dart:math';

import 'package:flutter/material.dart';

import '../data/events.dart';
import '../data/items.dart';
import '../models/event_card.dart';
import '../models/item_card.dart';
import '../services/discovered_events.dart';
import '../services/player_coins_service.dart';
import '../services/player_stats_service.dart';
import '../services/run_chronicle_service.dart';
import '../services/unlocked_items_service.dart';
import '../widgets/inventory_sheet.dart';
import '../widgets/stats_bar.dart';
import '../widgets/swipe_card.dart';

int get _initialHealth => PlayerStatsService.instance.startingHealth;
int get _initialAttack => PlayerStatsService.instance.startingAttack;

/// Номер карточки (1-indexed), на которой появляется босс
const _bossEvery = 20;

enum GameResult { playing, gameOver, victory }

/// Запись в дневнике героя — одно примечательное событие за забег.
class JournalEntry {
  JournalEntry({
    required this.emoji,
    required this.text,
    required this.cardNumber,
  });

  final String emoji;
  final String text;
  final int cardNumber;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.initialInventory,
    this.initialDungeonLevel,
    this.initialCardsPassed,
    this.initialCoins,
  });

  final List<ItemCard>? initialInventory;
  final int? initialDungeonLevel;
  final int? initialCardsPassed;
  final int? initialCoins;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
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
  int _poisonTurns = 0;
  int _bleedTurns = 0;
  int _blindnessTurns = 0;
  int _midasCurseTurns = 0;
  final List<JournalEntry> _journal = [];

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

  void _grantStartingCards() {
    final count = PlayerStatsService.instance.startingCardsCount;
    for (int i = 0; i < count; i++) {
      final card = getRandomUnlockedItemCard(
        _random,
        UnlockedItemsService.instance.unlockedIds,
      );
      if (card != null) {
        _inventoryItems.add(card);
      }
    }
  }

  void _initGame() {
    _health = _initialHealth;
    _attack = _initialAttack;
    _cardsPassed = widget.initialCardsPassed ?? 0;
    _deckPosition = 0;
    _dungeonLevel = widget.initialDungeonLevel ?? 1;
    _coins = widget.initialCoins ?? 0;
    _inventoryItems.clear();
    if (widget.initialInventory != null) {
      _inventoryItems.addAll(widget.initialInventory!);
    } else {
      _grantStartingCards();
    }
    _result = GameResult.playing;
    _lastFeedback = null;
    _cardKey = 0;
    _shieldCharges = 0;
    _invertNextChoice = false;
    _isRevealingChoices = false;
    _greedMagnetTurns = 0;
    _thornmailActive = false;
    _poisonTurns = 0;
    _bleedTurns = 0;
    _blindnessTurns = 0;
    _midasCurseTurns = 0;
    _journal.clear();
    _rebuildDeck();
    _discoverCurrentCard();
    _addJournalEntry('🗡️', 'Герой вошёл в подземелье');
    if (widget.initialInventory == null && _inventoryItems.isNotEmpty) {
      final names = _inventoryItems.map((e) => e.title).join(', ');
      _addJournalEntry('🎒', 'Стартовое снаряжение: $names');
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
      PlayerStatsService.instance.load(),
    ]);
    if (mounted) {
      setState(() {
        if (_cardsPassed == 0) {
          _health = _initialHealth;
          _attack = _initialAttack;
          if (widget.initialInventory == null &&
              _inventoryItems.isEmpty &&
              PlayerStatsService.instance.startingCardsCount > 0) {
            _grantStartingCards();
            if (_inventoryItems.isNotEmpty) {
              final names = _inventoryItems.map((e) => e.title).join(', ');
              _addJournalEntry('🎒', 'Стартовое снаряжение: $names');
            }
          }
        }
      });
    }
  }

  void _startNewGame() {
    setState(() {
      _initGame();
    });
  }

  // ─── Работа с колодой ───────────────────────

  /// Строит колоду из карточек текущего уровня и сбрасывает позицию.
  /// Гарантирует ровно [PlayerStatsService.guaranteedMerchants] торговцев
  /// в первых [_bossEvery]-1 позициях (до встречи с боссом).
  /// При 0 — торговцы появляются случайно.
  void _rebuildDeck() {
    var cards = allEvents.where((e) => e.level == _dungeonLevel).toList();
    if (cards.isEmpty) {
      cards = allEvents.toList();
    }
    cards.shuffle(_random);

    final guaranteed = PlayerStatsService.instance.guaranteedMerchants;
    if (guaranteed > 0) {
      // Количество карт, которые игрок видит до босса
      final visibleCount = min(_bossEvery - 1, cards.length);

      // Собираем доступных торговцев ТОЛЬКО текущего уровня
      final currentLevelMerchants = allEvents
          .where((e) => e.type == EventType.merchant && e.level == _dungeonLevel)
          .toList();
      final pool = currentLevelMerchants.isNotEmpty
          ? currentLevelMerchants
          : cards.where((e) => e.type == EventType.merchant).toList();

      if (pool.isNotEmpty) {
        // Сколько торговцев уже есть среди первых visibleCount карт
        var merchantsInVisible = cards
            .take(visibleCount)
            .where((e) => e.type == EventType.merchant)
            .length;

        // Добавляем недостающих торговцев
        for (var i = merchantsInVisible; i < guaranteed; i++) {
          // Берём торговца из хвоста колоды или дублируем из пула текущего уровня
          final tailIdx = cards
              .skip(visibleCount)
              .toList()
              .indexWhere((e) => e.type == EventType.merchant);

          final EventCard merchantCard;
          if (tailIdx != -1) {
            final realIdx = visibleCount + tailIdx;
            merchantCard = cards.removeAt(realIdx);
          } else {
            merchantCard = pool[_random.nextInt(pool.length)];
          }

          // Вставляем в случайное свободное место среди первых visibleCount позиций
          final insertPos = _random.nextInt(visibleCount);
          cards.insert(insertPos, merchantCard);
          merchantsInVisible++;
        }
      }
    }

    _deck = cards;
    _deckPosition = 0;
  }

  @visibleForTesting
  List<EventCard> get deck => List.unmodifiable(_deck);

  /// Выбирает боссовую карточку по номеру встреченного босса.
  EventCard _selectBoss() {
    final bossNumber = (_cardsPassed + 1) ~/ _bossEvery;
    return allBossCards[(bossNumber - 1) % allBossCards.length];
  }

  void _discoverCurrentCard() {
    DiscoveredEventsService.instance.markDiscovered(_currentCard.id);
  }

  /// Добавляет запись в дневник героя.
  void _addJournalEntry(String emoji, String text) {
    if (_journal.length >= 500) _journal.removeAt(0);
    _journal.add(
      JournalEntry(emoji: emoji, text: text, cardNumber: _cardsPassed + 1),
    );
  }

  String _eventActionEmoji(EventType type, int healthDelta) {
    switch (type) {
      case EventType.monster:
        return healthDelta < 0 ? '🗡️' : '⚔️';
      case EventType.trap:
        return healthDelta < 0 ? '💥' : '🪤';
      case EventType.treasure:
        return '💰';
      case EventType.merchant:
        return '🏪';
      case EventType.rest:
        return '🏕️';
      case EventType.mystery:
        return '🔮';
      case EventType.boss:
        return '⚔️';
    }
  }

  /// Переходит к следующей карточке.
  /// [wasBoss] — была ли текущая карточка боссом (для повышения уровня).
  void _advanceCard({bool wasBoss = false}) {
    _cardsPassed++;
    _cardKey++;
    if (wasBoss) {
      // Победа над боссом → проверяем наличие карточек событий следующего уровня
      final nextLevel = _dungeonLevel + 1;
      final hasNextLevelCards = allEvents.any((e) => e.level == nextLevel);
      if (!hasNextLevelCards) {
        // Карточек следующего уровня нет — подземелье успешно пройдено!
        _result = GameResult.victory;
        _addJournalEntry('🏆', 'Подземелье успешно пройдено!');
        if (_coins > 0) PlayerCoinsService.instance.applyDelta(_coins);
        _saveChronicle(isVictory: true);
        return;
      }
      _dungeonLevel = nextLevel;
      _rebuildDeck();
      _addJournalEntry('🏰', 'Достигнут уровень подземелья $_dungeonLevel');
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
    if (choice.givesRandomItem && UnlockedItemsService.instance.count == 0) {
      return;
    }

    final cardTitle = _currentCard.title;

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

    // 0. Проклятие Мидаса (если активно, монеты за выбор не начисляются)
    if (_midasCurseTurns > 0 && effectiveCoinsDelta > 0) {
      effectiveCoinsDelta = 0;
      triggeredBuffs.add('👑 Проклятие Мидаса: золото обратилось в прах');
    }

    // 1. Зеркало искажения
    if (_invertNextChoice) {
      _invertNextChoice = false;
      if (effectiveHealthDelta < 0) {
        effectiveHealthDelta = -effectiveHealthDelta;
      }
      if (effectiveAttackDelta < 0) {
        effectiveAttackDelta = -effectiveAttackDelta;
      }
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

    // 5. Наложение статусов от выбора
    if (choice.statusEffect != null && _random.nextDouble() < choice.statusChance) {
      switch (choice.statusEffect!) {
        case StatusEffectType.poison:
          _poisonTurns = 3;
          triggeredBuffs.add('🧪 Отравлен на 3 хода!');
          break;
        case StatusEffectType.bleed:
          _bleedTurns = 3;
          triggeredBuffs.add('🩸 Кровотечение на 3 хода!');
          break;
        case StatusEffectType.blindness:
          _blindnessTurns = 3;
          triggeredBuffs.add('👁️‍🗨️ Слепота на 3 хода!');
          break;
        case StatusEffectType.midasCurse:
          _midasCurseTurns = 3;
          triggeredBuffs.add('👑 Проклятие Мидаса на 3 хода!');
          break;
      }
    }

    // 6. Периодический урон от текущих статусов (DoT)
    int dotDamage = 0;
    if (_poisonTurns > 0) {
      dotDamage += 1;
      _poisonTurns--;
      triggeredBuffs.add('🧪 Яд (-1 ❤)');
    }
    if (_bleedTurns > 0) {
      dotDamage += 2;
      _bleedTurns--;
      triggeredBuffs.add('🩸 Кровотечение (-2 ❤)');
    }
    if (_blindnessTurns > 0) {
      _blindnessTurns--;
    }
    if (_midasCurseTurns > 0) {
      _midasCurseTurns--;
    }

    _isRevealingChoices = false;

    setState(() {
      _health = (_health + effectiveHealthDelta - dotDamage).clamp(0, 999);
      _attack = (_attack + effectiveAttackDelta).clamp(0, 99);
      _coins = (_coins + effectiveCoinsDelta).clamp(0, 999999);

      // ── Дневник героя (запись каждого действия) ───────────────────
      final actionEmoji = wasBoss
          ? (isRight ? '🏃' : '⚔️')
          : _eventActionEmoji(_currentCard.type, effectiveHealthDelta);

      final details = <String>[];
      if (effectiveHealthDelta != 0) {
        details.add(
          '${effectiveHealthDelta > 0 ? '+' : ''}$effectiveHealthDelta ❤',
        );
      }
      if (dotDamage > 0) {
        details.add('-$dotDamage ❤ статус');
      }
      if (effectiveAttackDelta != 0) {
        details.add(
          '${effectiveAttackDelta > 0 ? '+' : ''}$effectiveAttackDelta ⚡',
        );
      }
      if (effectiveCoinsDelta != 0) {
        details.add(
          '${effectiveCoinsDelta > 0 ? '+' : ''}$effectiveCoinsDelta 🪙',
        );
      }
      if (receivedItem != null) {
        details.add('🎒 ${receivedItem.title}');
      }
      if (triggeredBuffs.isNotEmpty) {
        details.addAll(triggeredBuffs);
      }

      final detailsStr = details.isNotEmpty ? ' (${details.join(', ')})' : '';
      _addJournalEntry(actionEmoji, '$cardTitle: ${choice.label}$detailsStr');

      if (wasBoss && !isRight && _health > 0) {
        _addJournalEntry('👑', 'Босс $cardTitle повержен!');
      }
      // ─────────────────────────────────────────────────────────────

      _lastFeedback = _buildFeedback(
        choice,
        receivedItem: receivedItem,
        buffsNote: triggeredBuffs.isNotEmpty ? triggeredBuffs.join(', ') : null,
        wasBoss: wasBoss,
      );

      if (_health <= 0) {
        _cardsPassed++;
        _result = GameResult.gameOver;
        final deathCause = dotDamage > 0 && effectiveHealthDelta == 0
            ? 'Герой пал от ран ($cardTitle)'
            : 'Герой пал — убит $cardTitle';
        _addJournalEntry('☠️', deathCause);
        if (_coins > 0) PlayerCoinsService.instance.applyDelta(_coins);
        _saveChronicle(isVictory: false);
      } else {
        _advanceCard(wasBoss: wasBoss);
      }
    });
  }

  /// Сохраняет текущий забег в хронику.
  void _saveChronicle({required bool isVictory}) {
    final journalLines = _journal
        .map((e) => '${e.emoji} [${e.cardNumber}] ${e.text}')
        .toList();
    RunChronicleService.instance.addRecord(
      RunRecord(
        endedAt: DateTime.now(),
        cardsPassed: _cardsPassed,
        dungeonLevel: _dungeonLevel,
        coins: _coins,
        isVictory: isVictory,
        journal: journalLines,
      ),
    );
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
      parts.add(
        'Здоровье ${choice.healthDelta > 0 ? '+' : ''}${choice.healthDelta}',
      );
    }
    if (choice.attackDelta != 0) {
      parts.add(
        'Атака ${choice.attackDelta > 0 ? '+' : ''}${choice.attackDelta}',
      );
    }
    if (choice.coinsDelta != 0) {
      parts.add(
        'Монеты ${choice.coinsDelta > 0 ? '+' : ''}${choice.coinsDelta}',
      );
    }
    return parts.isEmpty ? choice.label : parts.join(', ');
  }

  // ─── Использование предметов ─────────────────

  void _useItem(int index, ItemCard item) {
    if (index < 0 || index >= _inventoryItems.length) return;
    String resultTitle = item.title;
    String resultDescription = item.description;

    setState(() {
      _inventoryItems.removeAt(index);
      switch (item.effectType) {
        case ItemEffectType.heal:
          _health = (_health + item.value).clamp(0, 999);
          _lastFeedback = '${item.title}: +${item.value} ❤';
          _addJournalEntry(
            '🧪',
            'Использовано ${item.title}: +${item.value} ❤',
          );
          resultTitle = '+${item.value} ❤';
          resultDescription =
              'Здоровье героя восстановлено на +${item.value} ❤.\nТекущее здоровье: $_health ❤.';
          break;
        case ItemEffectType.attack:
          _attack = (_attack + item.value).clamp(0, 99);
          _lastFeedback = '${item.title}: +${item.value} ⚡';
          _addJournalEntry('⚡', 'Использован ${item.title}: +${item.value} ⚡');
          resultTitle = '+${item.value} ⚡';
          resultDescription =
              'Сила удара увеличена на +${item.value} ⚡.\nТекущая атака: $_attack ⚡.';
          break;
        case ItemEffectType.skip:
          final wasBoss = _isCurrentBoss;
          final skippedCard = _currentCard.title;
          _advanceCard(wasBoss: wasBoss);
          _lastFeedback = wasBoss
              ? '⏩ Пропуск хода: босс обойдён стороной!'
              : 'Событие пропущено!';
          _addJournalEntry(
            '⏩',
            'Использован ${item.title}: пропущено "$skippedCard"',
          );
          resultTitle = wasBoss ? 'Босс пропущен ⏩' : 'Событие пропущено';
          resultDescription = wasBoss
              ? 'Магический свиток перенёс вас мимо босса "$skippedCard"! Уровень подземелья успешно пройден без боя и потерь.'
              : 'Свиток перенёс вас в безопасное место: карта "$skippedCard" успешно обойдена стороной без урона и потерь.';
          break;
        case ItemEffectType.shield:
          _shieldCharges += item.value;
          _lastFeedback =
              'Рунический щит активирован! (+${item.value} заряд) 🛡️';
          _addJournalEntry(
            '🛡️',
            'Использован ${item.title}: +${item.value} 🛡️ (всего $_shieldCharges)',
          );
          resultTitle = 'Щит активирован (+${item.value} 🛡️)';
          resultDescription =
              'Рунический щит готов поглотить следующий урон по здоровью.\nВсего зарядов щита: $_shieldCharges.';
          break;
        case ItemEffectType.invertNext:
          _invertNextChoice = true;
          _lastFeedback = 'Зеркало искажения: потери станут выгодой! 🫞';
          _addJournalEntry(
            '🪞',
            'Использовано ${item.title}: искажение активировано',
          );
          resultTitle = 'Зеркало искажения 🪞';
          resultDescription =
              'Искажение активировано! На следующем ходу любые потери здоровья, атаки или монет превратятся в равную выгоду.';
          break;
        case ItemEffectType.thornmail:
          _thornmailActive = true;
          _lastFeedback = 'Шипованная броня готова! 🌵';
          _addJournalEntry(
            '🌵',
            'Использована ${item.title}: шипы активированы',
          );
          resultTitle = 'Шипованная броня 🌵';
          resultDescription =
              'Шипы наготове! При получении урона на следующем шаге вы нанесёте контратаку и получите x2 золота за каждую единицу потерянного здоровья.';
          break;
        case ItemEffectType.transmute:
          if (_coins >= 10) {
            final maxBundles = 10; // Ограничение: максимум 100 монет (10 * 10)
            final bundles = min(_coins ~/ 10, maxBundles);
            final usedCoins = bundles * 10;
            _coins -= usedCoins;
            _attack = (_attack + bundles).clamp(0, 99);
            _health = (_health + bundles * 2).clamp(0, 999);
            _lastFeedback =
                'Алхимия: -$usedCoins 🪙 → +$bundles ⚡, +${bundles * 2} ❤ ⚗️';
            _addJournalEntry(
              '⚗️',
              'Алхимия: $usedCoins🪙 → +$bundles⚡ +${bundles * 2}❤',
            );
            resultTitle = 'Трансмутация ⚗️';
            resultDescription =
                'Алхимический процесс успешен: $usedCoins 🪙 превращены в +$bundles ⚡ к атаке и +${bundles * 2} ❤ к здоровью!\nЗдоровье: $_health ❤, атака: $_attack ⚡.';
          } else {
            _inventoryItems.insert(index, item);
            _lastFeedback = 'Недостаточно монет (нужно 10 🪙)!';
            resultTitle = 'Недостаточно монет ⚗️';
            resultDescription =
                'Для алхимической трансмутации требуется минимум 10 🪙. Предмет сохранён в инвентаре.';
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
          _addJournalEntry('📜', 'Теневой пакт: -$hpLoss❤ → +$bonusCoins🪙');
          resultTitle = 'Теневой пакт 📜';
          resultDescription =
              'Сделка заключена: пожертвовано $hpLoss ❤, взамен получено +$bonusCoins 🪙${shadowItem != null ? ' и артефакт "${shadowItem.title}"' : ''}.\nЗдоровье: $_health ❤, баланс: $_coins 🪙.';
          break;
        case ItemEffectType.greedMagnet:
          _greedMagnetTurns += 3;
          _lastFeedback = 'Магнит жадности: +3 хода удвоения золота! 🧲';
          _addJournalEntry(
            '🧲',
            'Использован ${item.title}: x2 золото на 3 хода',
          );
          resultTitle = 'Магнит жадности 🧲';
          resultDescription =
              'Магнит активирован! Всё получаемое за выборы золото будет удваиваться на протяжении 3 ходов (осталось: $_greedMagnetTurns ходов).';
          break;
        case ItemEffectType.diceOfFate:
          final roll = _random.nextInt(6) + 1;
          if (roll <= 2) {
            if (_coins >= 10 && _random.nextBool()) {
              _coins = (_coins - 10).clamp(0, 999999);
              _lastFeedback = '🎲 Кубик [$roll]: Потеряно 10 🪙';
              _addJournalEntry('🎲', 'Кубик судьбы [$roll]: потеряно 10 🪙');
              resultTitle = 'Кубик [$roll]: Потеря 🎲';
              resultDescription =
                  'Неудача! Кубик судьбы забрал 10 🪙.\nТекущий баланс: $_coins 🪙.';
            } else {
              _health = (_health - 3).clamp(1, 999);
              _lastFeedback = '🎲 Кубик [$roll]: Потеряно 3 ❤';
              _addJournalEntry('🎲', 'Кубик судьбы [$roll]: потеряно 3 ❤');
              resultTitle = 'Кубик [$roll]: Урон 🎲';
              resultDescription =
                  'Неудача! Кубик судьбы отнял 3 ❤.\nТекущее здоровье: $_health ❤.';
            }
          } else if (roll <= 4) {
            final diceCard =
                getRandomUnlockedItemCard(
                  _random,
                  UnlockedItemsService.instance.unlockedIds,
                ) ??
                allItemCards[_random.nextInt(allItemCards.length)];
            _inventoryItems.add(diceCard);
            _lastFeedback =
                '🎲 Кубик [$roll]: Артефакт "${diceCard.title}"! 🎁';
            _addJournalEntry(
              '🎲',
              'Кубик судьбы [$roll]: получен артефакт "${diceCard.title}"',
            );
            resultTitle = 'Кубик [$roll]: Артефакт 🎁';
            resultDescription =
                'Кубик судьбы одарил вас новым предметом: "${diceCard.title}". Он добавлен в ваш инвентарь!';
          } else {
            _health = (_health + 5).clamp(0, 999);
            _attack = (_attack + 2).clamp(0, 99);
            _coins = (_coins + 25).clamp(0, 999999);
            _lastFeedback = '🎲 Кубик [$roll]: ДЖЕКПОТ! +5 ❤, +2 ⚡, +25 🪙 🎉';
            _addJournalEntry('🎲', 'Кубик судьбы: ДЖЕКПОТ! +5❤ +2⚡ +25🪙');
            resultTitle = 'Кубик [$roll]: ДЖЕКПОТ! 🎉';
            resultDescription =
                'Невероятное везение! Вы сорвали куш: +5 ❤ здоровья, +2 ⚡ к атаке и +25 🪙!\nЗдоровье: $_health ❤, атака: $_attack ⚡.';
          }
          break;
        case ItemEffectType.smokeBomb:
          final wasBoss = _isCurrentBoss;
          final bestCoins = max(
            0,
            max(
              _currentCard.leftChoice.coinsDelta,
              _currentCard.rightChoice.coinsDelta,
            ),
          ).toInt();
          if (bestCoins > 0) _coins = (_coins + bestCoins).clamp(0, 999999);
          final skippedCard = _currentCard.title;
          _advanceCard(wasBoss: wasBoss);
          _lastFeedback = wasBoss
              ? '💨 Дымовая шашка: босс ослеплён и пройден!${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}'
              : '💨 Дымовая шашка: чистый побег!${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}';
          _addJournalEntry(
            '💨',
            'Дымовая шашка: побег от "$skippedCard"${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}',
          );
          resultTitle = wasBoss ? 'Побег от босса 💨' : 'Побег в дыму 💨';
          resultDescription = wasBoss
              ? 'Вы бросили дымовую шашку и ослепили босса! "$skippedCard" остался позади, а уровень подземелья успешно пройден${bestCoins > 0 ? ', при этом подобрано +$bestCoins 🪙' : ''}!'
              : 'Вы бросили дымовую шашку и скрылись. Опасность "$skippedCard" благополучно пройдена стороной${bestCoins > 0 ? ', а в суматохе подобрано +$bestCoins 🪙' : ''}!';
          break;
        case ItemEffectType.bribery:
          if (_coins >= 15) {
            final wasBoss = _isCurrentBoss;
            _coins -= 15;
            final leftScore =
                _currentCard.leftChoice.coinsDelta +
                _currentCard.leftChoice.healthDelta +
                _currentCard.leftChoice.attackDelta;
            final rightScore =
                _currentCard.rightChoice.coinsDelta +
                _currentCard.rightChoice.healthDelta +
                _currentCard.rightChoice.attackDelta;
            final bestChoice = rightScore >= leftScore
                ? _currentCard.rightChoice
                : _currentCard.leftChoice;
            _health = (_health + max(0, bestChoice.healthDelta).toInt()).clamp(
              0,
              999,
            );
            _attack = (_attack + max(0, bestChoice.attackDelta).toInt()).clamp(
              0,
              99,
            );
            _coins = (_coins + max(0, bestChoice.coinsDelta).toInt()).clamp(
              0,
              999999,
            );
            ItemCard? bribeItem;
            if (bestChoice.givesRandomItem) {
              bribeItem = getRandomUnlockedItemCard(
                _random,
                UnlockedItemsService.instance.unlockedIds,
              );
              if (bribeItem != null) _inventoryItems.add(bribeItem);
            }
            final skippedCard = _currentCard.title;
            _advanceCard(wasBoss: wasBoss);
            _lastFeedback = '💰 Подкуп удался (-15 🪙): угроза нейтрализована!';
            _addJournalEntry(
              '💰',
              'Подкуп (-15 🪙): нейтрализовано "$skippedCard"${bribeItem != null ? ', 🎒 ${bribeItem.title}' : ''}',
            );
            resultTitle = 'Подкуп удался (-15 🪙) 💰';
            resultDescription =
                'Золото решило вопрос: потрачено 15 🪙, применён лучший исход события без боя и потерь!${bribeItem != null ? ' Также получен предмет: "${bribeItem.title}".' : ''}\nЗдоровье: $_health ❤, атака: $_attack ⚡.';
          } else {
            _inventoryItems.insert(index, item);
            _lastFeedback = 'Недостаточно монет (нужно 15 🪙)!';
            resultTitle = 'Недостаточно монет 💰';
            resultDescription =
                'Для подкупа требуется как минимум 15 🪙. Предмет сохранён в инвентаре.';
          }
          break;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showItemUsedDialog(item, resultTitle, resultDescription);
      }
    });
  }

  void _showItemUsedDialog(
    ItemCard item,
    String resultTitle,
    String resultDescription,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ItemUsedDialog(
        item: item,
        resultTitle: resultTitle,
        resultDescription: resultDescription,
      ),
    );
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
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE94560),
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Сдаться?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Сдаться и выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _addJournalEntry('🏳️', 'Герой сдался и покинул подземелье');
      _saveChronicle(isVictory: false);
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
                    nextBossIn: _result == GameResult.playing
                        ? _nextBossIn
                        : null,
                  ),
                  if (_result == GameResult.playing)
                    _ActiveBuffsBar(
                      shieldCharges: _shieldCharges,
                      invertNextChoice: _invertNextChoice,
                      isRevealingChoices: _isRevealingChoices,
                      greedMagnetTurns: _greedMagnetTurns,
                      thornmailActive: _thornmailActive,
                      poisonTurns: _poisonTurns,
                      bleedTurns: _bleedTurns,
                      blindnessTurns: _blindnessTurns,
                      midasCurseTurns: _midasCurseTurns,
                    ),
                  if (_lastFeedback != null && _result == GameResult.playing)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_lastFeedback),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                              hasUnlockedItems:
                                  UnlockedItemsService.instance.count > 0,
                              isRevealingChoices: _isRevealingChoices,
                              isBlind: _blindnessTurns > 0,
                              isBoss: isBoss,
                              dungeonLevel: _dungeonLevel,
                              onSwipe: _onSwipe,
                            )
                          : ResultOverlay(
                              cardsPassed: _cardsPassed,
                              health: _health,
                              attack: _attack,
                              dungeonLevel: _dungeonLevel,
                              runCoins: _coins,
                              totalCoins: PlayerCoinsService.instance.balance,
                              onRestart: _startNewGame,
                              onMenu: () => Navigator.of(context).pop(),
                              journal: List.of(_journal),
                              isVictory: _result == GameResult.victory,
                            ),
                    ),
                  ),
                  if (_result == GameResult.playing)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16,
                        left: 16,
                        right: 16,
                      ),
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
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _inventoryItems.isNotEmpty
                                        ? const Color(
                                            0xFFE94560,
                                          ).withValues(alpha: 0.6)
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
          Flexible(
            child: Text(
              '⚔ БОСС · Уровень $dungeonLevel — готовься к бою!',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
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
    this.poisonTurns = 0,
    this.bleedTurns = 0,
    this.blindnessTurns = 0,
    this.midasCurseTurns = 0,
  });

  final int shieldCharges;
  final bool invertNextChoice;
  final bool isRevealingChoices;
  final int greedMagnetTurns;
  final bool thornmailActive;
  final int poisonTurns;
  final int bleedTurns;
  final int blindnessTurns;
  final int midasCurseTurns;

  bool get _hasAnyBuff =>
      shieldCharges > 0 ||
      invertNextChoice ||
      isRevealingChoices ||
      greedMagnetTurns > 0 ||
      thornmailActive ||
      poisonTurns > 0 ||
      bleedTurns > 0 ||
      blindnessTurns > 0 ||
      midasCurseTurns > 0;

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
              _BuffChip(
                emoji: '🛡️',
                label: 'Щит ×$shieldCharges',
                color: const Color(0xFF29B6F6),
              ),
            if (invertNextChoice)
              const _BuffChip(
                emoji: '🪞',
                label: 'Зеркало',
                color: Color(0xFFAB47BC),
              ),
            if (isRevealingChoices)
              const _BuffChip(
                emoji: '👁️',
                label: 'Ясновидение',
                color: Color(0xFF26A69A),
              ),
            if (greedMagnetTurns > 0)
              _BuffChip(
                emoji: '🧲',
                label: 'x2 монеты ×$greedMagnetTurns',
                color: const Color(0xFFFF7043),
              ),
            if (thornmailActive)
              const _BuffChip(
                emoji: '🌵',
                label: 'Шипы',
                color: Color(0xFF8D6E63),
              ),
            if (poisonTurns > 0)
              _BuffChip(
                emoji: '🧪',
                label: 'Яд ×$poisonTurns (-1❤)',
                color: const Color(0xFF66BB6A),
              ),
            if (bleedTurns > 0)
              _BuffChip(
                emoji: '🩸',
                label: 'Кровотечение ×$bleedTurns (-2❤)',
                color: const Color(0xFFE53935),
              ),
            if (blindnessTurns > 0)
              _BuffChip(
                emoji: '👁️‍🗨️',
                label: 'Слепота ×$blindnessTurns',
                color: const Color(0xFF90A4AE),
              ),
            if (midasCurseTurns > 0)
              _BuffChip(
                emoji: '👑',
                label: 'Проклятие Мидаса ×$midasCurseTurns',
                color: const Color(0xFFFFB300),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuffChip extends StatelessWidget {
  const _BuffChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Экран итогов ───────────────────────────────────────────

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.cardsPassed,
    required this.health,
    required this.attack,
    required this.dungeonLevel,
    required this.runCoins,
    required this.totalCoins,
    required this.onRestart,
    required this.onMenu,
    required this.journal,
    this.isVictory = false,
  });

  final int cardsPassed;
  final int health;
  final int attack;
  final int dungeonLevel;
  final int runCoins;
  final int totalCoins;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final List<JournalEntry> journal;
  final bool isVictory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortScreen = constraints.maxHeight < 680;
        final isNarrowScreen = constraints.maxWidth < 380;
        final hPadding = isNarrowScreen ? 16.0 : (isShortScreen ? 20.0 : 28.0);
        final vPadding = isShortScreen ? 14.0 : 24.0;
        final iconSize = isShortScreen ? 52.0 : 68.0;
        final titleSize = isShortScreen ? 24.0 : 28.0;
        final spacing = isShortScreen ? 12.0 : 18.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: vPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                minHeight: (constraints.maxHeight - (vPadding * 2)).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isVictory
                        ? Icons.emoji_events
                        : (cardsPassed >= 20
                              ? Icons.emoji_events
                              : Icons.heart_broken),
                    size: iconSize,
                    color: isVictory
                        ? const Color(0xFFFFD700)
                        : (cardsPassed >= 20
                              ? const Color(0xFFF5A623)
                              : const Color(0xFFE94560)),
                  ),
                  SizedBox(height: isShortScreen ? 10 : 16),
                  Text(
                    isVictory ? 'Подземелье пройдено!' : 'Конец приключения',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isVictory ? const Color(0xFFFFD700) : Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isShortScreen ? 6 : 8),
                  Text(
                    isVictory
                        ? 'Поздравляем! Вы успешно прошли подземелье!\nВыдержано $cardsPassed событий · Уровень $dungeonLevel зачищен'
                        : 'Вы выдержали $cardsPassed событий!\nДобрались до уровня: $dungeonLevel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: isVictory ? 0.85 : 0.65,
                      ),
                      fontSize: isShortScreen ? 14 : 15,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultStat(
                          label: 'За забег',
                          value: '+$runCoins 🪙',
                          color: const Color(0xFFFFD700),
                          isCompact: isShortScreen,
                        ),
                      ),
                      SizedBox(width: isShortScreen ? 8 : 12),
                      Expanded(
                        child: _ResultStat(
                          label: 'Итого',
                          value: '$totalCoins 🪙',
                          color: const Color(0xFFFFD700),
                          isCompact: isShortScreen,
                        ),
                      ),
                    ],
                  ),
                  // ── Дневник героя ──────────────────────────────────
                  if (journal.isNotEmpty) ...[
                    SizedBox(height: spacing),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        isNarrowScreen ? 12 : 14,
                        12,
                        isNarrowScreen ? 12 : 14,
                        12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Хроника похода',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${journal.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(journal.length, (index) {
                            final e = journal[index];
                            final isLast = index == journal.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.emoji,
                                    style: TextStyle(
                                      fontSize: isShortScreen ? 14 : 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.text,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: isShortScreen ? 12 : 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${e.cardNumber}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  // ────────────────────────────────────────────────────
                  SizedBox(height: isShortScreen ? 16 : 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRestart,
                      icon: Icon(isVictory ? Icons.celebration : Icons.replay),
                      label: Text(isVictory ? 'Новый поход' : 'Снова в бой'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVictory
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE94560),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isShortScreen ? 12 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isShortScreen ? 8 : 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onMenu,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('В главное меню'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isShortScreen ? 10 : 13,
                        ),
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
      },
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    this.isCompact = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: isCompact ? 11 : 12,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 17 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemUsedDialog extends StatelessWidget {
  const ItemUsedDialog({
    super.key,
    required this.item,
    required this.resultTitle,
    required this.resultDescription,
  });

  final ItemCard item;
  final String resultTitle;
  final String resultDescription;

  @override
  Widget build(BuildContext context) {
    final themeColor = item.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeColor.withValues(alpha: 0.25),
                      themeColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(item.icon, color: themeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Карта использована',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.white54,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: themeColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resultTitle,
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        resultDescription,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Отлично',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
