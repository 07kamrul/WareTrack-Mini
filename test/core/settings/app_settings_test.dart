import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';

void main() {
  group('AppSettingsRepository', () {
    test('defaults to Japanese without saving', () async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);

      final settings = await repository.load();

      expect(settings.language, AppLanguage.japanese);
      expect(storage.values[AppSettingsRepository.storageKey], isNull);
    });

    test('removes legacy language and theme preferences', () async {
      final storage = _FakeLocalStorage({
        AppSettingsRepository.storageKey: jsonEncode({
          'language': 'en',
          'hasSelectedLanguage': true,
          'themeMode': 'dark',
        }),
      });
      final repository = AppSettingsRepository(storage);

      final settings = await repository.load();

      expect(settings.language, AppLanguage.japanese);
      expect(_savedSettings(storage), isNot(contains('themeMode')));
      expect(_savedSettings(storage), isNot(contains('language')));
      expect(_savedSettings(storage), isNot(contains('hasSelectedLanguage')));
    });

    test('controller locale is always Japanese', () async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);
      final settings = await repository.load();
      final controller = AppSettingsController(
        repository: repository,
        initialSettings: settings,
      );

      expect(controller.locale, const Locale('ja'));
    });
  });
}

Map<String, Object?> _savedSettings(_FakeLocalStorage storage) {
  final raw = storage.values[AppSettingsRepository.storageKey];
  return jsonDecode(raw!) as Map<String, Object?>;
}

final class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage([Map<String, String>? initialValues])
    : values = {...?initialValues};

  final Map<String, String> values;

  @override
  Future<bool?> readBool(String key) async {
    final value = values[key];
    return value == null ? null : bool.tryParse(value);
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value.toString();
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
