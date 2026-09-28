class WgIssueSummary {
  const WgIssueSummary({
    required this.totalIssues,
    required this.solved,
    required this.inProgress,
    required this.notAddressed,
    required this.totalPrimaryAgencies,
  });

  final int totalIssues;
  final int solved;
  final int inProgress;
  final int notAddressed;
  final int totalPrimaryAgencies;

  factory WgIssueSummary.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) throw FormatException('Invalid $key');
      return value;
    }

    return WgIssueSummary(
      totalIssues: count('totalIssues'),
      solved: count('solved'),
      inProgress: count('inProgress'),
      notAddressed: count('notAddressed'),
      totalPrimaryAgencies: count('totalPrimaryAgencies'),
    );
  }
}
