import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис хранения и сохранения постоянного баланса валют игрока:
/// * Монеты ([balance], [coins])
/// * Серебряные ключи ([silverKeys])
/// * Золотые ключи ([goldKeys])
///
/// Значения балансов сохраняются между запусками через [SharedPreferences].
class PlayerCoinsService extends ChangeNotifier {
  PlayerCoinsService._();

  /// Глобальный синглтон сервиса монет
  static final PlayerCoinsService instance = PlayerCoinsService._();

  static const _storageKey = 'player_coins';
  static const _silverKeysStorageKey = 'player_silver_keys';
  static const _goldKeysStorageKey = 'player_gold_keys';
  static const _tutorialRewardKey = 'tutorial_reward_granted';

  int _balance = 0;
  int _silverKeys = 0;
  int _goldKeys = 0;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Общий баланс монет игрока
  int get balance => _balance;
  int get coins => _balance;

  /// Баланс серебряных ключей
  int get silverKeys => _silverKeys;

  /// Баланс золотых ключей
  int get goldKeys => _goldKeys;

  /// Загружает сохранённый баланс из локального хранилища
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_storageKey) ?? 0;
    _silverKeys = prefs.getInt(_silverKeysStorageKey) ?? 0;
    _goldKeys = prefs.getInt(_goldKeysStorageKey) ?? 0;
    _loaded = true;
    _safeNotifyListeners();
  }

  /// Применяет изменение баланса монет синхронно в памяти,
  /// затем асинхронно сохраняет на диск.
  void applyDelta(int amount) {
    _balance = (_balance + amount).clamp(0, 999999);
    _persistAsync();
    _safeNotifyListeners();
  }

  /// Принудительно устанавливает баланс монет (для отката при поражении/выходе).
  void restoreBalance(int value) {
    _balance = value.clamp(0, 999999);
    _persistAsync();
    _safeNotifyListeners();
  }

  /// Применяет изменение баланса серебряных ключей
  void applySilverKeysDelta(int amount) {
    _silverKeys = (_silverKeys + amount).clamp(0, 99999);
    _persistAsync();
    _safeNotifyListeners();
  }

  /// Устанавливает баланс серебряных ключей
  void setSilverKeys(int value) {
    _silverKeys = value.clamp(0, 99999);
    _persistAsync();
    _safeNotifyListeners();
  }

  /// Применяет изменение баланса золотых ключей
  void applyGoldKeysDelta(int amount) {
    _goldKeys = (_goldKeys + amount).clamp(0, 99999);
    _persistAsync();
    _safeNotifyListeners();
  }

  /// Устанавливает баланс золотых ключей
  void setGoldKeys(int value) {
    _goldKeys = value.clamp(0, 99999);
    _persistAsync();
    _safeNotifyListeners();
  }

  void _persistAsync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_storageKey, _balance);
      prefs.setInt(_silverKeysStorageKey, _silverKeys);
      prefs.setInt(_goldKeysStorageKey, _goldKeys);
    });
  }

  void _safeNotifyListeners() {
    final binding = WidgetsBinding.instance;
    if (binding.buildOwner?.debugBuilding == true ||
        binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
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

