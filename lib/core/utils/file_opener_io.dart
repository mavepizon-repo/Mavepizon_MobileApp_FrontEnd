import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'download/file_downloader.dart';

/// Saves [bytes] on the device (system "Save as" picker on Android), then
/// opens the saved file with the default app for that type so the user can
/// view it right away. The saved location is shown in a snack bar.
Future<void> shareLocalFile(
  BuildContext context, {
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  final path = await downloadFileBytes(
    fileName: fileName,
    mimeType: mimeType,
    bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
  );
  if (path.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Save cancelled - no folder was chosen.'),
          behavior: SnackBarBehavior.floating,
        ));
    }
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Saved & opening: $path'),
      behavior: SnackBarBehavior.floating,
    ));
  await openDownloadedFile(path: path, mimeType: mimeType);
}