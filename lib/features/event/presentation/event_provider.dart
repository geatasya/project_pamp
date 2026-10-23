import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../domain/event_entity.dart';
import '../domain/usecases/event_usecases.dart';

enum EventFilter { semua, festival, solo, world, wishlist, dikunjungi }

enum SortMode { terdekat, terjauh, abjad }

String sortLabel(SortMode m) {
  switch (m) {
    case SortMode.terdekat:
      return 'Terdekat';
    case SortMode.terjauh:
      return 'Terjauh';
    case SortMode.abjad:
      return 'A - Z';
  }
}

class EventProvider extends ChangeNotifier {
  final GetEvents _get;
  final AddEvent _add;
  final UpdateEvent _update;
  final DeleteEvent _delete;
  final UploadPoster _upload;

  EventProvider(this._get, this._add, this._update, this._delete, this._upload);

  List<EventEntity> _all = [];
  bool isLoading = false;
  String? error;
  EventFilter filter = EventFilter.semua;
  SortMode sort = SortMode.terdekat;
  String query = '';

  List<EventEntity> get allEvents => _all;
  int get visitedCount => _all.where((e) => e.isVisited).length;
  int get favoriteCount => _all.where((e) => e.isFavorite).length;
  int get pendingCount => _all.length - visitedCount;

  List<EventEntity> get events {
    Iterable<EventEntity> list = _all;
    switch (filter) {
      case EventFilter.semua:
        break;
      case EventFilter.festival:
        list = list.where((e) => e.eventType == eventTypes[0]);
        break;
      case EventFilter.solo:
        list = list.where((e) => e.eventType == eventTypes[1]);
        break;
      case EventFilter.world:
        list = list.where((e) => e.eventType == eventTypes[2]);
        break;
      case EventFilter.wishlist:
        list = list.where((e) => e.isFavorite);
        break;
      case EventFilter.dikunjungi:
        list = list.where((e) => e.isVisited);
        break;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          (e.category ?? '').toLowerCase().contains(q) ||
          (e.lineup ?? '').toLowerCase().contains(q));
    }
    final out = list.toList();
    switch (sort) {
      case SortMode.terdekat:
        out.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortMode.terjauh:
        out.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortMode.abjad:
        out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return out;
  }

  EventEntity? byId(String id) {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  void setFilter(EventFilter f) {
    filter = f;
    notifyListeners();
  }

  void setSort(SortMode m) {
    sort = m;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void clear() {
    _all = [];
    filter = EventFilter.semua;
    sort = SortMode.terdekat;
    query = '';
    error = null;
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> fetchEvents() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _get();
    } catch (e) {
      error = _msg(e);
    }
    isLoading = false;
    notifyListeners();
  }

  /// Insert kalau id null, update kalau id ada.
  Future<bool> saveEvent(EventEntity e) async {
    try {
      if (e.id == null) {
        await _add(e);
      } else {
        await _update(e);
      }
      await fetchEvents();
      return true;
    } catch (err) {
      error = _msg(err);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _delete(id);
      await fetchEvents();
      return true;
    } catch (err) {
      error = _msg(err);
      notifyListeners();
      return false;
    }
  }

  // Update cepat (optimistic): tampilan berubah dulu, balik lagi kalau gagal.
  Future<void> _patch(EventEntity updated) async {
    final i = _all.indexWhere((x) => x.id == updated.id);
    if (i < 0) return;
    final old = _all[i];
    _all[i] = updated;
    notifyListeners();
    try {
      await _update(updated);
    } catch (err) {
      _all[i] = old;
      error = _msg(err);
      notifyListeners();
    }
  }

  Future<void> toggleVisited(EventEntity e) =>
      _patch(e.copyWith(isVisited: !e.isVisited));

  Future<void> toggleFavorite(EventEntity e) =>
      _patch(e.copyWith(isFavorite: !e.isFavorite));

  /// Return URL poster, atau null kalau gagal (pesan ada di [error]).
  Future<String?> uploadPoster(Uint8List bytes, String ext) async {
    try {
      return await _upload(bytes, ext);
    } catch (err) {
      error = _msg(err);
      notifyListeners();
      return null;
    }
  }
}
