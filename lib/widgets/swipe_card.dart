import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/event_card.dart';
import '../utils/event_style.dart';

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.event,
    required this.currentCoins,
    required this.currentAttack,
    required this.onSwipe,
    this.hasUnlockedItems = true,
  });

  final EventCard event;
  final int currentCoins;
  final int currentAttack;
  final bool hasUnlockedItems;
  final void Function(bool isRight) onSwipe;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _swipeThreshold = 100.0;
  double _exitDistance = 500.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
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
      final choice = isRight ? widget.event.rightChoice : widget.event.leftChoice;
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

  /// Возвращает причину блокировки или null, если действие доступно.
  String? _blockedReason(CardChoice choice) {
    if (choice.givesRandomItem && !widget.hasUnlockedItems) {
      return 'Карты';
    }
    if (choice.coinsDelta < 0 && widget.currentCoins < choice.coinsDelta.abs()) {
      return 'Монеты';
    }
    if (choice.attackDelta < 0 && widget.currentAttack < choice.attackDelta.abs()) {
      return 'Атака';
    }
    return null;
  }

  void _animateOffScreen(bool isRight) {
    final targetX = isRight ? _exitDistance : -_exitDistance;
    final animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    animation.addListener(() {
      setState(() => _dragOffset = animation.value);
    });

    _controller.forward(from: 0).then((_) {
      widget.onSwipe(isRight);
    });
  }

  void _animateBack() {
    final animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    animation.addListener(() {
      setState(() => _dragOffset = animation.value);
    });

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Рассчитываем пропорциональный размер карточки с соотношением ~0.72
        double cardWidth = (availableWidth - 36).clamp(260.0, 420.0);
        double cardHeight = cardWidth / 0.72;
        if (cardHeight > availableHeight - 20) {
          cardHeight = availableHeight - 20;
          cardWidth = cardHeight * 0.72;
        }

        _swipeThreshold = (cardWidth * 0.28).clamp(70.0, 120.0);
        _exitDistance = math.max(availableWidth, 500.0);

        final scale = (cardWidth / 340.0).clamp(0.8, 1.25);
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
                  _EventCardContent(
                    event: widget.event,
                    currentCoins: widget.currentCoins,
                    currentAttack: widget.currentAttack,
                    width: cardWidth,
                    height: cardHeight,
                    scale: scale,
                  ),
                  if (_isDragging || _dragOffset.dx != 0) ...[
                    Positioned(
                      top: 30 * scale,
                      left: 20 * scale,
                      child: Opacity(
                        opacity: leftOpacity,
                        child: _ChoiceHint(
                          choice: widget.event.leftChoice,
                          isLeft: true,
                          blockedReason: leftBlockedReason,
                          scale: scale,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30 * scale,
                      right: 20 * scale,
                      child: Opacity(
                        opacity: rightOpacity,
                        child: _ChoiceHint(
                          choice: widget.event.rightChoice,
                          isLeft: false,
                          blockedReason: rightBlockedReason,
                          scale: scale,
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
  });

  final EventCard event;
  final int currentCoins;
  final int currentAttack;
  final double width;
  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * scale),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            eventTypeColor(event.type),
            eventTypeColor(event.type).withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: eventTypeColor(event.type).withValues(alpha: 0.4),
            blurRadius: 20 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * scale),
        child: Stack(
          children: [
            Positioned(
              top: -30 * scale,
              right: -30 * scale,
              child: Icon(
                eventTypeIcon(event.type),
                size: 150 * scale,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: EdgeInsets.all((26 * scale).clamp(16.0, 32.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Text(
                      eventTypeLabel(event.type),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: (12 * scale).clamp(10.0, 15.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    event.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (26 * scale).clamp(20.0, 34.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: (15 * scale).clamp(12.0, 18.0),
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
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
  });

  final CardChoice choice;
  final bool isLeft;
  // null — не заблокировано; 'Монеты' или 'Атака' — причина блокировки
  final String? blockedReason;
  final double scale;

  bool get _isBlocked => blockedReason != null;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isBlocked
        ? const Color(0xFF6B0000)
        : (isLeft ? Colors.red : Colors.green);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (16 * scale).clamp(12.0, 20.0),
        vertical: (10 * scale).clamp(8.0, 14.0),
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
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (_isBlocked) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: const Color(0xFFFF6B6B),
                  size: (16 * scale).clamp(14.0, 20.0),
                ),
                SizedBox(width: 6 * scale),
                Text(
                  blockedReason == 'Карты'
                      ? 'Нет доступных карт'
                      : 'Нет ${blockedReason!.toLowerCase()}',
                  style: TextStyle(
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: (15 * scale).clamp(12.0, 18.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            Text(
              _requiredText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: (12 * scale).clamp(10.0, 15.0),
              ),
            ),
          ] else ...[
            Text(
              choice.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (16 * scale).clamp(13.0, 20.0),
              ),
            ),
            if (choice.healthDelta != 0 || choice.attackDelta != 0 || choice.coinsDelta != 0) ...[
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
    return parts.join('  ');
  }
}
