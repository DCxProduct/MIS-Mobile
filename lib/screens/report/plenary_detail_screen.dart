import '../../core/widgets/editor_content.dart';
import '../../features/shared/issues/widgets/issue_agency_logo.dart';
import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import 'rgc_decision_detail_screen.dart';
import '../../features/line_ministry/reports/ministry_rgc_decision_sheet.dart';
import '../../features/shared/meetings/data/plenary.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';
import '../../features/shared/issues/widgets/issue_display.dart';
import '../../translations/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/widgets/pdf_attachment_preview.dart';

class PlenaryDetailScreen extends StatefulWidget {
  const PlenaryDetailScreen({
    super.key,
    required this.title,
    this.plenaryId,
    this.documentReference,
    this.documentReferenceName,
  });

  final int? plenaryId;
  final String title;
  final String? documentReference;
  final String? documentReferenceName;

  @override
  State<PlenaryDetailScreen> createState() => _PlenaryDetailScreenState();
}

class _PlenaryDetailScreenState extends State<PlenaryDetailScreen> {
  Future<(Plenary, List<RgcDecision>)>? _future;

  Future<(Plenary, List<RgcDecision>)> _load() async {
    final settings = AppSettings.of(context);
    final results = await Future.wait<Object>([
      settings.plenaries.getPlenary(widget.plenaryId!),
      settings.rgcDecisions.getDecisions(
        filters: {'plenaryId': '${widget.plenaryId}'},
      ),
    ]);
    return (results[0] as Plenary, results[1] as List<RgcDecision>);
  }

  @override
  Widget build(BuildContext context) => TranslationPageScope(
    page: 'plenary_plenaries',
    child: Builder(builder: _buildContent),
  );

  Widget _buildContent(BuildContext context) {
    if (widget.plenaryId == null) return _content(context, null, const []);
    _future ??= _load();
    return FutureBuilder<(Plenary, List<RgcDecision>)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return _content(context, snapshot.data!.$1, snapshot.data!.$2);
        }
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.text('meetingRequestDetails'))),
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.text('plenariesLoadError')),
                      TextButton(
                        onPressed: () => setState(() {
                          _future = null;
                        }),
                        child: Text(l10n.text('retry')),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    Plenary? plenary,
    List<RgcDecision> decisions,
  ) {
    final documentReference = plenary == null
        ? widget.documentReference
        : plenary.documentReference;
    final documentReferenceName = plenary == null
        ? widget.documentReferenceName
        : plenary.documentReferenceName;

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryText(context),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).text('meetingRequestDetails'),
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('deadline'),
                    value: issueDateWithYear(
                      context,
                      plenary?.deadline?.toLocal(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('meetingDate'),
                    value: issueDateWithYear(
                      context,
                      plenary?.meetingDate?.toLocal(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(
                      context,
                    ).text('numberOfRgcDecision'),
                    value: plenary == null
                        ? '—'
                        : AppLocalizations.of(
                            context,
                          ).number(plenary.numberOfRgcDecisions),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _DetailBlock(
                    label: AppLocalizations.of(context).text('status'),
                    value: plenary == null
                        ? '—'
                        : '• ${AppLocalizations.of(context).status(plenary.status.isEmpty ? plenary.statusCode : plenary.status)}',
                    valueColor: Color(0xFF1E73BE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).text('approvalReport'),
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            PdfAttachmentPreview(
              path: documentReference ?? '',
              name: documentReference == null
                  ? null
                  : pdfAttachmentName(
                      documentReference,
                      name: documentReferenceName,
                    ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdfAttachmentName(
                            documentReference ?? '',
                            name: documentReferenceName,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'PDF',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final decision in decisions) ...[
              _PlenaryIssueItemCard(
                decision: decision,
                meetingDate: issueDateWithYear(
                  context,
                  decision.meetingDate?.toLocal(),
                ),
                category: _display(
                  AppLocalizations.of(context).category(decision.category),
                ),
                focalPerson: _display(decision.focalPerson),
                description: _display(decision.content),
                status: AppLocalizations.of(context).status(
                  decision.status.isEmpty
                      ? decision.statusCode
                      : decision.status,
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (plenary != null && decisions.isEmpty)
              Text(AppLocalizations.of(context).text('noRgcDecisions')),
          ],
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.primaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlenaryIssueItemCard extends StatelessWidget {
  const _PlenaryIssueItemCard({
    required this.decision,
    required this.meetingDate,
    required this.category,
    required this.focalPerson,
    required this.description,
    required this.status,
  });

  final RgcDecision decision;
  final String meetingDate;
  final String category;
  final String focalPerson;
  final String description;
  final String status;

  void _openRgcDecisionBottomSheet(BuildContext context) {
    if (AppSettings.of(context).moduleType == AppModuleType.lineMinistry) {
      showMinistryRgcDecisionSheet(context, decisionId: decision.id);
      return;
    }
    if (AppSettings.of(context).moduleType == AppModuleType.cdcSecretariat) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RgcDecisionDetailScreen(decisionId: decision.id),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TranslationPageScope(
          page: 'plenary_plenaries',
          child: _RgcDecisionBottomSheet(decision: decision),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openRgcDecisionBottomSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E8ED),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    icon: Icons.calendar_month_outlined,
                    label: AppLocalizations.of(context).text('meetingDate'),
                    value: meetingDate,
                    color: const Color(0xFF1E73BE),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.grid_view_outlined,
                    label: AppLocalizations.of(context).text('categories'),
                    value: category,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.person_outline,
                    label: AppLocalizations.of(context).text('focalPerson'),
                    value: focalPerson,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _decisionStatusColor(decision),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _decisionStatusColor(decision),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RgcDecisionBottomSheet extends StatelessWidget {
  const _RgcDecisionBottomSheet({required this.decision});

  final RgcDecision decision;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkCard : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).text('rgcDecision'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F2F5)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Text(
                      _display(decision.plenaryName),
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(
                              context,
                            ).text('governmentAgency'),
                            value: _display(decision.agencyName),
                            logo: decision.agencyLogo,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(context).text('status'),
                            value:
                                '• ${AppLocalizations.of(context).status(decision.status.isEmpty ? decision.statusCode : decision.status)}',
                            valueColor: _decisionStatusColor(decision),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(
                              context,
                            ).text('categories'),
                            value: _display(
                              AppLocalizations.of(
                                context,
                              ).category(decision.category),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(
                              context,
                            ).text('focalPersonHE'),
                            value: _display(decision.focalPerson),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(
                              context,
                            ).text('meetingDate'),
                            value: issueDateWithYear(
                              context,
                              decision.meetingDate?.toLocal(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FieldBlock(
                            label: AppLocalizations.of(
                              context,
                            ).text('indicators'),
                            value: _display(decision.indicatorName),
                          ),
                        ),
                      ],
                    ),
                    _DecisionSection(
                      label: AppLocalizations.of(context).text('issues'),
                      child: Text(
                        _display(decision.issueTitles.join('\n')),
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    _DecisionSection(
                      label: AppLocalizations.of(context).text('rgcDecision'),
                      child: EditorContent(
                        _display(decision.decisionHtml),
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    _DecisionSection(
                      label: AppLocalizations.of(context).text('indicators'),
                      child: Text(
                        _display(decision.indicatorName),
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    _DecisionSection(
                      label: AppLocalizations.of(
                        context,
                      ).text('sourceOfVerification'),
                      child: EditorContent(
                        _display(decision.verificationSource),
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                    _DecisionSection(
                      label: AppLocalizations.of(
                        context,
                      ).text('linkToVerificationSource'),
                      child: SelectableText(
                        _display(decision.verificationLink),
                        style: const TextStyle(
                          color: Color(0xFF1E73BE),
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.logo,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (logo != null)
          Row(
            children: [
              IssueAgencyLogo(path: logo!, size: 20, iconSize: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.primaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _display(String value) => value.trim().isEmpty ? '—' : value;

Color _decisionStatusColor(RgcDecision decision) {
  final status =
      (decision.statusCode.isEmpty ? decision.status : decision.statusCode)
          .toUpperCase()
          .replaceAll(' ', '_');
  return switch (status) {
    'SOLVED' || 'COMPLETED' => const Color(0xFF16A34A),
    'NOT_ADDRESSED' => const Color(0xFFE53935),
    'IN_PROGRESS' => const Color(0xFFFF8A00),
    _ => AppColors.mutedText,
  };
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      Text(
        label,
        style: TextStyle(
          color: AppColors.primaryText(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.darkBackground
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.isDark(context)
                ? AppColors.darkBorder
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: child,
      ),
    ],
  );
}
