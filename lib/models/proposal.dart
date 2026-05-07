class Proposal {
  final String id;
  final String cooperativeId;
  final String title;
  final String? description;
  final String? supplier;
  final double? estimatedCost;
  final DateTime voteDeadline;
  final String status;
  final int yesCount;
  final int noCount;
  final int abstainCount;
  final String? resultTxHash;
  final String? createdByName;
  final DateTime createdAt;
  final String? myVote; // vote de l'utilisateur connecté
  final String? myVoteTxHash;

  Proposal({
    required this.id,
    required this.cooperativeId,
    required this.title,
    this.description,
    this.supplier,
    this.estimatedCost,
    required this.voteDeadline,
    required this.status,
    required this.yesCount,
    required this.noCount,
    required this.abstainCount,
    this.resultTxHash,
    this.createdByName,
    required this.createdAt,
    this.myVote,
    this.myVoteTxHash,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      title: json['title'],
      description: json['description'],
      supplier: json['supplier'],
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : null,
      voteDeadline: DateTime.parse(json['vote_deadline']),
      status: json['status'] ?? 'open',
      yesCount: json['yes_count'] ?? 0,
      noCount: json['no_count'] ?? 0,
      abstainCount: json['abstain_count'] ?? 0,
      resultTxHash: json['result_tx_hash'],
      createdByName: json['profiles']?['display_name'],
      createdAt: DateTime.parse(json['created_at']),
      myVote: json['my_vote'],
      myVoteTxHash: json['my_vote_tx_hash'],
    );
  }

  int get totalVotes => yesCount + noCount + abstainCount;
  bool get isOpen => status == 'open' && voteDeadline.isAfter(DateTime.now());
  bool get isClosed => !isOpen;
  bool get hasVoted => myVote != null;

  double get yesPercent => totalVotes == 0 ? 0 : (yesCount / totalVotes) * 100;
  double get noPercent => totalVotes == 0 ? 0 : (noCount / totalVotes) * 100;
}
