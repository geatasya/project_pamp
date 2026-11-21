import '../../domain/entities/event_transaction_entity.dart';

class EventTransactionModel extends EventTransactionEntity {
  const EventTransactionModel({
    required super.id,
    required super.userId,
    required super.pocketId,
    required super.eventId,
    super.transactionType = 'withdraw',
    super.entrySource = 'event',
    required super.amount,
    super.notes,
    required super.transactionDate,
    super.createdAt,
    super.eventName,
    super.eventLocation,
    super.eventDate,
    super.eventImageUrl,
    super.pocketName,
  });

  factory EventTransactionModel.fromJson(Map<String, dynamic> j) {
    // Tangani nested join dari PostgREST (events dan savings_pockets)
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

    DateTime? crDate;
    if (j['created_at'] != null) {
      try {
        crDate = DateTime.parse(j['created_at'].toString());
      } catch (_) {}
    }

    DateTime? evDate;
    if (eventMap?['event_date'] != null) {
      try {
        evDate = DateTime.parse(eventMap!['event_date'].toString());
      } catch (_) {}
    }

    return EventTransactionModel(
      id: j['id']?.toString() ?? '',
      userId: j['user_id']?.toString() ?? '',
      pocketId: j['pocket_id']?.toString() ?? '',
      eventId: j['event_id']?.toString() ?? '',
      transactionType: j['transaction_type']?.toString() ?? 'withdraw',
      entrySource: j['entry_source']?.toString() ?? 'event',
      amount: parsedAmount,
      notes: j['notes']?.toString(),
      transactionDate: txDate,
      createdAt: crDate,
      eventName: eventMap?['name']?.toString() ?? j['event_name']?.toString(),
      eventLocation: eventMap?['location']?.toString(),
      eventDate: evDate,
      eventImageUrl: eventMap?['image_url']?.toString(),
      pocketName: pocketMap?['name']?.toString() ?? j['pocket_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'pocket_id': pocketId,
        'event_id': eventId,
        'transaction_type': transactionType,
        'entry_source': entrySource,
        'amount': amount,
        'notes': notes,
        'transaction_date': transactionDate.toIso8601String(),
      };
}
