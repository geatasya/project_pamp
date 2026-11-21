class EventTransactionEntity {
  final String id;
  final String userId;
  final String pocketId;
  final String eventId;
  final String transactionType; // 'withdraw'
  final String entrySource; // 'event'
  final double amount;
  final String? notes;
  final DateTime transactionDate;
  final DateTime? createdAt;

  // Joined relational data
  final String? eventName;
  final String? eventLocation;
  final DateTime? eventDate;
  final String? eventImageUrl;
  final String? pocketName;

  const EventTransactionEntity({
    required this.id,
    required this.userId,
    required this.pocketId,
    required this.eventId,
    this.transactionType = 'withdraw',
    this.entrySource = 'event',
    required this.amount,
    this.notes,
    required this.transactionDate,
    this.createdAt,
    this.eventName,
    this.eventLocation,
    this.eventDate,
    this.eventImageUrl,
    this.pocketName,
  });

  EventTransactionEntity copyWith({
    String? id,
    String? userId,
    String? pocketId,
    String? eventId,
    String? transactionType,
    String? entrySource,
    double? amount,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? eventName,
    String? eventLocation,
    DateTime? eventDate,
    String? eventImageUrl,
    String? pocketName,
  }) {
    return EventTransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pocketId: pocketId ?? this.pocketId,
      eventId: eventId ?? this.eventId,
      transactionType: transactionType ?? this.transactionType,
      entrySource: entrySource ?? this.entrySource,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      eventName: eventName ?? this.eventName,
      eventLocation: eventLocation ?? this.eventLocation,
      eventDate: eventDate ?? this.eventDate,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      pocketName: pocketName ?? this.pocketName,
    );
  }
}
