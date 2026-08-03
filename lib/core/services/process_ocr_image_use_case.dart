import 'dart:typed_data';

import 'package:waretrack_mini/data/models/ocr_result.dart';
import 'package:waretrack_mini/data/local/ocr_repository.dart';

class ProcessOcrImageUseCase {
  const ProcessOcrImageUseCase(this._ocrRepository);

  final OcrRepository _ocrRepository;

  Future<OcrResult> call(String imagePath) {
    return _ocrRepository.recognizeText(imagePath);
  }

  Future<OcrResult> fromBitmap(Uint8List bitmap, int width, int height) {
    return _ocrRepository.recognizeBitmap(bitmap, width, height);
  }

  Future<void> dispose() {
    return _ocrRepository.dispose();
  }
}
