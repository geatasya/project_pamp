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
}
