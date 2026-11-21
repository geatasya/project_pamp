import '../../domain/entities/pocket_transaction_entity.dart';
import '../../domain/entities/savings_pocket_entity.dart';
import '../../domain/repositories/savings_repository.dart';
import '../datasources/savings_remote_datasource.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  final SavingsRemoteDataSource remote;
  SavingsRepositoryImpl(this.remote);

  @override
  Future<List<SavingsPocketEntity>> getPockets() => remote.getPockets();

  @override
  Future<List<PocketTransactionEntity>> getTransactions() =>
      remote.getTransactions();

  @override
  Future<void> createPocket({
    required String name,
    required double targetAmount,
  }) =>
      remote.createPocket(name: name, targetAmount: targetAmount);

  @override
  Future<void> updatePocket({
    required String id,
    required String name,
    required double targetAmount,
  }) =>
      remote.updatePocket(id: id, name: name, targetAmount: targetAmount);

  @override
  Future<void> deletePocket(String id) => remote.deletePocket(id);

  @override
  Future<void> addTransaction({
    required String pocketId,
    required String type,
    required double amount,
    required DateTime date,
    String? notes,
    String? idempotencyKey,
  }) =>
      remote.addTransaction(
        pocketId: pocketId,
        type: type,
        amount: amount,
        date: date,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
}
