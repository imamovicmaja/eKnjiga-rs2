import 'dart:convert' show base64Decode, latin1;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfBase64;
  const PdfViewerPage({super.key, required this.pdfBase64});

  bool _isPdfHeader(Uint8List b) =>
      b.length >= 5 &&
      b[0] == 0x25 &&
      b[1] == 0x50 &&
      b[2] == 0x44 &&
      b[3] == 0x46 &&
      b[4] == 0x2D;

  Uint8List? _decode(String input) {
    if (input.trim().isEmpty) return null;
    final cleaned = input.contains(',') ? input.split(',').last : input;
    try {
      final b = base64Decode(cleaned);
      if (_isPdfHeader(b)) return b;
    } catch (_) {}

    final trimmed = input.trimLeft();
    if (trimmed.startsWith('%PDF-')) {
      final raw = Uint8List.fromList(latin1.encode(input));
      if (_isPdfHeader(raw)) return raw;
    }

    return null;
  }

  Future<File> _writeTemp(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/_eknjiga_preview.pdf');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(pdfBase64);

    if (bytes == null) {
      final head =
          pdfBase64.length > 40 ? pdfBase64.substring(0, 40) : pdfBase64;
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Pregled')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'Neuspjelo učitavanje PDF-a.\n'
            'Dužina stringa: ${pdfBase64.length}\n'
            'Početak stringa: ${head.replaceAll('\n', '\\n')}\n'
            'Očekujem base64 (npr. JVBERi0x…) ili RAW s %PDF-.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Pregled'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<File>(
        future: _writeTemp(bytes),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done || snap.hasError) {
            return SfPdfViewer.memory(bytes);
          }
          return SfPdfViewer.file(snap.data!);
        },
      ),
    );
  }
}
