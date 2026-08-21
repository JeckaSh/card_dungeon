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
  });

  final EventCard event;
  final int currentCoins;
  final int currentAttack;
  final void Function(bool isRight) onSwipe;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  static const _swipeThreshold = 100.0;

  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

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
    if (choice.coinsDelta < 0 && widget.currentCoins < choice.coinsDelta.abs()) {
      return 'Монеты';
    }
    if (choice.attackDelta < 0 && widget.currentAttack < choice.attackDelta.abs()) {
      return 'Атака';
    }
    return null;
  }

  void _animateOffScreen(bool isRight) {
    final targetX = isRight ? 500.0 : -500.0;
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
    final rotation = _dragOffset.dx / 1000;
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
            children: [
              _EventCardContent(
                event: widget.event,
                currentCoins: widget.currentCoins,
                currentAttack: widget.currentAttack,
              ),
              if (_isDragging || _dragOffset.dx != 0) ...[
                Positioned(
                  top: 40,
                  left: 24,
                  child: Opacity(
                    opacity: leftOpacity,
                    child: _ChoiceHint(
                      choice: widget.event.leftChoice,
                      isLeft: true,
                      blockedReason: leftBlockedReason,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 24,
                  child: Opacity(
                    opacity: rightOpacity,
                    child: _ChoiceHint(
                      choice: widget.event.rightChoice,
                      isLeft: false,
                      blockedReason: rightBlockedReason,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCardContent extends StatelessWidget {
  const _EventCardContent({
    required this.event,
    required this.currentCoins,
    required this.currentAttack,
  });

  final EventCard event;
  final int currentCoins;
  final int currentAttack;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.min(MediaQuery.of(context).size.width - 48, 340),
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Icon(
                eventTypeIcon(event.type),
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      eventTypeLabel(event.type),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.5,
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
  });

  final CardChoice choice;
  final bool isLeft;
  // null — не заблокировано; 'Монеты' или 'Атака' — причина блокировки
  final String? blockedReason;

  bool get _isBlocked => blockedReason != null;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isBlocked
        ? const Color(0xFF6B0000)
        : (isLeft ? Colors.red : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
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
                const Icon(Icons.lock, color: Color(0xFFFF6B6B), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Нет ${blockedReason!.toLowerCase()}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _requiredText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              choice.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (choice.healthDelta != 0 || choice.attackDelta != 0 || choice.coinsDelta != 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatDeltas(choice),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _requiredText() {
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
    return parts.join('  ');
  }
}
