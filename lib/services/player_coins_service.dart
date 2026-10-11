import 'package:shared_preferences/shared_preferences.dart';

/// Сервис хранения и сохранения постоянного баланса монет игрока.
///
/// Монеты зарабатываются во время успешных или завершённых забегов в подземелье
/// и расходуются на:
/// * Открытие новых карт в Магазине ([ShopScreen]);
/// * Постоянную прокачку характеристик персонажа в Инвентаре ([InventoryScreen]).
///
/// Значение баланса сохраняется между запусками через [SharedPreferences].
class PlayerCoinsService {
  PlayerCoinsService._();

  /// Глобальный синглтон сервиса монет
  static final PlayerCoinsService instance = PlayerCoinsService._();

  static const _storageKey = 'player_coins';
  static const _tutorialRewardKey = 'tutorial_reward_granted';

  int _balance = 0;
  bool _loaded = false;

  /// Общий баланс монет игрока
  int get balance => _balance;

  /// Загружает сохранённый баланс из локального хранилища
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

  /// Возвращает true, если награда за первое прохождение обучения уже была выдана.
  Future<bool> isTutorialRewardGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialRewardKey) ?? false;
  }

  /// Сохраняет флаг о том, что награда за обучение уже была выдана.
  Future<void> markTutorialRewardGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialRewardKey, true);
  }
}
