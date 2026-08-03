import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/allowed_input.dart';

String _format(TextInputFormatter formatter, String input) {
  return formatter
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: input),
      )
      .text;
}

void main() {
  group('AllowedInput.isValidSlip', () {
    test('accepts the specified example values', () {
      for (final value in ['Aa1-/', 'ABC-123', 'abc/456', 'A1/B-2']) {
        expect(AllowedInput.isValidSlip(value), isTrue, reason: value);
      }
    });

    test('accepts each allowed character class and preserves case', () {
      expect(AllowedInput.isValidSlip('AZ'), isTrue);
      expect(AllowedInput.isValidSlip('az'), isTrue);
      expect(AllowedInput.isValidSlip('0123456789'), isTrue);
      expect(AllowedInput.isValidSlip('-'), isTrue);
      expect(AllowedInput.isValidSlip('/'), isTrue);
      // Mixed case is neither required nor normalized.
      expect(AllowedInput.isValidSlip('AbCdEf'), isTrue);
    });

    test('rejects empty and out-of-set characters', () {
      expect(AllowedInput.isValidSlip(''), isFalse);
      expect(AllowedInput.isValidSlip('ABC 123'), isFalse); // space
      expect(AllowedInput.isValidSlip('ABC_123'), isFalse); // underscore
      expect(AllowedInput.isValidSlip('ABC.123'), isFalse); // dot
      expect(AllowedInput.isValidSlip('棚123'), isFalse); // Japanese
    });
  });

  group('AllowedInput.isValidShelf', () {
    test('accepts the slip set including slash', () {
      for (final value in ['Aa1-/', 'ABC-123', 'abc/456', 'A1/B-2']) {
        expect(AllowedInput.isValidShelf(value), isTrue, reason: value);
      }
    });

    test('additionally accepts Japanese characters and spaces', () {
      expect(AllowedInput.isValidShelf('棚番号-あア123'), isTrue);
      expect(AllowedInput.isValidShelf('棚 A/1'), isTrue);
    });

    test('rejects empty and unsupported symbols', () {
      expect(AllowedInput.isValidShelf(''), isFalse);
      expect(AllowedInput.isValidShelf('A#1'), isFalse);
      expect(AllowedInput.isValidShelf('A*1'), isFalse);
    });
  });

  group('slipFormatter (keyboard input)', () {
    test('keeps allowed characters and strips the rest, preserving case', () {
      expect(_format(AllowedInput.slipFormatter, 'Aa1-/'), 'Aa1-/');
      expect(_format(AllowedInput.slipFormatter, 'A B_C.1/2-3'), 'ABC1/2-3');
      expect(_format(AllowedInput.slipFormatter, '棚A1'), 'A1');
    });
  });

  group('shelfFormatter (keyboard input)', () {
    test('keeps allowed characters plus Japanese and spaces', () {
      expect(_format(AllowedInput.shelfFormatter, '棚 A/1-2'), '棚 A/1-2');
      expect(_format(AllowedInput.shelfFormatter, 'A#1*2'), 'A12');
    });
  });
}
