import 'dart:math';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/dungeons.dart';
import '../data/events.dart';
import '../data/items.dart';
import '../models/dungeon.dart';
import '../models/event_card.dart';
import '../models/item_card.dart';
import '../services/daily_quests_service.dart';
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

/// Интервал появления босса: каждая 20-я карточка забега
const _bossEvery = 20;

/// Статус текущей игровой сессии
enum GameResult {
  /// Забег продолжается, игрок делает выборы
  playing,

  /// Здоровье героя упало до 0 — поражение
  gameOver,

  /// Все этажи подземелья пройдены и финальный босс повержен — победа!
  victory,
}

/// Запись в хронологическом дневнике героя за текущий забег.
///
/// Каждое действие (свайп, получение урона, наложение статуса, побег или
/// использование зелья) фиксируется в дневнике с номером хода [cardNumber] и [emoji].
class JournalEntry {
  JournalEntry({
    required this.emoji,
    required this.text,
    required this.cardNumber,
  });

  /// Тематический эмодзи события (например, ⚔️, 🧪, 🛡️, 💰)
  final String emoji;

  /// Текстовое описание совершённого действия
  final String text;

  /// Порядковый номер встреченной карточки (1-indexed)
  final int cardNumber;
}

/// Главный игровой экран — карточный рогалик в подземелье.
///
/// Управляет полным жизненным циклом игрового забега:
/// 1. **Генерация колоды**: собирает доступные карты текущего этажа выбранного [dungeon],
///    гарантирует появление торговцев согласно прокачке игрока.
/// 2. **Обработка свайпов**: применяет числовые дельты здоровья/атаки/монет с учётом
///    активных щитов, зеркал инверсии, шипов и магнитов жадности.
/// 3. **Статусы и DoT**: накладывает яд, кровотечение, слепоту, проклятие Мидаса.
/// 4. **Инвентарь**: позволяет активировать 12 уникальных расходуемых предметов.
/// 5. **Боссы и переходы**: на каждой 20-й карте вызывает босса этажа; победа переводит
///    героя на следующий этаж или завершает игру победой.
/// 6. **Хроника**: по окончании забега сохраняет результат и дневник в [RunChronicleService].
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.initialInventory,
    this.initialDungeonLevel,
    this.initialCardsPassed,
    this.initialCoins,
    this.customDeck,
    this.dungeon = cursedForestDungeon,
    this.random,
  });

  /// Начальный инвентарь (если null — выдаются стартовые карты по уровню прокачки)
  final List<ItemCard>? initialInventory;

  /// Начальный уровень этажа (по умолчанию 1, используется для тестов/отладки)
  final int? initialDungeonLevel;

  /// Количество предварительно пройденных карт (для тестов/отладки)
  final int? initialCardsPassed;

  /// Стартовые монеты забега (для тестов/отладки)
  final int? initialCoins;

  /// Пользовательская колода (для тестов/отладки)
  final List<EventCard>? customDeck;

  /// Выбранное подземелье с уникальным набором этажей и боссов
  final Dungeon dungeon;

  /// Генератор случайных чисел (для тестов/детерминированности)
  final Random? random;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late final Random _random = widget.random ?? Random();

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

  // ─── Состояние трёхфазного босс-файта ───────────────────────
  /// Текущая фаза боссового боя: 0 = не в бою, 1/2/3 = фаза.
  int _bossPhase = 0;

  /// Зафиксированная карточка текущего босса (для многофазного боя).
  EventCard? _activeBossCard;

  // Активные статусы
  int _shieldCharges = 0;
  int _shieldTurns = 0;
  int _divineShieldCharges = 0;
  int _stoneskinTurns = 0;
  int _regenerationTurns = 0;
  int _regenerationHpPerTurn = 2;
  int _mirrorTurns = 0;
  bool _isRevealingChoices = false;
  int _greedMagnetTurns = 0;
  bool _thornmailActive = false;
  int _poisonTurns = 0;
  int _bleedTurns = 0;
  int _blindnessTurns = 0;
  int _midasCurseTurns = 0;
  final List<JournalEntry> _journal = [];

  // ─── Геттеры ────────────────────────────────

  /// Оставшиеся ходы зеркала искажения.
  int get mirrorTurns => _mirrorTurns;

  /// Активно ли зеркало искажения (хотя бы 1 ход).
  bool get invertNextChoice => _mirrorTurns > 0;

  @visibleForTesting
  void setMirrorTurnsForTesting(int turns) {
    _mirrorTurns = turns;
  }

  /// true, если сейчас идёт боссовый бой (включая активные фазы многофазного боя).
  bool get _isCurrentBoss =>
      _bossPhase > 0 || (_cardsPassed + 1) % _bossEvery == 0;

  EventCard get _currentCard {
    // В ходе многофазного боя возвращаем тот же boss EventCard;
    // UI сам читает _bossPhase чтобы показать нужную фазу из bossPhases.
    if (_bossPhase > 0 && _activeBossCard != null) return _activeBossCard!;
    if ((_cardsPassed + 1) % _bossEvery == 0) {
      final boss = _selectBoss();
      if (boss.isMultiPhase) {
        _activeBossCard = boss;
        if (_bossPhase == 0) _bossPhase = 1;
      }
      return boss;
    }
    return _deck[_deckPosition % _deck.length];
  }

  /// Возвращает данные текущей фазы боссового боя или null если босс однофазный.
  BossPhase? get _currentBossPhase {
    final boss = _activeBossCard ?? _currentCard;
    if (!boss.isMultiPhase) return null;
    if (_bossPhase == 0 && (_cardsPassed + 1) % _bossEvery == 0) {
      _activeBossCard = boss;
      _bossPhase = 1;
    }
    final idx = _bossPhase - 1;
    if (idx < 0 || idx >= boss.bossPhases!.length) return null;
    return boss.bossPhases![idx];
  }

  /// EventCard-обёртка для текущей фазы (title/description/leftChoice/rightChoice
  /// заменены данными фазы, isBoss/type/id сохранены из оригинального босса).
  EventCard get _effectiveCard {
    final phase = _currentBossPhase;
    if (phase == null) return _currentCard;
    final boss = _activeBossCard ?? _currentCard;
    return EventCard(
      id: boss.id,
      type: boss.type,
      title: '${phase.phaseEmoji} ${phase.title}',
      description: phase.description,
      leftChoice: phase.leftChoice,
      rightChoice: phase.rightChoice,
      level: boss.level,
      dungeonId: boss.dungeonId,
    );
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
    _bossPhase = 0;
    _activeBossCard = null;
    _shieldCharges = 0;
    _shieldTurns = 0;
    _divineShieldCharges = 0;
    _stoneskinTurns = 0;
    _regenerationTurns = 0;
    _regenerationHpPerTurn = 2;
    _mirrorTurns = 0;
    _isRevealingChoices = false;
    _greedMagnetTurns = 0;
    _thornmailActive = false;
    _poisonTurns = 0;
    _bleedTurns = 0;
    _blindnessTurns = 0;
    _midasCurseTurns = 0;
    _journal.clear();
    _rebuildDeck();
    if ((_cardsPassed + 1) % _bossEvery == 0) {
      final boss = _selectBoss();
      if (boss.isMultiPhase) {
        _activeBossCard = boss;
        _bossPhase = 1;
      }
    }
    _discoverCurrentCard();
    _addJournalEntry('🗡️', 'Герой вошёл в подземелье: ${widget.dungeon.name}');
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

  /// Строит колоду из карточек текущего уровня для выбранного подземелья и сбрасывает позицию.
  /// Гарантирует ровно [PlayerStatsService.guaranteedMerchants] торговцев
  /// в первых [_bossEvery]-1 позициях (до встречи с боссом).
  /// При 0 — торговцы появляются случайно.
  void _rebuildDeck() {
    if (widget.customDeck != null && widget.customDeck!.isNotEmpty) {
      _deck = List.of(widget.customDeck!);
      _deckPosition = 0;
      return;
    }
    final currentDungeonId = widget.dungeon.id;
    var cards = allEvents
        .where((e) =>
            e.level == _dungeonLevel &&
            e.isAvailableInDungeon(currentDungeonId))
        .toList();
    if (cards.isEmpty) {
      cards = allEvents
          .where((e) => e.isAvailableInDungeon(currentDungeonId))
          .toList();
      if (cards.isEmpty) {
        cards = allEvents.toList();
      }
    }
    cards.shuffle(_random);

    final guaranteed = PlayerStatsService.instance.guaranteedMerchants;
    if (guaranteed > 0) {
      // Количество карт, которые игрок видит до босса
      final visibleCount = min(_bossEvery - 1, cards.length);

      // Собираем доступных торговцев ТОЛЬКО текущего уровня для этого подземелья
      final currentLevelMerchants = allEvents
          .where((e) =>
              e.type == EventType.merchant &&
              e.level == _dungeonLevel &&
              e.isAvailableInDungeon(currentDungeonId))
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

  @visibleForTesting
  int get deckPosition => _deckPosition;

  @visibleForTesting
  int get shieldCharges => _shieldCharges;

  @visibleForTesting
  int get shieldTurns => _shieldTurns;

  @visibleForTesting
  void setShieldTurnsForTesting(int turns) =>
      setState(() => _shieldTurns = turns);

  @visibleForTesting
  int get divineShieldCharges => _divineShieldCharges;

  @visibleForTesting
  int get stoneskinTurns => _stoneskinTurns;

  @visibleForTesting
  int get regenerationTurns => _regenerationTurns;

  @visibleForTesting
  int get regenerationHpPerTurn => _regenerationHpPerTurn;

  @visibleForTesting
  void setRegenerationForTesting(int turns, [int hpPerTurn = 2]) =>
      setState(() {
        _regenerationTurns = turns;
        _regenerationHpPerTurn = hpPerTurn;
      });

  @visibleForTesting
  int get poisonTurns => _poisonTurns;

  @visibleForTesting
  int get bleedTurns => _bleedTurns;

  @visibleForTesting
  int get blindnessTurns => _blindnessTurns;

  @visibleForTesting
  void setPoisonForTesting(int turns) => setState(() => _poisonTurns = turns);

  @visibleForTesting
  void setBleedForTesting(int turns) => setState(() => _bleedTurns = turns);

  @visibleForTesting
  void setBlindnessForTesting(int turns) => setState(() => _blindnessTurns = turns);

  @visibleForTesting
  EventCard get currentCardForTesting => _currentCard;

  @visibleForTesting
  void setCurrentCardForTesting(EventCard card) {
    setState(() {
      if (_deck.isNotEmpty) {
        _deck[_deckPosition % _deck.length] = card;
      }
    });
  }

  @visibleForTesting
  int get healthForTesting => _health;

  @visibleForTesting
  int get attackForTesting => _attack;

  @visibleForTesting
  void setStatsForTesting({int? health, int? attack}) {
    setState(() {
      if (health != null) _health = health;
      if (attack != null) _attack = attack;
    });
  }

  @visibleForTesting
  int get coinsForTesting => _coins;

  @visibleForTesting
  int get bossPhaseForTesting => _bossPhase;

  @visibleForTesting
  void handleSwipeForTesting(bool isRight) => _onSwipe(isRight);

  /// Выбирает случайную боссовую карточку для текущего подземелья и текущего уровня этажа.
  ///
  /// При спуске на следующий уровень (например, в конце 1 уровня) выбирается
  /// случайный босс из пула боссов 1 уровня данного подземелья.
  EventCard _selectBoss() {
    if (_activeBossCard != null) return _activeBossCard!;

    final currentLevel =
        _dungeonLevel > 0 ? _dungeonLevel : ((_cardsPassed + 1) ~/ _bossEvery);

    // 1. Ищем боссов для текущего подземелья и текущего уровня этажа
    final dungeonLevelBosses = getBossesForDungeonAndLevel(
      widget.dungeon.id,
      currentLevel,
    );

    if (dungeonLevelBosses.isNotEmpty) {
      return dungeonLevelBosses[_random.nextInt(dungeonLevelBosses.length)];
    }

    // Запасной вариант 1: любые боссы этого подземелья
    final dungeonBosses = allBossCards
        .where((e) => e.isAvailableInDungeon(widget.dungeon.id))
        .toList();
    if (dungeonBosses.isNotEmpty) {
      return dungeonBosses[_random.nextInt(dungeonBosses.length)];
    }

    // Запасной вариант 2: любые боссы игры
    return allBossCards[_random.nextInt(allBossCards.length)];
  }

  void _discoverCurrentCard() {
    DiscoveredEventsService.instance.markDiscovered(_currentCard.id);
    DailyQuestsService.instance.onCardEncountered(_currentCard.type);
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
      // Победа над боссом → проверяем наличие карточек событий следующего уровня для этого подземелья
      final nextLevel = _dungeonLevel + 1;
      final hasNextLevelCards = nextLevel <= widget.dungeon.levelsCount &&
          allEvents.any((e) =>
              e.level == nextLevel &&
              e.isAvailableInDungeon(widget.dungeon.id));
      if (!hasNextLevelCards) {
        // Карточек следующего уровня нет или пройдены все уровни подземелья — победа!
        _result = GameResult.victory;
        _addJournalEntry('🏆', 'Подземелье успешно пройдено!');
        if (_coins > 0) PlayerCoinsService.instance.applyDelta(_coins);
        _saveChronicle(isVictory: true);
        DailyQuestsService.instance.onDungeonFinished(
          isVictory: true,
          dungeonId: widget.dungeon.id,
        );
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
    // Если следующая карточка — босс, сразу выбираем и активируем его
    if ((_cardsPassed + 1) % _bossEvery == 0) {
      final boss = _selectBoss();
      _activeBossCard = boss;
      _bossPhase = boss.isMultiPhase ? 1 : 0;
    } else {
      _activeBossCard = null;
      _bossPhase = 0;
    }
    if (_health > 0) _discoverCurrentCard();
  }

  // ─── Обработка свайпа ───────────────────────

  void _onSwipe(bool isRight) {
    if (_result != GameResult.playing) return;

    // Если начинается многофазный босс и фаза ещё не инициирована — гарантируем фазу 1
    if (_bossPhase == 0 && (_cardsPassed + 1) % _bossEvery == 0) {
      final card = _selectBoss();
      if (card.isMultiPhase) {
        _activeBossCard = card;
        _bossPhase = 1;
      }
    }

    final effectiveCard = _effectiveCard;
    final choice = isRight ? effectiveCard.rightChoice : effectiveCard.leftChoice;
    final wasBoss = _isCurrentBoss;

    // Проверяем доступность выбора
    if (choice.coinsDelta < 0 && _coins < choice.coinsDelta.abs()) return;
    if (choice.attackDelta < 0 && _attack < choice.attackDelta.abs()) return;
    if (choice.givesRandomItem &&
        !UnlockedItemsService.instance.hasUnlockedForLevel(effectiveCard.level)) {
      return;
    }

    final cardTitle = _currentCard.title;
    final triggeredBuffs = <String>[];

    ItemCard? receivedItem;
    final List<ItemCard> receivedItems = [];
    if (choice.givesRandomItem) {
      final itemsToGrant =
          choice.randomItemsCount > 0 ? choice.randomItemsCount : 1;
      for (int i = 0; i < itemsToGrant; i++) {
        final item = getRandomMerchantItemCard(
          random: _random,
          unlockedIds: UnlockedItemsService.instance.unlockedIds,
          baseLevel: effectiveCard.level,
          upgradeChancePercent:
              PlayerStatsService.instance.merchantCardUpgradeChance,
        );
        if (item != null) {
          _inventoryItems.add(item);
          receivedItems.add(item);
          receivedItem ??= item;
          if (item.level > effectiveCard.level) {
            triggeredBuffs.add(
              '⭐ Удача торговца: получена карта ${item.level} уровня!',
            );
          }
        }
      }
    }

    var effectiveHealthDelta = choice.healthDelta;
    var effectiveAttackDelta = choice.attackDelta;
    var effectiveCoinsDelta = choice.coinsDelta;

    // 0. Проклятие Мидаса (если активно, монеты за выбор не начисляются)
    if (_midasCurseTurns > 0 && effectiveCoinsDelta > 0) {
      effectiveCoinsDelta = 0;
      triggeredBuffs.add('👑 Проклятие Мидаса: золото обратилось в прах');
    }

    // 1. Зеркало искажения
    if (_mirrorTurns > 0) {
      _mirrorTurns--;
      if (effectiveHealthDelta < 0) {
        effectiveHealthDelta = -effectiveHealthDelta;
      }
      if (effectiveAttackDelta < 0) {
        effectiveAttackDelta = -effectiveAttackDelta;
      }
      if (effectiveCoinsDelta < 0) effectiveCoinsDelta = -effectiveCoinsDelta;
      triggeredBuffs.add('🫞 Зеркало сработало');
    }

    // 1.1. Уклонение (шанс избежать потери здоровья или атаки)
    final dodgeChance = PlayerStatsService.instance.dodgeChance;
    if (dodgeChance > 0 &&
        (effectiveHealthDelta < 0 || effectiveAttackDelta < 0) &&
        _random.nextInt(100) < dodgeChance) {
      final dodgedLosses = <String>[];
      if (effectiveHealthDelta < 0) {
        dodgedLosses.add('${effectiveHealthDelta.abs()} ❤');
        effectiveHealthDelta = 0;
      }
      if (effectiveAttackDelta < 0) {
        dodgedLosses.add('${effectiveAttackDelta.abs()} ⚡');
        effectiveAttackDelta = 0;
      }
      triggeredBuffs
          .add('💨 Уклонение: потери предотвращены (-${dodgedLosses.join(', -')})');
    }

    // 2. Щиты (сначала Божественный щит - 100%, затем Усиленный рунический щит - 50% на ходы, затем Рунический щит - 50% на заряды)
    if (effectiveHealthDelta < 0 && _divineShieldCharges > 0) {
      _divineShieldCharges--;
      final absorbed = effectiveHealthDelta.abs();
      effectiveHealthDelta = 0;
      triggeredBuffs.add('✨🛡️ Божественный щит поглотил весь урон (-$absorbed ❤)');
    } else if (effectiveHealthDelta < 0 && _shieldTurns > 0) {
      final absorbed = (effectiveHealthDelta.abs() / 2).ceil();
      effectiveHealthDelta += absorbed;
      triggeredBuffs.add('🛡️ Усиленный щит поглотил 50% урона (+$absorbed ❤)');
    } else if (effectiveHealthDelta < 0 && _shieldCharges > 0) {
      _shieldCharges--;
      final absorbed = (effectiveHealthDelta.abs() / 2).ceil();
      effectiveHealthDelta += absorbed;
      triggeredBuffs.add('🛡️ Рунический щит поглотил 50% урона (+$absorbed ❤)');
    }

    // 3. Шипы
    if (effectiveHealthDelta < 0 && _thornmailActive) {
      _thornmailActive = false;
      final bonusGold = effectiveHealthDelta.abs() * 10;
      effectiveCoinsDelta += bonusGold;
      triggeredBuffs.add('🌵 Шипы дали +$bonusGold 🪙');
    }

    // 3.1. Трофеи с монстров (шанс получить золото после победы над монстром)
    if (effectiveCard.type == EventType.monster) {
      final willSurvive = (_health +
              effectiveHealthDelta -
              (_poisonTurns > 0 ? 1 : 0) -
              (_bleedTurns > 0 ? 2 : 0) +
              (_regenerationTurns > 0 ? _regenerationHpPerTurn : 0)) >
          0;
      if (willSurvive) {
        final monsterGoldChance =
            PlayerStatsService.instance.monsterGoldChance;
        if (monsterGoldChance > 0 &&
            _random.nextInt(100) < monsterGoldChance) {
          if (_midasCurseTurns > 0) {
            triggeredBuffs.add('👑 Проклятие Мидаса: трофеи обратились в прах');
          } else {
            const minReward = PlayerStatsService.minMonsterGoldReward;
            const maxReward = PlayerStatsService.maxMonsterGoldReward;
            final dropGold =
                minReward + _random.nextInt(maxReward - minReward + 1);
            effectiveCoinsDelta += dropGold;
            triggeredBuffs.add('💰 Трофеи: +$dropGold 🪙');
          }
        }
      }
    }

    // 4. Магнит жадности и Каменная кожа
    if (effectiveCoinsDelta > 0 && _greedMagnetTurns > 0) {
      effectiveCoinsDelta *= 2;
      triggeredBuffs.add('🧲 x2 золото');
    }
    if (_greedMagnetTurns > 0) _greedMagnetTurns--;

    // 5. Наложение статусов от выбора
    if (choice.statusEffect != null &&
        _random.nextDouble() < choice.statusChance) {
      final effect = choice.statusEffect!;
      final isResistable = effect == StatusEffectType.poison ||
          effect == StatusEffectType.bleed ||
          effect == StatusEffectType.blindness;
      final resistanceChance = PlayerStatsService.instance.resistanceChance;

      if (isResistable &&
          resistanceChance > 0 &&
          _random.nextInt(100) < resistanceChance) {
        final effectName = effect == StatusEffectType.poison
            ? 'яд'
            : effect == StatusEffectType.bleed
                ? 'кровотечение'
                : 'слепота';
        triggeredBuffs.add('🛡️ Сопротивление: $effectName отражён!');
      } else {
        switch (effect) {
          case StatusEffectType.poison:
            if (_stoneskinTurns > 0) {
              triggeredBuffs.add('🪨 Каменная кожа отразила яд!');
            } else {
              _poisonTurns = 3;
              triggeredBuffs.add('🧪 Отравлен на 3 хода!');
            }
            break;
          case StatusEffectType.bleed:
            if (_stoneskinTurns > 0) {
              triggeredBuffs.add('🪨 Каменная кожа защитила от кровотечения!');
            } else {
              _bleedTurns = 3;
              triggeredBuffs.add('🩸 Кровотечение на 3 хода!');
            }
            break;
          case StatusEffectType.blindness:
            if (_stoneskinTurns > 0) {
              triggeredBuffs.add('🪨 Каменная кожа защитила от слепоты!');
            } else {
              _blindnessTurns = 3;
              triggeredBuffs.add('👁️‍🗨️ Слепота на 3 хода!');
            }
            break;
          case StatusEffectType.midasCurse:
            _midasCurseTurns = 3;
            triggeredBuffs.add('👑 Проклятие Мидаса на 3 хода!');
            break;
        }
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
    if (_stoneskinTurns > 0) {
      _stoneskinTurns--;
    }
    if (_shieldTurns > 0) {
      _shieldTurns--;
    }
    int regenHeal = 0;
    if (_regenerationTurns > 0) {
      regenHeal = _regenerationHpPerTurn;
      _regenerationTurns--;
      triggeredBuffs.add('🌿 Регенерация (+$_regenerationHpPerTurn ❤)');
      if (_regenerationTurns == 0) {
        _regenerationHpPerTurn = 2;
      }
    }

    _isRevealingChoices = false;

    setState(() {
      _health =
          (_health + effectiveHealthDelta - dotDamage + regenHeal).clamp(0, 999);
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
      if (regenHeal > 0) {
        details.add('+$regenHeal ❤ регенерация');
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
      if (receivedItems.isNotEmpty) {
        if (receivedItems.length == 1) {
          details.add('🎒 ${receivedItems.first.title}');
        } else {
          details.add(
            '🎒 ${receivedItems.map((i) => i.title).join(', ')}',
          );
        }
      }
      if (triggeredBuffs.isNotEmpty) {
        details.addAll(triggeredBuffs);
      }

      final detailsStr = details.isNotEmpty ? ' (${details.join(', ')})' : '';
      _addJournalEntry(actionEmoji, '$cardTitle: ${choice.label}$detailsStr');

      // ─── Завершение фазы / победа над боссом ────────────────────────────
      final bossDefeated = wasBoss && _health > 0;
      final isMultiPhase = _activeBossCard?.isMultiPhase ?? false;

      if (bossDefeated && isMultiPhase) {
        // Проверяем, закончились ли все фазы
        if (_bossPhase < 3) {
          // Переход к следующей фазе
          final nextPhase = _bossPhase + 1;
          final phaseName = _activeBossCard!.bossPhases![nextPhase - 1].title;
          _addJournalEntry(
            _activeBossCard!.bossPhases![_bossPhase - 1].phaseEmoji,
            '$cardTitle: фаза $_bossPhase пройдена!',
          );
          _lastFeedback = _buildFeedback(
            choice,
            receivedItem: receivedItem,
            buffsNote: triggeredBuffs.isNotEmpty ? triggeredBuffs.join(', ') : null,
            bossPhaseComplete: _bossPhase,
            nextPhaseTitle: phaseName,
          );
          _bossPhase = nextPhase;
          _cardKey++;
        } else {
          // Все 3 фазы пройдены — полная победа
          _addJournalEntry(
            _activeBossCard!.bossPhases![2].phaseEmoji,
            '$cardTitle: фаза 3 пройдена — БОСС ПОВЕРЖЕН! 👑',
          );
          _addJournalEntry('👑', 'Босс ${_activeBossCard!.title} повержен!');
          DailyQuestsService.instance.onBossKilled();
          _lastFeedback = _buildFeedback(
            choice,
            receivedItem: receivedItem,
            buffsNote: triggeredBuffs.isNotEmpty ? triggeredBuffs.join(', ') : null,
            wasBoss: true,
          );
          _bossPhase = 0;
          _activeBossCard = null;
          _advanceCard(wasBoss: true);
        }
      } else {
        if (bossDefeated) {
          _addJournalEntry('👑', 'Босс $cardTitle повержен!');
          DailyQuestsService.instance.onBossKilled();
        }
        _lastFeedback = _buildFeedback(
          choice,
          receivedItem: receivedItem,
          buffsNote: triggeredBuffs.isNotEmpty ? triggeredBuffs.join(', ') : null,
          wasBoss: bossDefeated,
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
          DailyQuestsService.instance.onDungeonFinished(
            isVictory: false,
            dungeonId: widget.dungeon.id,
          );
        } else if (!wasBoss) {
          _advanceCard(wasBoss: false);
        } else {
          // Однофазный босс побеждён или hero died to boss
          if (_health > 0) _advanceCard(wasBoss: true);
        }
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
        dungeonId: widget.dungeon.id,
        dungeonName: widget.dungeon.name,
      ),
    );
  }

  String _buildFeedback(
    CardChoice choice, {
    ItemCard? receivedItem,
    String? buffsNote,
    bool wasBoss = false,
    int? bossPhaseComplete,
    String? nextPhaseTitle,
  }) {
    final parts = <String>[];
    if (wasBoss) {
      parts.add('⚔ Босс повержен! 👑');
    } else if (bossPhaseComplete != null) {
      parts.add('✅ Фаза $bossPhaseComplete пройдена!');
      if (nextPhaseTitle != null) parts.add('Следующая: $nextPhaseTitle');
    }
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
        case ItemEffectType.coins:
          _coins = (_coins + item.value).clamp(0, 999999);
          _lastFeedback = '${item.title}: +${item.value} 🪙';
          _addJournalEntry('🪙', 'Использовано ${item.title}: +${item.value} 🪙');
          resultTitle = '+${item.value} 🪙';
          resultDescription =
              'Получено +${item.value} 🪙 золотых монет!\nТекущее золото за забег: $_coins 🪙.';
          break;
        case ItemEffectType.skip:
          final wasBoss = _isCurrentBoss;
          final skippedCard = _currentCard.title;
          final boss = _activeBossCard ?? _currentCard;
          final isMultiPhase = wasBoss && boss.isMultiPhase;
          final currentPhase = isMultiPhase ? (_bossPhase == 0 ? 1 : _bossPhase) : 0;

          if (isMultiPhase && currentPhase < 3) {
            final skippedPhase = currentPhase;
            final nextPhase = currentPhase + 1;
            final nextPhaseTitle = boss.bossPhases![nextPhase - 1].title;
            _activeBossCard ??= boss;
            _bossPhase = nextPhase;
            _cardKey++;
            _lastFeedback =
                '⏩ Фаза $skippedPhase босса пропущена! Следующая: $nextPhaseTitle';
            _addJournalEntry(
              '⏩',
              'Использован ${item.title}: пропущена фаза $skippedPhase босса "$skippedCard"',
            );
            resultTitle = 'Фаза $skippedPhase пропущена ⏩';
            resultDescription =
                'Магический свиток перенёс вас мимо фазы $skippedPhase босса "$skippedCard"!\nСледующая фаза: $nextPhaseTitle.';
          } else {
            _bossPhase = 0;
            _activeBossCard = null;
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
          }
          break;
        case ItemEffectType.shield:
          _shieldCharges += item.value;
          _lastFeedback =
              'Рунический щит: +${item.value} заряд (50% защита) 🛡️';
          _addJournalEntry(
            '🛡️',
            'Использован ${item.title}: +${item.value} 🛡️ (всего $_shieldCharges)',
          );
          resultTitle = 'Щит активирован (+${item.value} 🛡️)';
          resultDescription =
              'Рунический щит готов поглотить половину следующего урона по здоровью (50% защита).\nВсего зарядов щита: $_shieldCharges.';
          break;
        case ItemEffectType.divineShield:
          _divineShieldCharges += item.value;
          _lastFeedback = item.value > 1
              ? 'Божественный щит: +${item.value} заряда (100% защита) ✨🛡️'
              : 'Божественный щит: +${item.value} заряд (100% защита) ✨🛡️';
          _addJournalEntry(
            '✨🛡️',
            'Использован ${item.title}: +${item.value} ✨🛡️ (всего $_divineShieldCharges)',
          );
          resultTitle = 'Божественный щит (+${item.value} ✨🛡️)';
          resultDescription = item.value > 1
              ? '${item.title} активирован!\nСледующие ${item.value} удара по здоровью будут полностью поглощены (100% защита).\nВсего зарядов божественного щита: $_divineShieldCharges.'
              : 'Божественный рунический щит активирован!\nСледующий урон по здоровью будет полностью поглощён (100% защита).\nВсего зарядов божественного щита: $_divineShieldCharges.';
          break;
        case ItemEffectType.shieldTurns:
          _shieldTurns += item.value;
          _lastFeedback =
              'Усиленный щит: защита 50% на +${item.value} х.! 🛡️';
          _addJournalEntry(
            '🛡️',
            'Использован ${item.title}: защита 50% на $_shieldTurns х.',
          );
          resultTitle = 'Усиленный рунический щит (${item.value} х.)';
          resultDescription =
              'Усиленный рунический щит активирован!\nВ течение следующих $_shieldTurns ходов любой входящий урон по здоровью уменьшается на 50%.';
          break;
        case ItemEffectType.stoneskin:
          _stoneskinTurns += item.value;
          _lastFeedback =
              'Каменная кожа: защита от яда, кровотечения и слепоты на +${item.value} х.! 🪨';
          _addJournalEntry(
            '🪨',
            'Использовано ${item.title}: защита от яда, кровотечения и слепоты на $_stoneskinTurns х.',
          );
          resultTitle = 'Каменная кожа 🪨';
          resultDescription =
              'Кожа героя становится твёрдой, как гранит!\nНа протяжении $_stoneskinTurns ходов вы полностью защищены от получения эффектов яда, кровотечения и слепоты.';
          break;
        case ItemEffectType.antidote:
          final hadPoison = _poisonTurns > 0;
          final hadBleed = _bleedTurns > 0;
          final hadBlindness = _blindnessTurns > 0;
          _poisonTurns = 0;
          _bleedTurns = 0;
          _blindnessTurns = 0;
          final List<String> cleansed = [];
          if (hadPoison) cleansed.add('яд');
          if (hadBleed) cleansed.add('кровотечение');
          if (hadBlindness) cleansed.add('слепота');
          final cleansedText = cleansed.isNotEmpty
              ? '${cleansed.join(', ')} нейтрализованы!'
              : 'персонаж очищен от токсинов и негативных эффектов!';
          _lastFeedback = 'Противоядие: $cleansedText 🧪';
          _addJournalEntry(
            '🧪',
            'Использовано ${item.title}: $cleansedText',
          );
          resultTitle = 'Противоядие 🧪';
          resultDescription =
              'Противоядие нейтрализует опасные токсины, останавливает кровотечение и возвращает зрение.\nВременные эффекты яда, кровотечения и слепоты полностью сняты с персонажа.';
          break;
        case ItemEffectType.regeneration:
          final turns = item.duration > 0 ? item.duration : (item.value > 0 ? item.value : 3);
          final hpPerTurn = (item.duration > 0 && item.value > 0) ? item.value : 2;
          _regenerationTurns += turns;
          _regenerationHpPerTurn = _regenerationTurns == turns ? hpPerTurn : max(_regenerationHpPerTurn, hpPerTurn);
          _lastFeedback =
              'Регенерация: +$_regenerationHpPerTurn ❤ каждый ход на +$turns х.! 🌿';
          _addJournalEntry(
            '🌿',
            'Использовано ${item.title}: регенерация (+$hpPerTurn ❤/ход) на $turns х. (всего: $_regenerationTurns х.)',
          );
          resultTitle = 'Регенерация 🌿';
          resultDescription =
              '${item.title} активирует регенерацию!\nВ течение $_regenerationTurns ходов вы будете восстанавливать по $_regenerationHpPerTurn очков здоровья каждый ход.';
          break;
        case ItemEffectType.teleport:
          if (_isCurrentBoss) {
            _inventoryItems.insert(index, item);
            _lastFeedback =
                '${item.title} нельзя использовать в бою с боссом! ⛔';
            resultTitle = 'Телепортация невозможна ⛔';
            resultDescription =
                'Древняя магия босса блокирует пространственное перемещение! ${item.title} нельзя использовать во время битвы с боссом. Предмет сохранён в инвентаре.';
          } else {
            final int minSkip;
            final int maxSkip;
            if (item.id == 'black_hole') {
              minSkip = 5;
              maxSkip = 5;
            } else if (item.id == 'wormhole') {
              minSkip = 2;
              maxSkip = 4;
            } else {
              minSkip = 1;
              maxSkip = 3;
            }
            final skipRange = maxSkip - minSkip + 1;
            final skipCount =
                minSkip + (skipRange > 1 ? _random.nextInt(skipRange) : 0);
            int actualSkipped = 0;
            for (int i = 0; i < skipCount; i++) {
              if (_isCurrentBoss) break;
              _advanceCard(wasBoss: false);
              actualSkipped++;
              if (_isCurrentBoss) break;
            }
            final hitBoss = _isCurrentBoss;
            _lastFeedback =
                '${item.title}: перемещение на $actualSkipped карт вперёд! 🌀';
            _addJournalEntry(
              '🌀',
              'Использован ${item.title}: перемещение на $actualSkipped карт вперёд${hitBoss ? ' (остановка перед боссом)' : ''}',
            );
            resultTitle = '${item.title} (+ $actualSkipped) 🌀';
            resultDescription =
                'Пространство исказилось! ${item.title} переносит вас вперёд на $actualSkipped карт.\nТекущая карта: "${_currentCard.title}".${hitBoss ? '\n\n⚠️ Перемещение остановилось перед боссом!' : ''}';
          }
          break;
        case ItemEffectType.invertNext:
          final turns = item.duration > 0
              ? item.duration
              : (item.value > 0 ? item.value : 1);
          _mirrorTurns += turns;
          _lastFeedback = _mirrorTurns > 1
              ? 'Зеркало искажения: потери станут выгодой на $_mirrorTurns х.! 🫞'
              : 'Зеркало искажения: потери станут выгодой! 🫞';
          _addJournalEntry(
            '🪞',
            'Использовано ${item.title}: искажение активировано ($_mirrorTurns х.)',
          );
          resultTitle = '${item.title} 🪞';
          resultDescription = turns > 1
              ? 'Искажение активировано! В течение следующих $turns ходов любые потери здоровья, атаки или монет превратятся в равную выгоду.'
              : 'Искажение активировано! На следующем ходу любые потери здоровья, атаки или монет превратятся в равную выгоду.';
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
            final maxCoins = item.value > 0 ? item.value : 50;
            final maxBundles = maxCoins ~/ 10;
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
            resultTitle = '${item.title} ⚗️';
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
        case ItemEffectType.casinoOfFate:
          final roll = _random.nextInt(6) + 1;
          if (roll == 1) {
            if (_coins >= 15 && _random.nextBool()) {
              _coins = (_coins - 15).clamp(0, 999999);
              _lastFeedback = '🎰 Казино [$roll]: Ставка не сыграла (-15 🪙)';
              _addJournalEntry('🎰', 'Казино судьбы [$roll]: потеряно 15 🪙');
              resultTitle = 'Казино [$roll]: Проигрыш 🎰';
              resultDescription =
                  'Ставка не сыграла! Казино забрало 15 🪙.\nТекущий баланс: $_coins 🪙.';
            } else {
              _health = (_health - 2).clamp(1, 999);
              _lastFeedback = '🎰 Казино [$roll]: Проигрыш (-2 ❤)';
              _addJournalEntry('🎰', 'Казино судьбы [$roll]: потеряно 2 ❤');
              resultTitle = 'Казино [$roll]: Урон 🎰';
              resultDescription =
                  'Неудача! Казино отняло 2 ❤.\nТекущее здоровье: $_health ❤.';
            }
          } else if (roll <= 3) {
            final diceCard =
                getRandomUnlockedItemCard(
                  _random,
                  UnlockedItemsService.instance.unlockedIds,
                ) ??
                allItemCards[_random.nextInt(allItemCards.length)];
            _inventoryItems.add(diceCard);
            _coins = (_coins + 30).clamp(0, 999999);
            _lastFeedback =
                '🎰 Казино [$roll]: Артефакт "${diceCard.title}" и +30 🪙! 🎁';
            _addJournalEntry(
              '🎰',
              'Казино судьбы [$roll]: артефакт "${diceCard.title}" и +30 🪙',
            );
            resultTitle = 'Казино [$roll]: Выигрыш! 🎁';
            resultDescription =
                'Удачная ставка! Вы выиграли артефакт "${diceCard.title}" и +30 🪙!\nТекущий баланс: $_coins 🪙.';
          } else if (roll <= 5) {
            _health = (_health + 8).clamp(0, 999);
            _attack = (_attack + 3).clamp(0, 99);
            _coins = (_coins + 50).clamp(0, 999999);
            _lastFeedback =
                '🎰 Казино [$roll]: Крупный куш! +8 ❤, +3 ⚡, +50 🪙 💰';
            _addJournalEntry(
              '🎰',
              'Казино судьбы [$roll]: Крупный куш (+8❤ +3⚡ +50🪙)',
            );
            resultTitle = 'Казино [$roll]: Крупный куш! 💰';
            resultDescription =
                'Отличный расклад! Крупный куш: +8 ❤ здоровья, +3 ⚡ к атаке и +50 🪙!\nЗдоровье: $_health ❤, атака: $_attack ⚡, золото: $_coins 🪙.';
          } else {
            final bonusCard =
                getRandomUnlockedItemCard(
                  _random,
                  UnlockedItemsService.instance.unlockedIds,
                ) ??
                allItemCards[_random.nextInt(allItemCards.length)];
            _inventoryItems.add(bonusCard);
            _health = (_health + 12).clamp(0, 999);
            _attack = (_attack + 5).clamp(0, 99);
            _coins = (_coins + 100).clamp(0, 999999);
            _lastFeedback =
                '🎰 Казино [777]: МЕГА-ДЖЕКПОТ! +12 ❤, +5 ⚡, +100 🪙 и "${bonusCard.title}"! 🎉';
            _addJournalEntry(
              '🎰',
              'Казино судьбы [777]: МЕГА-ДЖЕКПОТ (+12❤ +5⚡ +100🪙 + ${bonusCard.title})',
            );
            resultTitle = 'Казино [777]: МЕГА-ДЖЕКПОТ! 👑';
            resultDescription =
                'Невероятная удача! Вы сорвали МЕГА-ДЖЕКПОТ 777:\n+12 ❤ здоровья, +5 ⚡ к атаке, +100 🪙 и легендарный артефакт "${bonusCard.title}"!\nЗдоровье: $_health ❤, атака: $_attack ⚡, золото: $_coins 🪙.';
          }
          break;
        case ItemEffectType.smokeBomb:
          final wasBoss = _isCurrentBoss;
          final ec = _effectiveCard;
          final bestCoins = max(
            0,
            max(
              ec.leftChoice.coinsDelta,
              ec.rightChoice.coinsDelta,
            ),
          ).toInt();
          if (bestCoins > 0) _coins = (_coins + bestCoins).clamp(0, 999999);
          final skippedCard = _currentCard.title;
          final boss = _activeBossCard ?? _currentCard;
          final isMultiPhase = wasBoss && boss.isMultiPhase;
          final currentPhase = isMultiPhase ? (_bossPhase == 0 ? 1 : _bossPhase) : 0;

          if (isMultiPhase && currentPhase < 3) {
            final skippedPhase = currentPhase;
            final nextPhase = currentPhase + 1;
            final nextPhaseTitle = boss.bossPhases![nextPhase - 1].title;
            _activeBossCard ??= boss;
            _bossPhase = nextPhase;
            _cardKey++;
            _lastFeedback =
                '💨 Дымовая шашка: фаза $skippedPhase пройдена! Следующая: $nextPhaseTitle${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}';
            _addJournalEntry(
              '💨',
              'Дымовая шашка: побег от фазы $skippedPhase босса "$skippedCard"${bestCoins > 0 ? ' (+$bestCoins 🪙)' : ''}',
            );
            resultTitle = 'Побег от фазы $skippedPhase 💨';
            resultDescription =
                'Вы бросили дымовую шашку и ослепили босса на фазе $skippedPhase! Следующая фаза: $nextPhaseTitle${bestCoins > 0 ? ', при этом подобрано +$bestCoins 🪙' : ''}.';
          } else {
            _bossPhase = 0;
            _activeBossCard = null;
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
          }
          break;
        case ItemEffectType.bribery:
          if (_coins >= 50) {
            final wasBoss = _isCurrentBoss;
            _coins -= 50;
            final ec2 = _effectiveCard;
            final leftScore =
                ec2.leftChoice.coinsDelta +
                ec2.leftChoice.healthDelta +
                ec2.leftChoice.attackDelta;
            final rightScore =
                ec2.rightChoice.coinsDelta +
                ec2.rightChoice.healthDelta +
                ec2.rightChoice.attackDelta;
            final bestChoice = rightScore >= leftScore
                ? ec2.rightChoice
                : ec2.leftChoice;
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
            final List<ItemCard> bribeItems = [];
            if (bestChoice.givesRandomItem) {
              final count = bestChoice.randomItemsCount > 0
                  ? bestChoice.randomItemsCount
                  : 1;
              for (int i = 0; i < count; i++) {
                final item = getRandomMerchantItemCard(
                  random: _random,
                  unlockedIds: UnlockedItemsService.instance.unlockedIds,
                  baseLevel: _effectiveCard.level,
                  upgradeChancePercent:
                      PlayerStatsService.instance.merchantCardUpgradeChance,
                );
                if (item != null) {
                  _inventoryItems.add(item);
                  bribeItems.add(item);
                }
              }
            }
            final bribeItemsStr = bribeItems.isEmpty
                ? ''
                : bribeItems.length == 1
                    ? ', 🎒 ${bribeItems.first.title}'
                    : ', 🎒 ${bribeItems.map((i) => i.title).join(', ')}';
            final bribeItemsDesc = bribeItems.isEmpty
                ? ''
                : bribeItems.length == 1
                    ? ', также получен предмет "${bribeItems.first.title}"'
                    : ', также получены предметы: ${bribeItems.map((i) => '"${i.title}"').join(', ')}';
            final skippedCard = _currentCard.title;
            final boss = _activeBossCard ?? _currentCard;
            final isMultiPhase = wasBoss && boss.isMultiPhase;
            final currentPhase = isMultiPhase ? (_bossPhase == 0 ? 1 : _bossPhase) : 0;

            if (isMultiPhase && currentPhase < 3) {
              final skippedPhase = currentPhase;
              final nextPhase = currentPhase + 1;
              final nextPhaseTitle = boss.bossPhases![nextPhase - 1].title;
              _activeBossCard ??= boss;
              _bossPhase = nextPhase;
              _cardKey++;
              _lastFeedback =
                  '💰 Подкуп удался (-50 🪙): фаза $skippedPhase нейтрализована! Следующая: $nextPhaseTitle';
              _addJournalEntry(
                '💰',
                'Подкуп (-50 🪙): нейтрализована фаза $skippedPhase "$skippedCard"$bribeItemsStr',
              );
              resultTitle = 'Фаза $skippedPhase нейтрализована 💰';
              resultDescription =
                  'За 50 монет вы откупились от фазы $skippedPhase босса "$skippedCard"! Следующая фаза: $nextPhaseTitle$bribeItemsDesc.';
            } else {
              _bossPhase = 0;
              _activeBossCard = null;
              _advanceCard(wasBoss: wasBoss);
              _lastFeedback = '💰 Подкуп удался (-50 🪙): угроза нейтрализована!';
              _addJournalEntry(
                '💰',
                'Подкуп (-50 🪙): нейтрализовано "$skippedCard"$bribeItemsStr',
              );
              resultTitle = wasBoss ? 'Босс подкуплен 💰' : 'Угроза нейтрализована';
              resultDescription = wasBoss
                  ? 'За 50 монет вы успешно откупились от босса "$skippedCard"! Уровень подземелья пройден без боя$bribeItemsDesc.'
                  : 'За 50 монет вы благополучно избежали опасности "$skippedCard"$bribeItemsDesc.';
            }
          } else {
            _inventoryItems.insert(index, item);
            _lastFeedback = 'Недостаточно монет (нужно 50 🪙)!';
            resultTitle = 'Недостаточно монет 💰';
            resultDescription =
                'Для подкупа требуется как минимум 50 🪙. Предмет сохранён в инвентаре.';
          }
          break;
        case ItemEffectType.rebirth:
          final prevHp = _health;
          final prevAtk = _attack;
          _health = _initialHealth;
          _attack = _initialAttack;
          _lastFeedback =
              'Тотем перерождения: здоровье ($_health ❤) и атака ($_attack ⚡) возвращены к исходу! 🔄';
          _addJournalEntry(
            '🔄',
            'Тотем перерождения: HP $prevHp→$_health, Атака $prevAtk→$_attack',
          );
          resultTitle = 'Тотем перерождения 🔄';
          resultDescription =
              'Тотем высвободил древнюю силу и вернул ваши характеристики к исходным стартовым значениям:\nЗдоровье: $_health ❤, Атака: $_attack ⚡.';
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
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE94560),
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.gameSurrenderTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            l10n.gameSurrenderContent(_coins),
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
                l10n.gameContinue,
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
              child: Text(l10n.gameSurrenderConfirm),
            ),
          ],
        );
      },
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
    if (isBoss && _bossPhase == 0) {
      final boss = _selectBoss();
      if (boss.isMultiPhase) {
        _activeBossCard = boss;
        _bossPhase = 1;
      }
    }
    final bossPhase = _bossPhase; // 0 = нет, 1/2/3 = фаза
    final isMultiPhaseBoss =
        isBoss && (_activeBossCard?.isMultiPhase ?? false) && bossPhase > 0;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                    child: Row(
                      children: [
                        Icon(
                          widget.dungeon.icon,
                          size: 15,
                          color: widget.dungeon.accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.dungeonName(widget.dungeon.id, widget.dungeon.name),
                          style: TextStyle(
                            color: widget.dungeon.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.gameDungeonFloor(_dungeonLevel, widget.dungeon.levelsCount),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      shieldTurns: _shieldTurns,
                      divineShieldCharges: _divineShieldCharges,
                      stoneskinTurns: _stoneskinTurns,
                      regenerationTurns: _regenerationTurns,
                      regenerationHp: _regenerationHpPerTurn,
                      mirrorTurns: _mirrorTurns,
                      invertNextChoice: _mirrorTurns > 0,
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
                  // Индикатор фазы босса
                  if (_result == GameResult.playing &&
                      isBoss &&
                      isMultiPhaseBoss)
                    _BossPhaseIndicator(
                      bossName: _activeBossCard!.title,
                      currentPhase: bossPhase,
                      totalPhases: 3,
                    ),
                  Expanded(
                    child: Center(
                      child: _result == GameResult.playing
                          ? SwipeCard(
                              key: ValueKey(_cardKey),
                              event: _effectiveCard,
                              currentCoins: _coins,
                              currentAttack: _attack,
                              hasUnlockedItems:
                                  UnlockedItemsService.instance.hasUnlockedForLevel(_effectiveCard.level),
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
                            context.l10n.gameSwipeHint,
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
                                  '${context.l10n.inventoryTitle}${_inventoryItems.isNotEmpty ? ' (${_inventoryItems.length})' : ''}',
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
                                  context.l10n.gameSurrender,
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


// ─── Индикатор фазы босса ────────────────────────────────────

class _BossPhaseIndicator extends StatelessWidget {
  const _BossPhaseIndicator({
    required this.bossName,
    required this.currentPhase,
    required this.totalPhases,
  });

  final String bossName;
  final int currentPhase;
  final int totalPhases;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B0000), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.crisis_alert, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bossName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Фаза $currentPhase / $totalPhases',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Полоска прогресса фаз
          Row(
            children: List.generate(totalPhases, (i) {
              final filled = i < currentPhase;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < totalPhases - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
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
    this.shieldTurns = 0,
    this.divineShieldCharges = 0,
    this.stoneskinTurns = 0,
    this.regenerationTurns = 0,
    this.regenerationHp = 2,
    this.mirrorTurns = 0,
    this.invertNextChoice = false,
    required this.isRevealingChoices,
    required this.greedMagnetTurns,
    required this.thornmailActive,
    this.poisonTurns = 0,
    this.bleedTurns = 0,
    this.blindnessTurns = 0,
    this.midasCurseTurns = 0,
  });

  final int shieldCharges;
  final int shieldTurns;
  final int divineShieldCharges;
  final int stoneskinTurns;
  final int regenerationTurns;
  final int regenerationHp;
  final int mirrorTurns;
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
      shieldTurns > 0 ||
      divineShieldCharges > 0 ||
      stoneskinTurns > 0 ||
      regenerationTurns > 0 ||
      mirrorTurns > 0 ||
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
            if (divineShieldCharges > 0)
              _BuffChip(
                emoji: '✨🛡️',
                label: context.l10n.gameBuffDivineShield(divineShieldCharges),
                color: const Color(0xFFFFD700),
              ),
            if (shieldTurns > 0)
              _BuffChip(
                emoji: '🛡️',
                label: context.l10n.gameBuffEnhancedShield(shieldTurns),
                color: const Color(0xFF0288D1),
              ),
            if (shieldCharges > 0)
              _BuffChip(
                emoji: '🛡️',
                label: context.l10n.gameBuffShield(shieldCharges),
                color: const Color(0xFF29B6F6),
              ),
            if (stoneskinTurns > 0)
              _BuffChip(
                emoji: '🪨',
                label: context.l10n.gameBuffStoneskin(stoneskinTurns),
                color: const Color(0xFF78909C),
              ),
            if (regenerationTurns > 0)
              _BuffChip(
                emoji: '🌿',
                label: context.l10n.gameBuffRegen(regenerationTurns, regenerationHp),
                color: const Color(0xFF66BB6A),
              ),
            if (mirrorTurns > 0 || invertNextChoice)
              _BuffChip(
                emoji: '🪞',
                label: mirrorTurns > 1
                    ? context.l10n.gameBuffMirrorTurns(mirrorTurns)
                    : context.l10n.gameBuffMirror,
                color: const Color(0xFFAB47BC),
              ),
            if (isRevealingChoices)
              _BuffChip(
                emoji: '👁️',
                label: context.l10n.gameBuffClairvoyance,
                color: const Color(0xFF26A69A),
              ),
            if (greedMagnetTurns > 0)
              _BuffChip(
                emoji: '🧲',
                label: context.l10n.gameBuffGreed(greedMagnetTurns),
                color: const Color(0xFFFF7043),
              ),
            if (thornmailActive)
              _BuffChip(
                emoji: '🌵',
                label: context.l10n.gameBuffThorns,
                color: const Color(0xFF8D6E63),
              ),
            if (poisonTurns > 0)
              _BuffChip(
                emoji: '🧪',
                label: context.l10n.gameBuffPoison(poisonTurns),
                color: const Color(0xFF66BB6A),
              ),
            if (bleedTurns > 0)
              _BuffChip(
                emoji: '🩸',
                label: context.l10n.gameBuffBleed(bleedTurns),
                color: const Color(0xFFE53935),
              ),
            if (blindnessTurns > 0)
              _BuffChip(
                emoji: '👁️‍🗨️',
                label: context.l10n.gameBuffBlindness(blindnessTurns),
                color: const Color(0xFF90A4AE),
              ),
            if (midasCurseTurns > 0)
              _BuffChip(
                emoji: '👑',
                label: context.l10n.gameBuffMidasCurse(midasCurseTurns),
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
                    isVictory ? context.l10n.gameDungeonCleared : context.l10n.gameAdventureOver,
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
                        ? context.l10n.gameVictoryCongrats(cardsPassed, dungeonLevel)
                        : context.l10n.gameDefeatDesc(cardsPassed, dungeonLevel),
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
                          label: context.l10n.gameThisRun,
                          value: '+$runCoins 🪙',
                          color: const Color(0xFFFFD700),
                          isCompact: isShortScreen,
                        ),
                      ),
                      SizedBox(width: isShortScreen ? 8 : 12),
                      Expanded(
                        child: _ResultStat(
                          label: context.l10n.gameTotalCoins,
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
                                context.l10n.gameRunChronicle,
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
                      label: Text(isVictory ? context.l10n.gameNewRun : context.l10n.gameFightAgain),
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
                      label: Text(context.l10n.gameMainMenu),
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
                            context.l10n.gameCardUsed,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.itemTitle(item.id, item.title),
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
                        child: Text(
                          context.l10n.great,
                          style: const TextStyle(
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
