import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../core/config/module_config.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/cdc_section/reports/rgc_decision_details.dart';
import '../../features/line_ministry/reports/ministry_rgc_decision_sheet.dart';
import '../../features/shared/meetings/data/plenary.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';
import '../../translations/app_localizations.dart';

class PlenaryDetailScreen extends StatefulWidget {
  const PlenaryDetailScreen({super.key, required this.plenaryId});
  final int plenaryId;
  @override
  State<PlenaryDetailScreen> createState() => _PlenaryDetailScreenState();
}

class _PlenaryDetailScreenState extends State<PlenaryDetailScreen> {
  Future<Plenary>? _future;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppSettings.of(context).plenaries.getPlenary(widget.plenaryId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ministry =
        AppSettings.of(context).moduleType == AppModuleType.lineMinistry;
    return Scaffold(
      backgroundColor: ministry
          ? cdcReportBackground(context)
          : AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground(context),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          l10n.text(ministry ? 'meetingRequestDetails' : 'plenary'),
          style: const TextStyle(fontSize: 15),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<Plenary>(
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
                    Text(
                      snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : l10n.text('notificationDetailError'),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _future = AppSettings.of(
                          context,
                        ).plenaries.getPlenary(widget.plenaryId);
                      }),
                      child: Text(l10n.text('retry')),
                    ),
                  ],
                ),
              );
            }
            final plenary = snapshot.data!;
            final documentName =
                plenary.documentName ??
                pdfAttachmentName(
                  plenary.documentReference ?? '',
                  fallbackName: '${l10n.text('approvalReport')}.pdf',
                );
            final status = plenary.status.toUpperCase() == 'SENT'
                ? l10n.text('sent')
                : plenary.status;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (!ministry)
                  Text(
                    plenary.name,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!ministry) const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailBlock(
                        label: l10n.text('deadline'),
                        value: plenaryDate(plenary.deadline),
                        valueWeight: ministry
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailBlock(
                        label: l10n.text('meetingDate'),
                        value: plenaryDate(plenary.meetingDate),
                        valueWeight: ministry
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailBlock(
                        label: l10n.text('numberOfRgcDecision'),
                        value: '${plenary.numberOfRgcDecisions}',
                        valueWeight: ministry
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailBlock(
                        label: l10n.text('status'),
                        value: status.isEmpty ? '—' : '• $status',
                        valueColor: AppColors.accent(context),
                        valueWeight: ministry
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (plenary.documentReference != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    l10n.text('approvalReport'),
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: ministry ? 12 : null,
                    ),
                  ),
                  ListTile(
                    dense: ministry,
                    minLeadingWidth: ministry ? 0 : null,
                    horizontalTitleGap: ministry ? 8 : null,
                    visualDensity: ministry ? VisualDensity.compact : null,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: ministry ? 18 : null,
                    ),
                    title: Text(
                      documentName,
                      style: TextStyle(fontSize: ministry ? 11 : null),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'PDF',
                      style: TextStyle(fontSize: ministry ? 8 : null),
                    ),
                    onTap: () => previewPdfAttachment(
                      context,
                      plenary.documentReference!,
                      name: documentName,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _PlenaryDecisions(plenaryId: plenary.id),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlenaryDecisions extends StatefulWidget {
  const _PlenaryDecisions({required this.plenaryId});
  final int plenaryId;
  @override
  State<_PlenaryDecisions> createState() => _PlenaryDecisionsState();
}

class _PlenaryDecisionsState extends State<_PlenaryDecisions> {
  Future<List<RgcDecision>>? _future;
  Future<List<RgcDecision>> _load() async {
    final settings = AppSettings.of(context);
    if (settings.moduleType == AppModuleType.lineMinistry) {
      return settings.rgcDecisions.getMinistryPlenaryDecisions(
        plenaryId: widget.plenaryId,
        userId: settings.currentUser?.id,
      );
    }
    return settings.rgcDecisions.getDecisions(
      filters: {'plenaryId': '${widget.plenaryId}'},
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ministry =
        AppSettings.of(context).moduleType == AppModuleType.lineMinistry;
    return FutureBuilder<List<RgcDecision>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              Text(l10n.text('rgcDecisionsLoadError')),
              TextButton(
                onPressed: () => setState(() {
                  _future = _load();
                }),
                child: Text(l10n.text('retry')),
              ),
            ],
          );
        }
        final decisions = snapshot.data ?? [];
        if (decisions.isEmpty) return Text(l10n.text('noRgcDecisions'));
        return Column(
          children: [
            for (final decision in decisions)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: AppColors.cardBackground(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ministry ? 12 : 10),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (ministry) {
                        showMinistryRgcDecisionSheet(
                          context,
                          decisionId: decision.id,
                        );
                      } else {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => CdcRgcDecisionOverviewScreen(
                              decisionId: decision.id,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!ministry && decision.agencyName.isNotEmpty) ...[
                            Text(
                              decision.agencyName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _DetailBlock(
                                  label: l10n.text('meetingDate'),
                                  value: plenaryDate(decision.meetingDate),
                                  icon: Icons.calendar_month_outlined,
                                  iconColor: AppColors.accent(context),
                                  compact: ministry,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DetailBlock(
                                  label: l10n.text('category'),
                                  value: decision.category,
                                  icon: ministry
                                      ? Icons.file_copy_outlined
                                      : Icons.grid_view_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  compact: ministry,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DetailBlock(
                                  label: l10n.text('focalPerson'),
                                  value: decision.focalPerson,
                                  icon: Icons.person_outline,
                                  iconColor: ministry
                                      ? AppColors.primaryText(context)
                                      : const Color(0xFF059669),
                                  compact: ministry,
                                ),
                              ),
                            ],
                          ),
                          if (decision.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              decision.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: ministry
                                  ? const TextStyle(fontSize: 12, height: 1.35)
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (ministry) ...[
                            Divider(
                              height: 1,
                              color: AppColors.border(context),
                            ),
                            const SizedBox(height: 14),
                            CdcRgcStatus(
                              status: decision.status,
                              fullWidth: true,
                            ),
                          ] else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      decision.status.toUpperCase() == 'SOLVED'
                                      ? const Color(0xFF16A34A)
                                      : AppColors.accent(context),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                decision.status.isEmpty
                                    ? l10n.text('viewDetail')
                                    : decision.status.toUpperCase() == 'SOLVED'
                                    ? l10n.text('solved')
                                    : decision.status,
                                style: TextStyle(
                                  color:
                                      decision.status.toUpperCase() == 'SOLVED'
                                      ? const Color(0xFF16A34A)
                                      : AppColors.accent(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.valueWeight = FontWeight.w700,
  });
  final String label, value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;
  final bool compact;
  final FontWeight valueWeight;
  @override
  Widget build(BuildContext context) => compact
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 22,
                height: 22,
                color: (iconColor ?? AppColors.primary).withValues(alpha: .08),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: valueColor ?? AppColors.primaryText(context),
                fontSize: 12,
                fontWeight: valueWeight,
              ),
            ),
          ],
        );
}
