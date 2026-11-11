import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/status_colors.dart';
import '../../../core/widgets/editor_content.dart';
import '../../../screens/report/rgc_decision_detail_screen.dart';
import '../../../translations/app_localizations.dart';
import '../../shared/meetings/data/rgc_decision.dart';
import '../../shared/issues/widgets/issue_agency_logo.dart';
import 'ministry_rgc_detail_widgets.dart';

Future<void> showMinistryRgcDecisionSheet(
  BuildContext context, {
  required int decisionId,
  RgcDecisionDetail? detail,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) =>
        MinistryRgcDecisionSheet(decisionId: decisionId, detail: detail),
  ),
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
  Future<RgcDecisionDetail> _load() => AppSettings.of(
    context,
  ).rgcDecisions.getDecision(widget.decisionId, includeDeadline: false);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= widget.detail == null ? _load() : Future.value(widget.detail!);
  }

  @override
  void didUpdateWidget(covariant MinistryRgcDecisionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decisionId != widget.decisionId ||
        oldWidget.detail != widget.detail) {
      _future = widget.detail == null ? _load() : Future.value(widget.detail!);
    }
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'plenary_rgc_decisions',
    child: Builder(builder: _buildContent),
  );
  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = AppColors.isDark(context)
        ? const Color(0xFF101828)
        : Colors.white;
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['KhBattambang'],
        ),
      ),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            l10n.text('rgcDecisionDetails'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          titleSpacing: 0,
        ),
        body: SafeArea(
          top: false,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontFamilyFallback: ['KhBattambang'],
              fontSize: 14,
              height: 1.6,
            ),
            child: FutureBuilder<RgcDecisionDetail>(
              future: _future,
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
                            _future = _load();
                          }),
                          child: Text(l10n.text('retry')),
                        ),
                      ],
                    ),
                  );
                }
                final detail = snapshot.data!;
                return ListView(
                  key: const ValueKey('ministry-rgc-detail-scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _DecisionPanel(detail: detail),
                    const SizedBox(height: 28),
                    RgcDecisionProgressReports(
                      key: ValueKey(detail.decision.id),
                      detail: detail,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.detail});
  final RgcDecisionDetail detail;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final decision = detail.decision;
    final statusCode = decision.statusCode.isEmpty
        ? decision.status
        : decision.statusCode;
    final statusColor = StatusColors.workflow(context, statusCode);
    final legacyIssue = detail.issues.firstOrNull;
    final content = detail.decisionContent.isNotEmpty
        ? detail.decisionContent
        : legacyIssue?.richText['rgcDecision'] ??
              legacyIssue?.rgcDecision ??
              '';
    final link = detail.verificationLink.isNotEmpty
        ? detail.verificationLink
        : legacyIssue?.verificationLink ?? '';
    final uri = Uri.tryParse(link);
    final clickable =
        uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
    final escapedLink = const HtmlEscape().convert(link);
    Widget value(String text) => Text(
      text.isEmpty ? '—' : text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    );
    Widget metadata(IconData icon, String key, Widget child) =>
        MinistryRgcMetadata(icon: icon, label: l10n.text(key), child: child);
    Widget rich(String text) =>
        EditorContent(text, style: const TextStyle(fontSize: 14, height: 1.65));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decision.plenaryName.isNotEmpty) ...[
          Text(
            decision.plenaryName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 19,
              color: AppColors.secondaryText(context),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                l10n.text('primaryAgency'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IssueAgencyLogo(path: decision.agencyLogo, size: 24, iconSize: 16),
            const SizedBox(width: 8),
            Flexible(child: value(decision.agencyName)),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 3 : 2;
            return Wrap(
              spacing: 18,
              runSpacing: 20,
              children: [
                for (final field in [
                  metadata(
                    Icons.calendar_month_outlined,
                    'meetingDate',
                    value(l10n.date(decision.meetingDate)),
                  ),
                  metadata(
                    Icons.label_outline,
                    'categories',
                    value(l10n.category(decision.category)),
                  ),
                  metadata(
                    Icons.toggle_on_outlined,
                    'status',
                    statusCode.isEmpty
                        ? value('')
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: .3),
                              ),
                            ),
                            child: Text(
                              l10n.status(statusCode),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                  ),
                  metadata(
                    Icons.bar_chart_outlined,
                    'indicators',
                    value(detail.indicatorName),
                  ),
                  metadata(
                    Icons.person_outline,
                    'focalPersonHE',
                    value(decision.focalPerson),
                  ),
                ])
                  SizedBox(
                    width:
                        (constraints.maxWidth - 18 * (columns - 1)) / columns,
                    child: field,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: AppColors.border(context)),
        MinistryRgcSection(
          label: l10n.text('linkedIssues'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final issue in detail.issues)
                if (issue.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: value(issue.title),
                  ),
            ],
          ),
        ),
        MinistryRgcSection(
          label: l10n.text('rgcDecision'),
          child: rich(content),
        ),
        MinistryRgcSection(
          label: l10n.text('indicators'),
          child: rich(detail.indicatorDescription),
        ),
        MinistryRgcSection(
          label: l10n.text('sourceOfVerification'),
          child: rich(detail.verificationSource),
        ),
        MinistryRgcSection(
          label: l10n.text('linkToVerificationSource'),
          child: clickable
              ? EditorContent(
                  '<a href="$escapedLink">$escapedLink</a>',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent(context),
                    height: 1.6,
                  ),
                )
              : SelectableText(
                  link,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
        ),
      ],
    );
  }
}
