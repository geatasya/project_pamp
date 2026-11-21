import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pocket_transaction_model.dart';
import '../models/savings_pocket_model.dart';

class SavingsRemoteDataSource {
  final SupabaseClient client;
  SavingsRemoteDataSource(this.client);

  String get _currentUserId {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Sesi pengguna tidak ditemukan. Silakan login kembali.');
    }
    return uid;
  }

  Future<List<SavingsPocketModel>> getPockets() async {
    final res = await client
        .from('savings_pockets')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: true);

    return (res as List)
        .map((e) => SavingsPocketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PocketTransactionModel>> getTransactions() async {
    final res = await client
        .from('savings_pocket_transactions')
        .select('*, events(id, name), savings_pockets(id, name)')
        .eq('user_id', _currentUserId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PocketTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPocket({
    required String name,
    required double targetAmount,
  }) async {
    await client.from('savings_pockets').insert({
      'user_id': _currentUserId,
      'name': name.trim(),
      'target_amount': targetAmount,
      'current_amount': 0,
    });
  }

  Future<void> updatePocket({
    required String id,
    required String name,
    required double targetAmount,
  }) async {
    await client
        .from('savings_pockets')
        .update({
          'name': name.trim(),
          'target_amount': targetAmount,
        })
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }

  Future<void> deletePocket(String id) async {
    await client
        .from('savings_pockets')
        .delete()
        .eq('id', id)
        .eq('user_id', _currentUserId);
  }

  /// Panggil RPC atomik PostgreSQL: create_manual_pocket_transaction
  Future<void> addTransaction({
    required String pocketId,
    required String type,
    required double amount,
    required DateTime date,
    String? notes,
    String? idempotencyKey,
  }) async {
    await client.rpc('create_manual_pocket_transaction', params: {
      'p_pocket_id': pocketId,
      'p_transaction_type': type,
      'p_amount': amount,
      'p_transaction_date': date.toIso8601String(),
      'p_notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'p_idempotency_key': idempotencyKey,
    });
  }
}
