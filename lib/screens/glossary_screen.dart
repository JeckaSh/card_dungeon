import 'package:flutter/material.dart';

import '../data/events.dart';
import '../models/event_card.dart';
import '../services/discovered_events.dart';
import '../utils/event_style.dart';
import '../widgets/glossary_card.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  bool _loading = true;

  // Все карточки для глоссария (обычные + боссы)
  static List<EventCard> get _allForGlossary => [...allEvents, ...allBossCards];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DiscoveredEventsService.instance.load();
    if (mounted) setState(() => _loading = false);
  }

  void _showCardDetails(EventCard event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _CardDetailSheet(event: event),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovered = DiscoveredEventsService.instance;
    final all = _allForGlossary;
    final discoveredCount = all.where((e) => discovered.isDiscovered(e.id)).length;

    // Категории без boss (он показывается отдельной секцией в конце)
    final regularCategories =
        EventType.values.where((t) => t != EventType.boss).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Глоссарий'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: CustomScrollView(
                  slivers: [
                    // Прогресс-бар открытия
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Открыто: $discoveredCount / ${all.length}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: discoveredCount / all.length,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFFE94560)),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Обычные категории событий
                    for (final type in regularCategories) ...[
                      _CategoryHeader(type: type, discovered: discovered, events: allEvents),
                      _CategoryGrid(
                        events: allEvents.where((e) => e.type == type).toList(),
                        discovered: discovered,
                        onTap: _showCardDetails,
                      ),
                    ],
                    // Секция боссов
                    _BossHeader(discovered: discovered),
                    _CategoryGrid(
                      events: allBossCards,
                      discovered: discovered,
                      onTap: _showCardDetails,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Заголовок обычной категории
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.type,
    required this.discovered,
    required this.events,
  });

  final EventType type;
  final DiscoveredEventsService discovered;
  final List<EventCard> events;

  @override
  Widget build(BuildContext context) {
    final typeEvents = events.where((e) => e.type == type).toList();
    final discoveredCount = typeEvents.where((e) => discovered.isDiscovered(e.id)).length;
    final color = eventTypeColor(type);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(eventTypeIcon(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              eventTypeLabel(type),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$discoveredCount / ${typeEvents.length}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок секции боссов
class _BossHeader extends StatelessWidget {
  const _BossHeader({required this.discovered});

  final DiscoveredEventsService discovered;

  @override
  Widget build(BuildContext context) {
    final discoveredCount =
        allBossCards.where((e) => discovered.isDiscovered(e.id)).length;
    const color = Color(0xFFEF5350);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.crisis_alert, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Боссы',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Появляются каждую 20-ю карточку',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$discoveredCount / ${allBossCards.length}',
                style: const TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сетка карточек
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.events,
    required this.discovered,
    required this.onTap,
  });

  final List<EventCard> events;
  final DiscoveredEventsService discovered;
  final void Function(EventCard) onTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 0.72,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = events[index];
            final isDiscovered = discovered.isDiscovered(event.id);
            return GlossaryCard(
              event: event,
              isDiscovered: isDiscovered,
              onTap: () => onTap(event),
            );
          },
          childCount: events.length,
        ),
      ),
    );
  }
}

class _CardDetailSheet extends StatelessWidget {
  const _CardDetailSheet({required this.event});

  final EventCard event;

  @override
  Widget build(BuildContext context) {
    final isBoss = event.isBoss;
    final color = isBoss ? const Color(0xFFEF5350) : eventTypeColor(event.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: isBoss
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null,
                ),
                child: Text(
                  isBoss ? '⚔ БОСС' : eventTypeLabel(event.type),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBoss ? 'Уровень ${event.level}' : 'Уровень ${event.level}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: isBoss
                  ? [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _DetailChoice(
            label: '← ${event.leftChoice.label}',
            choice: event.leftChoice,
          ),
          const SizedBox(height: 12),
          _DetailChoice(
            label: '${event.rightChoice.label} →',
            choice: event.rightChoice,
          ),
        ],
      ),
    );
  }
}

class _DetailChoice extends StatelessWidget {
  const _DetailChoice({required this.label, required this.choice});

  final String label;
  final CardChoice choice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (choice.healthDelta != 0 || choice.attackDelta != 0 || choice.coinsDelta != 0) ...[
            const SizedBox(height: 6),
            Text(
              _formatDeltas(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDeltas() {
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
