import 'package:flutter/material.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({
    super.key,
    required this.health,
    required this.attack,
    required this.cardsPassed,
    required this.cardsTotal,
  });

  final int health;
  final int attack;
  final int cardsPassed;
  final int cardsTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatItem(
                icon: Icons.favorite,
                color: const Color(0xFFE94560),
                label: 'Здоровье',
                value: health,
                maxValue: 12,
              )),
              const SizedBox(width: 16),
              Expanded(child: _StatItem(
                icon: Icons.flash_on,
                color: const Color(0xFFF5A623),
                label: 'Атака',
                value: attack,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Карточки: $cardsPassed / $cardsTotal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cardsPassed / cardsTotal,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF0F3460)),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.maxValue,
  });

  final IconData icon;
  final Color color;
  final Color labelColor = const Color(0xFFFFFFFF);
  final String label;
  final int value;
  final int? maxValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              maxValue != null ? '$value / $maxValue' : '$value',
              style: TextStyle(
                color: labelColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
