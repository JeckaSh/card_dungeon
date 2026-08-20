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
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CardDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovered = DiscoveredEventsService.instance;
    final discoveredCount = allEvents.where((e) => discovered.isDiscovered(e.id)).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Глоссарий'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : Column(
              children: [
                Padding(
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
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFE94560)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: allEvents.length,
                    itemBuilder: (context, index) {
                      final event = allEvents[index];
                      final isDiscovered = discovered.isDiscovered(event.id);
                      return GlossaryCard(
                        event: event,
                        isDiscovered: isDiscovered,
                        onTap: () => _showCardDetails(event),
                      );
                    },
                  ),
                ),
              ],
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
          _DetailChoice(label: '← ${event.leftChoice.label}', choice: event.leftChoice),
          const SizedBox(height: 12),
          _DetailChoice(label: '${event.rightChoice.label} →', choice: event.rightChoice),
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
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          if (choice.healthDelta != 0 || choice.attackDelta != 0) ...[
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
    return parts.join('  ');
  }
}
