import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';

enum AppLanguage {
  english('en'),
  japanese('ja');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    return switch (code) {
      'ja' => AppLanguage.japanese,
      _ => AppLanguage.english,
    };
  }

  static AppLanguage fromCountryCode(String? countryCode) {
    return switch (countryCode?.toUpperCase()) {
      'JP' => AppLanguage.japanese,
      _ => AppLanguage.english,
    };
  }
}

enum SaveFormat { csv, tsv, excel }

enum TransferMethod { email, server }

@immutable
final class ScannerSettings {
  const ScannerSettings({
    this.scanSound = true,
    this.autoScan = false,
    this.duplicateProtection = true,
    this.cameraResetAfterDetection = true,
    this.fastScanMode = true,
  });

  final bool scanSound;
  final bool autoScan;
  final bool duplicateProtection;
  final bool cameraResetAfterDetection;
  final bool fastScanMode;

  ScannerSettings copyWith({
    bool? scanSound,
    bool? autoScan,
    bool? duplicateProtection,
    bool? cameraResetAfterDetection,
    bool? fastScanMode,
  }) {
    return ScannerSettings(
      scanSound: scanSound ?? this.scanSound,
      autoScan: autoScan ?? this.autoScan,
      duplicateProtection: duplicateProtection ?? this.duplicateProtection,
      cameraResetAfterDetection:
          cameraResetAfterDetection ?? this.cameraResetAfterDetection,
      fastScanMode: fastScanMode ?? this.fastScanMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'scanSound': scanSound,
      'autoScan': autoScan,
      'duplicateProtection': duplicateProtection,
      'cameraResetAfterDetection': cameraResetAfterDetection,
      'fastScanMode': fastScanMode,
    };
  }

  factory ScannerSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return const ScannerSettings();
    }

    return ScannerSettings(
      scanSound: json['scanSound'] is bool ? json['scanSound']! as bool : true,
      autoScan: json['autoScan'] is bool ? json['autoScan']! as bool : false,
      duplicateProtection: json['duplicateProtection'] is bool
          ? json['duplicateProtection']! as bool
          : true,
      cameraResetAfterDetection: json['cameraResetAfterDetection'] is bool
          ? json['cameraResetAfterDetection']! as bool
          : true,
      fastScanMode: json['fastScanMode'] is bool
          ? json['fastScanMode']! as bool
          : true,
    );
  }
}

@immutable
final class TransferSettings {
  const TransferSettings({
    this.saveFormat = SaveFormat.csv,
    this.transferMethod = TransferMethod.email,
    this.emailAddress = '',
    this.uploadUrl = '',
    this.transferDestination = '',
  });

  final SaveFormat saveFormat;
  final TransferMethod transferMethod;
  final String emailAddress;
  final String uploadUrl;
  final String transferDestination;

  TransferSettings copyWith({
    SaveFormat? saveFormat,
    TransferMethod? transferMethod,
    String? emailAddress,
    String? uploadUrl,
    String? transferDestination,
  }) {
    return TransferSettings(
      saveFormat: saveFormat ?? this.saveFormat,
      transferMethod: transferMethod ?? this.transferMethod,
      emailAddress: emailAddress ?? this.emailAddress,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      transferDestination: transferDestination ?? this.transferDestination,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'saveFormat': saveFormat.name,
      'transferMethod': transferMethod.name,
      'emailAddress': emailAddress,
      'uploadUrl': uploadUrl,
      'transferDestination': transferDestination,
    };
  }

  factory TransferSettings.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return const TransferSettings();
    }

    return TransferSettings(
      saveFormat: SaveFormat.values.byNameOrDefault(
        json['saveFormat'],
        SaveFormat.csv,
      ),
      transferMethod: TransferMethod.values.byNameOrDefault(
        json['transferMethod'],
        TransferMethod.email,
      ),
      emailAddress: json['emailAddress'] is String
          ? json['emailAddress']! as String
          : '',
      uploadUrl: json['uploadUrl'] is String
          ? json['uploadUrl']! as String
          : '',
      transferDestination: json['transferDestination'] is String
          ? json['transferDestination']! as String
          : '',
    );
  }
}

@immutable
final class AppSettings {
  const AppSettings({
    this.scanner = const ScannerSettings(),
    this.transfer = const TransferSettings(),
  });

  final ScannerSettings scanner;
  final TransferSettings transfer;

  AppLanguage get language => AppLanguage.japanese;

  AppSettings copyWith({ScannerSettings? scanner, TransferSettings? transfer}) {
    return AppSettings(
      scanner: scanner ?? this.scanner,
      transfer: transfer ?? this.transfer,
    );
  }

  Map<String, Object?> toJson() {
    return {'scanner': scanner.toJson(), 'transfer': transfer.toJson()};
  }

  factory AppSettings.defaults() => const AppSettings();

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      scanner: ScannerSettings.fromJson(json['scanner']),
      transfer: TransferSettings.fromJson(json['transfer']),
    );
  }
}

final class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    required AppSettingsRepository repository,
    required AppSettings initialSettings,
  }) : _repository = repository,
       _settings = initialSettings;

  final AppSettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Locale get locale => const Locale('ja');

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _repository.save(settings);
  }

  Future<void> setScanner(ScannerSettings scanner) {
    return update(_settings.copyWith(scanner: scanner));
  }

  Future<void> setTransfer(TransferSettings transfer) {
    return update(_settings.copyWith(transfer: transfer));
  }
}

final class AppSettingsRepository {
  const AppSettingsRepository(this._storage);

  static const String storageKey = 'app_settings_v1';

  final LocalStorage _storage;

  Future<AppSettings> load() async {
    final fallback = AppSettings.defaults();

    final raw = await _storage.readString(storageKey);
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        await _storage.remove(storageKey);
        return fallback;
      }

      final settings = AppSettings.fromJson(decoded);
      if (decoded.containsKey('themeMode') ||
          decoded.containsKey('language') ||
          decoded.containsKey('hasSelectedLanguage')) {
        await save(settings);
      }

      return settings;
    } catch (_) {
      await _storage.remove(storageKey);
      return fallback;
    }
  }

  Future<void> save(AppSettings settings) async {
    await _storage.writeString(storageKey, jsonEncode(settings.toJson()));
  }
}

extension _EnumDecode<T extends Enum> on Iterable<T> {
  T byNameOrDefault(Object? value, T fallback) {
    if (value is! String) {
      return fallback;
    }

    for (final item in this) {
      if (item.name == value) {
        return item;
      }
    }

    return fallback;
  }
}
