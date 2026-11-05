import 'package:gpsf_app/core/status_colors.dart';
import '../../private_sector/dashboard/dashboard_screen.dart'
    show SharedDashboardCharts;
import '../reports/rgc_decision_card.dart';

import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import '../../shared/meetings/widgets/rgc_decisions_loader.dart';
import '../../shared/meetings/widgets/plenaries_loader.dart';
import '../../cdc_section/reports/rgc_decision_details.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/widgets/pdf_attachment_preview.dart';
import '../../../features/shared/dashboard/data/dashboard_repository.dart';
import '../../../features/shared/dashboard/widgets/pswg_live_dashboard.dart';

import '../../../screens/report/plenary_detail_screen.dart';
import '../../../translations/app_localizations.dart';

class CdcPlenaryScreen extends StatefulWidget {
  const CdcPlenaryScreen({super.key});
  @override
  State<CdcPlenaryScreen> createState() => _CdcPlenaryScreenState();
}

class _CdcPlenaryScreenState extends State<CdcPlenaryScreen> {
  int _tab = 0;
  static const _translationPages = [
    'dashboard_plenary',
    'plenary_plenaries',
    'cdc_rgc',
  ];
  final _filters = List.generate(3, (_) => FilterSelection());
  Future<void> _openFilters() async {
    final tab = _tab;
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          translationPage: _translationPages[tab],
          initial: _filters[tab],
          load: switch (tab) {
            0 => () => catalogs.dashboard('plenary'),
            1 => catalogs.plenaries,
            _ => () => catalogs.rgc(cdcGpsf: true),
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filters[tab] = result);
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: _translationPages[_tab],
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ApiFilterScope(
      selections: {'rgc-decisions': _filters[2], 'dashboard': _filters[0]},
      queries: {
        'dashboard': _filters[0].toQuery(),
        'plenaries': _filters[1].toQuery(),
        'rgc-decisions': _filters[2].toQuery(),
      },
      child: ColoredBox(
        color: AppColors.isDark(context)
            ? AppColors.darkBackground
            : const Color(0xFFF7F8FA),
        child: Column(
          children: [
            Container(
              color: AppColors.cardBackground(context),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).viewPadding.top + 20,
                16,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.api(
                            const [
                              'plenary_dashboard.title',
                              'plenary_plenaries.title',
                              'issue_matrix_rgc_decision.rgc.page.title',
                            ][_tab],
                            fallback: l10n.text(
                              const [
                                'dashboard',
                                'plenaries',
                                'rgcDecision',
                              ][_tab],
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _openFilters,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.border(context)),
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${l10n.text('filter')}${_filters[_tab].count == 0 ? '' : ' (${l10n.number(_filters[_tab].count)})'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.filter_list, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PlenaryTabs(
                    selectedIndex: _tab,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                child: switch (_tab) {
                  0 => const _ReportDashboardTab(),
                  1 => const _PlenaryTab(),
                  _ => const _RgcDecisionTab(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RgcDecisionTab extends StatelessWidget {
  const _RgcDecisionTab();

  @override
  Widget build(BuildContext context) {
    return RgcDecisionsLoader(
      includePlenaryDetails: false,
      builder: (decisions) => Column(
        children: [
          for (final decision in decisions)
            CdcGpsfRgcDecisionCard(decision: decision),
        ],
      ),
    );
  }
}

class _PlenaryTab extends StatelessWidget {
  const _PlenaryTab();

  @override
  Widget build(BuildContext context) {
    return PlenariesLoader(
      builder: (plenaries) => Column(
        children: [
          for (final plenary in plenaries)
            _PlenaryCard(
              plenaryId: plenary.id,
              title: plenary.name,
              status: plenary.status,
              meetingDate: plenaryDate(plenary.meetingDate, context: context),
              numberOfRgcDecision: AppLocalizations.of(
                context,
              ).number(plenary.numberOfRgcDecisions),
              deadline: rgcDate(plenary.deadline, context: context),
              attachmentCount:
                  '${AppLocalizations.of(context).number(plenary.attachmentCount)} ${AppLocalizations.of(context).text('attachmentsLabel')}',
              documentReference: plenary.documentReference,
              documentReferenceName: plenary.documentReferenceName,
            ),
        ],
      ),
    );
  }
}

class _PlenaryCard extends StatelessWidget {
  const _PlenaryCard({
    required this.plenaryId,
    required this.title,
    required this.status,
    required this.meetingDate,
    required this.numberOfRgcDecision,
    required this.deadline,
    required this.attachmentCount,
    this.documentReference,
    this.documentReferenceName,
  });

  final int plenaryId;
  final String title;
  final String status;
  final String meetingDate;
  final String numberOfRgcDecision;
  final String deadline;
  final String attachmentCount;
  final String? documentReference;
  final String? documentReferenceName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final translatedStatus = l10n.status(status);
    final statusColor = StatusColors.plenaryChip(context, status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFF0F2F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: .3)),
                ),
                child: Text(
                  AppLocalizations.of(context).status(translatedStatus),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow(label: l10n.text('meetingDate'), value: meetingDate),
          const SizedBox(height: 8),
          _ReportRow(
            label: l10n.text('rgcDecision'),
            value: numberOfRgcDecision,
          ),
          const SizedBox(height: 8),
          _ReportRow(label: l10n.text('deadline'), value: deadline),
          const SizedBox(height: 12),
          PdfAttachmentPreview(
            path: documentReference ?? '',
            name: documentReference == null
                ? null
                : pdfAttachmentName(
                    documentReference!,
                    name: documentReferenceName,
                  ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE5E8ED),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF4C5563), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    attachmentCount == '2 Attachement'
                        ? l10n.text('twoAttachments')
                        : attachmentCount,
                    style: const TextStyle(
                      color: Color(0xFF4C5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlenaryDetailScreen(
                      plenaryId: plenaryId,
                      title: title,
                      documentReference: documentReference,
                      documentReferenceName: documentReferenceName,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.accent(context).withValues(alpha: 0.18)
                    : const Color(0xFFF0F7FF),
                foregroundColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.text('viewDetails'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportDashboardTab extends StatelessWidget {
  const _ReportDashboardTab();
  @override
  Widget build(BuildContext context) {
    final selection = ApiFilterScope.selection(context, 'dashboard');
    return PswgDataLoader(
      scope: DashboardScope.plenary,
      selection: selection,
      progressReportId: int.tryParse(
        selection.toQuery()['progressReportId'] ?? '',
      ),
      builder: (_) => const SharedDashboardCharts(plenary: true),
    );
  }
}

class _PlenaryTabs extends StatelessWidget {
  const _PlenaryTabs({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SingleChildScrollView(
        key: const ValueKey('cdc-plenary-tabs'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < 3; index++)
              InkWell(
                key: ValueKey('cdc-plenary-tab-$index'),
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? AppColors.accent(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 16,
                        color: selectedIndex == index
                            ? Colors.white
                            : AppColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.api(
                          const [
                            'plenary_dashboard.title',
                            'plenary_plenaries.title',
                            'issue_matrix_rgc_decision.rgc.page.title',
                          ][index],
                          fallback: l10n.text(
                            const [
                              'dashboard',
                              'plenaries',
                              'rgcDecision',
                            ][index],
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
