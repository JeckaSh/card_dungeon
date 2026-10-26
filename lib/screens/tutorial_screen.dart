import 'dart:math';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
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

  /// Эмодзи наставника (🧙‍♂️, ⚔️, 🛡️, 🎒, 👑, 🔮, 🏪)
  final String mentorEmoji;

  /// Обучающая карта события для этого шага
  final EventCard card;

  /// Ожидаемое направление свайпа (null = любое)
  final bool? targetSwipeRight;

  /// Требуется ли открыть инвентарь и использовать предмет
  final bool requiresItemUsage;
}

/// Экран интерактивного обучения основам игры Card Dungeon.
///
/// Знакомит новичка с ключевыми механиками игры (версия 0.0.17):
/// 1. Свайпы и влияние характеристик (❤ Здоровье, ⚡ Атака, 🪙 Золото);
/// 2. Механика блокировки выбора при нехватке ресурсов (красный замочек 🔒);
/// 3. Тайники и сокровищницы: тактический выбор между картами в инвентарь и золотом;
/// 4. Торговцы подземелья (покупка предметов или бесплатный выбор «Идти дальше»);
/// 5. Инвентарь и активация артефактов (щиты, эликсиры) прямо во время хода;
/// 6. Статус-эффекты (яд, кровотечение, слепота) и навык «Сопротивление»;
/// 7. Битвы с боссами этажей (3 фазы, уникальные атаки, золотая рамка).
///
/// За успешное **первое** завершение обучения игрок получает награду +50 золота.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStepIndex = 0;
  int _health = 10;
  int _attack = 5;
  int _coins = 15;
  int _shieldCharges = 0;
  bool _usedItemInStep = false;
  bool _isFinished = false;
  String? _lastFeedback;

  /// true — первое прохождение (награда выдаётся), false — повторное (без награды)
  bool _isFirstCompletion = false;

  final List<ItemCard> _inventory = [
    const ItemCard(
      id: 'potion_heal',
      title: 'Зелье лечения',
      description: 'Восстанавливает +4 здоровья',
      effectType: ItemEffectType.heal,
      value: 4,
      icon: Icons.healing,
      color: Color(0xFFE94560),
      level: 2,
    ),
    const ItemCard(
      id: 'runic_shield',
      title: 'Рунический щит',
      description: 'Следующий урон по здоровью будет полностью поглощён.',
      effectType: ItemEffectType.shield,
      value: 1,
      icon: Icons.shield_outlined,
      color: Color(0xFF29B6F6),
      level: 1,
    ),
  ];

  List<TutorialStep> _getSteps(AppLocalizations l10n) => [
        // Шаг 1: Основы свайпов и 3 ресурса
        TutorialStep(
          mentorEmoji: '🧙‍♂️',
          mentorMessage: l10n.tutorialStep1Mentor,
          card: EventCard(
            id: 'tut_step_1',
            type: EventType.mystery,
            title: l10n.tutorialStep1CardTitle,
            description: l10n.tutorialStep1CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep1Left,
              healthDelta: 3,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep1Right,
              attackDelta: 2,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 2: Битва с монстром и механика блокировки (красный замочек 🔒)
        TutorialStep(
          mentorEmoji: '⚔️',
          mentorMessage: l10n.tutorialStep2Mentor,
          card: EventCard(
            id: 'tut_step_2',
            type: EventType.monster,
            title: l10n.tutorialStep2CardTitle,
            description: l10n.tutorialStep2CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep2Left,
              // Требует 10 атаки! У игрока 5 или 7 — свайп влево заблокирован
              attackDelta: -10,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep2Right,
              healthDelta: -2,
              coinsDelta: 15,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 3: Сокровища и тайники (выбор между картой в инвентарь или золотом)
        TutorialStep(
          mentorEmoji: '🔮',
          mentorMessage: l10n.tutorialStep3Mentor,
          card: EventCard(
            id: 'tut_step_3_treasure',
            type: EventType.treasure,
            title: l10n.tutorialStep3CardTitle,
            description: l10n.tutorialStep3CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep3Left,
              givesRandomItem: true,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep3Right,
              coinsDelta: 25,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 4: Торговцы в подземелье (покупка за монеты или бесплатный проход)
        TutorialStep(
          mentorEmoji: '🏪',
          mentorMessage: l10n.tutorialStep4Mentor,
          card: EventCard(
            id: 'tut_step_4_merchant',
            type: EventType.merchant,
            title: l10n.tutorialStep4CardTitle,
            description: l10n.tutorialStep4CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep4Left,
              coinsDelta: -15,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep4Right,
              coinsDelta: 0,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 5: Инвентарь и артефакты
        TutorialStep(
          mentorEmoji: '🎒',
          mentorMessage: l10n.tutorialStep5Mentor,
          requiresItemUsage: true,
          card: EventCard(
            id: 'tut_step_5_trap',
            type: EventType.trap,
            title: l10n.tutorialStep5CardTitle,
            description: l10n.tutorialStep5CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep5Left,
              healthDelta: -3,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep5Right,
              attackDelta: -1,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 6: Статус-эффекты и DoT
        TutorialStep(
          mentorEmoji: '🧪',
          mentorMessage: l10n.tutorialStep6Mentor,
          card: EventCard(
            id: 'tut_step_6_status',
            type: EventType.trap,
            title: l10n.tutorialStep6CardTitle,
            description: l10n.tutorialStep6CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep6Left,
              healthDelta: -1,
              statusEffect: StatusEffectType.poison,
              statusChance: 1.0,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep6Right,
              attackDelta: 1,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),

        // Шаг 7: Финальный экзамен — Босс
        TutorialStep(
          mentorEmoji: '👑',
          mentorMessage: l10n.tutorialStep7Mentor,
          card: EventCard(
            id: 'tut_step_7_boss',
            type: EventType.boss,
            title: l10n.tutorialStep7CardTitle,
            description: l10n.tutorialStep7CardDesc,
            leftChoice: CardChoice(
              label: l10n.tutorialStep7Left,
              healthDelta: -3,
              coinsDelta: 20,
            ),
            rightChoice: CardChoice(
              label: l10n.tutorialStep7Right,
              attackDelta: -2,
              coinsDelta: 20,
            ),
            level: 1,
            dungeonId: DungeonId.common,
          ),
        ),
      ];

  String _buildSwipeFeedback(
    CardChoice choice, {
    ItemCard? receivedItem,
    bool shieldBlocked = false,
    bool wasBoss = false,
    required bool isRu,
  }) {
    final parts = <String>[];
    if (wasBoss) {
      parts.add(isRu ? '⚔️ Босс повержен! 👑' : '⚔️ Boss defeated! 👑');
    }
    if (shieldBlocked) {
      parts.add(isRu ? '🛡️ Урон поглощён щитом' : '🛡️ Damage absorbed by shield');
    } else if (choice.healthDelta != 0) {
      final prefix = isRu ? 'Здоровье' : 'Health';
      parts.add('$prefix ${choice.healthDelta > 0 ? '+' : ''}${choice.healthDelta} ❤');
    }
    if (choice.attackDelta != 0) {
      final prefix = isRu ? 'Атака' : 'Attack';
      parts.add('$prefix ${choice.attackDelta > 0 ? '+' : ''}${choice.attackDelta} ⚡');
    }
    if (choice.coinsDelta != 0) {
      final prefix = isRu ? 'Монеты' : 'Coins';
      parts.add('$prefix ${choice.coinsDelta > 0 ? '+' : ''}${choice.coinsDelta} 🪙');
    }
    if (receivedItem != null) {
      final prefix = isRu ? 'Получено' : 'Received';
      parts.add('🎒 $prefix: ${receivedItem.title}');
    }
    if (choice.statusEffect == StatusEffectType.poison) {
      parts.add(isRu ? '🧪 Отравление на 3 хода!' : '🧪 Poisoned for 3 turns!');
    }
    return parts.isEmpty ? choice.label : parts.join(', ');
  }

  void _onSwipe(bool isRight, List<TutorialStep> steps) {
    if (_currentStepIndex >= steps.length) return;
    final step = steps[_currentStepIndex];
    final choice = isRight ? step.card.rightChoice : step.card.leftChoice;

    var effHealth = choice.healthDelta;
    var effAttack = choice.attackDelta;
    var effCoins = choice.coinsDelta;

    final wasShieldBlocked = effHealth < 0 && _shieldCharges > 0;
    // Щит поглощает входящий урон по здоровью
    if (wasShieldBlocked) {
      _shieldCharges--;
      effHealth = 0;
    }

    ItemCard? receivedItem;
    // Выдача предметов в инвентарь при свайпе
    if (choice.givesRandomItem) {
      receivedItem = const ItemCard(
        id: 'sweet_roll',
        title: 'Сладкий рулет',
        description: 'Восстанавливает +3 здоровья. Кажется, его кто-то украл.',
        effectType: ItemEffectType.heal,
        value: 3,
        icon: Icons.cake_rounded,
        color: Color(0xFFFFB74D),
        level: 1,
      );
      _inventory.add(receivedItem);
    } else if (step.card.id == 'tut_step_4_merchant' && !isRight) {
      receivedItem = const ItemCard(
        id: 'whetstone',
        title: 'Точильный камень',
        description: 'Увеличивает атаку на +2',
        effectType: ItemEffectType.attack,
        value: 2,
        icon: Icons.flash_on,
        color: Color(0xFFF5A623),
        level: 1,
      );
      _inventory.add(receivedItem);
    }

    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final feedback = _buildSwipeFeedback(
      choice,
      receivedItem: receivedItem,
      shieldBlocked: wasShieldBlocked,
      wasBoss: step.card.type == EventType.boss,
      isRu: isRu,
    );

    setState(() {
      _lastFeedback = feedback;
      _health = max(1, _health + effHealth);
      _attack = max(1, _attack + effAttack);
      _coins = max(0, _coins + effCoins);

      if (_currentStepIndex + 1 < steps.length) {
        _currentStepIndex++;
        _usedItemInStep = false;
      } else {
        _isFinished = true;
        // Начисляем стартовую награду 50 монет только при первом прохождении
        PlayerCoinsService.instance
            .isTutorialRewardGranted()
            .then((alreadyGranted) {
          if (!alreadyGranted) {
            PlayerCoinsService.instance.applyDelta(50);
            PlayerCoinsService.instance.markTutorialRewardGranted();
            if (mounted) setState(() => _isFirstCompletion = true);
          }
        });
      }
    });
  }

  /// Применяет предмет из инвентаря.
  void _useItem(int index, ItemCard item) {
    if (index < 0 || index >= _inventory.length) return;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    setState(() {
      _inventory.removeAt(index);
      if (item.effectType == ItemEffectType.heal) {
        _health = min(20, _health + item.value);
      } else if (item.effectType == ItemEffectType.attack) {
        _attack = min(20, _attack + item.value);
      } else if (item.effectType == ItemEffectType.shield) {
        _shieldCharges += item.value;
      } else if (item.effectType == ItemEffectType.rebirth) {
        _health = 10;
        _attack = 5;
      } else if (item.effectType == ItemEffectType.casinoOfFate) {
        _health = min(20, _health + 8);
        _attack = min(20, _attack + 3);
      }
      _usedItemInStep = true;
      _lastFeedback = isRu
          ? 'Использовано: ${item.title} (${item.effectBadge})'
          : 'Used: ${item.title} (${item.effectBadge})';
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
          child: InventorySheet(items: _inventory, onUseItem: _useItem),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps(context.l10n);
    final safeIndex = min(_currentStepIndex, steps.length - 1);
    final step = steps[safeIndex];
    final isBossStep = safeIndex == steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 8),
            Text(
              context.l10n.tutorialTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.tutorialExit,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _isFinished
                ? _buildVictoryScreen()
                : _buildTutorialGame(step, isBossStep, steps),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialGame(
    TutorialStep step,
    bool isBossStep,
    List<TutorialStep> steps,
  ) {
    return Column(
      children: [
        // Верхний прогресс и статы
        StatsBar(
          health: _health,
          attack: _attack,
          cardsPassed: _currentStepIndex,
          coins: _coins,
          dungeonLevel: 1,
          nextBossIn: isBossStep ? null : (steps.length - _currentStepIndex - 1),
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
                        Text(
                          context.l10n.tutorialMentor,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.tutorialStep(
                              _currentStepIndex + 1,
                              steps.length,
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
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

        // Последствия свайпов и действий (над карточкой, как в обычной игре)
        if (_lastFeedback != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_lastFeedback),
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                _lastFeedback!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
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
              onSwipe: (isRight) => _onSwipe(isRight, steps),
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
                  context.l10n.tutorialInventory(_inventory.length),
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
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD700),
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tutorialCompleted,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tutorialCompletedBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (_isFirstCompletion)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFD700),
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tutorialRewardLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        l10n.tutorialRewardCoins,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white54,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.tutorialRewardAlreadyGranted,
                    style: const TextStyle(color: Colors.white54, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Памятка искателю приключений
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.tutorialGuideTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuideCard(
            icon: Icons.castle_rounded,
            iconColor: const Color(0xFF64B5F6),
            title: l10n.tutorialGuideDungeonsTitle,
            desc: l10n.tutorialGuideDungeonsDesc,
          ),
          const SizedBox(height: 8),
          _buildGuideCard(
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF81C784),
            title: l10n.tutorialGuideSkillsTitle,
            desc: l10n.tutorialGuideSkillsDesc,
          ),
          const SizedBox(height: 8),
          _buildGuideCard(
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFFFFB74D),
            title: l10n.tutorialGuideShopTitle,
            desc: l10n.tutorialGuideShopDesc,
          ),
          const SizedBox(height: 8),
          _buildGuideCard(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: const Color(0xFFBA68C8),
            title: l10n.tutorialGuideQuestsTitle,
            desc: l10n.tutorialGuideQuestsDesc,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore),
              label: Text(
                l10n.tutorialToMenu,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
