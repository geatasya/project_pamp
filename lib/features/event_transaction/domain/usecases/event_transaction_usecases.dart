import '../../../event/domain/event_entity.dart';
import '../entities/event_transaction_entity.dart';
import '../repositories/event_transaction_repository.dart';

class GetEligibleEvents {
  final EventTransactionRepository repository;
  GetEligibleEvents(this.repository);

  Future<List<EventEntity>> call() => repository.getEligibleEvents();
}

class GetAvailablePockets {
  final EventTransactionRepository repository;
  GetAvailablePockets(this.repository);

  Future<List<Map<String, dynamic>>> call() => repository.getAvailablePockets();
}

class GetEventTransactions {
  final EventTransactionRepository repository;
  GetEventTransactions(this.repository);

  Future<List<EventTransactionEntity>> call() => repository.getEventTransactions();
}

class AddEventTransaction {
  final EventTransactionRepository repository;
  AddEventTransaction(this.repository);

  Future<void> call({
    required String eventId,
    required String pocketId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    String? idempotencyKey,
  }) =>
      repository.addEventTransaction(
        eventId: eventId,
        pocketId: pocketId,
        amount: amount,
        transactionDate: transactionDate,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
}

class UpdateEventTransaction {
  final EventTransactionRepository repository;
  UpdateEventTransaction(this.repository);

  Future<void> call({
    required String transactionId,
    required String newEventId,
    required String newPocketId,
    required double newAmount,
    required DateTime newTransactionDate,
    String? newNotes,
  }) =>
      repository.updateEventTransaction(
        transactionId: transactionId,
        newEventId: newEventId,
        newPocketId: newPocketId,
        newAmount: newAmount,
        newTransactionDate: newTransactionDate,
        newNotes: newNotes,
      );
}

class DeleteEventTransaction {
  final EventTransactionRepository repository;
  DeleteEventTransaction(this.repository);

  Future<void> call(String transactionId) =>
      repository.deleteEventTransaction(transactionId);
}
