import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../services/daily_reward_service.dart';

/// Открывает диалог ежедневной награды за вход в игру.
Future<void> showDailyRewardDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const DailyRewardDialog(),
  );
}

/// Диалог получения ежедневной награды за вход.
///
/// Отображает:
/// * Текущий день в 7-дневном стрике;
/// * Сумму сегодняшней награды (1-й день: 100, 2-й: 200, ..., 7-й: 700);
/// * Линейку из 7 дней с визуализацией пройденных, текущего и будущих дней;
/// * Кнопку получения награды с начислением монет.
class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({super.key});

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  bool _isClaiming = false;

  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    final reward = await DailyRewardService.instance.claimToday();

    if (!mounted) return;
    setState(() => _isClaiming = false);

    if (reward > 0) {
      Navigator.of(context).pop();
    } else {
      final error = DailyRewardService.instance.lastErrorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dailyService = DailyRewardService.instance;
    final currentStreakDay = dailyService.todayStreakDay;
    final canClaim = dailyService.canClaimToday;
    final rewardAmount = dailyService.todayRewardAmount;
    final silverKeysAmount = dailyService.todaySilverKeysAmount;
    final goldKeysAmount = dailyService.todayGoldKeysAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E38),
                  Color(0xFF151528),
                  Color(0xFF0F0F1A),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Верхняя иконка со свечением
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA000),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          size: 38,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Заголовок
                      Text(
                        l10n.dailyRewardTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Серия: день X из 7
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l10n.questsStreakProgress(currentStreakDay, 7),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Блок сегодняшней награды
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withValues(alpha: 0.08),
                              const Color(0xFFFFD700).withValues(alpha: 0.18),
                              const Color(0xFFFFD700).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              canClaim
                                  ? (l10n.isRussian ? 'Сегодняшняя награда:' : 'Today\'s reward:')
                                  : l10n.dailyRewardClaimedToday,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+$rewardAmount',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.isRussian ? 'монет' : 'coins',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (silverKeysAmount > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.vpn_key_rounded,
                                        color: Color(0xFFCFD8DC),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+$silverKeysAmount',
                                        style: const TextStyle(
                                          color: Color(0xFFCFD8DC),
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.isRussian
                                            ? (silverKeysAmount == 1 ? 'сер. ключ' : 'сер. ключа')
                                            : (silverKeysAmount == 1 ? 'silver key' : 'silver keys'),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (goldKeysAmount > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.key_rounded,
                                        color: Color(0xFFFFB300),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+$goldKeysAmount',
                                        style: const TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.isRussian ? 'зол. ключ' : 'gold key',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 7-дневный трекер входов
                      _buildSevenDaysTrack(
                        context,
                        currentStreakDay: currentStreakDay,
                        canClaimToday: canClaim,
                      ),
                      const SizedBox(height: 14),

                      // Информация об обновлении в полночь по МСК
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.dailyResetNote,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (dailyService.isRollbackDetected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.dailyRewardRollbackDetected,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Кнопка получения награды
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: canClaim
                            ? ElevatedButton(
                                onPressed: _isClaiming ? null : _claimReward,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB300),
                                  foregroundColor: const Color(0xFF141424),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                  shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.6),
                                ),
                                child: _isClaiming
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
                                          const Icon(Icons.check_circle_rounded, size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.dailyRewardClaimButton,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              )
                            : OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  l10n.close,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Кнопка закрытия (крестик в правом верхнем углу)
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Виджет отображения 7 дней стрика в виде горизонтального ряда карточек
  Widget _buildSevenDaysTrack(
    BuildContext context, {
    required int currentStreakDay,
    required bool canClaimToday,
  }) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 7 карточек с отступами
        final itemWidth = (totalWidth - 6 * 4) / 7;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1;
            final reward = DailyRewardService.getRewardForDay(day);
            final silverKeys = DailyRewardService.getSilverKeysForDay(day);
            final goldKeys = DailyRewardService.getGoldKeysForDay(day);

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

            final isJackpot = day == 7;

            return SizedBox(
              width: itemWidth,
              child: _DayCardMini(
                day: day,
                reward: reward,
                silverKeys: silverKeys,
                goldKeys: goldKeys,
                isPastClaimed: isPastClaimed,
                isToday: isToday,
                isFuture: isFuture,
                isJackpot: isJackpot,
                l10n: l10n,
              ),
            );
          }),
        );
      },
    );
  }
}

class _DayCardMini extends StatelessWidget {
  const _DayCardMini({
    required this.day,
    required this.reward,
    this.silverKeys = 0,
    this.goldKeys = 0,
    required this.isPastClaimed,
    required this.isToday,
    required this.isFuture,
    required this.isJackpot,
    required this.l10n,
  });

  final int day;
  final int reward;
  final int silverKeys;
  final int goldKeys;
  final bool isPastClaimed;
  final bool isToday;
  final bool isFuture;
  final bool isJackpot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Widget statusWidget;

    if (isPastClaimed) {
      borderColor = const Color(0xFF4CAF50).withValues(alpha: 0.6);
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.15);
      statusWidget = const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: Color(0xFF4CAF50),
      );
    } else if (isToday) {
      borderColor = const Color(0xFFFFD700);
      bgColor = const Color(0xFFFFD700).withValues(alpha: 0.22);
      statusWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'ВХОД',
          style: TextStyle(
            color: Color(0xFF141424),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // Future
      borderColor = isJackpot
          ? const Color(0xFFFFB300).withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.12);
      bgColor = isJackpot
          ? const Color(0xFFFFB300).withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.04);
      statusWidget = Icon(
        isJackpot ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
        size: 14,
        color: isJackpot
            ? const Color(0xFFFFB300).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.35),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isToday ? 1.8 : 1.0),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.isRussian ? 'Д$day' : 'D$day',
            style: TextStyle(
              color: isToday
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: isFuture ? 0.4 : 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          statusWidget,
          const SizedBox(height: 3),
          Text(
            '$reward',
            style: TextStyle(
              color: isJackpot
                  ? const Color(0xFFFFD700)
                  : (isPastClaimed
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withValues(alpha: isFuture ? 0.4 : 0.9)),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (silverKeys > 0) ...[
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.vpn_key_rounded, size: 8, color: Color(0xFFCFD8DC)),
                Text(
                  '+$silverKeys',
                  style: const TextStyle(
                    color: Color(0xFFCFD8DC),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (goldKeys > 0) ...[
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key_rounded, size: 8.5, color: Color(0xFFFFB300)),
                Text(
                  '+$goldKeys',
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
