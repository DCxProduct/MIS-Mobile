import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';
import '../issues/detail_widgets.dart';

// Design fixtures, pending a CDC report detail API contract.
const cdcRgcReports = [
  CdcRgcReport(
    status: 'In Progress',
    meetingDate: 'Nov 13, 2023',
    year: '2023',
  ),
  CdcRgcReport(status: 'Solved', meetingDate: 'Apr 28, 2025', year: '2025'),
];

class CdcRgcReport {
  const CdcRgcReport({
    required this.status,
    required this.meetingDate,
    required this.year,
  });
  final String status, meetingDate, year;
  String get agency => 'MPWT';
  String get category => 'Legislation';
  String get focalPerson => 'Peng Ponea';
  String get plenary => '19th G-PSF Plenary';
  String get workingGroup => 'Agriculture and Agro-Industry';
  String get measureCategory =>
      '5. Improving transportation and infrastructure';
  String get decisionDate => 'Not Specified';
}

const _decision =
    '5. Entrust His Excellency Peng Ponea, Minister of Public Works and Transport to amend the relevant laws and regulations with comprehensive study of technical aspects to determine the type of vehicles and the type of roads that can be used for increasing the weight level of trucks from 40 tons to 45 tons (per truck).';
const _verification =
    'https://drive.google.com/file/d/1edtgGRPmhe3RXUP5nOWsJW-xn23rrAPR/view?usp=drive_link';

Color cdcReportBackground(BuildContext context) => AppColors.isDark(context)
    ? AppColors.darkBackground
    : const Color(0xFFF8F9FA);

BoxDecoration cdcReportCardDecoration(BuildContext context) => BoxDecoration(
  color: AppColors.cardBackground(context),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border(context)),
);

Color _statusColor(String status) =>
    status == 'Solved' ? const Color(0xFF00BA36) : const Color(0xFFFF8A00);

String _statusLabel(BuildContext context, String status) => AppLocalizations.of(
  context,
).text(status == 'Solved' ? 'solved' : 'inProgress');

class CdcRgcStatus extends StatelessWidget {
  const CdcRgcStatus({super.key, required this.status, this.fullWidth = false});
  final String status;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? .1 : .025),
        border: Border.all(
          color: color.withValues(alpha: fullWidth ? .65 : .2),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!fullWidth) ...[
            Icon(Icons.circle_outlined, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              _statusLabel(context, status),
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

AppBar _detailAppBar(BuildContext context) => AppBar(
  backgroundColor: AppColors.cardBackground(context),
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    onPressed: () => Navigator.pop(context),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const Icon(Icons.arrow_back, size: 22),
  ),
  title: Text(
    AppLocalizations.of(context).text('rgcDecisionDetails'),
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
  ),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Divider(height: 1, color: AppColors.border(context)),
  ),
);

class CdcRgcDecisionOverviewScreen extends StatelessWidget {
  const CdcRgcDecisionOverviewScreen({super.key, required this.report});
  final CdcRgcReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cdcReportBackground(context),
      appBar: _detailAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('cdc-rgc-overview'),
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: AppColors.cardBackground(context),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CdcDetailInfoValue(
                          label: l10n.text('deadline'),
                          value: 'June 07, 2025',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text('meetingDate'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Ouk Sabda  '),
                                  TextSpan(
                                    text: '(${report.meetingDate})',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CdcDetailInfoValue(
                          label: l10n.text('numberOfRgcDecision'),
                          value: '179',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CdcDetailInfoValue(
                          label: '${l10n.text('status')} :',
                          value: _statusLabel(context, report.status),
                          color: _statusColor(report.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.text('approvalReport'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _RequestDocument(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: Column(
                children: [
                  for (final status in [
                    report.status,
                    report.status == 'Solved' ? 'In Progress' : 'Solved',
                    report.status,
                  ]) ...[
                    _DecisionIssueCard(report: report, status: status),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionIssueCard extends StatelessWidget {
  const _DecisionIssueCard({required this.report, required this.status});
  final CdcRgcReport report;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.cardBackground(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CdcRgcDecisionIssueScreen(report: report, status: status),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 12,
                    child: _IconInfo(
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF1890FF),
                      label: l10n.text('meetingDate'),
                      value: report.meetingDate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: _IconInfo(
                      icon: Icons.file_copy_outlined,
                      color: const Color(0xFFB437FF),
                      label: l10n.text('categories'),
                      value: report.category,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: _IconInfo(
                      icon: Icons.person_outline,
                      color: AppColors.primaryText(context),
                      label: l10n.text('focalPerson'),
                      value: report.focalPerson,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                _decision,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 14),
              CdcRgcStatus(status: status, fullWidth: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconInfo extends StatelessWidget {
  const _IconInfo({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 22,
        height: 22,
        color: color.withValues(alpha: .08),
        child: Icon(icon, size: 17, color: color),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ],
  );
}

class _RequestDocument extends StatelessWidget {
  const _RequestDocument();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFFFF4842)),
      SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Doc', style: TextStyle(fontSize: 11)),
            Text(
              '200 KB',
              style: TextStyle(fontSize: 7, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    ],
  );
}

class CdcRgcDecisionIssueScreen extends StatelessWidget {
  const CdcRgcDecisionIssueScreen({
    super.key,
    required this.report,
    required this.status,
  });
  final CdcRgcReport report;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cdcReportBackground(context),
      appBar: _detailAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('cdc-rgc-issue-details'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CdcDetailInfoValue(
                    label: l10n.text('submittedBy'),
                    value: 'Agriculture and Agro-In...',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CdcDetailInfoValue(
                    label: '${l10n.text('status')} :',
                    value: _statusLabel(context, status),
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CdcDetailInfoValue(
                    label: l10n.text('categories'),
                    value: report.category,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.text('meetingRequestDocument')}:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _RequestDocument(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CdcDetailDateChip(
                    label: l10n.text('submittedBy'),
                    value: 'Sabada',
                  ),
                  const SizedBox(width: 20),
                  CdcDetailDateChip(
                    label: l10n.text('submittedDate'),
                    value: 'Jun 24 2025',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final section in [
              ('issuesDescription', ''),
              ('recommendations', ''),
              ('rgcDecision', _decision),
              ('indicators', ''),
              ('progressSolution', ''),
              ('implementationChallenges', ''),
              ('request', ''),
              ('nextStep', ''),
              (
                'sourceOfVerification',
                'Announement No. 002 Dated on 27-02-2024 និង កំណត់ហេតុស្តីពីកិច្ចប្រជុំអន្តរក្រសួងស្តីពីការដោះស្រាយបញ្ហាប្រឈមពាក់ព័ន្ធនឹងការគ្រប់គ្រងលើវិស័យដឹកជញ្ជូនផ្លូវគោក ក្រសួងសាធារណការ និងដឹកជញ្ជូន និងក្រសួងអភិវឌ្ឍន៍ជនបទ',
              ),
              ('linkToVerificationSource', _verification),
            ]) ...[
              Text(l10n.text(section.$1), style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: section.$1 == 'linkToVerificationSource'
                    ? SelectableText(
                        section.$2,
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      )
                    : Text(
                        section.$2,
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
