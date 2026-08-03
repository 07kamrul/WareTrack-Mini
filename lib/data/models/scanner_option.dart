class ScannerOption {
  const ScannerOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.formats,
    required this.colorValue,
    this.isOcr = false,
    this.playDetectionSuccessSound = true,
  });

  final String key;
  final String title;
  final String subtitle;
  final List<ScannerFormat> formats;
  final int colorValue;
  final bool isOcr;
  final bool playDetectionSuccessSound;
}

enum ScannerFormat {
  all,
  code128,
  code39,
  code93,
  codabar,
  dataMatrix,
  ean13,
  ean8,
  itf2of5,
  itf14,
  pdf417,
  upcA,
  upcE,
  qrCode,
  aztec,
}
