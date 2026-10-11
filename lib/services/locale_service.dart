import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис хранения выбранного языка интерфейса.
///
/// Язык сохраняется между сессиями через [SharedPreferences].
/// Реагируйте на смену языка через [localeNotifier].
class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const _storageKey = 'app_locale';

  /// Уведомитель о текущей локали — подписывайтесь для реактивного
  /// обновления UI (например, через [ValueListenableBuilder]).
  final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ru'));

  Locale get currentLocale => localeNotifier.value;

  bool get isRussian => currentLocale.languageCode == 'ru';

  /// Загружает сохранённый язык из локального хранилища.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey) ?? 'ru';
    localeNotifier.value = Locale(code);
  }

  /// Устанавливает новый язык и сохраняет его.
  Future<void> setLocale(Locale locale) async {
    if (localeNotifier.value == locale) return;
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
  }
}
