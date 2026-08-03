import 'dart:typed_data';

import 'package:waretrack_mini/data/local/text_recognition_local_data_source.dart';
import 'package:waretrack_mini/data/models/ocr_result_model.dart';
import 'package:waretrack_mini/data/models/ocr_result.dart';
import 'package:waretrack_mini/data/local/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  OcrRepositoryImpl({required TextRecognitionLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final TextRecognitionLocalDataSource _localDataSource;

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    final text = await _localDataSource.processImage(imagePath);
    return OcrResultModel(text: text);
  }

  @override
  Future<OcrResult> recognizeBitmap(
    Uint8List bitmap,
    int width,
    int height,
  ) async {
    final text = await _localDataSource.processBitmap(bitmap, width, height);
    return OcrResultModel(text: text);
  }

  @override
  Future<void> dispose() {
    return _localDataSource.close();
  }
}
