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
    final discoveredCount =
        allEvents.where((e) => discovered.isDiscovered(e.id)).length;

    // Группируем по категориям в том же порядке, что задан в enum
    final categories = EventType.values;

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
                              'Открыто: $discoveredCount / ${allEvents.length}',
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
                                  value: discoveredCount / allEvents.length,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFE94560),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Секции по категориям событий
                    for (final type in categories) ...[
                      _CategoryHeader(type: type, discovered: discovered),
                      _CategoryGrid(
                        type: type,
                        discovered: discovered,
                        onTap: _showCardDetails,
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Заголовок категории
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.type, required this.discovered});

  final EventType type;
  final DiscoveredEventsService discovered;

  @override
  Widget build(BuildContext context) {
    final events = allEvents.where((e) => e.type == type).toList();
    final discoveredCount =
        events.where((e) => discovered.isDiscovered(e.id)).length;
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
                '$discoveredCount / ${events.length}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сетка карточек категории
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.type,
    required this.discovered,
    required this.onTap,
  });

  final EventType type;
  final DiscoveredEventsService discovered;
  final void Function(EventCard) onTap;

  @override
  Widget build(BuildContext context) {
    final events = allEvents.where((e) => e.type == type).toList();

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: eventTypeColor(event.type).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eventTypeLabel(event.type),
              style: TextStyle(color: eventTypeColor(event.type), fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (choice.healthDelta != 0 || choice.attackDelta != 0 || choice.coinsDelta != 0) ...[
            const SizedBox(height: 6),
            Text(
              _formatDeltas(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
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
