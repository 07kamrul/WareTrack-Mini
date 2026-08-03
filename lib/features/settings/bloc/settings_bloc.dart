import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_state.dart';

final class SettingsBloc extends Cubit<SettingsState> {
  SettingsBloc({required AppSettingsController settingsController})
    : _settingsController = settingsController,
      super(SettingsState(settings: settingsController.settings)) {
    _settingsController.addListener(_syncSettings);
  }

  final AppSettingsController _settingsController;

  AppSettings get _settings => _settingsController.settings;

  Future<void> setScanSound(bool value) {
    return _settingsController.setScanner(
      _settings.scanner.copyWith(scanSound: value),
    );
  }

  Future<void> setAutoScan(bool value) {
    return _settingsController.setScanner(
      _settings.scanner.copyWith(autoScan: value),
    );
  }

  Future<void> setDuplicateProtection(bool value) {
    return _settingsController.setScanner(
      _settings.scanner.copyWith(duplicateProtection: value),
    );
  }

  Future<void> setCameraResetAfterDetection(bool value) {
    return _settingsController.setScanner(
      _settings.scanner.copyWith(cameraResetAfterDetection: value),
    );
  }

  Future<void> setFastScanMode(bool value) {
    return _settingsController.setScanner(
      _settings.scanner.copyWith(fastScanMode: value),
    );
  }

  Future<void> setSaveFormat(SaveFormat saveFormat) {
    return _settingsController.setTransfer(
      _settings.transfer.copyWith(saveFormat: saveFormat),
    );
  }

  Future<void> setTransferMethod(TransferMethod transferMethod) {
    return _settingsController.setTransfer(
      _settings.transfer.copyWith(transferMethod: transferMethod),
    );
  }

  Future<void> setEmailAddress(String emailAddress) {
    return _settingsController.setTransfer(
      _settings.transfer.copyWith(emailAddress: emailAddress),
    );
  }

  Future<void> setUploadUrl(String uploadUrl) {
    return _settingsController.setTransfer(
      _settings.transfer.copyWith(uploadUrl: uploadUrl),
    );
  }

  Future<void> setTransferDestination(String transferDestination) {
    return _settingsController.setTransfer(
      _settings.transfer.copyWith(transferDestination: transferDestination),
    );
  }

  void _syncSettings() {
    if (!isClosed) {
      emit(state.copyWith(settings: _settingsController.settings));
    }
  }

  @override
  Future<void> close() {
    _settingsController.removeListener(_syncSettings);
    return super.close();
  }
}
