import 'dart:math';
import 'package:flutter/material.dart';
import '../../../event/domain/event_entity.dart';
import '../../domain/entities/event_transaction_entity.dart';
import '../../domain/usecases/event_transaction_usecases.dart';

class EventTransactionProvider extends ChangeNotifier {
  final GetEligibleEvents _getEligibleEvents;
  final GetAvailablePockets _getAvailablePockets;
  final GetEventTransactions _getEventTransactions;
  final AddEventTransaction _addEventTransaction;
  final UpdateEventTransaction _updateEventTransaction;
  final DeleteEventTransaction _deleteEventTransaction;

  EventTransactionProvider({
    required GetEligibleEvents getEligibleEvents,
    required GetAvailablePockets getAvailablePockets,
    required GetEventTransactions getEventTransactions,
    required AddEventTransaction addEventTransaction,
    required UpdateEventTransaction updateEventTransaction,
    required DeleteEventTransaction deleteEventTransaction,
  })  : _getEligibleEvents = getEligibleEvents,
        _getAvailablePockets = getAvailablePockets,
        _getEventTransactions = getEventTransactions,
        _addEventTransaction = addEventTransaction,
        _updateEventTransaction = updateEventTransaction,
        _deleteEventTransaction = deleteEventTransaction;

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<EventTransactionEntity> _transactions = [];
  List<EventEntity> _eligibleEvents = [];
  List<Map<String, dynamic>> _pockets = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<EventTransactionEntity> get transactions => _transactions;
  List<EventEntity> get eligibleEvents => _eligibleEvents;
  List<Map<String, dynamic>> get pockets => _pockets;

  List<EventTransactionEntity> get filteredTransactions {
    if (_searchQuery.trim().isEmpty) return _transactions;
    final q = _searchQuery.trim().toLowerCase();
    return _transactions.where((t) {
      final evName = (t.eventName ?? '').toLowerCase();
      final pName = (t.pocketName ?? '').toLowerCase();
      final notes = (t.notes ?? '').toLowerCase();
      return evName.contains(q) || pName.contains(q) || notes.contains(q);
    }).toList();
  }

  double get totalExpense {
    return _transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  String _cleanMsg(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '').replaceAll('PostgrestException(message: ', '').replaceAll(')', '');
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getEventTransactions(),
        _getEligibleEvents(),
        _getAvailablePockets(),
      ]);

      _transactions = List<EventTransactionEntity>.from(results[0] as List);
      _eligibleEvents = List<EventEntity>.from(results[1] as List);
      _pockets = List<Map<String, dynamic>>.from(results[2] as List);
      _error = null;
    } catch (e) {
      _error = _cleanMsg(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String generateIdempotencyKey() {
    final rand = Random().nextInt(999999);
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'tx_evt_${ts}_$rand';
  }

  Future<bool> createTransaction({
    required String eventId,
    required String pocketId,
    required double amount,
    required DateTime transactionDate,
    String? notes,
  }) async {
    _error = null;
    try {
      final key = generateIdempotencyKey();
      await _addEventTransaction(
        eventId: eventId,
        pocketId: pocketId,
        amount: amount,
        transactionDate: transactionDate,
        notes: notes,
        idempotencyKey: key,
      );
      await fetchAll();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String transactionId,
    required String newEventId,
    required String newPocketId,
    required double newAmount,
    required DateTime newTransactionDate,
    String? newNotes,
  }) async {
    _error = null;
    try {
      await _updateEventTransaction(
        transactionId: transactionId,
        newEventId: newEventId,
        newPocketId: newPocketId,
        newAmount: newAmount,
        newTransactionDate: newTransactionDate,
        newNotes: newNotes,
      );
      await fetchAll();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    _error = null;
    try {
      await _deleteEventTransaction(transactionId);
      await fetchAll();
      return true;
    } catch (e) {
      _error = _cleanMsg(e);
      notifyListeners();
      return false;
    }
  }
}
