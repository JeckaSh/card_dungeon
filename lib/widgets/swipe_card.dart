import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/event_card.dart';
import '../utils/event_style.dart';

/// Интерактивная карточка события с поддержкой свайпов влево и вправо.
///
/// Основной элемент игрового процесса:
/// * Свайп влево активирует [EventCard.leftChoice].
/// * Свайп вправо активирует [EventCard.rightChoice].
/// * Карточка блокирует свайп, если у игрока недостаточно ресурсов (монет или атаки).
/// * Поддерживает визуальные эффекты: пульсация босса, слепота ([isBlind]),
///   просмотр исходов ([isRevealingChoices]) и динамический наклон при перетаскивании.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.event,
    required this.currentCoins,
    required this.currentAttack,
    required this.onSwipe,
    this.hasUnlockedItems = true,
    this.isRevealingChoices = false,
    this.isBlind = false,
    this.isBoss = false,
    this.dungeonLevel = 1,
  });

  /// Текущее событие, отображаемое на карточке
  final EventCard event;

  /// Текущий баланс монет героя (для проверки доступности платных выборов)
  final int currentCoins;

  /// Текущая атака героя (для проверки требований силы к выбору)
  final int currentAttack;

  /// Доступны ли в коллекции открытые предметы (для выборов, дающих случайный предмет)
  final bool hasUnlockedItems;

  /// Режим ясновидения: показывать подсказки исходов без оттягивания карты
  final bool isRevealingChoices;

  /// Статус «Слепота»: скрывает текст последствий выбора от игрока
  final bool isBlind;

  /// Является ли текущая карточка боссом этажа (включает пульсирующую рамку)
  final bool isBoss;

  /// Текущий уровень (этаж) подземелья
  final int dungeonLevel;

  /// Коллбэк при завершении свайпа: `true` — вправо, `false` — влево
  final void Function(bool isRight) onSwipe;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _pulseController;
  Animation<Offset>? _offsetAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _swipeThreshold = 100.0;
  double _exitDistance = 500.0;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_offsetAnimation != null) {
          setState(() => _dragOffset = _offsetAnimation!.value);
        }
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isBoss) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _swipeController.stop();
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    if (_dragOffset.dx.abs() > _swipeThreshold) {
      final isRight = _dragOffset.dx > 0;
      final choice = isRight
          ? widget.event.rightChoice
          : widget.event.leftChoice;
      final blocked = _blockedReason(choice) != null;
      if (blocked) {
        _animateBack();
      } else {
        _animateOffScreen(isRight);
      }
    } else {
      _animateBack();
    }
  }

  String? _blockedReason(CardChoice choice) {
    if (choice.givesRandomItem && !widget.hasUnlockedItems) {
      return 'Карты';
    }
    if (choice.coinsDelta < 0 && widget.currentCoins < choice.coinsDelta.abs()) {
      return 'Монеты';
    }
    if (choice.attackDelta < 0 &&
        widget.currentAttack < choice.attackDelta.abs()) {
      return 'Атака';
    }
    return null;
  }

  void _animateOffScreen(bool isRight) {
    final targetX = isRight ? _exitDistance : -_exitDistance;
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      if (mounted) {
        widget.onSwipe(isRight);
      }
    });
  }

  void _animateBack() {
    _offsetAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut),
        );

    _swipeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final mediaQuery = MediaQuery.maybeOf(context);
        final screenWidth = mediaQuery?.size.width ?? availableWidth;
        // Мобильные экраны телефонов (ширина < 500)
        final isSmallScreen = screenWidth < 500;

        // На маленьких экранах (телефонах) карточка увеличена на 10%
        final widthFactor = isSmallScreen ? 0.46 : 0.80;
        final minWidth = isSmallScreen ? 154.0 : 260.0;
        final maxWidth = isSmallScreen ? 220.0 : 380.0;

        double cardWidth = ((availableWidth - 36) * widthFactor).clamp(
          minWidth,
          maxWidth,
        );
        double cardHeight = cardWidth / 0.72;

        if (cardHeight > availableHeight - 16) {
          cardHeight = availableHeight - 16;
          cardWidth = cardHeight * 0.72;
        }

        _swipeThreshold = (cardWidth * 0.28).clamp(40.0, 120.0);
        _exitDistance = math.max(availableWidth, 450.0);

        final scale = (cardWidth / 280.0).clamp(0.55, 1.25);
        final rotation = _dragOffset.dx / (1000 * scale);
        final leftOpacity = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
        final rightOpacity = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

        final leftChoice = widget.event.leftChoice;
        final rightChoice = widget.event.rightChoice;
        final leftBlockedReason = _blockedReason(leftChoice);
        final rightBlockedReason = _blockedReason(rightChoice);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: rotation,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Пульсирующая рамка для босса
                  if (widget.isBoss)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final pulse = _pulseController.value;
                        return Container(
                          width: cardWidth + 6 + pulse * 4,
                          height: cardHeight + 6 + pulse * 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22 * scale),
                            border: Border.all(
                              color: Color.lerp(
                                const Color(0xFFB71C1C),
                                const Color(0xFFFF5252),
                                pulse,
                              )!,
                              width: 2.5 + pulse * 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFEF5350,
                                ).withValues(alpha: 0.25 + pulse * 0.25),
                                blurRadius: 20 + pulse * 15,
                                spreadRadius: 2 + pulse * 3,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  _EventCardContent(
                    event: widget.event,
                    currentCoins: widget.currentCoins,
                    currentAttack: widget.currentAttack,
                    width: cardWidth,
                    height: cardHeight,
                    scale: scale,
                    isBoss: widget.isBoss,
                    dungeonLevel: widget.dungeonLevel,
                  ),
                  if (_isDragging ||
                      _dragOffset.dx != 0 ||
                      widget.isRevealingChoices) ...[
                    Positioned(
                      top: 14 * scale,
                      left: 10 * scale,
                      child: Opacity(
                        opacity: widget.isRevealingChoices ? 0.9 : leftOpacity,
                        child: _ChoiceHint(
                          choice: widget.event.leftChoice,
                          isLeft: true,
                          blockedReason: leftBlockedReason,
                          scale: scale,
                          isBlind: widget.isBlind,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14 * scale,
                      right: 10 * scale,
                      child: Opacity(
                        opacity: widget.isRevealingChoices ? 0.9 : rightOpacity,
                        child: _ChoiceHint(
                          choice: widget.event.rightChoice,
                          isLeft: false,
                          blockedReason: rightBlockedReason,
                          scale: scale,
                          isBlind: widget.isBlind,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EventCardContent extends StatelessWidget {
  const _EventCardContent({
    required this.event,
    required this.currentCoins,
    required this.currentAttack,
    required this.width,
    required this.height,
    required this.scale,
    this.isBoss = false,
    this.dungeonLevel = 1,
  });

  final EventCard event;
  final int currentCoins;
  final int currentAttack;
  final double width;
  final double height;
  final double scale;
  final bool isBoss;
  final int dungeonLevel;

  @override
  Widget build(BuildContext context) {
    final baseColor = eventTypeColor(event.type);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * scale),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBoss
              ? [const Color(0xFF4A0000), const Color(0xFF1A0000)]
              : [baseColor, baseColor.withValues(alpha: 0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isBoss ? const Color(0xFFEF5350) : baseColor).withValues(
              alpha: 0.4,
            ),
            blurRadius: 20 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * scale),
        child: Stack(
          children: [
            // Фоновый декоративный элемент
            Positioned(
              top: -30 * scale,
              right: -30 * scale,
              child: Icon(
                eventTypeIcon(event.type),
                size: 160 * scale,
                color: Colors.white.withValues(alpha: isBoss ? 0.06 : 0.08),
              ),
            ),
            // Для боссов — второй декоративный элемент снизу
            if (isBoss)
              Positioned(
                bottom: -20 * scale,
                left: -20 * scale,
                child: Icon(
                  Icons.crisis_alert,
                  size: 120 * scale,
                  color: const Color(0xFFEF5350).withValues(alpha: 0.06),
                ),
              ),
            Padding(
              padding: EdgeInsets.all((20 * scale).clamp(12.0, 28.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Верхний тег
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: (12 * scale).clamp(8.0, 16.0),
                            vertical: (5 * scale).clamp(3.0, 8.0),
                          ),
                          decoration: BoxDecoration(
                            color: isBoss
                                ? const Color(
                                    0xFFEF5350,
                                  ).withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: isBoss
                                ? Border.all(
                                    color: const Color(
                                      0xFFEF5350,
                                    ).withValues(alpha: 0.6),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBoss) ...[
                                Icon(
                                  Icons.crisis_alert,
                                  size: (13 * scale).clamp(10.0, 16.0),
                                  color: const Color(0xFFEF5350),
                                ),
                                SizedBox(width: 5 * scale),
                              ],
                              Flexible(
                                child: Text(
                                  isBoss
                                      ? '⚔ БОСС · Уровень $dungeonLevel'
                                      : eventTypeLabel(event.type),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isBoss
                                        ? const Color(0xFFEF5350)
                                        : Colors.white70,
                                    fontSize: (12 * scale).clamp(9.5, 15.0),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: isBoss ? 1.0 : 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (22 * scale).clamp(15.0, 32.0),
                            fontWeight: FontWeight.bold,
                            shadows: isBoss
                                ? [
                                    Shadow(
                                      color: const Color(
                                        0xFFEF5350,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        SizedBox(height: (8 * scale).clamp(4.0, 12.0)),
                        Text(
                          event.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: (13.5 * scale).clamp(10.5, 17.0),
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: (4 * scale).clamp(2.0, 8.0)),
                      ],
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

class _ChoiceHint extends StatelessWidget {
  const _ChoiceHint({
    required this.choice,
    required this.isLeft,
    required this.blockedReason,
    this.scale = 1.0,
    this.isBlind = false,
  });

  final CardChoice choice;
  final bool isLeft;
  final String? blockedReason;
  final double scale;
  final bool isBlind;

  bool get _isBlocked => blockedReason != null;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isBlocked
        ? const Color(0xFF6B0000)
        : (isLeft ? Colors.red : Colors.green);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (14 * scale).clamp(10.0, 20.0),
        vertical: (8 * scale).clamp(6.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: _isBlocked ? const Color(0xFFFF6B6B) : Colors.white,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: isLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (_isBlocked) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: const Color(0xFFFF6B6B),
                  size: (16 * scale).clamp(13.0, 20.0),
                ),
                SizedBox(width: 5 * scale),
                Text(
                  blockedReason == 'Карты'
                      ? 'Нет доступных карт'
                      : 'Нет ${blockedReason!.toLowerCase()}',
                  style: TextStyle(
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: (14 * scale).clamp(11.0, 18.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            Text(
              _requiredText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: (12 * scale).clamp(9.0, 15.0),
              ),
            ),
          ] else ...[
            Text(
              choice.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (15 * scale).clamp(11.0, 20.0),
              ),
            ),
            if (isBlind) ...[
              SizedBox(height: 4 * scale),
              Text(
                '❤ ?  ⚡ ?  🪙 ?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: (12 * scale).clamp(10.0, 15.0),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ] else if (choice.healthDelta != 0 ||
                choice.attackDelta != 0 ||
                choice.coinsDelta != 0 ||
                choice.givesRandomItem ||
                choice.statusEffect != null) ...[
              SizedBox(height: 4 * scale),
              Text(
                _formatDeltas(choice),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: (12 * scale).clamp(10.0, 15.0),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _requiredText() {
    if (blockedReason == 'Карты') {
      return 'нет доступных для покупки карточек';
    }
    if (blockedReason == 'Монеты') {
      return 'Нужно: ${choice.coinsDelta.abs()} 🪙';
    }
    if (blockedReason == 'Атака') {
      return 'Нужно: ${choice.attackDelta.abs()} ⚡';
    }
    return '';
  }

  String _formatDeltas(CardChoice choice) {
    final parts = <String>[];
    if (choice.healthDelta != 0) {
      parts.add('❤ ${choice.healthDelta > 0 ? '+' : ''}${choice.healthDelta}');
    }
    if (choice.attackDelta != 0) {
      parts.add('⚡ ${choice.attackDelta > 0 ? '+' : ''}${choice.attackDelta}');
    }
    if (choice.coinsDelta != 0) {
      parts.add('🪙 ${choice.coinsDelta > 0 ? '+' : ''}${choice.coinsDelta}');
    }
    if (choice.givesRandomItem) {
      parts.add('🎒 +1 карта');
    }
    if (choice.statusEffect != null) {
      parts.add('${choice.statusEffect!.icon} ${(choice.statusChance * 100).round()}%');
    }
    return parts.join('  ');
  }
}
