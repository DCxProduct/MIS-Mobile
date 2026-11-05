import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_settings.dart';
import '../../../core/widgets/filters/api_filter_sheet.dart';
import '../../../core/widgets/filters/api_filter_scope.dart';
import '../../../screens/report/tabs/report_progress_report_tab.dart';
import '../../../translations/app_localizations.dart';
import 'progress_report_ministries_screen.dart';

class CdcSecretariatReportsScreenView extends StatefulWidget {
  const CdcSecretariatReportsScreenView({super.key});
  @override
  State<CdcSecretariatReportsScreenView> createState() => _CdcReportsState();
}

class _CdcReportsState extends State<CdcSecretariatReportsScreenView> {
  FilterSelection _filter = FilterSelection();
  Future<void> _openFilters() async {
    final catalogs = AppSettings.of(context).filters;
    final result = await Navigator.of(context).push<FilterSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiFilterSheet(
          translationPage: 'progress_report',
          initial: _filter,
          load: catalogs.progressReports,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'progress_report',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ApiFilterScope(
      selections: {'progress-reports': _filter},
      queries: {'progress-reports': _filter.toQuery()},
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
                          l10n.text('progressReport'),
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
                              '${l10n.text('filter')}${_filter.count == 0 ? '' : ' (${l10n.number(_filter.count)})'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.filter_list, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                child: ReportProgressReportTab(
                  detailBuilder: (report) =>
                      CdcProgressReportMinistriesScreen(report: report),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
