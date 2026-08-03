import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

final class ExportInspectionItem {
  const ExportInspectionItem({
    required this.slipNumber,
    required this.productCode,
    required this.quantity,
    required this.dateTime,
    required this.userId,
  });

  final String slipNumber;
  final String productCode;
  final int quantity;
  final String dateTime;
  final String userId;
}

final class ExportFileResult {
  const ExportFileResult({
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    this.contentUri,
  });

  final String fileName;
  final String filePath;
  final String mimeType;
  final String? contentUri;
}

final class ExportFileService {
  const ExportFileService();

  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.anshintech.waretrackmini/downloads',
  );

  Future<ExportFileResult> exportCompletedWork({
    required String menuName,
    required String slipNumber,
    required String format,
    required List<ExportInspectionItem> items,
    DateTime? completedAt,
    AppLanguage language = AppLanguage.english,
    String? firstColumnLabel,
    String? productCodeColumnLabel,
    bool fileNameFromSlip = false,
    String? fileNamePrefix,
  }) async {
    final saveFormat = _saveFormat(format);
    final normalizedSlip = slipNumber.trim();
    final fileName = buildFileName(
      fileNamePrefix: fileNamePrefix ?? menuName,
      slipNumber: normalizedSlip,
      completedAt: completedAt ?? DateTime.now(),
      saveFormat: saveFormat,
      fileNameFromSlip: fileNameFromSlip,
    );
    final mimeType = _mimeType(saveFormat);
    final bytes = switch (saveFormat) {
      SaveFormat.excel => buildWorkbookBytes(
        menuName: menuName,
        slipNumber: normalizedSlip,
        items: items,
        language: language,
        fileName: fileName,
        firstColumnLabel: firstColumnLabel,
        productCodeColumnLabel: productCodeColumnLabel,
      ),
      SaveFormat.csv || SaveFormat.tsv => buildDelimitedBytes(
        items: items,
        language: language,
        saveFormat: saveFormat,
        firstColumnLabel: firstColumnLabel,
        productCodeColumnLabel: productCodeColumnLabel,
      ),
    };

    if (!kIsWeb && Platform.isAndroid) {
      final result = await _downloadsChannel.invokeMapMethod<String, String>(
        'saveExcelToDownloads',
        <String, Object>{
          'fileName': fileName,
          'bytes': Uint8List.fromList(bytes),
          'mimeType': mimeType,
        },
      );
      final filePath = result?['filePath'];
      if (filePath == null || filePath.isEmpty) {
        throw const FileSystemException('Unable to save export file.');
      }
      return ExportFileResult(
        fileName: fileName,
        filePath: filePath,
        mimeType: mimeType,
        contentUri: result?['contentUri'],
      );
    }

    final directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return ExportFileResult(
      fileName: fileName,
      filePath: file.path,
      mimeType: mimeType,
    );
  }

  Future<ExportFileResult> generateExportFile({
    required String menuName,
    required String slipNumber,
    required String format,
    required List<ExportInspectionItem> items,
    DateTime? completedAt,
    AppLanguage language = AppLanguage.english,
    String? firstColumnLabel,
    String? productCodeColumnLabel,
    bool fileNameFromSlip = false,
    String? fileNamePrefix,
  }) {
    return exportCompletedWork(
      menuName: menuName,
      slipNumber: slipNumber,
      format: format,
      items: items,
      completedAt: completedAt,
      language: language,
      firstColumnLabel: firstColumnLabel,
      productCodeColumnLabel: productCodeColumnLabel,
      fileNameFromSlip: fileNameFromSlip,
      fileNamePrefix: fileNamePrefix,
    );
  }

  @visibleForTesting
  List<int> buildDelimitedBytes({
    required List<ExportInspectionItem> items,
    required AppLanguage language,
    required SaveFormat saveFormat,
    String? firstColumnLabel,
    String? productCodeColumnLabel,
  }) {
    final l10n = _localizations(language);
    final delimiter = saveFormat == SaveFormat.tsv ? '\t' : ',';
    final rows = <List<Object>>[
      <Object>[
        firstColumnLabel ?? l10n.excelOrderNo,
        productCodeColumnLabel ?? l10n.excelProductCode,
        l10n.quantity,
        l10n.excelDateTime,
        l10n.excelUserId,
      ],
      for (final item in items)
        <Object>[
          item.slipNumber,
          item.productCode,
          item.quantity,
          item.dateTime,
          item.userId,
        ],
    ];
    final content = rows
        .map(
          (row) => row
              .map((value) => _escapeDelimitedValue('$value', delimiter))
              .join(delimiter),
        )
        .join('\r\n');

    return utf8.encode('\uFEFF$content\r\n');
  }

  @visibleForTesting
  List<int> buildWorkbookBytes({
    required String menuName,
    required String slipNumber,
    required List<ExportInspectionItem> items,
    required AppLanguage language,
    String? fileName,
    String? firstColumnLabel,
    String? productCodeColumnLabel,
  }) {
    final l10n = _localizations(language);
    final excel = Excel.createExcel();
    final sheet = excel[l10n.inspectionList];
    excel.setDefaultSheet(sheet.sheetName);

    // Light-blue background, black bold, centered text for the header row.
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.lightBlue,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    // All data cells are centered both horizontally and vertically.
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // The sheet starts directly with the column header row. The file name is
    // intentionally not repeated inside the sheet — it is already the Excel
    // file name.
    final headers = <CellValue>[
      TextCellValue(firstColumnLabel ?? l10n.excelOrderNo),
      TextCellValue(productCodeColumnLabel ?? l10n.excelProductCode),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.excelDateTime),
      TextCellValue(l10n.excelUserId),
    ];
    for (var col = 0; col < headers.length; col++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        headers[col],
        cellStyle: headerStyle,
      );
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final rowIndex = i + 1;
      final values = <CellValue>[
        TextCellValue(item.slipNumber),
        TextCellValue(item.productCode),
        IntCellValue(item.quantity),
        TextCellValue(item.dateTime),
        TextCellValue(item.userId),
      ];
      for (var col = 0; col < values.length; col++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          values[col],
          cellStyle: dataStyle,
        );
      }
    }

    excel.delete('Sheet1');

    final bytes = excel.save(fileName: fileName ?? 'completed_work.xlsx');
    if (bytes == null) {
      throw const FileSystemException('Unable to create export file.');
    }
    return bytes;
  }

  Future<void> share(
    ExportFileResult result, {
    required String emailAddress,
    AppLanguage language = AppLanguage.english,
  }) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _downloadsChannel.invokeMethod<void>(
        'shareExcelFile',
        buildShareArguments(
          result,
          emailAddress: emailAddress,
          language: language,
        ),
      );
      return;
    }

    throw const FileSystemException('Sharing export files is not supported.');
  }

  @visibleForTesting
  Map<String, Object?> buildShareArguments(
    ExportFileResult result, {
    required String emailAddress,
    AppLanguage language = AppLanguage.english,
  }) {
    final normalizedEmailAddress = emailAddress.trim();
    if (normalizedEmailAddress.isEmpty) {
      throw const FormatException('Email address is missing.');
    }

    final l10n = _localizations(language);
    return <String, Object?>{
      'fileName': result.fileName,
      'filePath': result.filePath,
      'contentUri': result.contentUri,
      'emailAddress': normalizedEmailAddress,
      'mimeType': result.mimeType,
      'subject': l10n.emailSubjectExport,
      'body': l10n.emailBodyExport,
    };
  }

  Future<void> open(ExportFileResult result) async {
    if (!kIsWeb && Platform.isAndroid) {
      await _downloadsChannel
          .invokeMethod<void>('openExcelFile', <String, Object?>{
            'filePath': result.filePath,
            'contentUri': result.contentUri,
            'mimeType': result.mimeType,
          });
      return;
    }

    throw const FileSystemException('Opening export files is not supported.');
  }

  @visibleForTesting
  String buildFileName({
    required String fileNamePrefix,
    required String slipNumber,
    required DateTime completedAt,
    SaveFormat saveFormat = SaveFormat.excel,
    bool fileNameFromSlip = false,
  }) {
    final extension = _fileExtension(saveFormat);
    final timestamp = _formatSavedDate(completedAt);

    // Shelf-storage menus (Shelf Placement / Stocktaking) already encode the
    // menu name and timestamp inside the slip number, so the file name only
    // needs the prefix and the timestamp once: e.g. Shelf20260629135250.csv.
    if (fileNameFromSlip) {
      return '$fileNamePrefix$timestamp.$extension';
    }

    // Order-based menus (Receiving / Shipping):
    // e.g. Receiving_123456_20260629135250.csv
    final safeSlip = _sanitizeFileNamePart(slipNumber);
    return '${fileNamePrefix}_${safeSlip}_$timestamp.$extension';
  }

  static String formatExportDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}'
        '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static SaveFormat _saveFormat(String format) {
    return switch (format.trim().toLowerCase()) {
      'csv' => SaveFormat.csv,
      'tsv' => SaveFormat.tsv,
      _ => SaveFormat.excel,
    };
  }

  static String _fileExtension(SaveFormat saveFormat) {
    return switch (saveFormat) {
      SaveFormat.csv => 'csv',
      SaveFormat.tsv => 'tsv',
      SaveFormat.excel => 'xlsx',
    };
  }

  static String _mimeType(SaveFormat saveFormat) {
    return switch (saveFormat) {
      SaveFormat.csv => 'text/csv',
      SaveFormat.tsv => 'text/tab-separated-values',
      SaveFormat.excel =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
  }

  static String _escapeDelimitedValue(String value, String delimiter) {
    if (!value.contains(delimiter) &&
        !value.contains('"') &&
        !value.contains('\r') &&
        !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  static AppLocalizations _localizations(AppLanguage language) {
    return language.localizations;
  }

  static String _formatSavedDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}'
        '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}'
        '${local.second.toString().padLeft(2, '0')}';
  }

  static String _sanitizeFileNamePart(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'[\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^\.+'), '')
        .replaceAll(RegExp(r'[. ]+$'), '');

    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}
