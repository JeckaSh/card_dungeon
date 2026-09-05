import 'package:flutter/material.dart';

import '../data/events.dart';
import '../data/items.dart';
import '../services/discovered_events.dart';
import '../services/player_coins_service.dart';
import '../services/unlocked_items_service.dart';

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
    ]);
    if (mounted) {
      _coinsController.text = PlayerCoinsService.instance.balance.toString();
      setState(() => _loading = false);
    }
  }

  void _refresh() => setState(() {});

  Future<void> _unlockAllEvents() async {
    final ids = [...allEvents, ...allBossCards].map((e) => e.id).toList();
    await DiscoveredEventsService.instance.unlockAll(ids);
    _showSnack('✅ Все события открыты (${ids.length})');
    _refresh();
  }

  Future<void> _lockAllEvents() async {
    await DiscoveredEventsService.instance.resetAll();
    _showSnack('🔒 Все события закрыты');
    _refresh();
  }

  Future<void> _unlockAllItems() async {
    final ids = allItemCards.map((i) => i.id).toList();
    await UnlockedItemsService.instance.unlockAll(ids);
    _showSnack('✅ Все карточки предметов открыты (${ids.length})');
    _refresh();
  }

  Future<void> _lockAllItems() async {
    await UnlockedItemsService.instance.reset();
    _showSnack('🔒 Все карточки предметов закрыты');
    _refresh();
  }

  void _addCoins(int amount) {
    PlayerCoinsService.instance.applyDelta(amount);
    _coinsController.text = PlayerCoinsService.instance.balance.toString();
    _showSnack('🪙 +$amount монет');
    _refresh();
  }

  void _removeCoins(int amount) {
    PlayerCoinsService.instance.applyDelta(-amount);
    _coinsController.text = PlayerCoinsService.instance.balance.toString();
    _showSnack('🪙 -$amount монет');
    _refresh();
  }

  void _setCoins() {
    final value = int.tryParse(_coinsController.text);
    if (value == null || value < 0) {
      _showSnack('⚠️ Введите корректное число');
      return;
    }
    PlayerCoinsService.instance.restoreBalance(value);
    _showSnack('🪙 Баланс установлен: $value');
    _refresh();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A40),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('Настройки'),
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
                        title: 'Карточки событий',
                        subtitle:
                            'Открыто: ${DiscoveredEventsService.instance.count} / ${allEvents.length + allBossCards.length}',
                        color: const Color(0xFFE94560),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DebugButton(
                              label: 'Открыть все',
                              icon: Icons.lock_open,
                              color: const Color(0xFF4CAF50),
                              onPressed: _unlockAllEvents,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DebugButton(
                              label: 'Закрыть все',
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
                        title: 'Карточки предметов (лутбоксы)',
                        subtitle:
                            'Открыто: ${UnlockedItemsService.instance.count} / ${allItemCards.length}',
                        color: const Color(0xFF9C27B0),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DebugButton(
                              label: 'Открыть все',
                              icon: Icons.lock_open,
                              color: const Color(0xFF4CAF50),
                              onPressed: _unlockAllItems,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DebugButton(
                              label: 'Закрыть все',
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
                        title: 'Монеты',
                        subtitle: 'Баланс: ${PlayerCoinsService.instance.balance} 🪙',
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
                            label: 'Обнулить',
                            onPressed: () {
                              PlayerCoinsService.instance.restoreBalance(0);
                              _coinsController.text = '0';
                              _showSnack('🪙 Монеты обнулены');
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
                                labelText: 'Установить баланс',
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
                            child: const Text(
                              'Применить',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
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
