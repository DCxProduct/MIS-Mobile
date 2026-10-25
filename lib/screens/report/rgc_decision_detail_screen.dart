import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../core/widgets/editor_content.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/shared/issues/widgets/issue_agency_logo.dart';
import '../../features/shared/issues/widgets/issue_display.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';
import '../../translations/app_localizations.dart';

class RgcDecisionDetailScreen extends StatefulWidget {
  const RgcDecisionDetailScreen({super.key, required this.decisionId});
  final int decisionId;
  @override
  State<RgcDecisionDetailScreen> createState() =>
      _RgcDecisionDetailScreenState();
}

class _RgcDecisionDetailScreenState extends State<RgcDecisionDetailScreen> {
  Future<RgcDecisionDetail>? _request;
  Future<RgcDecisionDetail> _load() => AppSettings.of(
    context,
  ).rgcDecisions.getDecision(widget.decisionId, includeDeadline: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _load();
  }

  @override
  void didUpdateWidget(covariant RgcDecisionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decisionId != widget.decisionId) _request = _load();
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'cdc_rgc_detail',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.text('rgcDecisionDetails'),
          style: const TextStyle(fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<RgcDecisionDetail>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.text('rgcDecisionsLoadError')),
                    TextButton(
                      onPressed: () => setState(() {
                        _request = _load();
                      }),
                      child: Text(l10n.text('retry')),
                    ),
                  ],
                ),
              );
            }
            return CdcGpsfRgcDecisionDetail(
              key: ValueKey(widget.decisionId),
              detail: snapshot.data!,
            );
          },
        ),
      ),
    );
  }
}

class CdcGpsfRgcDecisionDetail extends StatelessWidget {
  const CdcGpsfRgcDecisionDetail({super.key, required this.detail});
  final RgcDecisionDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decision = detail.decision;
    return ListView(
      key: const ValueKey('cdc-gpsf-rgc-detail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          decision.plenaryName.isEmpty
              ? l10n.api(
                  'issue_matrix_rgc_decision.rgc.detail.rgc_fallback',
                  fallback: l10n.text('rgcDecision'),
                )
              : decision.plenaryName,
          style: const TextStyle(
            fontSize: 17,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IssueAgencyLogo(path: decision.agencyLogo, size: 24, iconSize: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                detail.ministryName.isEmpty ? '—' : detail.ministryName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = (constraints.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                for (final field in <Widget>[
                  _DetailMetadataField(
                    label: l10n.text('meetingDate'),
                    value: issueDate(context, decision.meetingDate),
                  ),
                  _DetailMetadataField(
                    label: l10n.text('categories'),
                    value: decision.category,
                  ),
                  _DetailMetadataField(
                    label: l10n.text('status'),
                    value: l10n.status(decision.status),
                    valueColor: switch (decision.statusCode.toUpperCase()) {
                      'SOLVED' => const Color(0xFF16A34A),
                      'IN_PROGRESS' => const Color(0xFFFF8A00),
                      _ => const Color(0xFFEF4444),
                    },
                  ),
                  if (detail.workflowStatus.isNotEmpty &&
                      AppSettings.of(context).moduleType !=
                          AppModuleType.lineMinistry)
                    _DetailMetadataField(
                      label: '${l10n.text('status')} RGC',
                      value: l10n.status(detail.workflowStatus),
                      valueColor: AppColors.accent(context),
                    ),
                  _DetailMetadataField(
                    label: l10n.text('focalPersonHE'),
                    value: decision.focalPerson,
                  ),
                ])
                  SizedBox(width: columnWidth, child: field),
              ],
            );
          },
        ),
        _section(
          context,
          'issuesDescription',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail.issues.isEmpty) const Text('—'),
              for (final issue in detail.issues) ...[
                if (detail.issues.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      issue.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                _content(
                  issue.richText['issuesDescription'] ?? issue.description,
                ),
                if (detail.issues.length > 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        _section(
          context,
          'recommendations',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail.issues.isEmpty) const Text('—'),
              for (final issue in detail.issues) ...[
                _content(
                  issue.richText['recommendations'] ?? issue.recommendations,
                ),
                if (detail.issues.length > 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        _section(context, 'rgcDecision', _content(detail.decisionContent)),
        _section(context, 'indicators', _content(detail.indicatorName)),
        _section(
          context,
          'sourceOfVerification',
          _content(detail.verificationSource),
        ),
        _section(
          context,
          'linkToVerificationSource',
          _verificationLink(detail.verificationLink),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.text('progressReport'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        RgcDecisionProgressReports(detail: detail),
      ],
    );
  }
}

class RgcDecisionProgressReports extends StatefulWidget {
  const RgcDecisionProgressReports({super.key, required this.detail});
  final RgcDecisionDetail detail;
  @override
  State<RgcDecisionProgressReports> createState() =>
      RgcDecisionProgressReportsState();
}

class RgcDecisionProgressReportsState
    extends State<RgcDecisionProgressReports> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: AppSettings.of(context).moduleType == AppModuleType.lineMinistry
        ? 'plenary_rgc_decisions'
        : 'cdc_rgc_report',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = widget.detail.progressReports;
    if (reports.isEmpty) return Text(l10n.text('noProgressReports'));
    final update = reports[_selected];
    final report = update.report;
    String title(int index) {
      final item = reports[index].report;
      if (const {
            AppModuleType.cdcSecretariat,
            AppModuleType.cdcSection,
            AppModuleType.cefp,
          }.contains(AppSettings.of(context).moduleType) &&
          item.hasGeneratedTitle &&
          item.title.isNotEmpty) {
        return l10n
            .api(
              'issue_matrix_rgc_decision.rgc.report.tab',
              fallback: item.title,
            )
            .replaceAll('{semester}', item.semester)
            .replaceAll('{year}', item.year?.toString() ?? '')
            .trim();
      }
      if (item.title.isNotEmpty) return item.title;
      return '${l10n.text('report')} ${index + 1}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < reports.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(title(index)),
                    selected: index == _selected,
                    onSelected: (_) => setState(() => _selected = index),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Metadata(
          label: l10n.text('implementationDate'),
          value: issueDate(context, report.implementationDate),
        ),
        _section(
          context,
          'rgcReportReferenceName',
          _content(
            report.referenceName.trim().isEmpty
                ? l10n.text('rgcReportNoReference')
                : report.richText['referenceName'] ?? report.referenceName,
          ),
        ),
        if (report.attachmentPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.text('rgcReportReferenceAttachment'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          for (final path in report.attachmentPaths)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PdfAttachmentPreview(
                path: path,
                name: pdfAttachmentName(
                  path,
                  name: report.attachmentNames[path],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.border(context).withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                  ),
                  title: Text(
                    pdfAttachmentName(path, name: report.attachmentNames[path]),
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle:
                      report.attachmentSize != null &&
                          report.attachmentPaths.length == 1
                      ? Text(
                          '${(report.attachmentSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
              ),
            ),
        ],
        _section(
          context,
          'progressSolution',
          _content(report.richText['description'] ?? report.description),
        ),
        _section(
          context,
          'rgcReportSolutionIndicators',
          _content(report.richText['indicators'] ?? report.indicators),
        ),
        _section(
          context,
          'rgcReportChallenges',
          _content(
            report.richText['implementationChallenges'] ??
                report.implementationChallenges,
          ),
        ),
        _section(
          context,
          'requests',
          _content(report.richText['requests'] ?? report.requests),
        ),
        _section(
          context,
          'rgcDecision',
          _content(
            report.rgcDecision.isEmpty
                ? widget.detail.decisionContent
                : report.richText['rgcDecision'] ?? report.rgcDecision,
          ),
        ),
        if (report.nextStep.isNotEmpty)
          _section(
            context,
            'nextStep',
            _content(report.richText['nextStep'] ?? report.nextStep),
          ),
        if (report.sourceOfVerification.isNotEmpty)
          _section(
            context,
            'sourceOfVerification',
            _content(
              report.richText['sourceOfVerification'] ??
                  report.sourceOfVerification,
            ),
          ),
        if (report.verificationLink.isNotEmpty)
          _section(
            context,
            'linkToVerificationSource',
            _verificationLink(report.verificationLink),
          ),
      ],
    );
  }
}

class _DetailMetadataField extends StatelessWidget {
  const _DetailMetadataField({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      const SizedBox(height: 6),
      Text(
        value.isEmpty ? '—' : value,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: valueColor ?? AppColors.primaryText(context),
        ),
      ),
    ],
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.fieldBackground(context),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: TextStyle(color: AppColors.primaryText(context)),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 12),
    ),
  );
}

Widget _content(String value) => EditorContent(
  value.trim().isEmpty ? '—' : value,
  style: const TextStyle(fontSize: 13, height: 1.5),
);
Widget _verificationLink(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty) {
    return _content(value);
  }
  final escaped = htmlEscape.convert(value);
  return _content('<a href="$escaped">$escaped</a>');
}

Widget _section(BuildContext context, String labelKey, Widget child) => Padding(
  padding: const EdgeInsets.only(top: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).text(labelKey),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 9),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.subtleBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: child,
      ),
    ],
  ),
);
