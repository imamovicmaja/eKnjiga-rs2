import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final Uint8List bytes;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.bytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SfPdfViewer.memory(
        bytes,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
      ),
    );
  }
}