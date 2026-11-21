import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/pocket_transaction_entity.dart';
import '../../domain/entities/savings_pocket_entity.dart';
import '../../domain/usecases/savings_usecases.dart';

class SavingsProvider extends ChangeNotifier {
  final GetSavingsPockets _getPockets;
  final GetPocketTransactions _getTransactions;
  final CreatePocket _createPocket;
  final UpdatePocket _updatePocket;
  final DeletePocket _deletePocket;
  final AddPocketTransaction _addTransaction;

  SavingsProvider({
    required GetSavingsPockets getPockets,
    required GetPocketTransactions getTransactions,
    required CreatePocket createPocket,
    required UpdatePocket updatePocket,
    required DeletePocket deletePocket,
    required AddPocketTransaction addTransaction,
  })  : _getPockets = getPockets,
        _getTransactions = getTransactions,
        _createPocket = createPocket,
        _updatePocket = updatePocket,
        _deletePocket = deletePocket,
        _addTransaction = addTransaction;

  bool _isLoading = false;
  String? _error;

  List<SavingsPocketEntity> _pockets = [];
  List<PocketTransactionEntity> _transactions = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SavingsPocketEntity> get pockets => _pockets;
  List<PocketTransactionEntity> get transactions => _transactions;

  double get totalBalance => _pockets.fold<double>(0.0, (sum, p) => sum + p.currentAmount);
  double get totalTarget => _pockets.fold<double>(0.0, (sum, p) => sum + p.targetAmount);

  double get totalDeposit => _transactions
      .where((t) => t.isDeposit)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  double get totalWithdraw => _transactions
      .where((t) => !t.isDeposit)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  String _cleanMsg(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '').replaceAll('PostgrestException(message: ', '').replaceAll(')', '');
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getPockets(),
        _getTransactions(),
      ]);

      _pockets = results[0] as List<SavingsPocketEntity>;
      _transactions = results[1] as List<PocketTransactionEntity>;
      _error = null;
    } catch (e) {
      _error = _cleanMsg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _generateIdempotencyKey() {
    final rand = Random().nextInt(999999);
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'tx_sav_${ts}_$rand';
  }

  Future<bool> createNewPocket({
    required String name,
    required double targetAmount,
  }) async {
    _error = null;
    try {
      await _createPocket(name: name, targetAmount: targetAmount);
      await fetchData();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> editPocket({
    required String id,
    required String name,
    required double targetAmount,
  }) async {
    _error = null;
    try {
      await _updatePocket(id: id, name: name, targetAmount: targetAmount);
      await fetchData();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removePocket(String id) async {
    _error = null;
    try {
      await _deletePocket(id);
      await fetchData();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordTransaction({
    required String pocketId,
    required String type,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    _error = null;
    try {
      final key = _generateIdempotencyKey();
      await _addTransaction(
        pocketId: pocketId,
        type: type,
        amount: amount,
        date: date,
        notes: notes,
        idempotencyKey: key,
      );
      await fetchData();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }
}
