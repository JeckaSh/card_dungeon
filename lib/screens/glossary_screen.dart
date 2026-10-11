import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/events.dart';
import '../models/event_card.dart';
import '../services/discovered_events.dart';
import '../services/locale_service.dart';
import '../utils/event_style.dart';
import '../widgets/glossary_card.dart';

/// Экран бестиария и энциклопедии встреченных событий (Глоссарий).
///
/// Отображает все существующие в игре карты событий и боссов, сгруппированные
/// по категориям ([EventType]). Карты, которые герой ещё не встречал в игре,
/// отображаются закрытыми силуэтами.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  bool _loading = true;
  final Set<String> _collapsedCategories = {};

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

  bool _isCategoryExpanded(String key) => !_collapsedCategories.contains(key);

  void _toggleCategory(String key) {
    setState(() {
      if (_collapsedCategories.contains(key)) {
        _collapsedCategories.remove(key);
      } else {
        _collapsedCategories.add(key);
      }
    });
  }

  void _toggleAll(List<EventType> regularCategories) {
    setState(() {
      final allKeys = [
        ...regularCategories.map((t) => t.name),
        'boss',
      ];
      if (_collapsedCategories.isEmpty) {
        _collapsedCategories.addAll(allKeys);
      } else {
        _collapsedCategories.clear();
      }
    });
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

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            title: Text(l10n.glossaryTitle),
            actions: [
              IconButton(
                tooltip: _collapsedCategories.isEmpty
                    ? l10n.glossaryCollapseAll
                    : l10n.glossaryExpandAll,
                icon: Icon(
                  _collapsedCategories.isEmpty
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => _toggleAll(regularCategories),
              ),
              const SizedBox(width: 4),
            ],
            elevation: 0,
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560)),
                )
          : CustomScrollView(
                  slivers: [
                    // Прогресс-бар открытия
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              '${l10n.glossaryDiscovered}: $discoveredCount / ${all.length}',
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
                      _CategoryHeader(
                        type: type,
                        discovered: discovered,
                        events: allEvents,
                        isExpanded: _isCategoryExpanded(type.name),
                        onToggle: () => _toggleCategory(type.name),
                      ),
                      if (_isCategoryExpanded(type.name))
                        _CategoryGrid(
                          events: allEvents.where((e) => e.type == type).toList(),
                          discovered: discovered,
                          onTap: _showCardDetails,
                        ),
                    ],
                    // Секция боссов
                    _BossHeader(
                      discovered: discovered,
                      isExpanded: _isCategoryExpanded('boss'),
                      onToggle: () => _toggleCategory('boss'),
                    ),
                    if (_isCategoryExpanded('boss'))
                      _CategoryGrid(
                        events: allBossCards,
                        discovered: discovered,
                        onTap: _showCardDetails,
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
        );
      },
    );
  }
}

/// Заголовок обычной категории
class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.type,
    required this.discovered,
    required this.events,
    required this.isExpanded,
    required this.onToggle,
  });

  final EventType type;
  final DiscoveredEventsService discovered;
  final List<EventCard> events;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final typeEvents = events.where((e) => e.type == type).toList();
    final discoveredCount = typeEvents.where((e) => discovered.isDiscovered(e.id)).length;
    final color = eventTypeColor(type);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                  context.l10n.eventTypeLabel(type),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: color,
                    size: 18,
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
        ),
      ),
    );
  }
}

/// Заголовок секции боссов
class _BossHeader extends StatelessWidget {
  const _BossHeader({
    required this.discovered,
    required this.isExpanded,
    required this.onToggle,
  });

  final DiscoveredEventsService discovered;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final discoveredCount =
        allBossCards.where((e) => discovered.isDiscovered(e.id)).length;
    const color = Color(0xFFEF5350);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.eventTypePluralLabel(EventType.boss),
                          style: const TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      context.l10n.glossaryBossHint,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
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

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                      isBoss ? context.l10n.glossaryBossBadge : context.l10n.eventTypeLabel(event.type),
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
                      context.l10n.glossaryLevel(event.level),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.isCommonDungeon
                          ? const Color(0xFF64B5F6).withValues(alpha: 0.15)
                          : const Color(0xFF81C784).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: event.isCommonDungeon
                            ? const Color(0xFF64B5F6).withValues(alpha: 0.35)
                            : const Color(0xFF81C784).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      context.l10n.dungeonScope(event.isCommonDungeon, event.dungeonId, event.dungeonLabel),
                      style: TextStyle(
                        color: event.isCommonDungeon
                            ? const Color(0xFF90CAF9)
                            : const Color(0xFFA5D6A7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: context.l10n.close,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.l10n.close,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          if (choice.healthDelta != 0 ||
              choice.attackDelta != 0 ||
              choice.coinsDelta != 0 ||
              choice.statusEffect != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatDeltas(context),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDeltas(BuildContext context) {
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
    if (choice.statusEffect != null) {
      parts.add('${choice.statusEffect!.icon} ${context.l10n.statusEffectLabel(choice.statusEffect!)} (${(choice.statusChance * 100).round()}%)');
    }
    return parts.join('  ');
  }
}

