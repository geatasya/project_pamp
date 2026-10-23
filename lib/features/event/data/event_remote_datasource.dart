import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_model.dart';

class EventRemoteDataSource {
  final SupabaseClient client;
  EventRemoteDataSource(this.client);

  Future<List<EventModel>> getEvents() async {
    final res = await client
        .from('events')
        .select()
        .order('event_date', ascending: true);
    return (res as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addEvent(EventModel m) async {
    await client.from('events').insert(m.toJson());
  }

  Future<void> updateEvent(EventModel m) async {
    await client.from('events').update(m.toJson()).eq('id', m.id!);
  }

  Future<void> deleteEvent(String id) async {
    await client.from('events').delete().eq('id', id);
  }

  /// Upload poster ke Supabase Storage (bucket "posters"), return URL publik.
  Future<String> uploadPoster(Uint8List bytes, String ext) async {
    final uid = client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mime = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await client.storage
        .from('posters')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    return client.storage.from('posters').getPublicUrl(path);
  }
}
