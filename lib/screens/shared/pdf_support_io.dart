import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

const bool isPdfViewSupported = true;

Widget buildPdfView(Uint8List bytes) => PDFView(pdfData: bytes);