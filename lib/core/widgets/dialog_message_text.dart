import 'package:flutter/widgets.dart';

/// Zero-width, non-printing character that forbids a line break between the
/// glyphs it sits between (Unicode WORD JOINER).
const String _wordJoiner = '⁠';

/// Characters after which a line break reads naturally — Japanese and ASCII
/// clause/sentence delimiters plus closing brackets. A break is allowed
/// *after* these so clauses stay intact and wrap at sentence-like boundaries.
const Set<int> _breakAfterCodePoints = {
  0x3001, // 、
  0x3002, // 。
  0xFF0C, // ，
  0xFF0E, // ．
  0xFF01, // ！
  0xFF1F, // ？
  0xFF1B, // ；
  0xFF1A, // ：
  0x30FB, // ・
  0x2026, // …
  0x002C, // ,
  0x002E, // .
  0x0021, // !
  0x003F, // ?
  0x003B, // ;
  0x003A, // :
  0xFF09, // ）
  0x0029, // )
  0xFF3D, // ］
  0x005D, // ]
  0x300D, // 」
  0x300F, // 』
  0x3011, // 】
  0x3015, // 〕
  0x3009, // 〉
  0x300B, // 》
};

bool _isWhitespace(int codeUnit) {
  return codeUnit == 0x0020 || // space
      codeUnit == 0x0009 || // tab
      codeUnit == 0x3000; // ideographic (full-width) space
}

bool _isHiragana(int rune) => rune >= 0x3041 && rune <= 0x309F;

bool _isKatakana(int rune) =>
    (rune >= 0x30A0 && rune <= 0x30FF) || // katakana (incl. ー)
    (rune >= 0x31F0 && rune <= 0x31FF) || // katakana phonetic extensions
    (rune >= 0xFF66 && rune <= 0xFF9D); // half-width katakana

bool _isKanji(int rune) =>
    (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK unified ideographs
    (rune >= 0x3400 && rune <= 0x4DBF) || // CJK extension A
    rune == 0x3005; // 々 iteration mark

/// A Japanese phrase (bunsetsu) typically ends in hiragana — a particle or
/// okurigana — and the next word starts with kanji or katakana, so that
/// transition is a natural place to wrap without splitting a word
/// (e.g. 「…から｜メール…」「…を｜設定…」).
bool _isWordBoundary(int current, int next) =>
    _isHiragana(current) && (_isKanji(next) || _isKatakana(next));

/// Rewrites [message] so that, when rendered, it only wraps at natural break
/// positions — spaces, existing line breaks, boundaries after Japanese/ASCII
/// clause delimiters, and Japanese word boundaries — instead of breaking
/// words or phrases in the middle.
///
/// Flutter (like the underlying text engine) treats almost every boundary
/// between CJK characters as a valid break, which chops words apart. We glue
/// the glyphs of each word together with a WORD JOINER and leave a break
/// opportunity only at the natural positions, so text fills each line and
/// wraps like ordinary Japanese body text without splitting words. Existing
/// `\n` characters are preserved as hard breaks. Nothing is added or removed
/// from the visible text, so no content is truncated.
String wrapDialogMessage(String message) {
  if (message.isEmpty) {
    return message;
  }

  // Preserve any author-provided hard breaks, gluing each segment on its own.
  return message.split('\n').map(_glueClause).join('\n');
}

String _glueClause(String segment) {
  // Iterate by rune (code point) so surrogate-pair characters are never split.
  final runes = segment.runes.toList(growable: false);
  if (runes.length < 2) {
    return segment;
  }

  final buffer = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    buffer.writeCharCode(runes[i]);
    if (i == runes.length - 1) {
      break;
    }

    final current = runes[i];
    final next = runes[i + 1];
    final breakAllowed = _breakAfterCodePoints.contains(current) ||
        _isWhitespace(current) ||
        _isWhitespace(next) ||
        _isWordBoundary(current, next);
    if (!breakAllowed) {
      buffer.write(_wordJoiner);
    }
  }
  return buffer.toString();
}

/// Text widget for popup/dialog bodies and titles that wraps Japanese (and
/// mixed) text at natural word boundaries instead of breaking words
/// mid-way. Use this for every dialog message so the behaviour stays
/// consistent across the app.
class DialogMessageText extends StatelessWidget {
  const DialogMessageText(
    this.message, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.fitOneLine = false,
  });

  final String message;
  final TextStyle? style;
  final TextAlign textAlign;

  /// When true, the message never soft-wraps: it stays on one line (hard
  /// `\n` breaks are still honoured) and is scaled down to fit the available
  /// width, so narrow devices shrink the text instead of breaking the
  /// sentence mid-phrase. Use only for short confirmation messages — long
  /// text would become unreadably small.
  final bool fitOneLine;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      wrapDialogMessage(message),
      textAlign: textAlign,
      style: style,
    );

    if (!fitOneLine) {
      return text;
    }

    return FittedBox(fit: BoxFit.scaleDown, child: text);
  }
}
