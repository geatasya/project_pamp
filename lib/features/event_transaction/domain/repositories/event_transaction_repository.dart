import '../../../event/domain/event_entity.dart';
import '../entities/event_transaction_entity.dart';

abstract class EventTransactionRepository {
  /// Ambil event milik user yang berstatus wishlist (is_favorite = true) dan sudah dikunjungi (is_visited = true)
  Future<List<EventEntity>> getEligibleEvents();

  /// Ambil pocket tabungan milik user untuk opsi sumber dana
  Future<List<Map<String, dynamic>>> getAvailablePockets();

  /// Ambil seluruh riwayat transaksi pengeluaran event milik user
  Future<List<EventTransactionEntity>> getEventTransactions();

  /// Catat pengeluaran event secara atomik via RPC PostgreSQL
  Future<void> addEventTransaction({
    required String eventId,
    required String pocketId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    String? idempotencyKey,
  });

  /// Update transaksi pengeluaran event secara atomik via RPC PostgreSQL
  Future<void> updateEventTransaction({
    required String transactionId,
    required String newEventId,
    required String newPocketId,
    required double newAmount,
    required DateTime newTransactionDate,
    String? newNotes,
  });

  /// Hapus transaksi pengeluaran event dan rollback saldo secara atomik via RPC PostgreSQL
  Future<void> deleteEventTransaction(String transactionId);

  /// Catat otomatis pengeluaran ketika konser ditandai dikunjungi (Skenario B)
  Future<Map<String, dynamic>?> autoRecordExpenseForEvent({
    required EventEntity event,
  });
}
