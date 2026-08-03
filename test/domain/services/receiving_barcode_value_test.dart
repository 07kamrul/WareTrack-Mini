import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/receiving_barcode_value.dart';

void main() {
  group('ReceivingBarcodeValue.normalize', () {
    test('accepts product BR code 1 values', () {
      for (final value in const [
        '4910041850001',
        '4910041850002',
        '4910041850003',
        '4910041850004',
        '4910041850005',
        '4910041850006',
        '4910041850007',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('accepts product BR code 2 values', () {
      for (final value in const [
        '491004185100000',
        '491004185200000',
        '491004185300000',
        '491004185400000',
        '491004185500000',
        '491004185600000',
        '491004185700000',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('accepts any valid 13 or 15 digit product barcode', () {
      for (final value in const ['131202230550000', '4901234567894']) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('strips NW7 start and end letters', () {
      const values = {
        'a1234561234a': '1234561234',
        'b1234562345b': '1234562345',
        'c1234563456c': '1234563456',
        'd1234564567d': '1234564567',
        'e1234565678e': '1234565678',
      };

      for (final entry in values.entries) {
        expect(ReceivingBarcodeValue.normalize(entry.key), entry.value);
      }
    });

    test('strips Codabar scanner guard variants', () {
      const values = {
        't1234567890n': '1234567890',
        '*1234567890*': '1234567890',
      };

      for (final entry in values.entries) {
        expect(ReceivingBarcodeValue.normalize(entry.key), entry.value);
      }
    });

    test('accepts cleaned NW7 values after camera normalization', () {
      for (final value in const [
        '1234561234',
        '1234562345',
        '1234563456',
        '1234564567',
        '1234565678',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('rejects overlong cleaned NW7 values', () {
      expect(
        ReceivingBarcodeValue.normalize(
          '4910041857000000',
          type: ReceivingBarcodeInputType.nw7,
        ),
        isNull,
      );
    });

    test('accepts QR values with symbols', () {
      for (final value in const [
        '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777',
        '#QR~/A~001-23456789/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('accepts Tanabango values with hyphens', () {
      for (final value in const [
        '3-1-1-1',
        '3-1-9-1',
        '3-2-1-1',
        '3-2-9-1',
        '3-3-1-1',
        '3-3-9-1',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), value);
      }
    });

    test('rejects partial or different-format values', () {
      for (final value in const [
        '491004185000',
        '4910041857000000',
        '#QR~////',
        '#QR~',
        '#QR~/A~001-12345678',
        '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~88888888',
        '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ABCID~7777777',
        '#QR~/A~001-12345678/PCS~1/ID~88888888/ABCID~7777777',
        '#QR~/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777',
        '#QR~/A~001-12345678/H~ABC87654321/ID~88888888/ABCID~7777777',
        '#QR~/A~001-1234567X/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777',
        '#QR~/A~001-12345678/H~A/PCS~1/ID~88888888/ABCID~7777777',
        '#QR~/A~001-12345678/H~ABC87654321/PCS~0/ID~88888888/ABCID~7777777',
        '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~ABC/ABCID~7777777',
        '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~88888888/ABCID~ABC',
        '/A~',
        '37371-1',
        '3-371-1',
        'CODE-001',
        'ABC123456789',
      ]) {
        expect(ReceivingBarcodeValue.normalize(value), isNull);
      }
    });

    test('rejects empty or unreadable values', () {
      for (final value in const ['', '   ', 'ABC\uFFFD123']) {
        expect(ReceivingBarcodeValue.normalize(value), isNull);
      }
    });
  });

  group('ReceivingBarcodeValue.normalizeForInspectionList', () {
    test('keeps QR values exactly', () {
      const value =
          '#QR~/A~001-12345678/H~AbC87654321/PCS~1/ID~88888888/ABCID~7777777';

      expect(ReceivingBarcodeValue.normalizeForInspectionList(value), value);
    });

    test('normalizes NW7 values to digits only', () {
      const values = {
        'A123456A': '123456',
        'a123456b': '123456',
        'e12345678e': '12345678',
        'A12-345B': '12345',
        '*1234567890*': '1234567890',
      };

      for (final entry in values.entries) {
        expect(
          ReceivingBarcodeValue.normalizeForInspectionList(entry.key),
          entry.value,
        );
        expect(
          ReceivingBarcodeValue.normalizeNw7Output(entry.key),
          entry.value,
        );
      }
    });

    test('keeps barcode and OCR text values exactly', () {
      for (final value in const [
        'CODE-001',
        'ab12-3456ab~xY',
        'OCR text Value 123',
      ]) {
        expect(ReceivingBarcodeValue.normalizeForInspectionList(value), value);
      }
    });
  });

  group('ReceivingBarcodeValue.normalizeOcrForInspectionList', () {
    test('preserves the scanned value exactly', () {
      for (final value in const [
        'A12B34C5',
        'a12b34c5',
        'Ab12/CD~ef-34',
        'CODE-001',
        '棚番号-123/A',
        '1234567890',
      ]) {
        expect(
          ReceivingBarcodeValue.normalizeOcrForInspectionList(value),
          value,
        );
      }
    });

    test('does not strip letters from NW7-shaped values', () {
      // These would become digits-only under normalizeForInspectionList; the
      // OCR path must keep the letters, case, and symbols intact.
      const values = ['A12-345B', 'A123456A', 'e12345678e'];

      for (final value in values) {
        expect(
          ReceivingBarcodeValue.normalizeOcrForInspectionList(value),
          value,
        );
      }
    });

    test('only trims control whitespace', () {
      expect(
        ReceivingBarcodeValue.normalizeOcrForInspectionList('  A12B34C5\n'),
        'A12B34C5',
      );
    });

    test('rejects blank and unreadable results', () {
      expect(ReceivingBarcodeValue.normalizeOcrForInspectionList(''), isNull);
      expect(ReceivingBarcodeValue.normalizeOcrForInspectionList('   '), isNull);
      expect(
        ReceivingBarcodeValue.normalizeOcrForInspectionList('A12�34'),
        isNull,
      );
    });
  });
}
