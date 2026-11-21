import '../entities/pocket_transaction_entity.dart';
import '../entities/savings_pocket_entity.dart';

abstract class SavingsRepository {
  Future<List<SavingsPocketEntity>> getPockets();
  Future<List<PocketTransactionEntity>> getTransactions();
  Future<void> createPocket({required String name, required double targetAmount});
  Future<void> updatePocket({required String id, required String name, required double targetAmount});
  Future<void> deletePocket(String id);
  Future<void> addTransaction({
    required String pocketId,
    required String type, // 'deposit' | 'withdraw'
    required double amount,
    required DateTime date,
    String? notes,
    String? idempotencyKey,
  });
}
