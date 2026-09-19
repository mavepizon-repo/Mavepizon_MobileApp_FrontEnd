import 'package:flutter/material.dart';

/// Web fallback for the Io-only share flow. On web the file is downloaded
/// directly through the browser inside `openFileUrl`, so nothing happens here.
Future<void> shareLocalFile(
  BuildContext context, {
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {}