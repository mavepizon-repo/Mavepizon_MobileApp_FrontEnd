import 'dart:typed_data';

/// Mirrors the backend `CloudinaryService` upload rules so invalid files are
/// rejected in the UI before they reach the network:
///   - max size: 5MB
///   - allowed extensions: png/jpg/jpeg/pdf/doc/docx/xls/xlsx
///   - filenames must not contain "..", "/" or "\"
class UploadValidator {
  UploadValidator._();

  static const int maxBytes = 5 * 1024 * 1024;

  static const Set<String> allowedExtensions = {
    'png',
    'jpg',
    'jpeg',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
  };

  /// Returns an error message, or `null` when the file is acceptable.
  static String? validate(String filename, {required int sizeBytes}) {
    final nameError = validateFilename(filename);
    if (nameError != null) return nameError;
    if (sizeBytes > 0) {
      final sizeError = validateSize(sizeBytes);
      if (sizeError != null) return sizeError;
    }
    return null;
  }

  static String? validateFilename(String filename) {
    if (filename.trim().isEmpty) {
      return 'Please choose a file to upload';
    }
    final base = filename.split('\\').last.split('/').last;
    if (base.isEmpty) {
      return 'Please choose a file to upload';
    }
    if (base.contains('..') || base.contains('/') || base.contains('\\')) {
      return 'Unsupported filename';
    }
    final dot = base.lastIndexOf('.');
    final ext = dot < 0 ? '' : base.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Unsupported file type. Allowed: ${allowedExtensions.join(', ')}';
    }
    return null;
  }

  static String? validateSize(int sizeBytes) {
    if (sizeBytes <= 0) {
      return 'Please choose a file that is not empty';
    }
    if (sizeBytes > maxBytes) {
      return 'File exceeds 5MB limit';
    }
    return null;
  }

  /// Convenience for byte-based uploads that already have the data in memory.
  static String? validateBytes(String filename, Uint8List bytes) {
    return validate(filename, sizeBytes: bytes.length);
  }
}