import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/network/api_client.dart';
import '../../core/text/html_text.dart';
import '../../core/widgets/filters/api_filter_scope.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/cdc_section/reports/rgc_decision_details.dart';
import '../../features/line_ministry/issues/issues_screen.dart';
import '../../features/private_sector/issues/issue_detail_screen.dart' as ps;
import '../../features/private_sector/meetings/meeting_request_detail_screen.dart'
    as ps;
import '../../features/private_sector/meetings/tabs/calendar_tab.dart';
import '../../features/private_sector/reports/meeting_summary_detail_screen.dart';
import '../../features/shared/meetings/data/meeting_request.dart';
import '../../features/shared/meetings/data/calendar_meeting.dart';
import '../../features/shared/issues/data/working_group_issue.dart';
import '../../features/shared/meetings/data/progress_reports_repository.dart';
import '../../features/shared/meetings/widgets/rgc_decisions_loader.dart';
import '../../features/shared/notifications/data/notification_destination.dart';
import '../../translations/app_localizations.dart';
import '../report/progress_report_detail_loader.dart';

/// Mobile equivalents of the notification's documented web routes. Detail
/// requests use the resource ID, never the system-notification ID.
class NotificationDestinationScreen extends StatelessWidget {
  const NotificationDestinationScreen({super.key, required this.destination});
  final NotificationDestination destination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (destination.kind) {
      NotificationDestinationKind.progressReport => ProgressReportDetailLoader(
        id: destination.id!,
        scope: ProgressReportDetailScope.ministry,
      ),
      NotificationDestinationKind.sharedProgressReport =>
        ProgressReportDetailLoader(
          id: destination.id!,
          scope: ProgressReportDetailScope.sharedAssignment,
        ),
      NotificationDestinationKind.rgcDecision => CdcRgcDecisionOverviewScreen(
        decisionId: destination.id!,
      ),
      NotificationDestinationKind.meetingSummary => MeetingSummaryDetailScreen(
        id: destination.id,
      ),
      NotificationDestinationKind.calendar => Scaffold(
        appBar: AppBar(title: Text(l10n.text('meetingCalendar'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [CalendarTab(initialMeetingId: destination.id)],
        ),
      ),
      NotificationDestinationKind.issueMatrix => Scaffold(
        appBar: AppBar(title: Text(l10n.text('issuesMatrix'))),
        body: const LineMinistryIssuesScreenView(showTabs: false),
      ),
      NotificationDestinationKind.rgcDecisions => Scaffold(
        appBar: AppBar(title: Text(l10n.text('rgcDecision'))),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: _DecisionList(),
        ),
      ),
      _ => _ResourceDetail(destination: destination),
    };
  }
}

class _ResourceDetail extends StatefulWidget {
  const _ResourceDetail({required this.destination});
  final NotificationDestination destination;
  @override
  State<_ResourceDetail> createState() => _ResourceDetailState();
}

class _ResourceDetailState extends State<_ResourceDetail> {
  Future<Map<String, dynamic>>? _future;
  final _editors = <String, TextEditingController>{};
  final _initialText = <String, String>{};
  bool _saving = false;
  bool get _editable =>
      widget.destination.kind == NotificationDestinationKind.editMeetingSummary;
  bool get _dirty => _editors.entries.any(
    (entry) => entry.value.text != _initialText[entry.key],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await AppSettings.of(
      context,
    ).notifications.getResource(widget.destination.endpoint!);
    if (data['id'] != widget.destination.id) {
      throw const ApiException('The server returned a different record.');
    }
    return data;
  }

  @override
  void dispose() {
    for (final editor in _editors.values) {
      editor.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = <String, dynamic>{};
      final issues = <int, Map<String, dynamic>>{};
      for (final entry in _editors.entries) {
        if (entry.value.text == _initialText[entry.key]) continue;
        final parts = entry.key.split(':');
        if (parts.length == 3) {
          final id = int.parse(parts[1]);
          (issues[id] ??= {'issueId': id})[parts[2]] = entry.value.text;
        } else {
          changes[entry.key] = entry.value.text;
        }
      }
      if (issues.isNotEmpty) changes['issueResolves'] = issues.values.toList();
      await AppSettings.of(
        context,
      ).notifications.updateSummary(widget.destination.id!, changes);
      if (!mounted) return;
      for (final entry in _editors.entries) {
        _initialText[entry.key] = entry.value.text;
      }
      setState(() {
        _future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).text('notificationChangesSaved'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : AppLocalizations.of(
                      context,
                    ).text('notificationDetailError'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleKey = switch (widget.destination.kind) {
      NotificationDestinationKind.meetingRequest ||
      NotificationDestinationKind.scheduledMeeting => 'meetingRequest',
      NotificationDestinationKind.plenary => 'plenary',
      NotificationDestinationKind.progressReport ||
      NotificationDestinationKind.sharedProgressReport => 'progressReport',
      NotificationDestinationKind.issue => 'issues',
      _ => 'meetingSummary',
    };
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            (widget.destination.kind ==
                    NotificationDestinationKind.meetingRequest ||
                widget.destination.kind ==
                    NotificationDestinationKind.scheduledMeeting)) {
          // Calendar cards already map meetings (including linked requests,
          // issues and documents) into this same detail UI.
          final request =
              widget.destination.kind ==
                  NotificationDestinationKind.scheduledMeeting
              ? CalendarMeeting.fromJson(snapshot.data!).details
              : MeetingRequest(snapshot.data!);
          return ps.MeetingRequestDetailScreen(
            title: request.title,
            request: request,
          );
        }
        if (snapshot.hasData &&
            widget.destination.kind == NotificationDestinationKind.issue) {
          final issue = WorkingGroupIssue.fromJson(snapshot.data!);
          return ps.IssueDetailScreen(
            title: issue.title,
            category: issue.category,
            issue: issue,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.text(titleKey))),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError || !snapshot.hasData
              ? Center(
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
                          _future = _load();
                        }),
                        child: Text(l10n.text('retry')),
                      ),
                    ],
                  ),
                )
              : _content(context, snapshot.data!),
          bottomNavigationBar: _editable && snapshot.hasData
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _saving || !_dirty ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                          : Text(l10n.text('save')),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final children = <Widget>[];
    void info(String key, Object? value) {
      final text = value is String
          ? htmlToPlainText(value)
          : value is num
          ? '$value'
          : '';
      if (text.trim().isEmpty) return;
      children.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.text(key)),
          subtitle: Text(text),
        ),
      );
    }

    void document(Object? value) {
      final path = value is String ? value : _object(value)['path'] as String?;
      if (path == null || path.isEmpty) return;
      children.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(pdfAttachmentName(path)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => previewPdfAttachment(context, path),
        ),
      );
    }

    void date(String key, Object? value) {
      final date = value is String ? DateTime.tryParse(value)?.toLocal() : null;
      if (date != null) info(key, '${date.day}/${date.month}/${date.year}');
    }

    void heading(String title) => children.add(
      Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );

    if (widget.destination.kind == NotificationDestinationKind.plenary) {
      heading('${data['name'] ?? ''}');
      info('status', data['status']);
      date('meetingDate', data['meetingDate']);
      date('deadline', data['deadline']);
      for (final ministry in _objects(data['ministries'])) {
        info('primaryAgency', ministry['name']);
      }
      document(data['documentReference']);
      heading(l10n.text('rgcDecision'));
      children.add(
        ApiFilterScope(
          queries: {
            'rgc-decisions': {'plenaryId': '${widget.destination.id}'},
          },
          child: const _DecisionList(),
        ),
      );
    } else {
      final meeting = _object(data['meeting']);
      heading(
        '${meeting['title'] ?? _object(data['meetingRequest'])['title'] ?? ''}',
      );
      info('status', data['status']);
      date('meetingDate', meeting['meetingDate']);
      info('location', meeting['location']);
      document(data['documentReference']);
      document(meeting['documentReference']);
      document(_object(data['meetingRequest'])['meetingRequestLetter']);
      for (final entry in const {
        'ministryReporter': 'notificationMinistryReporter',
        'ministryReporterPosition': 'notificationReporterPosition',
        'ministryRepresentative': 'notificationMinistryRepresentative',
        'ministryRepresentativePosition': 'notificationRepresentativePosition',
      }.entries) {
        if (_editable) {
          children.add(
            _editor(
              entry.key,
              l10n.text(entry.value),
              data[entry.key],
              maxLength: 255,
            ),
          );
        } else {
          info(entry.value, data[entry.key]);
        }
      }
      heading(l10n.text('allIssues'));
      for (final issue in _objects(data['issues'])) {
        heading('${issue['issue'] ?? ''}');
        info('category', issue['category']);
        info('status', issue['status']);
        info('description', issue['issueDescription']);
        info('recommendation', issue['recommendation']);
        for (final key in ['rgcDecision', 'nextStep', 'remark']) {
          if (_editable && issue['id'] is int) {
            children.add(
              _editor(
                'issue:${issue['id']}:$key',
                l10n.text(key),
                issue[key],
                maxLines: 4,
              ),
            );
          } else {
            info(key, issue[key]);
          }
        }
        document(issue['issueReference']);
        document(issue['referenceDocument']);
      }
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _editor(
    String key,
    String label,
    Object? value, {
    int maxLines = 1,
    int? maxLength,
  }) {
    final text = value is String ? htmlToPlainText(value) : '';
    final controller = _editors.putIfAbsent(key, () {
      _initialText[key] = text;
      return TextEditingController(text: text);
    });
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
  static Iterable<Map<String, dynamic>> _objects(Object? value) =>
      value is List ? value.whereType<Map<String, dynamic>>() : const [];
}

class _DecisionList extends StatelessWidget {
  const _DecisionList();
  @override
  Widget build(BuildContext context) => RgcDecisionsLoader(
    builder: (decisions) => Column(
      children: [
        if (decisions.isEmpty)
          Text(AppLocalizations.of(context).text('noRgcDecisions')),
        for (final decision in decisions)
          Card(
            child: ListTile(
              title: Text(decision.agencyName),
              subtitle: Text('${decision.category}\n${decision.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      CdcRgcDecisionOverviewScreen(decisionId: decision.id),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
