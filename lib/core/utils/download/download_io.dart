import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] on the device and returns the absolute path of the saved
/// file.
///
/// On Android a native "Save as" picker is shown so the user chooses a visible
/// folder (usually Downloads); on other platforms the file is written to the
/// app's documents folder. Returns an empty string when the user cancels the
/// save dialog or the save fails.
Future<String> downloadFileBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  if (Platform.isAndroid) {
    return _saveWithSystemPicker(
        fileName: fileName, mimeType: mimeType, bytes: bytes);
  }
  return _saveToAppFolder(fileName: fileName, bytes: bytes);
}

Future<String> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  return downloadFileBytes(
      fileName: fileName, mimeType: mimeType, bytes: bytes);
}

/// Opens an already-saved file with the default system app for its type.
/// Best-effort: the file stays saved even if no app can open it.
Future<void> openDownloadedFile({
  required String path,
  String? mimeType,
}) async {
  if (path.isEmpty) return;
  try {
    final type = (mimeType ?? '').isNotEmpty ? mimeType : null;
    await OpenFilex.open(path, type: type);
  } catch (_) {
    // Ignore - the file is still saved on the device.
  }
}

Future<String> _saveWithSystemPicker({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  try {
    final directory = await FileSaver.instance.saveAs(
      name: _nameWithoutExtension(fileName),
      bytes: bytes,
      ext: _extensionOnly(fileName),
      mimeType: MimeType.custom,
      customMimeType: mimeType,
    );
    if (directory != null && directory.isNotEmpty) return directory;
  } catch (_) {
    // Fall through to the app folder so the file is not lost.
  }
  return _saveToAppFolder(fileName: fileName, bytes: bytes);
}

Future<String> _saveToAppFolder({
  required String fileName,
  required Uint8List bytes,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return '';
  }
}

String _nameWithoutExtension(String fileName) {
  final i = fileName.lastIndexOf('.');
  if (i <= 0) return fileName;
  return fileName.substring(0, i);
}

String _extensionOnly(String fileName) {
  final i = fileName.lastIndexOf('.');
  if (i <= 0 || i == fileName.length - 1) return '';
  return fileName.substring(i + 1);
}