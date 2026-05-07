class Contribution {
  final String id;
  final String cooperativeId;
  final String userId;
  final double amount;
  final String paymentMethod;
  final String? txHash;
  final String blockchainStatus;
  final String? note;
  final DateTime createdAt;
  final String? memberName; // jointure profiles

  Contribution({
    required this.id,
    required this.cooperativeId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.txHash,
    required this.blockchainStatus,
    this.note,
    required this.createdAt,
    this.memberName,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      cooperativeId: json['cooperative_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] ?? 'mobile_money',
      txHash: json['tx_hash'],
      blockchainStatus: json['blockchain_status'] ?? 'pending',
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      memberName: json['profiles']?['display_name'],
    );
  }

  bool get isConfirmed => blockchainStatus == 'confirmed';
  bool get isPending => blockchainStatus == 'pending';
}
