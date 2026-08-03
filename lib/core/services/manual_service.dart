import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';

/// Opens the bundled instruction manual PDF with the device's default PDF
/// viewer. The asset is copied into app storage first so external viewer
/// apps can access it, and it stays available offline since the PDF ships
/// inside the app bundle.
class ManualService {
  const ManualService._();

  static const String _assetPath =
      'assets/files/Zaicom Mini操作マニュアル（スマートフォン操作用)_20260731.pdf';

  /// Name of the copy written to app storage. Kept ASCII-only so external
  /// PDF viewer apps never trip over non-ASCII file names in content URIs.
  static const String _fileName = 'Zaicom Mini操作マニュアル（スマートフォン操作用)';

  static Future<void> openManual(BuildContext context) async {
    var opened = false;
    try {
      final file = await _materializeAsset();
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      opened = result.type == ResultType.done;
    } catch (_) {
      opened = false;
    }

    if (opened || !context.mounted) {
      return;
    }

    showValidationErrorDialog(
      context,
      AppLocalizations.of(context).unableToOpenManual,
    );
  }

  /// Copies the bundled PDF asset into app storage (skipped when an
  /// identical copy already exists) and returns the on-disk file.
  static Future<File> _materializeAsset() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$_fileName');
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return file;
  }
}
