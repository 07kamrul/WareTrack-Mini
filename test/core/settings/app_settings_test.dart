import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';

void main() {
  group('AppSettingsRepository', () {
    test('defaults to English without saving', () async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);

      final settings = await repository.load();

      expect(settings.language, AppLanguage.english);
      expect(storage.values[AppSettingsRepository.storageKey], isNull);
    });

    test('removes legacy theme preferences but keeps the saved language', () async {
      final storage = _FakeLocalStorage({
        AppSettingsRepository.storageKey: jsonEncode({
          'language': 'bn',
          'hasSelectedLanguage': true,
          'themeMode': 'dark',
        }),
      });
      final repository = AppSettingsRepository(storage);

      final settings = await repository.load();

      expect(settings.language, AppLanguage.bangla);
      expect(_savedSettings(storage), isNot(contains('themeMode')));
      expect(_savedSettings(storage), isNot(contains('hasSelectedLanguage')));
      expect(_savedSettings(storage)['language'], 'bn');
    });

    test('controller locale defaults to English', () async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);
      final settings = await repository.load();
      final controller = AppSettingsController(
        repository: repository,
        initialSettings: settings,
      );

      expect(controller.locale, const Locale('en'));
    });

    test('controller locale switches to Bangla after setLanguage', () async {
      final storage = _FakeLocalStorage();
      final repository = AppSettingsRepository(storage);
      final settings = await repository.load();
      final controller = AppSettingsController(
        repository: repository,
        initialSettings: settings,
      );

      await controller.setLanguage(AppLanguage.bangla);

      expect(controller.locale, const Locale('bn'));
      expect(_savedSettings(storage)['language'], 'bn');
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
