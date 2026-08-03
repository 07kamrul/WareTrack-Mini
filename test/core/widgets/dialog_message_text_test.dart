import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/widgets/dialog_message_text.dart';

const String _wordJoiner = '\u{2060}';

int _joinerCount(String value) => value.split(_wordJoiner).length - 1;

double _layoutWidth(String text, TextStyle style, {double? maxWidth}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter.width;
}

int _lineCount(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return painter.computeLineMetrics().length;
}

void main() {
  group('wrapDialogMessage', () {
    test('does not change the visible text (no truncation, nothing added)', () {
      const message = 'この端末は既に登録されています。'
          'アプリを利用する場合は、現在登録されている端末登録を解除してから、'
          '再度承認コードを入力してください。';

      final wrapped = wrapDialogMessage(message);

      // Stripping the invisible joiners must reproduce the original exactly.
      expect(wrapped.replaceAll(_wordJoiner, ''), message);
    });

    test('glues every boundary inside a clause so it cannot break mid-phrase',
        () {
      final wrapped = wrapDialogMessage('現在登録');

      // 4 characters → 3 internal boundaries, each glued with a joiner so the
      // phrase can never be split across lines.
      expect(_joinerCount(wrapped), 3);
      expect(wrapped.replaceAll(_wordJoiner, ''), '現在登録');
    });

    test('allows a break (no joiner) after Japanese clause delimiters', () {
      final wrapped = wrapDialogMessage('場合は、現在');

      // If no joiner sits between 、 and 現, the raw substring survives — the
      // line is therefore free to break right after the comma.
      expect(wrapped.contains('、現'), isTrue);
    });

    test('allows a break after a full stop。', () {
      final wrapped = wrapDialogMessage('います。アプリ');

      expect(wrapped.contains('。ア'), isTrue);
    });

    test('preserves author-provided hard line breaks', () {
      final wrapped = wrapDialogMessage('一行目\n二行目');

      expect(wrapped.split('\n'), hasLength(2));
      expect(wrapped.replaceAll(_wordJoiner, ''), '一行目\n二行目');
    });

    test('does not glue across spaces (keeps natural word breaks)', () {
      final wrapped = wrapDialogMessage('hello world');

      // The space stays a valid break point (no joiner glued around it)...
      expect(wrapped.contains('o w'), isTrue);
      // ...and the full text is preserved.
      expect(wrapped.replaceAll(_wordJoiner, ''), 'hello world');
    });

    test('returns short input unchanged', () {
      expect(wrapDialogMessage(''), '');
      expect(wrapDialogMessage('あ'), 'あ');
    });
  });

  group('rendered line breaking', () {
    const style = TextStyle(fontSize: 14);
    const clauses = <String>[
      'この端末は既に登録されています。',
      'アプリを利用する場合は、',
      '現在登録されている端末登録を解除してから、',
      '再度承認コードを入力してください。',
    ];
    final message = clauses.join();

    test(
      'wrapped message breaks once per clause when each clause fits the width',
      () {
        // Self-calibrate the width to the widest (wrapped) clause plus a little
        // slack, so every clause fits on its own line but no two clauses can
        // share one. This is independent of the test font metrics.
        final widest = clauses
            .map((clause) => _layoutWidth(wrapDialogMessage(clause), style))
            .reduce(math.max);
        final width = widest + style.fontSize!;

        final wrappedLines = _lineCount(wrapDialogMessage(message), style, width);
        expect(
          wrappedLines,
          clauses.length,
          reason: 'each clause should occupy exactly one line',
        );

        // The engine genuinely honours the joiners: without them it greedily
        // packs glyphs across clause boundaries and produces a different
        // line layout at the very same width.
        expect(_lineCount(message, style, width), isNot(wrappedLines));
      },
    );
  });
}
