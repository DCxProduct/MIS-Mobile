import '../../core/widgets/editor_content.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../core/network/api_client.dart';
import '../../core/text/html_text.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/cdc_section/reports/rgc_decision_details.dart';
import '../../features/shared/meetings/data/progress_reports_repository.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';
import '../../translations/app_localizations.dart';

Future<void> showReportItemDetail(
  BuildContext context, {
  required Map<String, dynamic> item,
  required ProgressReportItemType type,
  String? requestDocument,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _ReportItemDetailSheet(
    item: item,
    type: type,
    requestDocument: requestDocument,
  ),
);

Map<String, dynamic> _object(Object? value) =>
    value is Map<String, dynamic> ? value : const {};
String _rich(Object? value) => value is String ? value : '';
String _text(Object? value) => value is String ? htmlToPlainText(value) : '';
String _name(Object? value) => value is String
    ? value
    : _text(_object(value)['name'] ?? _object(value)['code']);
String _value(String text) => text.trim().isEmpty ? '—' : text;
String _status(Object? value) => switch (_name(value)) {
  'NOT_ADDRESSED' => 'Not Addressed',
  'IN_PROGRESS' => 'In Progress',
  'SOLVED' => 'Solved',
  final text => _value(text),
};

class _ReportItemDetailSheet extends StatefulWidget {
  const _ReportItemDetailSheet({
    required this.item,
    required this.type,
    this.requestDocument,
  });
  final Map<String, dynamic> item;
  final ProgressReportItemType type;
  final String? requestDocument;
  @override
  State<_ReportItemDetailSheet> createState() => _ReportItemDetailSheetState();
}

class _ReportItemDetailSheetState extends State<_ReportItemDetailSheet> {
  Future<Map<String, dynamic>>? _future;
  Future<Map<String, dynamic>> _load() => AppSettings.of(
    context,
  ).progressReports.getItemDetail(widget.item, type: widget.type);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .95,
      expand: false,
      builder: (context, controller) => Material(
        color: AppColors.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    l10n.text(
                      widget.type == ProgressReportItemType.issue
                          ? 'issuesDetails'
                          : 'rgcDecisionDetails',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      widget.type == ProgressReportItemType.rgcDecision) {
                    return _rgcContent(snapshot.data!, controller);
                  }
                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: snapshot.hasData
                        ? _content(context, snapshot.data!)
                        : [
                            if (snapshot.hasError) ...[
                              Text(
                                snapshot.error is ApiException
                                    ? (snapshot.error as ApiException).message
                                    : l10n.text('notificationDetailError'),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _future = _load();
                                }),
                                child: Text(l10n.text('retry')),
                              ),
                            ] else
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _documents(Map<String, dynamic> data) {
    final request = _object(data['meetingRequest']);
    final update = _object(data['progressUpdate']);
    final issue = widget.type == ProgressReportItemType.issue;
    final linked = !issue && data['issues'] is List
        ? (data['issues'] as List).whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    final documents = <String, String>{};
    void addDocument(Object? value) {
      final metadata = _object(value);
      final path = (value is String ? value : _text(metadata['path'])).trim();
      if (path.isEmpty) return;
      final name = _text(metadata['originalName'] ?? metadata['name']);
      documents.putIfAbsent(
        path,
        () => name.isEmpty ? pdfAttachmentName(path) : name,
      );
    }

    addDocument(request['meetingRequestLetter']);
    addDocument(request['documentReference']);
    for (final item in linked) {
      final linkedRequest = _object(item['meetingRequest']);
      addDocument(linkedRequest['meetingRequestLetter']);
      addDocument(linkedRequest['documentReference']);
    }
    if (documents.isEmpty) addDocument(widget.requestDocument);
    if (documents.isEmpty) {
      for (final item in linked) {
        addDocument(item['attachment']);
      }
    }
    if (documents.isEmpty) {
      addDocument(data['attachment']);
      addDocument(update['attachment']);
      addDocument(data['recordAttachment']);
    }
    return documents;
  }

  Widget _rgcContent(Map<String, dynamic> data, ScrollController controller) {
    final linked = data['issues'] is List
        ? (data['issues'] as List).whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final update = _object(data['progressUpdate']);
    final issues = [
      for (final source in linked.isEmpty ? [data] : linked)
        RgcDecisionIssue.fromJson({
          ...source,
          // Match CDC: the linked issue owns its submitter, date, status,
          // category, documents, descriptions, recommendations and agencies.
          'submittedByName': linked.isEmpty
              ? _text(
                  _object(data['createdBy'])['name'] ??
                      _object(data['user'])['name'] ??
                      data['submittedBy'],
                )
              : _text(_object(source['user'])['name'] ?? source['submittedBy']),
          'submittedDate': linked.isEmpty
              ? data['submittedDate'] ??
                    data['submittedToCdcAt'] ??
                    data['createdAt']
              : source['submittedDate'] ?? source['createdAt'],
          'status': _status(
            source['issueStatus'] ?? source['status'] ?? data['status'],
          ),
          'category': _name(source['category'] ?? data['category']),
          'description': _rich(source['description']),
          'recommendations': _rich(
            source['recommendations'] ?? source['recommendation'],
          ),
          if (RgcDecisionIssue.fromJson(
                source,
              ).meetingRequestDocumentPath.isEmpty &&
              widget.requestDocument?.trim().isNotEmpty == true)
            'attachment': widget.requestDocument,
          'rgcDecision': _rich(data['decision']),
          // Progress belongs to the selected report, never progressReports.last
          // from the master decision (which can belong to another semester).
          for (final field in const [
            'indicators',
            'progressSolution',
            'implementationChallenges',
            'nextStep',
          ])
            field: _rich(data[field] ?? update[field]),
          'request': _rich(data['requests'] ?? update['requests']),
          'sourceOfVerification': _rich(
            data['sourceOfVerification'] ??
                update['sourceOfVerification'] ??
                data['verificationSource'],
          ),
          'verificationLink': _text(
            data['linkToVerificationSource'] ??
                update['linkToVerificationSource'] ??
                data['verificationLink'],
          ),
        }),
    ];
    return CdcRgcDecisionIssueDetails(
      detail: RgcDecisionDetail.fromJson(data),
      issue: issues.first,
      additionalIssues: issues.skip(1).toList(),
      controller: controller,
      documents: linked.isEmpty ? _documents(data) : null,
    );
  }

  List<Widget> _content(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final update = _object(data['progressUpdate']);
    final documents = _documents(data);
    final rawDate = _text(data['submittedDate'] ?? data['createdAt']);
    final date = DateTime.tryParse(rawDate)?.toLocal();
    final organization = _name(data['workingGroup']).isNotEmpty
        ? _name(data['workingGroup'])
        : _name(data['stakeholder']);
    final person = [
      _text(data['submittedBy']),
      _text(_object(data['createdBy'])['name']),
      _text(_object(data['user'])['name']),
    ].firstWhere((name) => name.trim().isNotEmpty, orElse: () => '');
    final status = _status(data['status'] ?? data['issueStatus']);
    final children = <Widget>[
      Text(
        _value(_text(data['title'] ?? data['decision'])),
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Info(
              label: l10n.text('submittedBy'),
              value: _value(organization),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _Info(
              label: l10n.text('status'),
              value: status,
              color: status == 'Solved'
                  ? Colors.green
                  : const Color(0xFFFF4842),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Info(
              label: l10n.text('categories'),
              value: _value(_name(data['category'])),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('meetingRequestDocument'),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (documents.isEmpty)
                  const Text('—')
                else
                  for (final document in documents.entries)
                    PdfAttachmentPreview(
                      path: document.key,
                      name: document.value,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFE53935),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              document.value,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(text: '${l10n.text('submittedBy')}: ${_value(person)}'),
          _Chip(
            text:
                '${l10n.text('submittedDate')}: ${date == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(date)}',
          ),
        ],
      ),
      const SizedBox(height: 18),
      _ExpandableText(
        label: l10n.text('descriptions'),
        text: _value(_rich(data['description'])),
      ),
      _ExpandableText(
        label: l10n.text('recommendations'),
        text: _value(_rich(data['recommendation'] ?? data['recommendations'])),
      ),
    ];
    for (final entry in const {
      'indicators': 'indicators',
      'progressSolution': 'progressSolution',
      'implementationChallenges': 'implementationChallenges',
      'requests': 'request',
      'nextStep': 'nextStep',
      'sourceOfVerification': 'sourceOfVerification',
    }.entries) {
      final text = _rich(data[entry.key] ?? update[entry.key]);
      if (text.isNotEmpty) {
        children.add(
          _ExpandableText(label: l10n.text(entry.value), text: text),
        );
      }
    }
    return children;
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
      ),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(fontSize: 12, color: color)),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.subtleBackground(context),
      border: Border.all(color: AppColors.border(context)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11)),
  );
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.label, required this.text});
  final String label, text;
  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border(context)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final style = TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.secondaryText(context),
              );
              final painter = TextPainter(
                text: TextSpan(
                  text: htmlToPlainText(widget.text),
                  style: style,
                ),
                maxLines: 5,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);
              final overflow =
                  painter.didExceedMaxLines ||
                  containsEditorFormatting(widget.text);
              painter.dispose();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorContent(
                    widget.text,
                    style: style,
                    maxLines: _expanded ? null : 5,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (overflow)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).text(_expanded ? 'showLess' : 'readMore'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
