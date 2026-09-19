import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../../screens/shared/excel_viewer_screen.dart';
import '../../screens/shared/file_viewer_screen.dart';
import 'download/file_downloader.dart';
import 'file_opener_io.dart' if (dart.library.html) 'file_opener_web.dart';

/// Extracts a displayable file name from a remote URL or file path.
/// Handles query strings and fragments (e.g. signed Cloudinary URLs).
String fileNameFromUrl(String? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  var name = raw.split('/').last;
  final q = name.indexOf('?');
  if (q >= 0) name = name.substring(0, q);
  final h = name.indexOf('#');
  if (h >= 0) name = name.substring(0, h);
  return name;
}

/// Lowercased file extension including the dot (e.g. ".pdf"), or empty when
/// the name has no usable extension.
String _extensionOf(String fileName) {
  final i = fileName.lastIndexOf('.');
  if (i <= 0 || i == fileName.length - 1) return '';
  return fileName.substring(i).toLowerCase();
}

/// Maps a MIME type to a recommended file extension (e.g. "application/pdf").
String _extensionForMime(String? mimeType) {
  switch ((mimeType ?? '').split(';').first.trim().toLowerCase()) {
    case 'application/pdf':
      return '.pdf';
    case 'application/msword':
      return '.doc';
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return '.docx';
    case 'application/vnd.ms-excel':
      return '.xls';
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return '.xlsx';
    case 'application/vnd.ms-powerpoint':
      return '.ppt';
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return '.pptx';
    case 'application/zip':
    case 'application/x-zip-compressed':
      return '.zip';
    case 'application/vnd.rar':
      return '.rar';
    case 'application/x-7z-compressed':
      return '.7z';
    case 'image/jpeg':
      return '.jpg';
    case 'image/png':
      return '.png';
    case 'image/gif':
      return '.gif';
    case 'image/webp':
      return '.webp';
    case 'image/bmp':
      return '.bmp';
    case 'image/tiff':
      return '.tiff';
    case 'text/plain':
      return '.txt';
    case 'text/csv':
    case 'application/vnd.ms-excel.csv':
      return '.csv';
    case 'audio/mpeg':
      return '.mp3';
    case 'audio/wav':
    case 'audio/x-wav':
      return '.wav';
    case 'video/mp4':
      return '.mp4';
    case 'video/quicktime':
      return '.mov';
    default:
      return '';
  }
}

/// Resolves the URL — full Cloudinary URLs are used as-is; relative paths
/// are resolved against the configured backend base URL.
Uri? _resolveUri(String raw) {
  var uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (!uri.hasScheme) {
    final separator = raw.startsWith('/') ? '' : '/';
    uri = Uri.tryParse('${ApiClient.baseUrl}$separator$raw');
  }
  return uri;
}

/// Sniffs the leading bytes of a file and returns the most likely
/// `(extension, mimeType)`. Returns empty values when it cannot tell.
///
/// This is important because Cloudinary raw URLs often strip the file
/// extension and the server may answer with `application/octet-stream`, which
/// makes the device report the file as "not supported". Content sniffing lets
/// us re-add the correct extension and MIME type.
(String, String) _sniffType(Uint8List bytes) {
  if (bytes.length >= 4 &&
      bytes[0] == 0x25 && bytes[1] == 0x50 &&
      bytes[2] == 0x44 && bytes[3] == 0x46) {
    return ('pdf', 'application/pdf');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 && bytes[1] == 0x50 &&
      bytes[2] == 0x4E && bytes[3] == 0x47) {
    return ('png', 'image/png');
  }
  if (bytes.length >= 3 && bytes[0] == 0xFF &&
      bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return ('jpg', 'image/jpeg');
  }
  if (bytes.length >= 4 && bytes[0] == 'G'.codeUnitAt(0) &&
      bytes[1] == 'I'.codeUnitAt(0) && bytes[2] == 'F'.codeUnitAt(0) &&
      bytes[3] == '8'.codeUnitAt(0)) {
    return ('gif', 'image/gif');
  }
  if (bytes.length >= 12 && bytes[0] == 'R'.codeUnitAt(0) &&
      bytes[1] == 'I'.codeUnitAt(0) && bytes[2] == 'F'.codeUnitAt(0) &&
      bytes[3] == 'F'.codeUnitAt(0) && bytes[8] == 'W'.codeUnitAt(0) &&
      bytes[9] == 'E'.codeUnitAt(0) && bytes[10] == 'B'.codeUnitAt(0) &&
      bytes[11] == 'P'.codeUnitAt(0)) {
    return ('webp', 'image/webp');
  }
  if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return ('bmp', 'image/bmp');
  }
  if (bytes.length >= 4 &&
      ((bytes[0] == 0x49 && bytes[1] == 0x49 &&
            bytes[2] == 0x2A && bytes[3] == 0x00) ||
       (bytes[0] == 0x4D && bytes[1] == 0x4D &&
            bytes[2] == 0x00 && bytes[3] == 0x2A))) {
    return ('tiff', 'image/tiff');
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0xD0 && bytes[1] == 0xCF &&
      bytes[2] == 0x11 && bytes[3] == 0xE0) {
    return ('xls', 'application/vnd.ms-excel');
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x37 && bytes[1] == 0x7A &&
      bytes[2] == 0xBC && bytes[3] == 0xAF &&
      bytes[4] == 0x27 && bytes[5] == 0x1C) {
    return ('7z', 'application/x-7z-compressed');
  }
  if (bytes.length >= 7 &&
      bytes[0] == 'R'.codeUnitAt(0) && bytes[1] == 'a'.codeUnitAt(0) &&
      bytes[2] == 'r'.codeUnitAt(0) && bytes[3] == '!'.codeUnitAt(0) &&
      bytes[4] == 0x1A && bytes[5] == 0x07) {
    return ('rar', 'application/vnd.rar');
  }
  if (bytes.length >= 3 && bytes[0] == 'I'.codeUnitAt(0) &&
      bytes[1] == 'D'.codeUnitAt(0) && bytes[2] == '3'.codeUnitAt(0)) {
    return ('mp3', 'audio/mpeg');
  }
  if (bytes.length >= 8 && bytes[4] == 'f'.codeUnitAt(0) &&
      bytes[5] == 't'.codeUnitAt(0) && bytes[6] == 'y'.codeUnitAt(0) &&
      bytes[7] == 'p'.codeUnitAt(0)) {
    return ('mp4', 'video/mp4');
  }
  if (bytes.length >= 4 && bytes[0] == 'O'.codeUnitAt(0) &&
      bytes[1] == 'g'.codeUnitAt(0) && bytes[2] == 'g'.codeUnitAt(0) &&
      bytes[3] == 'S'.codeUnitAt(0)) {
    return ('ogg', 'audio/ogg');
  }
  if (bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 &&
      bytes[2] == 0xDF && bytes[3] == 0xA3) {
    return ('mkv', 'video/x-matroska');
  }
  if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B &&
      (bytes[2] == 0x03 || bytes[2] == 0x05) &&
      bytes[3] == 0x04) {
    // ZIP container — refine into the matching Office format if possible.
    final length = bytes.length > 131072 ? 131072 : bytes.length;
    final text = String.fromCharCodes(bytes.sublist(0, length));
    if (text.contains('word/document.xml') ||
        text.contains('_rels/.rels')) {
      if (text.contains('ppt/presentation.xml')) {
        return ('pptx',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation');
      }
      if (text.contains('xl/workbook.xml') ||
          text.contains('xl/worksheets/')) {
        return ('xlsx',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }
      if (text.contains('word/document.xml') ||
          text.contains('word/')) {
        return ('docx',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      }
    }
    return ('zip', 'application/zip');
  }
  return ('', '');
}

/// Determines the MIME type of a file.
///
/// Prefers the server-declared Content-Type when it is specific. Falls back to
/// magic-byte sniffing and then extension-based mapping.
String _resolveMime({
  required String? headerMime,
  required List<int> bytes,
  required String fileName,
}) {
  final header = (headerMime ?? '').split(';').first.trim().toLowerCase();
  if (header.isNotEmpty && header != 'application/octet-stream') {
    return header;
  }
  final sniffed = _sniffType(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  if (sniffed.$2.isNotEmpty) return sniffed.$2;
  return _mimeType(fileName);
}

/// Ensures the file name carries a proper extension so the OS can pick a
/// handler app. Content sniffing is preferred because Cloudinary raw URLs
/// strip the extension and the server may only report octet-stream.
String _nameWithExtension(String name,
    {required String mimeType, required (String, String) sniffed}) {
  if (_extensionOf(name).isNotEmpty) return name;
  String ext;
  if (sniffed.$1.isNotEmpty) {
    ext = '.${sniffed.$1}';
  } else {
    ext = _extensionForMime(mimeType);
  }
  if (ext.isEmpty) return name;
  return '$name$ext';
}

/// Downloads the file at [value] and opens it in-app.
///
/// Images, PDFs and text files open in the built-in [FileViewerScreen];
/// Excel files open in [ExcelViewerScreen]. On web the bytes are handed to
/// the browser download instead (no in-app preview). Falls back to the share
/// sheet for file types that could not be previewed.
Future<void> openFileUrl(BuildContext context, String? value) => openFileInApp(context, value);

/// Downloads the file at [value] and views it inside the app.
Future<void> openFileInApp(BuildContext context, String? value,
    {String title = 'File'}) async {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    _showError(context, 'No file available');
    return;
  }
  final uri = _resolveUri(raw);
  if (uri == null) {
    _showError(context, 'Could not open the file');
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(
      content: Text('Opening file...'),
      duration: Duration(seconds: 2),
    ));

  try {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      uri.toString(),
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    final rawName = fileNameFromUrl(raw);
    if (bytes == null || rawName.isEmpty) {
      if (context.mounted) _showError(context, 'Could not open the file');
      return;
    }

    final sniffed = _sniffType(
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    final headerMime = response.headers.value(Headers.contentTypeHeader);
    final mimeType = _resolveMime(
      headerMime: headerMime,
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      fileName: rawName,
    );
    final fileName = _nameWithExtension(
      rawName,
      mimeType: mimeType,
      sniffed: sniffed,
    );
    final byteList = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (!context.mounted) return;
    if (kIsWeb) {
      await downloadFileBytes(
        fileName: fileName,
        mimeType: mimeType,
        bytes: byteList,
      );
      return;
    }

    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
        : '';
    if (sniffed.$1 == 'xls' || sniffed.$1 == 'xlsx' ||
        ext == '.xls' || ext == '.xlsx') {
      // Excel -> in-app table preview.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExcelViewerScreen(bytes: byteList, title: title),
      ));
      return;
    }

    final previewable = sniffed.$1.isNotEmpty && const [
      'pdf', 'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'tiff',
      'txt', 'csv', 'log', 'md', 'json',
    ].contains(sniffed.$1);
    if (previewable) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FileViewerScreen(
            bytes: byteList, fileName: fileName, title: title),
      ));
      return;
    }

    // Not previewable -> share sheet (existing behaviour).
    await shareLocalFile(
      context,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  } catch (e) {
    if (context.mounted) _showError(context, 'Could not open the file');
  }
}

String _mimeType(String fileName) {
  switch (_extensionOf(fileName)) {
    case '.pdf':
      return 'application/pdf';
    case '.doc':
      return 'application/msword';
    case '.docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case '.xls':
      return 'application/vnd.ms-excel';
    case '.xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.ppt':
      return 'application/vnd.ms-powerpoint';
    case '.pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.bmp':
      return 'image/bmp';
    case '.tiff':
      return 'image/tiff';
    case '.txt':
      return 'text/plain';
    case '.csv':
      return 'text/csv';
    case '.zip':
      return 'application/zip';
    case '.rar':
      return 'application/vnd.rar';
    case '.7z':
      return 'application/x-7z-compressed';
    case '.mp3':
      return 'audio/mpeg';
    case '.wav':
      return 'audio/wav';
    case '.mp4':
      return 'video/mp4';
    case '.mov':
      return 'video/quicktime';
    default:
      return 'application/octet-stream';
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}