import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'pdf_support_io.dart' if (dart.library.html) 'pdf_support_web.dart';

/// Whether an in-app PDF preview is supported on this platform.
bool get pdfViewSupported => isPdfViewSupported;

/// Renders an in-app PDF preview for [bytes].
Widget pdfViewWidget(Uint8List bytes) => buildPdfView(bytes);