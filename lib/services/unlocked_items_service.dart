import 'package:shared_preferences/shared_preferences.dart';

class UnlockedItemsService {
  UnlockedItemsService._();
  static final UnlockedItemsService instance = UnlockedItemsService._();

  static const _key = 'unlocked_item_ids';
  final Set<String> _unlockedIds = {};

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  int get count => _unlockedIds.length;

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
