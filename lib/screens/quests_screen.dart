import 'dart:async';

import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../services/daily_quests_service.dart';
import '../services/daily_reward_service.dart';
import '../services/locale_service.dart';
import '../services/player_coins_service.dart';
import '../widgets/currencies_bar.dart';

/// Экран заданий и ежедневных наград.
///
/// Отображает:
/// * Баланс монет игрока;
/// * 7-дневную серию ежедневных входов в игру (стрик);
/// * Ежедневные случайные задания (2 задания в день, по 150 монет каждое);
/// * Таймер обратного отсчёта до смены дня в 00:00 по Московскому времени (UTC+3).
class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  bool _isClaimingDailyStreak = false;
  final Set<String> _claimingQuestIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([
      PlayerCoinsService.instance.load(),
      DailyRewardService.instance.load(),
      DailyQuestsService.instance.load(),
    ]);
    if (mounted) setState(() {});
  }

  void _updateTimeLeft() {
    final remaining = DailyRewardService.timeUntilNextMskMidnight;
    if (mounted) {
      if (remaining == Duration.zero) {
        DailyQuestsService.instance.checkDayTransition();
      }
      setState(() {
        _timeLeft = remaining;
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _claimDailyStreakReward() async {
    if (_isClaimingDailyStreak) return;
    setState(() => _isClaimingDailyStreak = true);

    await DailyRewardService.instance.claimToday();

    if (!mounted) return;
    setState(() => _isClaimingDailyStreak = false);
  }

  Future<void> _claimQuest(DailyQuest quest) async {
    if (_claimingQuestIds.contains(quest.id)) return;
    setState(() => _claimingQuestIds.add(quest.id));

    await DailyQuestsService.instance.claimQuest(quest.id);

    if (!mounted) return;
    setState(() => _claimingQuestIds.remove(quest.id));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);

        return ListenableBuilder(
          listenable: Listenable.merge([
            DailyRewardService.instance,
            DailyQuestsService.instance,
          ]),
          builder: (context, _) {
            final dailyService = DailyRewardService.instance;
            final streakDay = dailyService.todayStreakDay;
            final canClaimStreak = dailyService.canClaimToday;
            final streakRewardAmount = dailyService.todayRewardAmount;
            final dailyQuests = DailyQuestsService.instance.quests;

            return Scaffold(
              backgroundColor: const Color(0xFF0F0F1A),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(l10n.questsTitle),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Панель валют (монеты, серебряные и золотые ключи) ───────
                      const PlayerCurrenciesBar(),
                      const SizedBox(height: 24),

                      // ── Блок ежедневного входа (стрик) ───────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1F1F38),
                              Color(0xFF16162A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA000),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.hotel_class_rounded,
                                    color: Color(0xFF141424),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.questsDailySection,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.questsWeeklyStreak,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.questsStreakProgress(streakDay, 7),
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Text(
                              l10n.dailyRewardSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Плашка с таймером и временем смены дня
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 16,
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.dailyResetNote,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F0F1A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _formatDuration(_timeLeft),
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.dailyRewardResetAfterSeven,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Карточки 7 дней ──────────────────────────────
                            _buildDaysGrid(
                              context,
                              currentStreakDay: streakDay,
                              canClaimToday: canClaimStreak,
                              l10n: l10n,
                            ),
                            const SizedBox(height: 20),

                            // Большая кнопка "Забрать", если сегодня ещё не получено
                            if (canClaimStreak)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isClaimingDailyStreak ? null : _claimDailyStreakReward,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFB300),
                                    foregroundColor: const Color(0xFF141424),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                    shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.6),
                                  ),
                                  child: _isClaimingDailyStreak
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF141424),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, size: 24),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${l10n.dailyRewardClaimButton} (+$streakRewardAmount 🪙)',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF4CAF50),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.dailyRewardClaimedToday,
                                      style: const TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Блок ежедневных заданий ───────────────────────────
                      _buildDailyQuestsSection(context, l10n, dailyQuests),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Секция ежедневных заданий (2 случайных задания в день по 150 монет)
  Widget _buildDailyQuestsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<DailyQuest> quests,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A32),
            Color(0xFF141424),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF8C7AE6),
                      Color(0xFF575FCF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dailyQuestsSection,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.dailyQuestsSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (quests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                ),
              ),
            )
          else
            Column(
              children: quests.map((quest) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuestCard(context, l10n, quest),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Карточка одного ежедневного задания
  Widget _buildQuestCard(
    BuildContext context,
    AppLocalizations l10n,
    DailyQuest quest,
  ) {
    final String title;
    final String desc;
    final IconData iconData;
    final Color iconColor;

    switch (quest.type) {
      case DailyQuestType.dungeonRuns:
        title = l10n.questPlayDungeonsTitle(quest.target);
        desc = l10n.questPlayDungeonsDesc;
        iconData = Icons.explore_rounded;
        iconColor = const Color(0xFF00D2D3);
        break;
      case DailyQuestType.killBosses:
        title = l10n.questKillBossesTitle(quest.target);
        desc = l10n.questKillBossesDesc;
        iconData = Icons.military_tech_rounded;
        iconColor = const Color(0xFFFF5252);
        break;
      case DailyQuestType.clearDungeon:
        title = l10n.questClearDungeonTitle;
        desc = l10n.questClearDungeonDesc;
        iconData = Icons.emoji_events_rounded;
        iconColor = const Color(0xFFFFD700);
        break;
      case DailyQuestType.encounterCards:
        title = l10n.questEncounterCardsTitle(quest.target, quest.targetEventType);
        desc = l10n.questEncounterCardsDesc;
        iconData = Icons.style_rounded;
        iconColor = const Color(0xFFAB47BC);
        break;
    }

    final isClaiming = _claimingQuestIds.contains(quest.id);
    final progressFraction = (quest.progress / quest.target).clamp(0.0, 1.0);

    Color cardBorderColor;
    Color cardBgColor;

    if (quest.isClaimed) {
      cardBorderColor = const Color(0xFF4CAF50).withValues(alpha: 0.4);
      cardBgColor = const Color(0xFF4CAF50).withValues(alpha: 0.08);
    } else if (quest.canClaim) {
      cardBorderColor = const Color(0xFFFFD700);
      cardBgColor = const Color(0xFFFFD700).withValues(alpha: 0.12);
    } else {
      cardBorderColor = Colors.white.withValues(alpha: 0.1);
      cardBgColor = Colors.white.withValues(alpha: 0.03);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor, width: quest.canClaim ? 1.8 : 1.0),
        boxShadow: quest.canClaim
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.4)),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  l10n.questRewardBadgeText(DailyQuest.rewardCoins),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Прогресс бар
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: quest.isCompleted ? const Color(0xFF4CAF50) : const Color(0xFFFFB300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.questProgressText(quest.progress, quest.target),
                style: TextStyle(
                  color: quest.isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Кнопка получения или статус
          if (quest.canClaim)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isClaiming ? null : () => _claimQuest(quest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF141424),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.5),
                ),
                child: isClaiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF141424),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.questClaimButtonText(DailyQuest.rewardCoins),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          else if (quest.isClaimed)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.questClaimedBadgeText,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.questInProgressBadgeText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Сетка карточек 7 дней стрика
  Widget _buildDaysGrid(
    BuildContext context, {
    required int currentStreakDay,
    required bool canClaimToday,
    required AppLocalizations l10n,
  }) {
    return Column(
      children: [
        // Первые 4 дня в первом ряду
        Row(
          children: List.generate(4, (index) {
            final day = index + 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: _buildDayCard(
                  day: day,
                  currentStreakDay: currentStreakDay,
                  canClaimToday: canClaimToday,
                  l10n: l10n,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Дни 5, 6, 7 во втором ряду (День 7 чуть шире/акцентнее)
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildDayCard(
                  day: 5,
                  currentStreakDay: currentStreakDay,
                  canClaimToday: canClaimToday,
                  l10n: l10n,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildDayCard(
                  day: 6,
                  currentStreakDay: currentStreakDay,
                  canClaimToday: canClaimToday,
                  l10n: l10n,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _buildDayCard(
                day: 7,
                currentStreakDay: currentStreakDay,
                canClaimToday: canClaimToday,
                l10n: l10n,
                isJackpot: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCard({
    required int day,
    required int currentStreakDay,
    required bool canClaimToday,
    required AppLocalizations l10n,
    bool isJackpot = false,
  }) {
    final reward = DailyRewardService.getRewardForDay(day);

    final bool isPastClaimed;
    final bool isToday;
    final bool isFuture;

    if (canClaimToday) {
      isPastClaimed = day < currentStreakDay;
      isToday = day == currentStreakDay;
      isFuture = day > currentStreakDay;
    } else {
      isPastClaimed = day <= currentStreakDay;
      isToday = false;
      isFuture = day > currentStreakDay;
    }

    Color borderColor;
    Color bgColor;

    if (isPastClaimed) {
      borderColor = const Color(0xFF4CAF50).withValues(alpha: 0.6);
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.12);
    } else if (isToday) {
      borderColor = const Color(0xFFFFD700);
      bgColor = const Color(0xFFFFD700).withValues(alpha: 0.2);
    } else if (isJackpot) {
      borderColor = const Color(0xFFFFB300).withValues(alpha: 0.5);
      bgColor = const Color(0xFFFFB300).withValues(alpha: 0.1);
    } else {
      borderColor = Colors.white.withValues(alpha: 0.1);
      bgColor = Colors.white.withValues(alpha: 0.04);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isToday ? 2.0 : 1.0),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isJackpot
                ? (l10n.isRussian ? 'День 7 👑' : 'Day 7 👑')
                : (l10n.isRussian ? 'День $day' : 'Day $day'),
            style: TextStyle(
              color: isToday
                  ? const Color(0xFFFFD700)
                  : (isJackpot
                      ? const Color(0xFFFFB300)
                      : Colors.white.withValues(alpha: isFuture ? 0.45 : 0.9)),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          if (isPastClaimed)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: 22,
            )
          else if (isToday)
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            )
          else if (isJackpot)
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB300),
              size: 22,
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
          const SizedBox(height: 6),

          Text(
            '+$reward 🪙',
            style: TextStyle(
              color: isToday
                  ? const Color(0xFFFFD700)
                  : (isJackpot
                      ? const Color(0xFFFFB300)
                      : (isPastClaimed
                          ? const Color(0xFF4CAF50)
                          : Colors.white.withValues(alpha: isFuture ? 0.4 : 0.85))),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
