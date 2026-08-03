final class OcrTextValue {
  const OcrTextValue._();

  static String? bestValue(String text) {
    if (text.trim().isEmpty || text.contains('\uFFFD')) {
      return null;
    }

    final candidates = <String>{};
    void addCandidate(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty || cleaned.contains('\uFFFD')) {
        return;
      }

      candidates.add(cleaned);

      final compact = cleaned.replaceAll(RegExp(r'\s+'), '');
      if (compact.isNotEmpty) {
        candidates.add(compact);
      }
    }

    final readableText = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ');
    addCandidate(readableText);

    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      addCandidate(line);
    }

    for (final token in text.split(RegExp(r'\s+'))) {
      addCandidate(token);
    }

    final compactText = text.replaceAll(RegExp(r'\s+'), '');
    final qrStart =
        RegExp(r'#QR~', caseSensitive: false).firstMatch(compactText)?.start ??
        -1;
    if (qrStart >= 0) {
      final qrText = compactText.substring(qrStart);
      final structuredQrMatch = RegExp(
        r'#QR~.*?/ABCID~\d+',
        caseSensitive: false,
      ).firstMatch(qrText);
      addCandidate(structuredQrMatch?.group(0) ?? qrText);
    }

    final scoredCandidates =
        candidates
            .map((candidate) {
              final normalized = _normalizeGeneralText(candidate);
              if (normalized == null) {
                return null;
              }

              return _OcrCandidate(
                value: normalized,
                score: _candidateScore(normalized),
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) {
            final scoreComparison = b.score.compareTo(a.score);
            if (scoreComparison != 0) {
              return scoreComparison;
            }

            return b.value.length.compareTo(a.value.length);
          });

    return scoredCandidates.firstOrNull?.value;
  }

  static String? _normalizeGeneralText(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[\r\n\t]+'), '').trim();
    if (normalized.isEmpty || normalized.contains('\uFFFD')) {
      return null;
    }

    return normalized;
  }

  static int _candidateScore(String value) {
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);

    if (RegExp(r'#QR~', caseSensitive: false).hasMatch(value)) {
      return 10000 + value.length;
    }

    if (RegExp(r'^\d+(?:-\d+)+$').hasMatch(value)) {
      return 8000 + value.length;
    }

    if (hasLetter && hasDigit) {
      return 7000 + value.length;
    }

    if (RegExp(r'^\d+$').hasMatch(value)) {
      return 6000 + value.length;
    }

    if (value.length >= 2) {
      return 1000 + value.length;
    }

    return value.length;
  }
}

final class _OcrCandidate {
  const _OcrCandidate({required this.value, required this.score});

  final String value;
  final int score;
}
