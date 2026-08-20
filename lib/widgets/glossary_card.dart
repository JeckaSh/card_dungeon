import 'package:flutter/material.dart';

import '../models/event_card.dart';
import '../utils/event_style.dart';

class GlossaryCard extends StatelessWidget {
  const GlossaryCard({
    super.key,
    required this.event,
    required this.isDiscovered,
    this.onTap,
  });

  final EventCard event;
  final bool isDiscovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDiscovered ? onTap : null,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDiscovered
                  ? [
                      eventTypeColor(event.type),
                      eventTypeColor(event.type).withValues(alpha: 0.6),
                    ]
                  : [
                      const Color(0xFF2A2A3E),
                      const Color(0xFF1A1A2E),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isDiscovered ? _KnownContent(event: event) : const _UnknownContent(),
          ),
        ),
      ),
    );
  }
}

class _KnownContent extends StatelessWidget {
  const _KnownContent({required this.event});

  final EventCard event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -20,
          right: -20,
          child: Icon(
            eventTypeIcon(event.type),
            size: 90,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  eventTypeLabel(event.type),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              const Spacer(),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                event.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _MiniChoice(choice: event.leftChoice, isLeft: true)),
                  const SizedBox(width: 6),
                  Expanded(child: _MiniChoice(choice: event.rightChoice, isLeft: false)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniChoice extends StatelessWidget {
  const _MiniChoice({required this.choice, required this.isLeft});

  final CardChoice choice;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLeft ? '← ${choice.label}' : '${choice.label} →',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isLeft ? TextAlign.left : TextAlign.right,
        style: const TextStyle(color: Colors.white60, fontSize: 9),
      ),
    );
  }
}

class _UnknownContent extends StatelessWidget {
  const _UnknownContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _QuestionPatternPainter()),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Неизвестно',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Встреть в подземелье',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
