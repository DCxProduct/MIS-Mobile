class WorkingGroupSummary {
  const WorkingGroupSummary({
    required this.id,
    required this.name,
    required this.total,
    required this.solved,
    required this.inProgress,
    required this.notAddressed,
  });

  final int id;
  final String name;
  final int total;
  final int solved;
  final int inProgress;
  final int notAddressed;

  factory WorkingGroupSummary.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) throw FormatException('Invalid $key');
      return value;
    }

    final name = json['workingGroupName'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid working group name');
    }
    return WorkingGroupSummary(
      id: count('workingGroupId'),
      name: name,
      total: count('total'),
      solved: count('solved'),
      inProgress: count('inProgress'),
      notAddressed: count('notAddressed'),
    );
  }
}
