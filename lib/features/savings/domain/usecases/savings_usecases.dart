import '../entities/pocket_transaction_entity.dart';
import '../entities/savings_pocket_entity.dart';
import '../repositories/savings_repository.dart';

class GetSavingsPockets {
  final SavingsRepository repository;
  GetSavingsPockets(this.repository);
  Future<List<SavingsPocketEntity>> call() => repository.getPockets();
}

class GetPocketTransactions {
  final SavingsRepository repository;
  GetPocketTransactions(this.repository);
  Future<List<PocketTransactionEntity>> call() => repository.getTransactions();
}

class CreatePocket {
  final SavingsRepository repository;
  CreatePocket(this.repository);
  Future<void> call({required String name, required double targetAmount}) =>
      repository.createPocket(name: name, targetAmount: targetAmount);
}

class UpdatePocket {
  final SavingsRepository repository;
  UpdatePocket(this.repository);
  Future<void> call({required String id, required String name, required double targetAmount}) =>
      repository.updatePocket(id: id, name: name, targetAmount: targetAmount);
}

class DeletePocket {
  final SavingsRepository repository;
  DeletePocket(this.repository);
  Future<void> call(String id) => repository.deletePocket(id);
}

class AddPocketTransaction {
  final SavingsRepository repository;
  AddPocketTransaction(this.repository);
  Future<void> call({
    required String pocketId,
    required String type,
    required double amount,
    required DateTime date,
    String? notes,
    String? idempotencyKey,
  }) =>
      repository.addTransaction(
        pocketId: pocketId,
        type: type,
        amount: amount,
        date: date,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
}
