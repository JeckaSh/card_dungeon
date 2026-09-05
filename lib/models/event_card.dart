enum EventType {
  monster,
  trap,
  treasure,
  merchant,
  rest,
  mystery,
  boss,
}

class CardChoice {
  const CardChoice({
    required this.label,
    this.healthDelta = 0,
    this.attackDelta = 0,
    this.coinsDelta = 0,
    this.givesRandomItem = false,
  });

  final String label;
  final int healthDelta;
  final int attackDelta;
  final int coinsDelta;
  final bool givesRandomItem;
}

class EventCard {
  const EventCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.leftChoice,
    required this.rightChoice,
    this.level = 1,
  });

  final String id;
  final EventType type;
  final String title;
  final String description;
  final CardChoice leftChoice;
  final CardChoice rightChoice;

  /// Уровень подземелья, на котором встречается карточка (1-3).
  /// Для боссов — номер уровня, на котором они появляются.
  final int level;

  bool get isBoss => type == EventType.boss;
}
