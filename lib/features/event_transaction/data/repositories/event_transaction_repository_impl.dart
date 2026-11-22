import '../../../event/domain/event_entity.dart';
import '../../domain/entities/event_transaction_entity.dart';
import '../../domain/repositories/event_transaction_repository.dart';
import '../datasources/event_transaction_remote_datasource.dart';

class EventTransactionRepositoryImpl implements EventTransactionRepository {
  final EventTransactionRemoteDataSource remote;
  EventTransactionRepositoryImpl(this.remote);

  @override
  Future<List<EventEntity>> getEligibleEvents() => remote.getEligibleEvents();

  @override
  Future<List<Map<String, dynamic>>> getAvailablePockets() =>
      remote.getAvailablePockets();

  @override
  Future<List<EventTransactionEntity>> getEventTransactions() =>
      remote.getEventTransactions();

  @override
  Future<void> addEventTransaction({
    required String eventId,
    required String pocketId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    String? idempotencyKey,
  }) =>
      remote.addEventTransaction(
        eventId: eventId,
        pocketId: pocketId,
        amount: amount,
        transactionDate: transactionDate,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> updateEventTransaction({
    required String transactionId,
    required String newEventId,
    required String newPocketId,
    required double newAmount,
    required DateTime newTransactionDate,
    String? newNotes,
  }) =>
      remote.updateEventTransaction(
        transactionId: transactionId,
        newEventId: newEventId,
        newPocketId: newPocketId,
        newAmount: newAmount,
        newTransactionDate: newTransactionDate,
        newNotes: newNotes,
      );

  @override
  Future<void> deleteEventTransaction(String transactionId) =>
      remote.deleteEventTransaction(transactionId);

  @override
  Future<Map<String, dynamic>?> autoRecordExpenseForEvent({
    required EventEntity event,
  }) async {
    if (event.id == null) return null;

    final alreadyExists = await remote.hasTransactionForEvent(event.id!);
    if (alreadyExists) return null;

    final amount = (event.priceFrom != null && event.priceFrom! > 0)
        ? event.priceFrom!.toDouble()
        : 500000.0;

    final pocket = await remote.ensurePocketForExpense(requiredAmount: amount);
    final pocketId = pocket['id'].toString();
    final pocketName = pocket['name']?.toString() ?? 'Tabungan Konser';

    final notes = 'Otomatis dicatat saat konser ditandai dikunjungi (Saldo diambil dari kantong: $pocketName)';
    final ts = DateTime.now().microsecondsSinceEpoch;
    final idempotencyKey = 'auto_tx_${event.id}_$ts';

    await remote.addEventTransaction(
      eventId: event.id!,
      pocketId: pocketId,
      amount: amount,
      transactionDate: DateTime.now(),
      notes: notes,
      idempotencyKey: idempotencyKey,
    );

    return {
      'pocketName': pocketName,
      'amount': amount,
    };
  }
}
