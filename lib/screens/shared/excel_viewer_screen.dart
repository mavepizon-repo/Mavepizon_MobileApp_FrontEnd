import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/download/file_downloader.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// In-app Excel (.xlsx) preview screen.
///
/// Receives the raw workbook bytes (from `buildTableExcelBytes`) and renders
/// the first sheet as a scrollable table - no external viewer required.
class ExcelViewerScreen extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  const ExcelViewerScreen({
    super.key,
    required this.bytes,
    this.title = 'Excel Report',
  });

  @override
  State<ExcelViewerScreen> createState() => _ExcelViewerScreenState();
}

class _ExcelViewerScreenState extends State<ExcelViewerScreen> {
  late final Excel _workbook;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    try {
      _workbook = Excel.decodeBytes(widget.bytes);
    } catch (e) {
      _error = 'Could not read workbook: $e';
    }
  }

  String get _fileName {
    final base = widget.title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${base.isEmpty ? 'Report' : base}.xlsx';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final path = await downloadFileBytes(
        fileName: _fileName,
        mimeType: _xlsxMime,
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
          await openDownloadedFile(path: path, mimeType: _xlsxMime);
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

  List<List<String>> _sheetRows() {
    if (_error != null || _workbook.tables.isEmpty) return [];
    final sheet = _workbook.tables.values.first;
    if (sheet.rows.isEmpty) return [];
    final maxCols = sheet.maxColumns;
    return sheet.rows.map((row) {
      return List.generate(maxCols, (c) {
        final cell = c < row.length ? row[c] : null;
        return _cellText(cell?.value);
      });
    }).toList();
  }

  String _cellText(CellValue? v) {
    if (v == null) return '';
    switch (v) {
      case IntCellValue():
        return v.value.toString();
      case DoubleCellValue():
        final n = v.value;
        return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
      case BoolCellValue():
        return v.value ? 'TRUE' : 'FALSE';
      case DateCellValue():
        return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
      case TextCellValue():
        return v.value.text ?? '';
      default:
        return v.toString();
    }
  }

  String _sheetName() {
    if (_error != null || _workbook.tables.isEmpty) return '';
    return _workbook.tables.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sheetRows();
    final sheetName = _sheetName();

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
              tooltip: 'Download Excel',
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.download_rounded,
                      color: AppColors.primary),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            )
          : Column(children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.table_view_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sheet: $sheetName  |  ${rows.length - 1} rows',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Text('Sheet is empty',
                            style: TextStyle(color: AppColors.textHint)))
                    : SingleChildScrollView(
                        // horizontal scroll for wide sheets
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var r = 0; r < rows.length; r++)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: r == 0 ||
                                            r == 1
                                        ? AppColors.primarySurface
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.borderC(context),
                                        width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var c = 0;
                                          c < rows[r].length;
                                          c++)
                                        Container(
                                          width: 110,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          child: Text(
                                            rows[r][c],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: r == 0
                                                  ? FontWeight.w800
                                                  : FontWeight.w400,
                                              color: r == 0
                                                  ? AppColors.primaryDark
                                                  : AppColors
                                                      .textPri(context),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ]),
    );
  }
}