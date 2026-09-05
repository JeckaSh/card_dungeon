import 'package:flutter/material.dart';

import '../models/event_card.dart';

Color eventTypeColor(EventType type) {
  return switch (type) {
    EventType.monster => const Color(0xFF8B0000),
    EventType.trap => const Color(0xFF4A3728),
    EventType.treasure => const Color(0xFFB8860B),
    EventType.merchant => const Color(0xFF2E5090),
    EventType.rest => const Color(0xFF1B5E20),
    EventType.mystery => const Color(0xFF4A148C),
    EventType.boss => const Color(0xFF7B0000),
  };
}

IconData eventTypeIcon(EventType type) {
  return switch (type) {
    EventType.monster => Icons.pets,
    EventType.trap => Icons.warning_amber,
    EventType.treasure => Icons.diamond,
    EventType.merchant => Icons.storefront,
    EventType.rest => Icons.local_fire_department,
    EventType.mystery => Icons.auto_awesome,
    EventType.boss => Icons.crisis_alert,
  };
}

String eventTypeLabel(EventType type) {
  return switch (type) {
    EventType.monster => 'Монстр',
    EventType.trap => 'Ловушка',
    EventType.treasure => 'Сокровище',
    EventType.merchant => 'Торговец',
    EventType.rest => 'Привал',
    EventType.mystery => 'Тайна',
    EventType.boss => 'БОСС',
  };
}
