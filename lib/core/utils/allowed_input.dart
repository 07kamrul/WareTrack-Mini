import 'package:flutter/services.dart';

/// Character-set policy for user-entered / scanned codes.
///
/// Two policies are supported:
///  - **slip** — 伝票/発注番号 for 入荷検品 (receiving) and 出荷検品 (shipping):
///    ASCII letters, digits, hyphen, and slash.
///  - **shelf** — 棚番号 for 棚入れ (stocking) and 棚卸 (stocktaking): the slip
///    set plus whitespace and Japanese characters (kana / kanji) that existing
///    shelf labels already use.
///
/// Both the keyboard [TextInputFormatter]s and the validators reject only the
/// characters outside the allowed set — the original character case is always
/// preserved (no upper/lower normalization).
final class AllowedInput {
  const AllowedInput._();

  // Character classes shared between the formatter (matches a single allowed
  // character) and the validator (anchors the whole string).
  static const String _slipChars = r'A-Za-z0-9/\-';
  static const String _shelfChars =
      r'A-Za-z0-9/\s\-぀-ヿ㐀-䶿一-鿿々〆ヶ';

  /// Whole-string validator for slip / order numbers.
  static final RegExp slipPattern = RegExp('^[$_slipChars]+\$');

  /// Whole-string validator for shelf numbers.
  static final RegExp shelfPattern = RegExp(
    '^[$_shelfChars]+\$',
    unicode: true,
  );

  /// Keyboard input formatter for slip / order number fields.
  static final TextInputFormatter slipFormatter =
      FilteringTextInputFormatter.allow(RegExp('[$_slipChars]'));

  /// Keyboard input formatter for shelf number fields.
  static final TextInputFormatter shelfFormatter =
      FilteringTextInputFormatter.allow(RegExp('[$_shelfChars]', unicode: true));

  /// Whether [value] contains only allowed slip characters (and is non-empty).
  static bool isValidSlip(String value) => slipPattern.hasMatch(value);

  /// Whether [value] contains only allowed shelf characters (and is non-empty).
  static bool isValidShelf(String value) => shelfPattern.hasMatch(value);
}
