import 'package:waretrack_mini/core/api_services/send_mail_service.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';
import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';

final class CompletedWorkService {
  const CompletedWorkService({
    required AppDatabase database,
    required ExportFileService exportFileService,
    required SendMailService sendMailService,
    required AppSettingsController settingsController,
    required LocalStorage localStorage,
  }) : _database = database,
       _exportFileService = exportFileService,
       _sendMailService = sendMailService,
       _settingsController = settingsController,
       _localStorage = localStorage;

  final AppDatabase _database;
  final ExportFileService _exportFileService;
  final SendMailService _sendMailService;
  final AppSettingsController _settingsController;
  final LocalStorage _localStorage;

  String get emailAddress =>
      _settingsController.settings.transfer.emailAddress.trim();

  SaveFormat get _selectedSendFormat {
    return _settingsController.settings.transfer.saveFormat == SaveFormat.excel
        ? SaveFormat.excel
        : SaveFormat.csv;
  }

  Future<List<CompletedOrderRecord>> loadCompletedWorks(
    InspectionWorkType menuType,
  ) {
    return _database.readCompletedWorks(workType: menuType);
  }

  Future<List<CompletedOrderRecord>> loadAllCompletedWorks() async {
    final works = <CompletedOrderRecord>[];
    for (final workType in InspectionWorkType.values) {
      works.addAll(await loadCompletedWorks(workType));
    }
    works.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return works;
  }

  Future<List<CompletedItemRecord>> getCompletedWorkDetails(
    InspectionWorkType menuType,
    String slipNumber,
  ) {
    return _database.readCompletedWorkDetails(slipNumber, workType: menuType);
  }

  Future<void> deleteCompletedWork(
    InspectionWorkType menuType,
    String slipNumber,
  ) {
    return _database.deleteCompletedWork(slipNumber, workType: menuType);
  }

  /// Persists the "sent" status for a completed work after a successful send.
  Future<void> markWorkSent(InspectionWorkType menuType, String slipNumber) {
    return _database.markCompletedWorkSent(slipNumber, workType: menuType);
  }

  Future<ExportFileResult> exportCompletedWork({
    required InspectionWorkType menuType,
    required String slipNumber,
    required DateTime completedAt,
  }) async {
    final details = await _withUserIdFallback(
      await getCompletedWorkDetails(menuType, slipNumber),
    );

    return _exportFileService.generateExportFile(
      menuName: menuType.menuName,
      slipNumber: slipNumber,
      format: _selectedSendFormat.name,
      items: _exportItems(details),
      completedAt: completedAt,
      language: _settingsController.settings.language,
      firstColumnLabel: _usesShelfStorage(menuType) ? '棚番号' : null,
      productCodeColumnLabel: _usesShelfStorage(menuType) ? 'バーコード/QR' : null,
      fileNameFromSlip: _usesShelfStorage(menuType),
    );
  }

  Future<void> validateAuthentication() {
    return _sendMailService.validateAuthentication();
  }

  Future<void> send(ExportFileResult result) {
    return _sendMailService.send(
      email: emailAddress,
      selectedFormat: _selectedSendFormat.name,
      exportResult: result,
    );
  }

  Future<List<CompletedItemRecord>> _withUserIdFallback(
    List<CompletedItemRecord> details,
  ) async {
    if (details.every((detail) => detail.userId.trim().isNotEmpty)) {
      return details;
    }

    final fallbackUserId =
        (await _localStorage.readString(kCode))?.trim() ?? '';
    if (fallbackUserId.isEmpty) {
      return details;
    }

    return [
      for (final detail in details)
        detail.userId.trim().isEmpty
            ? detail.copyWith(userId: fallbackUserId)
            : detail,
    ];
  }

  static List<ExportInspectionItem> _exportItems(
    List<CompletedItemRecord> details,
  ) {
    return [
      for (final detail in details)
        ExportInspectionItem(
          slipNumber: detail.slipNumber,
          productCode: detail.code,
          quantity: detail.quantity,
          dateTime: ExportFileService.formatExportDateTime(detail.createdAt),
          userId: detail.userId,
        ),
    ];
  }

  static bool _usesShelfStorage(InspectionWorkType menuType) {
    return menuType == InspectionWorkType.stocking ||
        menuType == InspectionWorkType.inventory;
  }
}
