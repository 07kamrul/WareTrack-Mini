import 'dart:typed_data';

import 'package:waretrack_mini/core/utils/base_repository.dart';
import 'package:waretrack_mini/data/models/ocr_result.dart';

abstract class OcrRepository implements BaseRepository {
  Future<OcrResult> recognizeText(String imagePath);
  Future<OcrResult> recognizeBitmap(Uint8List bitmap, int width, int height);
  Future<void> dispose();
}
