import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/dungeons.dart';
import '../models/dungeon.dart';
import '../services/locale_service.dart';
import 'game_screen.dart';

/// Экран выбора подземелий.
class DungeonSelectScreen extends StatelessWidget {
  const DungeonSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, l10n),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        for (final dungeon in allDungeons)
                          _DungeonCard(
                            dungeon: dungeon,
                            l10n: l10n,
                            onSelect: dungeon.isAvailable
                                ? () => _enterDungeon(context, dungeon)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _enterDungeon(BuildContext context, Dungeon dungeon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(dungeon: dungeon),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
            ),
            tooltip: l10n.back,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.explore_rounded,
            color: Color(0xFFE94560),
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dungeonSelectTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                l10n.dungeonSelectSubtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DungeonCard extends StatelessWidget {
  const _DungeonCard({
    required this.dungeon,
    required this.l10n,
    required this.onSelect,
  });

  final Dungeon dungeon;
  final AppLocalizations l10n;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final isAvailable = dungeon.isAvailable;
    final accent = dungeon.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.4,
        ),
        boxShadow: isAvailable
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхний ряд: Иконка + Заголовок + Бейдж статуса
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isAvailable ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: isAvailable ? 0.4 : 0.2),
                        ),
                      ),
                      child: Icon(
                        dungeon.icon,
                        color: isAvailable ? accent : Colors.white38,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dungeonName(dungeon.id, dungeon.name),
                            style: TextStyle(
                              color: isAvailable ? Colors.white : Colors.white60,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${l10n.dungeonLevelsCount}: ${dungeon.levelsCount}',
                            style: TextStyle(
                              color: isAvailable ? accent : Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable
                              ? accent.withValues(alpha: 0.35)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        isAvailable ? l10n.dungeonAvailable : l10n.dungeonSoon,
                        style: TextStyle(
                          color: isAvailable ? accent : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Описание
                Text(
                  l10n.dungeonDescription(dungeon.id, dungeon.description),
                  style: TextStyle(
                    color: isAvailable
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Чипы параметров
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.layers_rounded,
                      label: l10n.dungeonLevels(dungeon.levelsCount),
                      color: isAvailable ? accent : Colors.white38,
                    ),
                    _InfoChip(
                      icon: Icons.style_rounded,
                      label: isAvailable ? l10n.dungeonUniqueCards : l10n.dungeonNewCards,
                      color: isAvailable
                          ? const Color(0xFF64B5F6)
                          : Colors.white38,
                    ),
                    _InfoChip(
                      icon: Icons.military_tech_rounded,
                      label: isAvailable ? l10n.dungeonBossEachLevel : l10n.dungeonNewBosses,
                      color: isAvailable
                          ? const Color(0xFFFFB74D)
                          : Colors.white38,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Кнопка входа
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isAvailable
                      ? ElevatedButton.icon(
                          onPressed: onSelect,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            l10n.dungeonEnterButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: accent.withValues(alpha: 0.5),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline_rounded, size: 18),
                          label: Text(l10n.dungeonInDevelopment),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white30,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
