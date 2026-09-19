import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

/// Web downloads are handled by the browser itself (saved into the browser's
/// default download folder), so we only return the file name as a fake path.
Future<String> downloadFileBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return fileName;
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

/// Not applicable on web - the browser already downloaded the file.
Future<void> openDownloadedFile({
  String? path,
  String? mimeType,
}) async {}