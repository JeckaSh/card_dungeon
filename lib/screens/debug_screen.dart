import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../data/events.dart';
import '../data/items.dart';
import '../services/daily_quests_service.dart';
import '../services/daily_reward_service.dart';
import '../services/discovered_events.dart';
import '../services/locale_service.dart';
import '../services/player_coins_service.dart';
import '../services/player_stats_service.dart';
import '../services/run_chronicle_service.dart';
import '../services/unlocked_items_service.dart';

/// Экран отладки и читов для разработчика и тестирования.
///
/// Предоставляет инструменты быстрого тестирования игрового баланса:
/// * Изменение баланса монет (добавить, списать, задать вручную);
/// * Разблокировка и блокировка всех карт в коллекции;
/// * Разблокировка всех событий в глоссарии;
/// * Мгновенная настройка уровней прокачки характеристик персонажа;
/// * Запуск тестовых забегов с кастомными параметрами (этаж, инвентарь, HP).
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _loading = true;
  final _coinsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      UnlockedItemsService.instance.load(),
      DiscoveredEventsService.instance.load(),
      PlayerStatsService.instance.load(),
      RunChronicleService.instance.load(),
      DailyRewardService.instance.load(),
      DailyQuestsService.instance.load(),
    ]);
    if (mounted) {
      _coinsController.text = PlayerCoinsService.instance.balance.toString();
      setState(() => _loading = false);
    }
  }

  void _refresh() => setState(() {});

  Future<void> _clearChronicle() async {
    await RunChronicleService.instance.clear();
    _refresh();
  }

  Future<void> _unlockAllEvents() async {
    final ids = [...allEvents, ...allBossCards].map((e) => e.id).toList();
    await DiscoveredEventsService.instance.unlockAll(ids);
    _refresh();
  }

  Future<void> _lockAllEvents() async {
    await DiscoveredEventsService.instance.resetAll();
    _refresh();
  }

  Future<void> _unlockAllItems() async {
    final ids = allItemCards.map((i) => i.id).toList();
    await UnlockedItemsService.instance.unlockAll(ids);
    _refresh();
  }

  Future<void> _lockAllItems() async {
    await UnlockedItemsService.instance.reset();
    _refresh();
  }

  void _addCoins(int amount) {
    PlayerCoinsService.instance.applyDelta(amount);
    _coinsController.text = PlayerCoinsService.instance.balance.toString();
    _refresh();
  }

  void _removeCoins(int amount) {
    PlayerCoinsService.instance.applyDelta(-amount);
    _coinsController.text = PlayerCoinsService.instance.balance.toString();
    _refresh();
  }

  void _setCoins() {
    final value = int.tryParse(_coinsController.text);
    if (value == null || value < 0) {
      return;
    }
    PlayerCoinsService.instance.restoreBalance(value);
    _refresh();
  }

  void _addSilverKeys(int amount) {
    PlayerCoinsService.instance.applySilverKeysDelta(amount);
    _refresh();
  }

  void _addGoldKeys(int amount) {
    PlayerCoinsService.instance.applyGoldKeysDelta(amount);
    _refresh();
  }

  void _resetKeys() {
    PlayerCoinsService.instance.setSilverKeys(0);
    PlayerCoinsService.instance.setGoldKeys(0);
    _refresh();
  }

  void _setHealthLevel(int level) {
    PlayerStatsService.instance.setHealthLevel(level);
    _refresh();
  }

  void _setAttackLevel(int level) {
    PlayerStatsService.instance.setAttackLevel(level);
    _refresh();
  }

  void _setMerchantLevel(int level) {
    PlayerStatsService.instance.setMerchantLevel(level);
    _refresh();
  }

  void _setStartingCardsLevel(int level) {
    PlayerStatsService.instance.setStartingCardsLevel(level);
    _refresh();
  }

  void _setMerchantCardUpgradeLevel(int level) {
    PlayerStatsService.instance.setMerchantCardUpgradeLevel(level);
    _refresh();
  }

  void _resetStats() {
    PlayerStatsService.instance.resetStats();
    _refresh();
  }

  void _maxStats() {
    PlayerStatsService.instance.setHealthLevel(PlayerStatsService.maxHealthLevel);
    PlayerStatsService.instance.setAttackLevel(PlayerStatsService.maxAttackLevel);
    PlayerStatsService.instance.setMerchantLevel(PlayerStatsService.maxMerchantLevel);
    PlayerStatsService.instance.setStartingCardsLevel(PlayerStatsService.maxStartingCardsLevel);
    PlayerStatsService.instance.setMerchantCardUpgradeLevel(PlayerStatsService.maxMerchantCardUpgradeLevel);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final stats = PlayerStatsService.instance;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'DEBUG',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(l10n.debugTitle),
              ],
            ),
            elevation: 0,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // === СОБЫТИЯ ===
                          _SectionHeader(
                            icon: Icons.auto_stories,
                            title: l10n.debugEventsTitle,
                            subtitle: l10n.debugUnlockedCount(
                              DiscoveredEventsService.instance.count,
                              allEvents.length + allBossCards.length,
                            ),
                            color: const Color(0xFFE94560),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugUnlockAll,
                                  icon: Icons.lock_open,
                                  color: const Color(0xFF4CAF50),
                                  onPressed: _unlockAllEvents,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugLockAll,
                                  icon: Icons.lock_outline,
                                  color: const Color(0xFFE94560),
                                  onPressed: _lockAllEvents,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // === ПРЕДМЕТЫ ===
                          _SectionHeader(
                            icon: Icons.card_giftcard,
                            title: l10n.debugItemsTitle,
                            subtitle: l10n.debugUnlockedCount(
                              UnlockedItemsService.instance.count,
                              allItemCards.length,
                            ),
                            color: const Color(0xFF9C27B0),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugUnlockAll,
                                  icon: Icons.lock_open,
                                  color: const Color(0xFF4CAF50),
                                  onPressed: _unlockAllItems,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugLockAll,
                                  icon: Icons.lock_outline,
                                  color: const Color(0xFFE94560),
                                  onPressed: _lockAllItems,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // === МОНЕТЫ ===
                          _SectionHeader(
                            icon: Icons.monetization_on,
                            title: l10n.debugCoinsTitle,
                            subtitle: l10n.debugCoinsBalance(PlayerCoinsService.instance.balance),
                            color: const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 12),
                          // Быстрые кнопки
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _QuickCoinButton(label: '+50', onPressed: () => _addCoins(50)),
                              _QuickCoinButton(label: '+200', onPressed: () => _addCoins(200)),
                              _QuickCoinButton(label: '+1000', onPressed: () => _addCoins(1000)),
                              _QuickCoinButton(
                                label: '-50',
                                onPressed: () => _removeCoins(50),
                                isNegative: true,
                              ),
                              _QuickCoinButton(
                                label: '-200',
                                onPressed: () => _removeCoins(200),
                                isNegative: true,
                              ),
                              _QuickCoinButton(
                                label: l10n.debugResetCoins,
                                onPressed: () {
                                  PlayerCoinsService.instance.restoreBalance(0);
                                  _coinsController.text = '0';
                                  _refresh();
                                },
                                isNegative: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Ручной ввод
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _coinsController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: l10n.debugSetCoinsLabel,
                                    labelStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFFD700),
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.monetization_on,
                                      color: Color(0xFFFFD700),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _setCoins,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.debugApply,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // === КЛЮЧИ (ВАЛЮТЫ) ===
                          _SectionHeader(
                            icon: Icons.vpn_key_rounded,
                            title: l10n.debugKeysTitle,
                            subtitle:
                                '${l10n.debugSilverKeysBalance(PlayerCoinsService.instance.silverKeys)} • ${l10n.debugGoldKeysBalance(PlayerCoinsService.instance.goldKeys)}',
                            color: const Color(0xFFDDE4F0),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _QuickCoinButton(
                                label: '+1 🗝️',
                                onPressed: () => _addSilverKeys(1),
                              ),
                              _QuickCoinButton(
                                label: '+5 🗝️',
                                onPressed: () => _addSilverKeys(5),
                              ),
                              _QuickCoinButton(
                                label: '+1 🔑',
                                onPressed: () => _addGoldKeys(1),
                              ),
                              _QuickCoinButton(
                                label: '+5 🔑',
                                onPressed: () => _addGoldKeys(5),
                              ),
                              _QuickCoinButton(
                                label: 'Сбросить ключи',
                                onPressed: _resetKeys,
                                isNegative: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // === ПРОКАЧКА ХАРАКТЕРИСТИК ===
                          _SectionHeader(
                            icon: Icons.upgrade_rounded,
                            title: l10n.debugHeroStatsTitle,
                            subtitle: l10n.debugHeroStatsSubtitle(
                              healthLvl: stats.healthLevel,
                              startingHealth: stats.startingHealth,
                              attackLvl: stats.attackLevel,
                              startingAttack: stats.startingAttack,
                              merchantLvl: stats.merchantLevel,
                              cardsLvl: stats.startingCardsLevel,
                              cardsCount: stats.startingCardsCount,
                            ),
                            color: const Color(0xFF00E676),
                          ),
                          const SizedBox(height: 12),
                          _StatLevelControllerCard(
                            title: l10n.debugHealthLevelTitle,
                            icon: Icons.favorite,
                            color: const Color(0xFFE94560),
                            level: stats.healthLevel,
                            maxLevel: PlayerStatsService.maxHealthLevel,
                            startingValue: '${stats.startingHealth} ❤',
                            bonusText: '+${stats.healthLevel * PlayerStatsService.healthPerLevel} ❤',
                            l10n: l10n,
                            onChanged: _setHealthLevel,
                          ),
                          const SizedBox(height: 12),
                          _StatLevelControllerCard(
                            title: l10n.debugAttackLevelTitle,
                            icon: Icons.flash_on,
                            color: const Color(0xFFFFD700),
                            level: stats.attackLevel,
                            maxLevel: PlayerStatsService.maxAttackLevel,
                            startingValue: '${stats.startingAttack} ⚡',
                            bonusText: '+${stats.attackLevel * PlayerStatsService.attackPerLevel} ⚡',
                            l10n: l10n,
                            onChanged: _setAttackLevel,
                          ),
                          const SizedBox(height: 12),
                          _StatLevelControllerCard(
                            title: l10n.debugMerchantLevelTitle,
                            icon: Icons.storefront_rounded,
                            color: const Color(0xFF26A69A),
                            level: stats.merchantLevel,
                            maxLevel: PlayerStatsService.maxMerchantLevel,
                            startingValue: stats.guaranteedMerchants == 0
                                ? l10n.debugRandom
                                : l10n.debugMerchantsPerLevel(stats.guaranteedMerchants),
                            bonusText: stats.merchantLevel == 0
                                ? l10n.debugNoGuarantee
                                : l10n.debugMerchantsGuaranteed(stats.merchantLevel),
                            l10n: l10n,
                            onChanged: _setMerchantLevel,
                          ),
                          const SizedBox(height: 12),
                          _StatLevelControllerCard(
                            title: l10n.debugStartingCardsLevelTitle,
                            icon: Icons.auto_awesome_motion_rounded,
                            color: const Color(0xFFAB47BC),
                            level: stats.startingCardsLevel,
                            maxLevel: PlayerStatsService.maxStartingCardsLevel,
                            startingValue: stats.startingCardsCount == 0
                                ? l10n.debugNoCards
                                : l10n.debugCardsAtStart(stats.startingCardsCount),
                            bonusText: stats.startingCardsLevel == 0
                                ? l10n.debugZeroCards
                                : l10n.debugRandomCardsBonus(stats.startingCardsLevel),
                            l10n: l10n,
                            onChanged: _setStartingCardsLevel,
                          ),
                          const SizedBox(height: 12),
                          _StatLevelControllerCard(
                            title: l10n.inventoryMerchantLuck,
                            icon: Icons.auto_awesome,
                            color: const Color(0xFF42A5F5),
                            level: stats.merchantCardUpgradeLevel,
                            maxLevel:
                                PlayerStatsService.maxMerchantCardUpgradeLevel,
                            startingValue:
                                '${stats.merchantCardUpgradeChance}%',
                            bonusText:
                                '+${stats.merchantCardUpgradeLevel * PlayerStatsService.merchantCardUpgradePerLevel}% ⭐',
                            l10n: l10n,
                            onChanged: _setMerchantCardUpgradeLevel,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugResetStats,
                                  icon: Icons.refresh_rounded,
                                  color: const Color(0xFFE94560),
                                  onPressed: _resetStats,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugMaxStats,
                                  icon: Icons.rocket_launch_rounded,
                                  color: const Color(0xFF00E676),
                                  onPressed: _maxStats,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // === ХРОНИКА ЗАБЕГОВ ===
                          _SectionHeader(
                            icon: Icons.history_edu_rounded,
                            title: l10n.debugChronicleTitle,
                            subtitle: l10n.debugChronicleRecords(
                              RunChronicleService.instance.records.length,
                              RunChronicleService.maxRuns,
                            ),
                            color: const Color(0xFF00BCD4),
                          ),
                          const SizedBox(height: 12),
                          _DebugButton(
                            label: l10n.debugClearChronicle,
                            icon: Icons.delete_sweep_rounded,
                            color: const Color(0xFFE94560),
                            onPressed: _clearChronicle,
                          ),
                          const SizedBox(height: 28),

                          // === ЕЖЕДНЕВНЫЕ НАГРАДЫ ===
                          _SectionHeader(
                            icon: Icons.hotel_class_rounded,
                            title: l10n.debugDailyTitle,
                            subtitle: '${l10n.dailyRewardDayNumber(DailyRewardService.instance.todayStreakDay)} / 7 '
                                '(${DailyRewardService.instance.isClaimedToday ? l10n.dailyRewardClaimedToday : l10n.dailyRewardClaimButton})',
                            color: const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugDailyResetToday,
                                  icon: Icons.replay_rounded,
                                  color: const Color(0xFFFF9800),
                                  onPressed: () async {
                                    await DailyRewardService.instance.debugResetTodayClaim();
                                    _refresh();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugDailyResetAll,
                                  icon: Icons.delete_outline_rounded,
                                  color: const Color(0xFFE94560),
                                  onPressed: () async {
                                    await DailyRewardService.instance.debugResetStreak();
                                    _refresh();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(7, (index) {
                              final day = index + 1;
                              return ActionChip(
                                label: Text(l10n.debugDailySetStreak(day)),
                                avatar: const Icon(Icons.stars, size: 16, color: Color(0xFFFFD700)),
                                backgroundColor: const Color(0xFF1E1E38),
                                side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                onPressed: () async {
                                  await DailyRewardService.instance.debugSetStreak(day, claimedToday: false);
                                  _refresh();
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 28),

                          // === ЕЖЕДНЕВНЫЕ И ЕЖЕНЕДЕЛЬНЫЕ ЗАДАНИЯ ===
                          _SectionHeader(
                            icon: Icons.assignment_turned_in_rounded,
                            title: l10n.debugQuestsTitle,
                            subtitle: 'День: ${DailyQuestsService.instance.quests.where((q) => q.isCompleted).length}/${DailyQuestsService.instance.quests.length} | Неделя: ${DailyQuestsService.instance.weeklyQuests.where((q) => q.isCompleted).length}/${DailyQuestsService.instance.weeklyQuests.length}',
                            color: const Color(0xFF6C5CE7),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugQuestsCompleteAll,
                                  icon: Icons.done_all_rounded,
                                  color: const Color(0xFF4CAF50),
                                  onPressed: () async {
                                    await DailyQuestsService.instance.debugCompleteAll();
                                    _refresh();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DebugButton(
                                  label: l10n.debugQuestsReroll,
                                  icon: Icons.shuffle_rounded,
                                  color: const Color(0xFF26A69A),
                                  onPressed: () async {
                                    await DailyQuestsService.instance.debugRerollQuests();
                                    await DailyQuestsService.instance.debugRerollWeeklyQuests();
                                    _refresh();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DebugButton(
                            label: l10n.debugQuestsReset,
                            icon: Icons.refresh_rounded,
                            color: const Color(0xFFE94560),
                            onPressed: () async {
                              await DailyQuestsService.instance.debugResetProgress();
                              _refresh();
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

class _QuickCoinButton extends StatelessWidget {
  const _QuickCoinButton({
    required this.label,
    required this.onPressed,
    this.isNegative = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final color = isNegative ? const Color(0xFFE94560) : const Color(0xFF4CAF50);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StatLevelControllerCard extends StatelessWidget {
  const _StatLevelControllerCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.level,
    required this.maxLevel,
    required this.startingValue,
    required this.bonusText,
    required this.l10n,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int level;
  final int maxLevel;
  final String startingValue;
  final String bonusText;
  final AppLocalizations l10n;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.debugStartBonus(startingValue, bonusText),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  l10n.debugLevelMax(level, maxLevel),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: level > 0 ? color : Colors.white24,
                onPressed: level > 0 ? () => onChanged(level - 1) : null,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.2),
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: level.toDouble(),
                    min: 0,
                    max: maxLevel.toDouble(),
                    divisions: maxLevel,
                    label: '$level',
                    onChanged: (val) => onChanged(val.round()),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: level < maxLevel ? color : Colors.white24,
                onPressed: level < maxLevel ? () => onChanged(level + 1) : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _QuickLevelChip(
                label: l10n.debugLevelMinChip,
                isSelected: level == 0,
                color: color,
                onTap: () => onChanged(0),
              ),
              const SizedBox(width: 8),
              _QuickLevelChip(
                label: l10n.debugLevelChip(5),
                isSelected: level == 5,
                color: color,
                onTap: () => onChanged(5),
              ),
              const SizedBox(width: 8),
              _QuickLevelChip(
                label: l10n.debugLevelMaxChip(maxLevel),
                isSelected: level == maxLevel,
                color: color,
                onTap: () => onChanged(maxLevel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLevelChip extends StatelessWidget {
  const _QuickLevelChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

