import 'dart:typed_data';
import '../domain/event_entity.dart';
import '../domain/event_repository.dart';
import 'event_model.dart';
import 'event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remote;
  EventRepositoryImpl(this.remote);

  @override
  Future<List<EventEntity>> getEvents() => remote.getEvents();

  @override
  Future<void> addEvent(EventEntity e) => remote.addEvent(EventModel.fromEntity(e));

  @override
  Future<void> updateEvent(EventEntity e) =>
      remote.updateEvent(EventModel.fromEntity(e));

  @override
  Future<void> deleteEvent(String id) => remote.deleteEvent(id);

  @override
  Future<String> uploadPoster(Uint8List bytes, String ext) =>
      remote.uploadPoster(bytes, ext);
}
