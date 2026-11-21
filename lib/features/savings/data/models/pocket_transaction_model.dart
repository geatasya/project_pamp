import '../../domain/entities/pocket_transaction_entity.dart';

class PocketTransactionModel extends PocketTransactionEntity {
  const PocketTransactionModel({
    required super.id,
    required super.pocketId,
    required super.userId,
    super.eventId,
    required super.transactionType,
    required super.entrySource,
    required super.amount,
    super.notes,
    required super.transactionDate,
    required super.createdAt,
    super.pocketName,
    super.eventName,
  });

  factory PocketTransactionModel.fromJson(Map<String, dynamic> j) {
    final eventMap = j['events'] is Map<String, dynamic> ? j['events'] as Map<String, dynamic> : null;
    final pocketMap = j['savings_pockets'] is Map<String, dynamic> ? j['savings_pockets'] as Map<String, dynamic> : null;

    final parsedAmount = (j['amount'] is num)
        ? (j['amount'] as num).toDouble()
        : double.tryParse(j['amount']?.toString() ?? '0') ?? 0.0;

    DateTime txDate;
    try {
      txDate = DateTime.parse(j['transaction_date'].toString());
    } catch (_) {
      txDate = DateTime.now();
    }

    DateTime crDate;
    try {
      crDate = DateTime.parse(j['created_at'].toString());
    } catch (_) {
      crDate = DateTime.now();
    }

    return PocketTransactionModel(
      id: j['id']?.toString() ?? '',
      pocketId: j['pocket_id']?.toString() ?? '',
      userId: j['user_id']?.toString() ?? '',
      eventId: j['event_id']?.toString(),
      transactionType: j['transaction_type']?.toString() ?? 'deposit',
      entrySource: j['entry_source']?.toString() ?? 'manual',
      amount: parsedAmount,
      notes: j['notes']?.toString(),
      transactionDate: txDate,
      createdAt: crDate,
      pocketName: pocketMap?['name']?.toString() ?? j['pocket_name']?.toString(),
      eventName: eventMap?['name']?.toString() ?? j['event_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pocket_id': pocketId,
        'user_id': userId,
        'event_id': eventId,
        'transaction_type': transactionType,
        'entry_source': entrySource,
        'amount': amount,
        'notes': notes,
        'transaction_date': transactionDate.toIso8601String(),
      };
}
