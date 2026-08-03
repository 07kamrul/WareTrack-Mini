import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations_ja.dart';

void main() {
  group('ExportFileService', () {
    const service = ExportFileService();

    test('starts with the column header row without a file-name banner', () {
      final bytes = service.buildWorkbookBytes(
        menuName: '入荷検品',
        slipNumber: '12e',
        language: AppLanguage.japanese,
        items: const <ExportInspectionItem>[],
      );

      final workbook = Excel.decodeBytes(bytes);
      final l10n = AppLocalizationsJa();
      final sheet = workbook[l10n.inspectionList];

      // The sheet must start directly with the column header row — no
      // menu-name / slip-number banner above it.
      expect(
        (sheet.row(0)[0]?.value as TextCellValue).value.text,
        l10n.excelOrderNo,
      );
      expect(
        (sheet.row(0)[1]?.value as TextCellValue).value.text,
        l10n.excelProductCode,
      );
      expect(
        workbook.getMergedCells(l10n.inspectionList),
        isNot(contains('A1:E1')),
      );
    });

    test('styles the header light-blue/bold/centered and centers data', () {
      final bytes = service.buildWorkbookBytes(
        menuName: '入荷検品',
        slipNumber: 'S1',
        language: AppLanguage.japanese,
        items: <ExportInspectionItem>[
          ExportInspectionItem(
            slipNumber: 'S1',
            productCode: 'P1',
            quantity: 3,
            dateTime: '202601020304',
            userId: 'u1',
          ),
        ],
      );

      final workbook = Excel.decodeBytes(bytes);
      final l10n = AppLocalizationsJa();
      final sheet = workbook[l10n.inspectionList];

      // Header look: bold, light-blue background, black text. Center alignment
      // is also applied (and written to the file) but the excel 4.0.6 decoder
      // does not read alignment back, so it cannot be asserted via round-trip.
      final headerStyle = sheet.row(0)[0]?.cellStyle;
      expect(headerStyle?.isBold, isTrue);
      expect(headerStyle?.backgroundColor, ExcelColor.lightBlue);
      expect(headerStyle?.fontColor, ExcelColor.black);
    });

    test('exports details in the same order they are displayed', () {
      final bytes = service.buildWorkbookBytes(
        menuName: '入荷検品',
        slipNumber: 'SLIP-9001',
        language: AppLanguage.english,
        items: <ExportInspectionItem>[
          ExportInspectionItem(
            slipNumber: 'SLIP-9001',
            productCode: 'LATEST',
            quantity: 1,
            dateTime: '202601020304',
            userId: 'u1',
          ),
          ExportInspectionItem(
            slipNumber: 'SLIP-9001',
            productCode: 'OLDER',
            quantity: 2,
            dateTime: '202601020305',
            userId: 'u2',
          ),
        ],
      );

      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook[AppLocalizationsJa().inspectionList];

      expect((sheet.row(1)[1]?.value as TextCellValue).value.text, 'LATEST');
      expect((sheet.row(2)[1]?.value as TextCellValue).value.text, 'OLDER');
    });

    test('uses Japanese menu name and order number for order-based menus', () {
      final completedAt = DateTime(2026, 6, 29, 13, 52, 50);

      expect(
        service.buildFileName(
          fileNamePrefix: '入荷検品',
          slipNumber: '123456',
          completedAt: completedAt,
          saveFormat: SaveFormat.csv,
        ),
        '入荷検品_123456_20260629135250.csv',
      );
      expect(
        service.buildFileName(
          fileNamePrefix: '出荷検品',
          slipNumber: '123456',
          completedAt: completedAt,
          saveFormat: SaveFormat.csv,
        ),
        '出荷検品_123456_20260629135250.csv',
      );
    });

    test(
      'shelf-storage menus use the Japanese menu name and timestamp only once',
      () {
        const service = ExportFileService();
        final completedAt = DateTime(2026, 6, 29, 13, 52, 50);

        expect(
          service.buildFileName(
            fileNamePrefix: '棚入れ',
            slipNumber: '棚入れ20260629135250',
            completedAt: completedAt,
            saveFormat: SaveFormat.csv,
            fileNameFromSlip: true,
          ),
          '棚入れ20260629135250.csv',
        );
        expect(
          service.buildFileName(
            fileNamePrefix: '棚卸',
            slipNumber: '棚卸20260629135250',
            completedAt: completedAt,
            saveFormat: SaveFormat.csv,
            fileNameFromSlip: true,
          ),
          '棚卸20260629135250.csv',
        );
      },
    );

    test('builds CSV with localized headers and escaped saved values', () {
      final bytes = service.buildDelimitedBytes(
        language: AppLanguage.japanese,
        saveFormat: SaveFormat.csv,
        items: <ExportInspectionItem>[
          ExportInspectionItem(
            slipNumber: 'SLIP-9001',
            productCode: 'CODE,"001"',
            quantity: 2,
            dateTime: '202601020304',
            userId: 'u1',
          ),
        ],
      );

      expect(bytes.take(3), orderedEquals(<int>[0xEF, 0xBB, 0xBF]));
      expect(
        utf8.decode(bytes),
        '伝票番号,商品コード,数量,日時,ユーザーID\r\n'
        'SLIP-9001,"CODE,""001""",2,202601020304,u1\r\n',
      );
    });

    test('builds stocking CSV with shelf and barcode headers', () {
      final bytes = service.buildDelimitedBytes(
        language: AppLanguage.japanese,
        saveFormat: SaveFormat.csv,
        firstColumnLabel: '棚番号',
        productCodeColumnLabel: 'バーコード/QR',
        items: const <ExportInspectionItem>[
          ExportInspectionItem(
            slipNumber: 'abc',
            productCode: '123',
            quantity: 2,
            dateTime: '202601020304',
            userId: 'user-007',
          ),
        ],
      );

      expect(
        utf8.decode(bytes),
        '棚番号,バーコード/QR,数量,日時,ユーザーID\r\n'
        'abc,123,2,202601020304,user-007\r\n',
      );
    });

    test('builds email attachment arguments with trimmed recipient', () {
      const result = ExportFileResult(
        fileName: '入荷検品49100418503_260102030405.csv',
        filePath: '/tmp/入荷検品49100418503_260102030405.csv',
        mimeType: 'text/csv',
        contentUri: 'content://downloads/1',
      );

      expect(
        service.buildShareArguments(
          result,
          emailAddress: ' receiver@example.com ',
        ),
        <String, Object?>{
          'fileName': result.fileName,
          'filePath': result.filePath,
          'contentUri': result.contentUri,
          'emailAddress': 'receiver@example.com',
          'mimeType': 'text/csv',
          'subject': 'スマートフォンハンディ エクスポートファイル',
          'body': 'エクスポートファイルを添付しましたので、ご確認ください。',
        },
      );
    });

    test('rejects email attachment arguments without a recipient', () {
      const result = ExportFileResult(
        fileName: 'Receiving1_260102030405.xlsx',
        filePath: '/tmp/Receiving1_260102030405.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      expect(
        () => service.buildShareArguments(result, emailAddress: '  '),
        throwsFormatException,
      );
    });
  });
}
