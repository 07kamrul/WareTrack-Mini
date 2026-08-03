final class ReceivingBarcodeValue {
  const ReceivingBarcodeValue._();

  static final RegExp _controlWhitespacePattern = RegExp(r'[\r\n\t]+');
  static final RegExp _productPattern = RegExp(r'^(?:\d{13}|\d{15})$');
  static final RegExp _tanabangoPattern = RegExp(r'^\d-\d-\d-\d$');
  static final RegExp _nw7Pattern = RegExp(r'^[A-DENT*](\d{3,62})[A-DENT*]$');
  static final RegExp _nw7DigitsPattern = RegExp(r'^\d{10}$');
  static final RegExp _nw7OutputPattern = RegExp(
    r'^[A-ENT*a-ent*].*\d.*[A-ENT*a-ent*]$',
  );
  static final RegExp _nonDigitPattern = RegExp(r'\D+');
  static final RegExp _qrPattern = RegExp(
    r'^#QR~(?:/[A-Z0-9]+~[^/\s]+)+$',
    caseSensitive: false,
  );
  static final RegExp _qrAValuePattern = RegExp(r'^\d{3}-\d{8}$');
  static final RegExp _qrTextValuePattern = RegExp(r'^[A-Z0-9]{2,64}$');
  static final RegExp _qrPositiveIntPattern = RegExp(r'^[1-9]\d*$');
  static final RegExp _qrDigitsPattern = RegExp(r'^\d+$');

  static String? normalize(
    String value, {
    ReceivingBarcodeInputType type = ReceivingBarcodeInputType.any,
  }) {
    final normalized = value
        .trim()
        .replaceAll(_controlWhitespacePattern, '')
        .trim();
    if (normalized.isEmpty || normalized.contains('\uFFFD')) {
      return null;
    }

    final upperValue = normalized.toUpperCase();
    final nw7Match = _nw7Pattern.firstMatch(upperValue);

    return switch (type) {
      ReceivingBarcodeInputType.product => _normalizeProduct(upperValue),
      ReceivingBarcodeInputType.tanabango => _normalizeTanabango(upperValue),
      ReceivingBarcodeInputType.nw7 =>
        nw7Match?.group(1) ?? _normalizeNw7Digits(upperValue),
      ReceivingBarcodeInputType.qr => _normalizeQr(normalized),
      ReceivingBarcodeInputType.any =>
        nw7Match?.group(1) ??
            _normalizeProduct(upperValue) ??
            _normalizeTanabango(upperValue) ??
            _normalizeNw7Digits(upperValue) ??
            _normalizeQr(normalized),
    };
  }

  static String? normalizeForInspectionList(String value) {
    final normalized = value
        .trim()
        .replaceAll(_controlWhitespacePattern, '')
        .trim();
    if (normalized.isEmpty || normalized.contains('\uFFFD')) {
      return null;
    }

    if (_qrPattern.hasMatch(normalized)) {
      return normalized;
    }

    final nw7Value = normalizeNw7Output(normalized);
    if (nw7Value != null) {
      return nw7Value;
    }

    return normalized;
  }

  /// Normalizes an **OCR-scanned** value for inspection-list insertion.
  ///
  /// OCR results must be preserved exactly as read: this only strips
  /// surrounding/control whitespace and rejects blank or unreadable text.
  /// Unlike [normalizeForInspectionList], it never removes letters, changes
  /// letter case, or converts NW7/QR barcodes to a digits-only form \u2014 so a
  /// scan such as `A12B34C5` stays `A12B34C5`. Barcode/QR and manual input
  /// keep using [normalizeForInspectionList].
  static String? normalizeOcrForInspectionList(String value) {
    final normalized = value
        .trim()
        .replaceAll(_controlWhitespacePattern, '')
        .trim();
    if (normalized.isEmpty || normalized.contains('\uFFFD')) {
      return null;
    }

    return normalized;
  }

  static String? normalizeNw7Output(String value) {
    final normalized = value
        .trim()
        .replaceAll(_controlWhitespacePattern, '')
        .trim();
    if (!_nw7OutputPattern.hasMatch(normalized)) {
      return null;
    }

    final digits = normalized.replaceAll(_nonDigitPattern, '');
    return digits.isEmpty ? null : digits;
  }

  static String? _normalizeProduct(String value) {
    return _productPattern.hasMatch(value) ? value : null;
  }

  static String? _normalizeTanabango(String value) {
    return _tanabangoPattern.hasMatch(value) ? value : null;
  }

  static String? _normalizeNw7Digits(String value) {
    return _nw7DigitsPattern.hasMatch(value) ? value : null;
  }

  static String? _normalizeQr(String value) {
    if (!_qrPattern.hasMatch(value)) {
      return null;
    }

    final segments = _qrSegments(value);
    if (segments == null ||
        !_hasValidQrSegment(segments, 'A', _qrAValuePattern) ||
        !_hasValidQrSegment(segments, 'H', _qrTextValuePattern) ||
        !_hasValidQrSegment(segments, 'PCS', _qrPositiveIntPattern) ||
        !_hasValidQrSegment(segments, 'ID', _qrDigitsPattern) ||
        !_hasValidQrSegment(segments, 'ABCID', _qrDigitsPattern)) {
      return null;
    }

    return value;
  }

  static bool _hasValidQrSegment(
    Map<String, String> segments,
    String key,
    RegExp pattern,
  ) {
    final value = segments[key];
    return value != null && pattern.hasMatch(value);
  }

  static Map<String, String>? _qrSegments(String value) {
    if (!value.toUpperCase().startsWith('#QR~')) {
      return null;
    }

    final segments = <String, String>{};
    final matches = RegExp(
      r'/([A-Z0-9]+)~([^/\s]+)',
      caseSensitive: false,
    ).allMatches(value.substring(4));

    var consumed = 0;
    for (final match in matches) {
      if (match.start != consumed) {
        return null;
      }

      final key = match.group(1)!.toUpperCase();
      final segmentValue = match.group(2)!;
      if (segmentValue.isEmpty || segments.containsKey(key)) {
        return null;
      }

      segments[key] = segmentValue;
      consumed = match.end;
    }

    return consumed == value.length - 4 && segments.isNotEmpty
        ? segments
        : null;
  }
}

enum ReceivingBarcodeInputType { any, product, tanabango, nw7, qr }
