class Cooperative {
  final String id;
  final String name;
  final String? description;
  final double goalAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String status;
  final String? txHash;
  final DateTime createdAt;
  final double progressPercent;
  final int memberCount;
  final int contributionCount;

  Cooperative({
    required this.id,
    required this.name,
    this.description,
    required this.goalAmount,
    required this.currentAmount,
    this.deadline,
    required this.status,
    this.txHash,
    required this.createdAt,
    required this.progressPercent,
    required this.memberCount,
    required this.contributionCount,
  });

  factory Cooperative.fromJson(Map<String, dynamic> json) {
    return Cooperative(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      goalAmount: (json['goal_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num? ?? 0).toDouble(),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] as String? ?? 'active',
      txHash: json['tx_hash'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      progressPercent: (json['progress_percent'] as num? ?? 0).toDouble(),
      memberCount: (json['member_count'] as num? ?? 0).toInt(),
      contributionCount: (json['contribution_count'] as num? ?? 0).toInt(),
    );
  }

  // Helpers utiles dans l'UI
  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';
  double get remaining => goalAmount - currentAmount;
  bool get isDeadlinePassed =>
      deadline != null && deadline!.isBefore(DateTime.now());
}
