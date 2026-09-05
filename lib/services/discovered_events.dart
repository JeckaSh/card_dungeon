import 'package:shared_preferences/shared_preferences.dart';

class DiscoveredEventsService {
  DiscoveredEventsService._();

  static final DiscoveredEventsService instance = DiscoveredEventsService._();

  static const _storageKey = 'discovered_event_ids';

  Set<String> _discovered = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _discovered = (prefs.getStringList(_storageKey) ?? []).toSet();
    _loaded = true;
  }

  Future<void> markDiscovered(String eventId) async {
    await load();
    if (!_discovered.add(eventId)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _discovered.toList());
  }

  Future<void> unlockAll(List<String> eventIds) async {
    await load();
    _discovered.addAll(eventIds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _discovered.toList());
  }

  Future<void> resetAll() async {
    _discovered.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  bool isDiscovered(String eventId) => _discovered.contains(eventId);

  int get count => _discovered.length;
}
