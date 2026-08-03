import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class TextRecognitionLocalDataSource {
  Future<String> processImage(String imagePath);
  Future<String> processBitmap(Uint8List bitmap, int width, int height);
  Future<void> close();
}

class TextRecognitionLocalDataSourceImpl
    implements TextRecognitionLocalDataSource {
  TextRecognitionLocalDataSourceImpl()
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _textRecognizer;

  @override
  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _textRecognizer.processImage(inputImage);
    return result.text;
  }

  @override
  Future<String> processBitmap(Uint8List bitmap, int width, int height) async {
    final inputImage = InputImage.fromBitmap(
      bitmap: bitmap,
      width: width,
      height: height,
    );
    final result = await _textRecognizer.processImage(inputImage);
    return result.text;
  }

  @override
  Future<void> close() async {
    await _textRecognizer.close();
  }
}
