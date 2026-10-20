import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис синхронизации и валидации мирового времени (World Time / Network Time).
///
/// Защищает от читов и эксплойтов с перемоткой времени вперёд или назад в настройках телефона:
/// 1. При запуске и по запросу получает точное мировое время по протоколу HTTP (заголовки Date
///    высоконадежных серверов Google, Cloudflare или Time API).
/// 2. Во время работы приложения использует монотонный таймер [Stopwatch] (аппаратные тики CPU),
///    который полностью защищён от любых изменений системного времени пользователем на устройстве.
/// 3. Фиксирует максимальную известную мировую дату ([_storageKeyLastKnownWorldTimeMs]) и определяет
///    попытки отката системных часов назад (Time Rollback).
/// 4. Обновление ежедневных наград и заданий привязано к Московскому времени (UTC+3, MSK)
///    на основе подтверждённого мирового времени.
class WorldTimeService extends ChangeNotifier {
  WorldTimeService._();

  /// Глобальный синглтон сервиса
  static final WorldTimeService instance = WorldTimeService._();

  static const _storageKeyLastKnownWorldTimeMs = 'world_time_last_known_ms';

  DateTime? _lastSyncedServerUtc;
  final Stopwatch _stopwatch = Stopwatch();
  bool _isSynchronized = false;
  int? _lastKnownWorldTimeMs;
  bool _isRollbackDetected = false;
  bool _isSyncing = false;

  // Поля для тестирования
  DateTime? _mockTimeUtc;
  bool _forceOfflineForTest = false;
  bool _forceRollbackForTest = false;

  bool get _isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

  bool get isSynchronized {
    if (_forceOfflineForTest) return false;
    return _mockTimeUtc != null || _isSynchronized || _isTestEnvironment;
  }

  bool get isRollbackDetected => _forceRollbackForTest || _isRollbackDetected;
  bool get isSyncing => _isSyncing;

  /// Инициализирует сервис, считывает сохранённую отметку времени и выполняет фоновую синхронизацию.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastKnownWorldTimeMs = prefs.getInt(_storageKeyLastKnownWorldTimeMs);
    _checkRollbackAgainstLocalTime();
    await sync();
  }

  /// Синхронизирует мировое время с проверенными публичными серверами.
  ///
  /// Возвращает `true`, если время успешно подтверждено.
  Future<bool> sync({Duration timeout = const Duration(seconds: 4)}) async {
    if (_forceOfflineForTest) {
      _isSynchronized = false;
      notifyListeners();
      return false;
    }

    if (_mockTimeUtc != null) {
      _isSynchronized = true;
      _isRollbackDetected = false;
      notifyListeners();
      return true;
    }

    if (_isTestEnvironment) {
      _isSynchronized = true;
      _isRollbackDetected = false;
      notifyListeners();
      return true;
    }

    _isSyncing = true;
    notifyListeners();

    DateTime? serverUtc;

    try {
      // 1. Быстрый HEAD-запрос к Google (чтение HTTP заголовка Date)
      serverUtc = await _fetchFromHttpHead('https://www.google.com', timeout);

      // 2. Fallback: HEAD-запрос к Cloudflare
      serverUtc ??= await _fetchFromHttpHead('https://cloudflare.com', timeout);

      // 3. Fallback: TimeAPI JSON
      serverUtc ??= await _fetchFromJsonApi(
        'https://timeapi.io/api/time/current/zone?timeZone=UTC',
        'dateTime',
        timeout,
      );

      // 4. Fallback: WorldTimeAPI JSON
      serverUtc ??= await _fetchFromJsonApi(
        'https://worldtimeapi.org/api/timezone/Etc/UTC',
        'utc_datetime',
        timeout,
      );
    } catch (_) {
      serverUtc = null;
    }

    _isSyncing = false;

    if (serverUtc != null) {
      _lastSyncedServerUtc = serverUtc;
      _stopwatch.reset();
      _stopwatch.start();
      _isSynchronized = true;
      _isRollbackDetected = false;

      await recordKnownWorldTime(serverUtc);
      notifyListeners();
      return true;
    } else {
      // Оффлайн или сетевая ошибка — проверяем на откат локального времени
      _checkRollbackAgainstLocalTime();
      notifyListeners();
      return false;
    }
  }

  /// Проверяет, не перевёл ли пользователь часы назад относительно последней известной отметки.
  void _checkRollbackAgainstLocalTime() {
    if (_lastKnownWorldTimeMs != null) {
      final localMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      // Допускаем небольшую погрешность в 2 минуты
      if (localMs < _lastKnownWorldTimeMs! - 120000) {
        _isRollbackDetected = true;
      } else {
        _isRollbackDetected = false;
      }
    }
  }

  /// Запоминает проверенную отметку мирового времени для предотвращения отката.
  Future<void> recordKnownWorldTime(DateTime utcTime) async {
    final ms = utcTime.millisecondsSinceEpoch;
    if (_lastKnownWorldTimeMs == null || ms > _lastKnownWorldTimeMs!) {
      _lastKnownWorldTimeMs = ms;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKeyLastKnownWorldTimeMs, ms);
    }
  }

  /// Текущее мировое время в формате UTC.
  ///
  /// * Если есть синхронизация — время рассчитывается на базе полученного от сервера значения
  ///   и монотонного счётчика [Stopwatch], что исключает любое вмешательство через системные часы.
  /// * Если синхронизации нет — используется локальное время с защитой от отката назад.
  DateTime get nowUtc {
    if (_mockTimeUtc != null) {
      return _mockTimeUtc!;
    }
    if (_isSynchronized && _lastSyncedServerUtc != null) {
      return _lastSyncedServerUtc!.add(_stopwatch.elapsed);
    }
    final localUtc = DateTime.now().toUtc();
    if (_lastKnownWorldTimeMs != null &&
        localUtc.millisecondsSinceEpoch < _lastKnownWorldTimeMs!) {
      // Защита от перемотки назад: время не может стать меньше ранее зафиксированного
      return DateTime.fromMillisecondsSinceEpoch(_lastKnownWorldTimeMs!, isUtc: true);
    }
    return localUtc;
  }

  /// Текущее время по Московскому часовому поясу (UTC+3, MSK).
  DateTime get nowMsk {
    return nowUtc.add(const Duration(hours: 3));
  }

  /// Ключ сегодняшнего дня по МСК в формате 'YYYY-MM-DD'.
  String get todayMskKey {
    final msk = nowMsk;
    final y = msk.year.toString().padLeft(4, '0');
    final m = msk.month.toString().padLeft(2, '0');
    final d = msk.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Дата сегодняшнего дня по МСК (00:00:00 UTC) для вычисления разницы в днях.
  DateTime get todayMskDate {
    final msk = nowMsk;
    return DateTime.utc(msk.year, msk.month, msk.day);
  }

  /// Время до полуночи по Московскому времени (UTC+3).
  Duration get timeUntilNextMskMidnight {
    final msk = nowMsk;
    final nextMidnight = DateTime.utc(msk.year, msk.month, msk.day + 1);
    final current = DateTime.utc(
      msk.year,
      msk.month,
      msk.day,
      msk.hour,
      msk.minute,
      msk.second,
    );
    final diff = nextMidnight.difference(current);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Дата понедельника текущей недели по МСК (00:00:00 UTC).
  DateTime get currentWeekMondayMsk {
    final msk = nowMsk;
    // DateTime.weekday: 1 (Mon) .. 7 (Sun)
    return DateTime.utc(msk.year, msk.month, msk.day - (msk.weekday - 1));
  }

  /// Ключ текущей недели по МСК в формате 'YYYY-W-MM-DD' (понедельник недели).
  String get thisWeekMskKey {
    final mon = currentWeekMondayMsk;
    final y = mon.year.toString().padLeft(4, '0');
    final m = mon.month.toString().padLeft(2, '0');
    final d = mon.day.toString().padLeft(2, '0');
    return '$y-W-$m-$d';
  }

  /// Время до смены недели (понедельник 00:00:00 по МСК).
  Duration get timeUntilNextMskWeek {
    final msk = nowMsk;
    // Если понедельник (weekday=1), до следующего понедельника 7 дней.
    // Если воскресенье (weekday=7), до следующего понедельника 1 день.
    final daysUntilNextMonday = 8 - msk.weekday;
    final nextMonday = DateTime.utc(msk.year, msk.month, msk.day + daysUntilNextMonday);
    final current = DateTime.utc(
      msk.year,
      msk.month,
      msk.day,
      msk.hour,
      msk.minute,
      msk.second,
    );
    final diff = nextMonday.difference(current);
    return diff.isNegative ? Duration.zero : diff;
  }

  // ── Вспомогательные сетевые методы ──────────────────────────────────────────

  Future<DateTime?> _fetchFromHttpHead(String url, Duration timeout) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;
      final uri = Uri.parse(url);
      final request = await client.headUrl(uri);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader != null && dateHeader.isNotEmpty) {
        return HttpDate.parse(dateHeader).toUtc();
      }
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  Future<DateTime?> _fetchFromJsonApi(
    String url,
    String fieldName,
    Duration timeout,
  ) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(timeout);
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final raw = json[fieldName] as String?;
        if (raw != null) {
          return DateTime.parse(raw).toUtc();
        }
      }
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  // ── Методы для тестирования и отладки ────────────────────────────────────────

  /// Установить мок-время для юнит-тестов
  @visibleForTesting
  void setMockTime(DateTime? time) {
    _mockTimeUtc = time?.toUtc();
    if (time != null) {
      _isSynchronized = true;
      _isRollbackDetected = false;
      _lastKnownWorldTimeMs = time.toUtc().millisecondsSinceEpoch;
    }
    notifyListeners();
  }

  /// Имитировать оффлайн для тестов
  @visibleForTesting
  void setOfflineForTest(bool offline) {
    _forceOfflineForTest = offline;
    if (offline) {
      _isSynchronized = false;
    }
    notifyListeners();
  }

  /// Имитировать обнаружение отката времени для тестов
  @visibleForTesting
  void setRollbackForTest(bool rollback) {
    _forceRollbackForTest = rollback;
    notifyListeners();
  }

  /// Сбросить состояние сервиса в тестах
  @visibleForTesting
  void resetForTest() {
    _mockTimeUtc = null;
    _lastSyncedServerUtc = null;
    _stopwatch.reset();
    _isSynchronized = true; // в тестах по умолчанию синхронизировано
    _lastKnownWorldTimeMs = null;
    _isRollbackDetected = false;
    _isSyncing = false;
    _forceOfflineForTest = false;
    _forceRollbackForTest = false;
  }
}
