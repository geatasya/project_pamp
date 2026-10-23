import 'dart:typed_data';
import '../event_entity.dart';
import '../event_repository.dart';

class GetEvents {
  final EventRepository repo;
  GetEvents(this.repo);
  Future<List<EventEntity>> call() => repo.getEvents();
}

class AddEvent {
  final EventRepository repo;
  AddEvent(this.repo);
  Future<void> call(EventEntity e) => repo.addEvent(e);
}

class UpdateEvent {
  final EventRepository repo;
  UpdateEvent(this.repo);
  Future<void> call(EventEntity e) => repo.updateEvent(e);
}

class DeleteEvent {
  final EventRepository repo;
  DeleteEvent(this.repo);
  Future<void> call(String id) => repo.deleteEvent(id);
}

class UploadPoster {
  final EventRepository repo;
  UploadPoster(this.repo);
  Future<String> call(Uint8List bytes, String ext) =>
      repo.uploadPoster(bytes, ext);
}
