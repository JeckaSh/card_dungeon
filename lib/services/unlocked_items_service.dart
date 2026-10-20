import 'package:shared_preferences/shared_preferences.dart';

import '../data/items.dart';
import '../models/item_card.dart';

/// Сервис учёта открытых игроком предметов (артефактов).
///
/// Предметы открываются через лутбоксы в Магазине ([ShopScreen]).
/// Только открытые карты:
/// 1. Могут выпадать герою в подземелье от торговцев, алтарей и тайников;
/// 2. Могут быть выданы на старте при наличии навыка стартовых карт ([PlayerStatsService.startingCardsCount]);
/// 3. Показываются с полным описанием и параметрами в инвентаре.
class UnlockedItemsService {
  UnlockedItemsService._();

  /// Глобальный синглтон сервиса открытых предметов
  static final UnlockedItemsService instance = UnlockedItemsService._();

  static const _key = 'unlocked_item_ids';
  final Set<String> _unlockedIds = {};

  /// Неизменяемый набор строковых идентификаторов открытых предметов
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  /// Проверяет, открыт ли предмет с указанным [id]
  bool isUnlocked(String id) => _unlockedIds.contains(id);

  /// Общее количество открытых предметов
  int get count => _unlockedIds.length;

  /// Проверяет, открыт ли хотя бы один предмет указанного уровня [level].
  /// Если [level] не указан, проверяет наличие любых открытых предметов.
  bool hasUnlockedForLevel([int? level]) {
    if (level == null) return _unlockedIds.isNotEmpty;
    return allItemCards.any(
      (item) => item.level == level && _unlockedIds.contains(item.id),
    );
  }

  /// Возвращает список всех открытых предметов указанного [level] (или всех, если null).
  List<ItemCard> getUnlockedItems([int? level]) {
    return allItemCards
        .where((item) =>
            _unlockedIds.contains(item.id) &&
            (level == null || item.level == level))
        .toList();
  }

  /// Загружает список открытых предметов из локального хранилища
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _unlockedIds
      ..clear()
      ..addAll(list);
  }

  Future<bool> unlock(String id) async {
    if (_unlockedIds.contains(id)) return false; // Уже открыта

    _unlockedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _unlockedIds.toList());
    return true; // Впервые открыта
  }

  Future<void> unlockAll(List<String> ids) async {
    _unlockedIds.addAll(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _unlockedIds.toList());
  }

  Future<void> reset() async {
    _unlockedIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
