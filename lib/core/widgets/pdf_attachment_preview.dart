import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const _fileHost = 'https://admin-mis-stage.datacolabx.com';

String pdfAttachmentUrl(String path) {
  final value = path.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '$_fileHost${value.startsWith('/') ? value : '/$value'}';
}

String pdfAttachmentName(String path, {String? fallbackName}) {
  final value = path.split('?').first;
  var name = value.split('/').last.trim();
  try {
    name = Uri.decodeComponent(name);
  } on ArgumentError {
    // Keep filenames containing a literal percent sign.
  }
  name = name.replaceFirst(RegExp(r'^\d{13}[-_]'), '');
  if (fallbackName != null &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.pdf$',
        caseSensitive: false,
      ).hasMatch(name)) {
    return fallbackName;
  }
  return name.isEmpty ? 'PDF Preview' : name;
}

Future<void> previewPdfAttachment(
  BuildContext context,
  String path, {
  String? name,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PdfAttachmentViewerScreen(
        url: pdfAttachmentUrl(path),
        name: name?.trim().isNotEmpty == true
            ? name!.trim()
            : pdfAttachmentName(path),
      ),
    ),
  );
}

class PdfAttachmentViewerScreen extends StatelessWidget {
  const PdfAttachmentViewerScreen({
    super.key,
    required this.url,
    required this.name,
  });

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}

class PdfAttachmentPreview extends StatelessWidget {
  const PdfAttachmentPreview({
    super.key,
    required this.path,
    required this.child,
    this.name,
  });

  final String path;
  final String? name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (path.trim().isEmpty) return child;
    return InkWell(
      onTap: () => previewPdfAttachment(context, path, name: name),
      borderRadius: BorderRadius.circular(6),
      child: child,
    );
  }
}
