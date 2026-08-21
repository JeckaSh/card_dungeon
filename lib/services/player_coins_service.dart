import 'package:shared_preferences/shared_preferences.dart';

/// Хранит общий баланс монет игрока (сохраняется между сессиями).
class PlayerCoinsService {
  PlayerCoinsService._();

  static final PlayerCoinsService instance = PlayerCoinsService._();

  static const _storageKey = 'player_coins';

  int _balance = 0;
  bool _loaded = false;

  /// Общий баланс монет (инвентарь).
  int get balance => _balance;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_storageKey) ?? 0;
    _loaded = true;
  }

  /// Применяет изменение баланса синхронно в памяти,
  /// затем асинхронно сохраняет на диск.
  void applyDelta(int amount) {
    _balance = (_balance + amount).clamp(0, 999999);
    _persistAsync();
  }

  /// Принудительно устанавливает баланс (для отката при поражении/выходе).
  void restoreBalance(int value) {
    _balance = value.clamp(0, 999999);
    _persistAsync();
  }

  void _persistAsync() {
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_storageKey, _balance),
    );
  }
}
