import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/download/file_downloader.dart';
import 'pdf_view.dart';

/// In-app file viewer.
///
/// Renders the file directly inside the app - no external app required.
/// Supported previews:
///   - Images (png/jpg/jpeg/webp/gif/bmp) -> displays the image
///   - PDF -> native in-app PDF viewer (flutter_pdfview)
///   - Excel (xlsx/xls) -> use [ExcelViewerScreen] separately
///   - Text/csv -> shows the raw text
/// If a file type cannot be previewed, the screen still offers Save and Share.
class FileViewerScreen extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;
  final String title;
  const FileViewerScreen({
    super.key,
    required this.bytes,
    required this.fileName,
    this.title = 'File',
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool _saving = false;

  String get _ext {
    final i = widget.fileName.lastIndexOf('.');
    if (i <= 0 || i == widget.fileName.length - 1) return '';
    return widget.fileName.substring(i).toLowerCase();
  }

  bool get _isImage => const [
        '.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.tiff', '.heic',
      ].contains(_ext);

  bool get _isPdf => _ext == '.pdf';

  bool get _isText => const ['.txt', '.csv', '.log', '.md', '.json']
      .contains(_ext);

  String get _mimeForImage {
    switch (_ext) {
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
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final mimeType = _isPdf
        ? 'application/pdf'
        : _isImage
            ? _mimeForImage
            : 'application/octet-stream';
    try {
      final path = await downloadFileBytes(
        fileName: widget.fileName,
        mimeType: mimeType,
        bytes: widget.bytes,
      );
      if (!mounted) return;
      if (path.isEmpty && !kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Save cancelled - no folder was chosen.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              path.isEmpty ? 'Download started' : 'Saved & opening: $path'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        if (path.isNotEmpty) {
          await openDownloadedFile(path: path, mimeType: mimeType);
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save the file'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _buildBody(BuildContext context) {
    if (_isImage) {
      return Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Could not display this image'),
            ),
          ),
        ),
      );
    }
    if (_isPdf) {
      if (!pdfViewSupported) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    size: 64,
                    color: AppColors.textHi(context).withOpacity(0.4)),
                const SizedBox(height: 14),
                Text('PDF viewer is not available on this platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textHi(context))),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return pdfViewWidget(widget.bytes);
    }
    if (_isText) {
      final text = String.fromCharCodes(widget.bytes);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      );
    }
    // Unsupported preview: show fallback with Save/Share.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file_rounded,
                size: 64, color: AppColors.textHi(context).withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(
              'This file type can not be previewed in-app.\nSave it to view it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHi(context)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save file'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Save file',
              icon: const Icon(Icons.download_rounded,
                  color: AppColors.primary),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}