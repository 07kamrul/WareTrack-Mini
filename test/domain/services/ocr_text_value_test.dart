import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/ocr_text_value.dart';

void main() {
  group('OcrTextValue.bestValue', () {
    test('detects general text and digits', () {
      expect(OcrTextValue.bestValue('1234567890'), '1234567890');
      expect(OcrTextValue.bestValue('ABC'), 'ABC');
      expect(OcrTextValue.bestValue('Passport'), 'Passport');
      expect(OcrTextValue.bestValue('Name'), 'Name');
      expect(OcrTextValue.bestValue('DOB'), 'DOB');
    });

    test('detects mixed and hyphenated values', () {
      expect(OcrTextValue.bestValue('A123'), 'A123');
      expect(OcrTextValue.bestValue('ABC87654321'), 'ABC87654321');
      expect(OcrTextValue.bestValue('3-3-1-1'), '3-3-1-1');
    });

    test('preserves OCR letter case and symbols', () {
      expect(OcrTextValue.bestValue('ab12-3456ab'), 'ab12-3456ab');
      expect(OcrTextValue.bestValue('a~b123-ba456ab'), 'a~b123-ba456ab');
      expect(OcrTextValue.bestValue('Ab12/CD~ef-34'), 'Ab12/CD~ef-34');
    });

    test('chooses full QR text over partial OCR lines', () {
      const qr =
          '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777';

      expect(OcrTextValue.bestValue('Label\n$qr\nABC87654321'), qr);
    });

    test('reassembles QR text split by OCR whitespace', () {
      const qr =
          '#QR~/A~001-12345678/H~ABC87654321/PCS~1/ID~88888888/ABCID~7777777';

      expect(
        OcrTextValue.bestValue(
          '#QR~/A~001-12345678/H~ABC87654321\n/PCS~1/ID~88888888/ABCID~7777777',
        ),
        qr,
      );
    });

    test('rejects blank and unreadable results', () {
      expect(OcrTextValue.bestValue(''), isNull);
      expect(OcrTextValue.bestValue('   '), isNull);
      expect(OcrTextValue.bestValue('ABC\uFFFD123'), isNull);
    });
  });
}
