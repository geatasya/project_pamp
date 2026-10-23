import 'dart:typed_data';
import 'event_entity.dart';

abstract class EventRepository {
  Future<List<EventEntity>> getEvents();
  Future<void> addEvent(EventEntity event);
  Future<void> updateEvent(EventEntity event);
  Future<void> deleteEvent(String id);
  Future<String> uploadPoster(Uint8List bytes, String ext);
}
