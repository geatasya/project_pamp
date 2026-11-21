class PocketTransactionEntity {
  final String id;
  final String pocketId;
  final String userId;
  final String? eventId;
  final String transactionType; // 'deposit' | 'withdraw'
  final String entrySource; // 'manual' | 'event'
  final double amount;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;

  // Joined fields
  final String? pocketName;
  final String? eventName;

  const PocketTransactionEntity({
    required this.id,
    required this.pocketId,
    required this.userId,
    this.eventId,
    required this.transactionType,
    required this.entrySource,
    required this.amount,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    this.pocketName,
    this.eventName,
  });

  bool get isDeposit => transactionType == 'deposit';
  bool get isFromEvent => entrySource == 'event';
}
