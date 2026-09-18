import 'dart:math';

import 'package:flutter/material.dart';

import '../models/event_card.dart';
import '../models/item_card.dart';
import '../services/player_coins_service.dart';
import '../widgets/inventory_sheet.dart';
import '../widgets/stats_bar.dart';
import '../widgets/swipe_card.dart';

/// Шаг обучающего сценария.
class TutorialStep {
  const TutorialStep({
    required this.mentorMessage,
    required this.mentorEmoji,
    required this.card,
    this.targetSwipeRight,
    this.requiresItemUsage = false,
  });

  /// Сообщение от наставника
  final String mentorMessage;

  /// Эмодзи наставника (🧙‍♂️, ⚔️, 🛡️, 🎒, 🏆)
  final String mentorEmoji;

  /// Обучающая карта события для этого шага
  final EventCard card;

  /// Ожидаемое направление свайпа (null = любое)
  final bool? targetSwipeRight;

  /// Требуется ли открыть инвентарь и использовать предмет
  final bool requiresItemUsage;
}

/// Экран интерактивного обучения основам игры.
///
/// Знакомит новичка с ключевыми механиками:
/// 1. Свайпы и влияние характеристик (❤ Здоровье, ⚡ Атака, 🪙 Золото);
/// 2. Сражение с монстрами и ограничения по ресурсам;
/// 3. Сбор сокровищ и сохранение золота между забегами;
/// 4. Использование расходуемых предметов и артефактов из инвентаря;
/// 5. Статус-эффекты (яд, кровотечение, слепота, проклятие);
/// 6. Битвы с боссами в конце этажей.
///
/// За успешное завершение обучения игрок получает награду +50 золота.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStepIndex = 0;
  int _health = 10;
  int _attack = 5;
  int _coins = 10;
  int _shieldCharges = 0;
  bool _usedItemInStep = false;
  bool _isFinished = false;

  final List<ItemCard> _inventory = [
    const ItemCard(
      id: 'potion_heal',
      title: 'Зелье лечения',
      description: 'Восстанавливает +4 здоровья',
      effectType: ItemEffectType.heal,
      value: 4,
      icon: Icons.healing,
      color: Color(0xFFE94560),
    ),
    const ItemCard(
      id: 'runic_shield',
      title: 'Рунический щит',
      description: 'Следующий урон по здоровью будет полностью поглощён.',
      effectType: ItemEffectType.shield,
      value: 1,
      icon: Icons.shield_outlined,
      color: Color(0xFF29B6F6),
    ),
  ];

  static const List<TutorialStep> _steps = [
    // Шаг 1: Основы свайпов
    TutorialStep(
      mentorEmoji: '🧙‍♂️',
      mentorMessage:
          'Добро пожаловать в подземелье! Сверху отображаются твои Здоровье (❤), Сила атаки (⚡) и Золото (🪙). Оттяни карту влево или вправо, чтобы увидеть исходы, и свайпни!',
      card: EventCard(
        id: 'tut_step_1',
        type: EventType.mystery,
        title: 'Развилка в подземелье',
        description: 'Перед тобой два пути: левый ведёт к тихой реке, правый — к древним руинам.',
        leftChoice: CardChoice(
          label: 'Идти налево (+2 ❤)',
          healthDelta: 2,
        ),
        rightChoice: CardChoice(
          label: 'Идти направо (+1 ⚡)',
          attackDelta: 1,
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),

    // Шаг 2: Битва с монстром
    TutorialStep(
      mentorEmoji: '⚔️',
      mentorMessage:
          'Впереди монстр! Если твоей атаки недостаточно, выбор будет заблокирован. Выбери «Атаковать клинком» (свайп влево) или «Откупиться мясом» (свайп вправо).',
      card: EventCard(
        id: 'tut_step_2',
        type: EventType.monster,
        title: 'Пещерный гоблин',
        description: 'Гоблин с ржавым тесаком преграждает путь и скалит зубы.',
        leftChoice: CardChoice(
          label: 'Атаковать (-2 ⚡, +8 🪙)',
          attackDelta: -2,
          coinsDelta: 8,
        ),
        rightChoice: CardChoice(
          label: 'Отдать припасы (-2 ❤, +1 ⚡)',
          healthDelta: -2,
          attackDelta: 1,
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),

    // Шаг 3: Сокровища и экономика
    TutorialStep(
      mentorEmoji: '💰',
      mentorMessage:
          'Отлично! Золото (🪙) сохраняется после каждого похода. На него в главном меню можно открывать новые карты в Магазине и прокачивать героя в Инвентаре!',
      card: EventCard(
        id: 'tut_step_3',
        type: EventType.treasure,
        title: 'Кованый сундук',
        description: 'Тяжёлый дубовый сундук с бронзовым замком, доверху набитый золотыми монетами.',
        leftChoice: CardChoice(
          label: 'Забрать золото (+15 🪙)',
          coinsDelta: 15,
        ),
        rightChoice: CardChoice(
          label: 'Оставить',
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),

    // Шаг 4: Инвентарь и артефакты
    TutorialStep(
      mentorEmoji: '🎒',
      mentorMessage:
          'Внизу экрана есть кнопка «Инвентарь». Открой её прямо сейчас и активируй «Рунический щит» 🛡️, чтобы защититься от следующего удара!',
      requiresItemUsage: true,
      card: EventCard(
        id: 'tut_step_4',
        type: EventType.trap,
        title: 'Шипастый коридор',
        description: 'Пол усеян нажимными плитами. Любая оплошность активирует острые пики.',
        leftChoice: CardChoice(
          label: 'Идти напролом (-3 ❤)',
          healthDelta: -3,
        ),
        rightChoice: CardChoice(
          label: 'Осторожно перешагнуть (-1 ⚡)',
          attackDelta: -1,
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),

    // Шаг 5: Статусы и DoT-урон
    TutorialStep(
      mentorEmoji: '🧪',
      mentorMessage:
          'Опасные ловушки могут накладывать статусы на 3 хода: Отравление (-1 ❤), Кровотечение (-2 ❤), Слепоту или Проклятие Мидаса. Пройди ловушку!',
      card: EventCard(
        id: 'tut_step_5',
        type: EventType.trap,
        title: 'Ядовитые споровики',
        description: 'Из трещин в стене сочатся ядовитые грибы, распыляющие удушливый газ.',
        leftChoice: CardChoice(
          label: 'Пробежать сквозь газ',
          healthDelta: -1,
          statusEffect: StatusEffectType.poison,
          statusChance: 1.0,
        ),
        rightChoice: CardChoice(
          label: 'Сжечь споры факелом (+5 🪙)',
          coinsDelta: 5,
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),

    // Шаг 6: Финальный экзамен — Босс
    TutorialStep(
      mentorEmoji: '👑',
      mentorMessage:
          'Финальное испытание — БОСС! Каждые 20 карт этажа появляется могучий босс с пульсирующей рамкой. Победи Тренировочного Голема, чтобы завершить обучение!',
      card: EventCard(
        id: 'tut_step_6',
        type: EventType.boss,
        title: 'Тренировочный Голем',
        description: 'Магический голем из цельного камня. Его удары сокрушительны, но награда за победу велика!',
        leftChoice: CardChoice(
          label: 'Сокрушить ядро (-3 ❤, +2 ⚡, +20 🪙)',
          healthDelta: -3,
          attackDelta: 2,
          coinsDelta: 20,
        ),
        rightChoice: CardChoice(
          label: 'Опрокинуть рычагом (-2 ⚡, +15 🪙)',
          attackDelta: -2,
          coinsDelta: 15,
        ),
        level: 1,
        dungeonId: DungeonId.common,
      ),
    ),
  ];

  TutorialStep get _currentStep => _steps[_currentStepIndex];

  void _onSwipe(bool isRight) {
    final step = _currentStep;
    final choice = isRight ? step.card.rightChoice : step.card.leftChoice;

    var effHealth = choice.healthDelta;
    var effAttack = choice.attackDelta;
    var effCoins = choice.coinsDelta;

    // Щит поглощает урон
    if (effHealth < 0 && _shieldCharges > 0) {
      _shieldCharges--;
      effHealth = 0;
    }

    setState(() {
      _health = max(1, _health + effHealth);
      _attack = max(1, _attack + effAttack);
      _coins = max(0, _coins + effCoins);

      if (_currentStepIndex + 1 < _steps.length) {
        _currentStepIndex++;
        _usedItemInStep = false;
      } else {
        _isFinished = true;
        // Начисляем стартовую награду 50 монет
        PlayerCoinsService.instance.applyDelta(50);
      }
    });
  }

  /// Применяет предмет из инвентаря.
  ///
  /// Вызывается как коллбэк из [InventorySheet].
  /// **Важно:** [InventorySheet] сам закрывает шторку перед вызовом этого метода,
  /// поэтому дополнительный `Navigator.pop()` здесь не нужен (иначе будет двойной
  /// pop, который закроет весь экран).
  void _useItem(int index, ItemCard item) {
    if (index < 0 || index >= _inventory.length) return;
    setState(() {
      _inventory.removeAt(index);
      if (item.effectType == ItemEffectType.heal) {
        _health = min(20, _health + item.value);
      } else if (item.effectType == ItemEffectType.shield) {
        _shieldCharges += item.value;
      }
      _usedItemInStep = true;
    });
    // InventorySheet уже вызвал Navigator.pop() до передачи управления сюда —
    // повторный pop здесь не нужен и закроет экран обучения!

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A2E),
        content: Text(
          'Использовано: ${item.title} (${item.effectBadge})',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openInventory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: InventorySheet(items: _inventory, onUseItem: _useItem),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep;
    final isBossStep = _currentStepIndex == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFFFFD700), size: 22),
            SizedBox(width: 8),
            Text('Обучение', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Выйти', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _isFinished ? _buildVictoryScreen() : _buildTutorialGame(step, isBossStep),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialGame(TutorialStep step, bool isBossStep) {
    return Column(
      children: [
        // Верхний прогресс и статы
        StatsBar(
          health: _health,
          attack: _attack,
          cardsPassed: _currentStepIndex,
          coins: _coins,
          dungeonLevel: 1,
          nextBossIn: isBossStep ? null : (_steps.length - _currentStepIndex - 1),
        ),

        // Панель наставника
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step.mentorEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Наставник',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Шаг ${_currentStepIndex + 1} из ${_steps.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.mentorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Карточка события
        Expanded(
          child: Center(
            child: SwipeCard(
              key: ValueKey(_currentStepIndex),
              event: step.card,
              currentCoins: _coins,
              currentAttack: _attack,
              hasUnlockedItems: true,
              isBoss: isBossStep,
              dungeonLevel: 1,
              onSwipe: _onSwipe,
            ),
          ),
        ),

        // Нижняя панель с кнопкой инвентаря
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openInventory,
                icon: Badge(
                  isLabelVisible: _inventory.isNotEmpty,
                  label: Text('${_inventory.length}'),
                  backgroundColor: const Color(0xFFE94560),
                  child: const Icon(
                    Icons.backpack_outlined,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
                label: Text(
                  'Инвентарь (${_inventory.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: step.requiresItemUsage && !_usedItemInStep
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFE94560).withValues(alpha: 0.6),
                    width: step.requiresItemUsage && !_usedItemInStep ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVictoryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFD700),
            size: 80,
          ),
          const SizedBox(height: 18),
          const Text(
            'Обучение завершено!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ты освоил все основы выживания в подземелье!\nТеперь ты знаешь, как делать правильные выборы, использовать артефакты и сражаться с боссами.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Награда за обучение',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '+50 🪙 Золота',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore),
              label: const Text('В главное меню', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
