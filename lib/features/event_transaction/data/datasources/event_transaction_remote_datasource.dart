import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../event/data/event_model.dart';
import '../models/event_transaction_model.dart';

class EventTransactionRemoteDataSource {
  final SupabaseClient client;
  EventTransactionRemoteDataSource(this.client);

  String get _currentUserId {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login kembali.');
    }
    return uid;
  }

  /// Ambil event milik user dengan syarat: is_favorite = true AND is_visited = true
  Future<List<EventModel>> getEligibleEvents() async {
    final res = await client
        .from('events')
        .select()
        .eq('user_id', _currentUserId)
        .eq('is_favorite', true)
        .eq('is_visited', true)
        .order('event_date', ascending: false);

    return (res as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil pocket tabungan aktif milik user
  Future<List<Map<String, dynamic>>> getAvailablePockets() async {
    final res = await client
        .from('savings_pockets')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Ambil daftar transaksi event beserta data relasi event dan pocket
  Future<List<EventTransactionModel>> getEventTransactions() async {
    final res = await client
        .from('savings_pocket_transactions')
        .select('*, events(id, name, location, event_date, image_url), savings_pockets(id, name, current_amount)')
        .eq('user_id', _currentUserId)
        .eq('entry_source', 'event')
        .order('transaction_date', ascending: false);

    return (res as List)
        .map((e) => EventTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Panggil RPC atomik PostgreSQL: create_event_transaction
  Future<void> addEventTransaction({
    required String eventId,
    required String pocketId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
    String? idempotencyKey,
  }) async {
    await client.rpc('create_event_transaction', params: {
      'p_event_id': eventId,
      'p_pocket_id': pocketId,
      'p_amount': amount,
      'p_transaction_date': transactionDate.toIso8601String(),
      'p_notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'p_idempotency_key': idempotencyKey,
    });
  }

  /// Panggil RPC atomik PostgreSQL: update_event_transaction
  Future<void> updateEventTransaction({
    required String transactionId,
    required String newEventId,
    required String newPocketId,
    required double newAmount,
    required DateTime newTransactionDate,
    String? newNotes,
  }) async {
    await client.rpc('update_event_transaction', params: {
      'p_transaction_id': transactionId,
      'p_new_event_id': newEventId,
      'p_new_pocket_id': newPocketId,
      'p_new_amount': newAmount,
      'p_new_transaction_date': newTransactionDate.toIso8601String(),
      'p_new_notes': (newNotes == null || newNotes.trim().isEmpty) ? null : newNotes.trim(),
    });
  }

  /// Panggil RPC atomik PostgreSQL: delete_event_transaction
  Future<void> deleteEventTransaction(String transactionId) async {
    await client.rpc('delete_event_transaction', params: {
      'p_transaction_id': transactionId,
    });
  }
}
