import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/download/file_downloader.dart';
import '../../../widgets/certificate_template_view.dart';

class CertificatePreviewScreen extends StatefulWidget {
  final CertificateData data;
  final String? fileName;

  const CertificatePreviewScreen({
    super.key,
    required this.data,
    this.fileName,
  });

  @override
  State<CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState extends State<CertificatePreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<File> _captureImage() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getApplicationDocumentsDirectory();
    final name =
        (widget.fileName?.isNotEmpty ?? false) ? widget.fileName! : 'certificate';
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _captureImage();
      final bytes = await file.readAsBytes();
      final name = (widget.fileName?.isNotEmpty ?? false)
          ? widget.fileName!
          : 'certificate';
      if (kIsWeb) {
        await downloadFileBytes(
          fileName: '$name.png',
          mimeType: 'image/png',
          bytes: bytes,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Certificate download started: $name.png'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ));
        return;
      }
      final path = await downloadFileBytes(
        fileName: '$name.png',
        mimeType: 'image/png',
        bytes: bytes,
      );
      if (!mounted) return;
      if (path.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Save cancelled - no folder was chosen.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ));
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Certificate saved: $path'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
      await openDownloadedFile(path: path, mimeType: 'image/png');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _captureImage();
      await Share.shareXFiles([XFile(file.path)],
          text: 'Mavepizon Technologies - Certificate of Achievement');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Share failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data.studentName.isNotEmpty
        ? widget.data.studentName
        : 'Certificate of Achievement';

    return Scaffold(
      backgroundColor: const Color(0xFF15233A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Certificate',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share',
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download',
            onPressed: _download,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: CertificateTemplateView.templateWidth /
                      CertificateTemplateView.templateHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: CertificateTemplateView(data: widget.data),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Column(
                children: [
                  Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _share,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Share',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _download,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                              _busy ? 'Processing...' : 'Download as Image',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}