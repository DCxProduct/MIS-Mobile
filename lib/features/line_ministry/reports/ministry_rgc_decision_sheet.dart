import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/widgets/editor_content.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/meetings/data/rgc_decision.dart';

Future<void> showMinistryRgcDecisionSheet(
  BuildContext context, {
  required int decisionId,
  RgcDecisionDetail? detail,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      MinistryRgcDecisionSheet(decisionId: decisionId, detail: detail),
);

class MinistryRgcDecisionSheet extends StatefulWidget {
  const MinistryRgcDecisionSheet({
    super.key,
    required this.decisionId,
    this.detail,
  });
  final int decisionId;
  final RgcDecisionDetail? detail;

  @override
  State<MinistryRgcDecisionSheet> createState() =>
      _MinistryRgcDecisionSheetState();
}

class _MinistryRgcDecisionSheetState extends State<MinistryRgcDecisionSheet> {
  Future<RgcDecisionDetail>? _future;

  Future<RgcDecisionDetail> _load() =>
      AppSettings.of(context).rgcDecisions.getDecision(widget.decisionId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.detail == null ? _load() : Future.value(widget.detail!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => Material(
        color: AppColors.isDark(context)
            ? AppColors.darkBackground
            : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 48, 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n.text('rgcDecisionDetails'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<RgcDecisionDetail>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            l10n.text('rgcDecisionsLoadError'),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _future = _load();
                            }),
                            child: Text(l10n.text('retry')),
                          ),
                        ],
                      );
                    }
                    final detail = snapshot.data!;
                    final issues = detail.issues;
                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        _DecisionPanel(detail: detail, issues: issues),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.detail, required this.issues});
  final RgcDecisionDetail detail;
  final List<RgcDecisionIssue> issues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decision = detail.decision;
    final statusColor = switch (decision.status.toLowerCase()) {
      'solved' => const Color(0xFF00BA36),
      'sent' => AppColors.primary,
      _ => const Color(0xFFFF8A00),
    };
    Widget field(String label, String value, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.text(label),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 12,
            color: color ?? AppColors.primaryText(context),
          ),
        ),
      ],
    );
    Widget section(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text(label),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: child,
          ),
        ],
      ),
    );
    // The ministry, category and date belong to the RGC decision. Linked
    // private-sector issues have independent submitters and classifications.
    final legacyIssue = issues.firstOrNull;
    final content = detail.decisionContent.isNotEmpty
        ? detail.decisionContent
        : legacyIssue?.richText['rgcDecision'] ??
              legacyIssue?.rgcDecision ??
              '';
    final link = detail.verificationLink.isNotEmpty
        ? detail.verificationLink
        : legacyIssue?.verificationLink ?? '';
    final uri = Uri.tryParse(link);
    final clickable = uri != null && ['http', 'https'].contains(uri.scheme);
    final escapedLink = const HtmlEscape().convert(link);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decision.plenaryName.isNotEmpty) ...[
          Text(
            decision.plenaryName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('primaryAgency'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (decision.agencyLogo.isNotEmpty) ...[
                        ClipOval(
                          child: Image.network(
                            pdfAttachmentUrl(decision.agencyLogo),
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.account_balance_outlined,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          decision.agencyName.isEmpty
                              ? '—'
                              : decision.agencyName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: field(
                'status',
                decision.status.isEmpty ? '' : '• ${decision.status}',
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field('categories', decision.category)),
            const SizedBox(width: 18),
            Expanded(child: field('focalPersonHE', decision.focalPerson)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: field('meetingDate', _decisionDate(decision.meetingDate)),
            ),
            const SizedBox(width: 18),
            Expanded(child: field('indicators', detail.indicatorName)),
          ],
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: AppColors.border(context)),
        if (issues.any((issue) => issue.title.isNotEmpty))
          section(
            'linkedIssues',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final issue in issues)
                  if (issue.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        issue.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              ],
            ),
          ),
        section(
          'rgcDecision',
          EditorContent(
            content,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
        if (detail.indicatorName.isNotEmpty)
          section(
            'indicators',
            Text(detail.indicatorName, style: const TextStyle(fontSize: 12)),
          ),
        if (detail.verificationSource.isNotEmpty)
          section(
            'sourceOfVerification',
            EditorContent(
              detail.verificationSource,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        if (link.isNotEmpty)
          section(
            'linkToVerificationSource',
            clickable
                ? EditorContent(
                    '<a href="$escapedLink">$escapedLink</a>',
                    style: const TextStyle(fontSize: 12),
                  )
                : SelectableText(link, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  static String _decisionDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
