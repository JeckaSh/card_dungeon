enum EventType {
  monster,
  trap,
  treasure,
  merchant,
  rest,
  mystery,
}

class CardChoice {
  const CardChoice({
    required this.label,
    this.healthDelta = 0,
    this.attackDelta = 0,
  });

  final String label;
  final int healthDelta;
  final int attackDelta;
}

class EventCard {
  const EventCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.leftChoice,
    required this.rightChoice,
  });

  final String id;
  final EventType type;
  final String title;
  final String description;
  final CardChoice leftChoice;
  final CardChoice rightChoice;
}
