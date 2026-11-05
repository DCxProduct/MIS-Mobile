import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';
import 'pdf_attachment_preview.dart';
import 'pdf_icon.dart';

/// Compact reference card for both uploaded PDFs and external document links.
class ReferenceDocumentCard extends StatelessWidget {
  const ReferenceDocumentCard({
    super.key,
    required this.path,
    required this.emptyLabel,
    this.name,
  });

  final String path;
  final String emptyLabel;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final value = path.trim();
    final uri = Uri.tryParse(value);
    final isWebLink =
        uri != null &&
        const ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
    final isPdf =
        uri != null &&
        (isWebLink || (uri.scheme.isEmpty && uri.host.isEmpty)) &&
        uri.path.toLowerCase().endsWith('.pdf');
    final label = value.isEmpty
        ? emptyLabel
        : name?.trim().isNotEmpty == true
        ? name!.trim()
        : isPdf
        ? pdfAttachmentName(value)
        : isWebLink
        ? uri.host
        : value;

    Future<void> open() async {
      if (isPdf) {
        await previewPdfAttachment(context, value, name: label);
        return;
      }
      if (!isWebLink) return;
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Keep the original link available if no external app can open it.
      }
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: SelectableText(value),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 320),
        child: Material(
          color: AppColors.cardBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border(context)),
          ),
          child: InkWell(
            onTap: value.isNotEmpty && (isPdf || isWebLink) ? open : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPdf || value.isEmpty)
                    const PdfIcon(size: 36)
                  else
                    Icon(
                      Icons.link,
                      size: 30,
                      color: AppColors.accent(context),
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
