import '../../../../core/text/html_text.dart';

/// A progress report attached to a working-group issue detail response.
class IssueProgressReport {
  const IssueProgressReport({
    required this.progressReportId,
    this.semester = '',
    required this.title,
    required this.implementationDate,
    required this.referenceName,
    required this.attachmentPaths,
    required this.description,
    required this.indicators,
    required this.implementationChallenges,
    required this.requests,
    required this.nextStep,
    required this.rgcDecision,
    required this.verificationLink,
    required this.sourceOfVerification,
    required this.attachmentName,
    required this.attachmentSize,
    this.richText = const {},
  });

  final int? progressReportId;
  final String semester;
  final String title;
  final DateTime? implementationDate;
  final String referenceName;
  final List<String> attachmentPaths;
  final String description;
  final String indicators;
  final String implementationChallenges;
  final String requests;
  final String nextStep;
  final String rgcDecision;
  final String verificationLink;
  final String sourceOfVerification;
  final String attachmentName;
  final int? attachmentSize;
  final Map<String, String> richText;

  /// Older issue records keep progress details directly on the issue instead
  /// of returning a linked progressReports entry.
  static IssueProgressReport? fromIssueFields(Map<String, dynamic> issue) {
    const contentKeys = [
      'progressSolution',
      'indicators',
      'implementationChallenges',
      'requests',
      'nextStep',
      'rgcDecision',
      'sourceOfVerification',
      'linkToVerificationSource',
    ];
    const progressKeys = [
      'progressSolution',
      'indicators',
      'implementationChallenges',
      'dateOfIssueSolution',
      'sourceOfVerification',
      'linkToVerificationSource',
    ];
    if (!progressKeys.any((key) {
      final value = issue[key];
      return value is String && value.trim().isNotEmpty;
    })) {
      return null;
    }
    return IssueProgressReport.fromJson({
      for (final key in [...contentKeys, 'dateOfIssueSolution'])
        if (issue.containsKey(key)) key: issue[key],
    });
  }

  factory IssueProgressReport.fromJson(
    Map<String, dynamic> json, {
    String issueSourceOfVerification = '',
  }) {
    final report = json['progressReport'] is Map<String, dynamic>
        ? json['progressReport'] as Map<String, dynamic>
        : json;
    String value(Object? input) => input is String ? input.trim() : '';
    String path(Object? input) => switch (input) {
      String text => text.trim(),
      Map<String, dynamic> file => value(file['path']),
      _ => '',
    };

    final semester = value(report['semester']);
    final year = report['year'];
    final generatedTitle = semester.isNotEmpty || year is int
        ? [
            'Report',
            if (semester.isNotEmpty) semester,
            if (year is int) '$year',
          ].join(' ')
        : '';
    final title = value(json['title']).isNotEmpty
        ? value(json['title'])
        : value(report['title']).isNotEmpty
        ? value(report['title'])
        : generatedTitle;
    final dateText = value(json['dateOfIssueSolution']).isNotEmpty
        ? value(json['dateOfIssueSolution'])
        : value(json['implementationDate']).isNotEmpty
        ? value(json['implementationDate'])
        : value(report['dateOfIssueSolution']).isNotEmpty
        ? value(report['dateOfIssueSolution'])
        : value(report['implementationDate']);
    final attachment = json['attachment'] is Map<String, dynamic>
        ? json['attachment'] as Map<String, dynamic>
        : report['attachment'] is Map<String, dynamic>
        ? report['attachment'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final paths = <String>{};
    for (final file in [
      json['attachment'],
      json['referenceDocument'],
      report['attachment'],
      report['requestDocument'],
    ]) {
      final location = path(file);
      if (location.isNotEmpty) paths.add(location);
    }
    for (final files in [json['attachments'], report['attachments']]) {
      if (files is List) {
        for (final file in files) {
          final location = path(file);
          if (location.isNotEmpty) paths.add(location);
        }
      }
    }
    final sourceOfVerification = htmlToPlainText(
      value(json['sourceOfVerification']).isNotEmpty
          ? value(json['sourceOfVerification'])
          : value(report['sourceOfVerification']).isNotEmpty
          ? value(report['sourceOfVerification'])
          : issueSourceOfVerification,
    );
    return IssueProgressReport(
      richText: Map.unmodifiable({
        'description': value(json['progressSolution']).isNotEmpty
            ? value(json['progressSolution'])
            : value(report['progressSolution']).isNotEmpty
            ? value(report['progressSolution'])
            : value(json['description']).isNotEmpty
            ? value(json['description'])
            : value(report['description']),
        for (final key in [
          'indicators',
          'implementationChallenges',
          'requests',
          'nextStep',
          'rgcDecision',
        ])
          key: value(json[key] ?? report[key]),
        'sourceOfVerification': value(json['sourceOfVerification']).isNotEmpty
            ? value(json['sourceOfVerification'])
            : value(report['sourceOfVerification']).isNotEmpty
            ? value(report['sourceOfVerification'])
            : issueSourceOfVerification,
        'referenceName': sourceOfVerification.isNotEmpty
            ? value(json['sourceOfVerification']).isNotEmpty
                  ? value(json['sourceOfVerification'])
                  : value(report['sourceOfVerification']).isNotEmpty
                  ? value(report['sourceOfVerification'])
                  : issueSourceOfVerification
            : value(json['referenceName']).isNotEmpty
            ? value(json['referenceName'])
            : value(report['referenceName']),
      }),
      semester: semester,
      progressReportId: json['progressReportId'] is int
          ? json['progressReportId'] as int
          : report['id'] is int
          ? report['id'] as int
          : null,
      title: title,
      implementationDate: DateTime.tryParse(dateText),
      referenceName: sourceOfVerification.isNotEmpty
          ? sourceOfVerification
          : htmlToPlainText(
              value(json['referenceName']).isNotEmpty
                  ? value(json['referenceName'])
                  : value(report['referenceName']),
            ),
      attachmentPaths: List.unmodifiable(paths),
      description: htmlToPlainText(
        value(json['progressSolution']).isNotEmpty
            ? value(json['progressSolution'])
            : value(report['progressSolution']).isNotEmpty
            ? value(report['progressSolution'])
            : value(json['description']).isNotEmpty
            ? value(json['description'])
            : value(report['description']),
      ),
      indicators: htmlToPlainText(
        value(json['indicators'] ?? report['indicators']),
      ),
      implementationChallenges: htmlToPlainText(
        value(
          json['implementationChallenges'] ??
              report['implementationChallenges'],
        ),
      ),
      requests: htmlToPlainText(value(json['requests'] ?? report['requests'])),
      nextStep: htmlToPlainText(value(json['nextStep'] ?? report['nextStep'])),
      rgcDecision: htmlToPlainText(
        value(json['rgcDecision'] ?? report['rgcDecision']),
      ),
      verificationLink: value(
        json['linkToVerificationSource'] ?? report['linkToVerificationSource'],
      ),
      sourceOfVerification: sourceOfVerification,
      attachmentName: value(attachment['originalName'] ?? attachment['name']),
      attachmentSize: attachment['size'] is int
          ? attachment['size'] as int
          : null,
    );
  }
}
