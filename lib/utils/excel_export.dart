import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../core/utils/download/file_downloader.dart';

const String xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class ColorConcern {
  const ColorConcern(this.hex);
  final String hex;
  static const ColorConcern blue = ColorConcern('FF0EA5E9');
  static const ColorConcern cyan = ColorConcern('FF06B6D4');
  static const ColorConcern green = ColorConcern('FF10B981');
  static const ColorConcern amber = ColorConcern('FFF59E0B');
  static const ColorConcern white = ColorConcern('FFFFFFFF');
  static const ColorConcern lightFill = ColorConcern('FFE0F2FE');
  static const ColorConcern darkFill = ColorConcern('FFF8FAFC');
  static const ColorConcern border = ColorConcern('FFCBD5E1');
}

/// Exports a styled .xlsx file and saves it on the device via
/// [downloadFileBytes]. Returns true on success.
Future<bool> exportTableToExcel({
  required String fileName,
  required String sheetName,
  required List<String> headers,
  required List<List<dynamic>> rows,
  String? title,
  String? subtitle,
}) async {
  final bytes = await buildTableExcelBytes(
    sheetName: sheetName,
    headers: headers,
    rows: rows,
    title: title,
    subtitle: subtitle,
  );
  if (bytes == null) return false;

  await downloadFileBytes(
    fileName: fileName,
    mimeType: xlsxMimeType,
    bytes: bytes,
  );
  return true;
}

/// Builds a styled .xlsx workbook in memory and returns its bytes
/// (so the caller can both save AND preview it in-app).
Future<Uint8List?> buildTableExcelBytes({
  required String sheetName,
  required List<String> headers,
  required List<List<dynamic>> rows,
  String? title,
  String? subtitle,
}) async {
  try {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString(ColorConcern.white.hex),
      backgroundColorHex: ExcelColor.fromHexString(ColorConcern.blue.hex),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString(ColorConcern.border.hex)),
      rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString(ColorConcern.border.hex)),
      topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString(ColorConcern.border.hex)),
      bottomBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString(ColorConcern.border.hex)),
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 15,
      fontColorHex: ExcelColor.fromHexString(ColorConcern.blue.hex),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final subStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(ColorConcern.border.hex),
      italic: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    Border thinBorder() => Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString(ColorConcern.border.hex),
        );

    final bodyStyleLight = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder(),
      rightBorder: thinBorder(),
      topBorder: thinBorder(),
      bottomBorder: thinBorder(),
    );

    final bodyStyleDark = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      backgroundColorHex:
          ExcelColor.fromHexString(ColorConcern.lightFill.hex),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder(),
      rightBorder: thinBorder(),
      topBorder: thinBorder(),
      bottomBorder: thinBorder(),
    );

    CellValue cell(dynamic v) {
      if (v == null) return TextCellValue('');
      if (v is int) return IntCellValue(v);
      if (v is double) return DoubleCellValue(v);
      if (v is bool) return BoolCellValue(v);
      return TextCellValue(v.toString());
    }

    int row = 0;
    if (title != null && title.isNotEmpty) {
      sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
          TextCellValue(title),
          cellStyle: titleStyle);
      row++;
    }
    if (subtitle != null && subtitle.isNotEmpty) {
      sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
          TextCellValue(subtitle),
          cellStyle: subStyle);
      row++;
    }
    if (title != null || subtitle != null) {
      row++;
    }

    // Header row
    for (var c = 0; c < headers.length; c++) {
      sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
          TextCellValue(headers[c]),
          cellStyle: headerStyle);
    }
    row++;

    // Data rows (banded)
    for (var r = 0; r < rows.length; r++) {
      final data = rows[r];
      final style = r.isEven ? bodyStyleLight : bodyStyleDark;
      for (var c = 0; c < headers.length; c++) {
        final v = c < data.length ? data[c] : null;
        sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row + r),
            cell(v),
            cellStyle: style);
      }
    }

    // Column widths (approx based on header + sample data length)
    for (var c = 0; c < headers.length; c++) {
      var width = (headers[c].length + 4).toDouble();
      for (final r in rows) {
        if (c < r.length && r[c] != null) {
          final len = r[c].toString().length + 2;
          if (len > width) width = len.toDouble();
        }
      }
      if (width < 10) width = 10;
      if (width > 45) width = 45;
      sheet.setColumnWidth(c, width);
    }

    final bytes = excel.save();
    if (bytes == null) return null;
    return Uint8List.fromList(bytes);
  } catch (_) {
    return null;
  }
}