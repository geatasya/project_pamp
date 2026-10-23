import '../domain/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    super.id,
    required super.name,
    required super.date,
    super.endDate,
    super.startTime,
    super.endTime,
    super.doorTime,
    required super.location,
    super.address,
    super.eventType,
    super.category,
    super.description,
    super.lineup,
    super.ticketUrl,
    super.ticketTier,
    super.priceFrom,
    super.savedAmount,
    super.notes,
    super.checklist,
    super.imageUrl,
    super.isVisited,
    super.isFavorite,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: j['id'] as String,
        name: j['name'] as String,
        date: DateTime.parse(j['event_date'] as String),
        endDate: j['end_date'] == null
            ? null
            : DateTime.parse(j['end_date'] as String),
        startTime: j['start_time'] as String?,
        endTime: j['end_time'] as String?,
        doorTime: j['door_time'] as String?,
        location: j['location'] as String,
        address: j['address'] as String?,
        eventType: j['event_type'] as String?,
        category: j['category'] as String?,
        description: j['description'] as String?,
        lineup: j['lineup'] as String?,
        ticketUrl: j['ticket_url'] as String?,
        ticketTier: j['ticket_tier'] as String?,
        priceFrom: (j['price_from'] as num?)?.toInt(),
        savedAmount: (j['saved_amount'] as num?)?.toInt(),
        notes: j['notes'] as String?,
        checklist: j['checklist'] as String?,
        imageUrl: j['image_url'] as String?,
        isVisited: (j['is_visited'] as bool?) ?? false,
        isFavorite: (j['is_favorite'] as bool?) ?? false,
      );

  factory EventModel.fromEntity(EventEntity e) => EventModel(
        id: e.id,
        name: e.name,
        date: e.date,
        endDate: e.endDate,
        startTime: e.startTime,
        endTime: e.endTime,
        doorTime: e.doorTime,
        location: e.location,
        address: e.address,
        eventType: e.eventType,
        category: e.category,
        description: e.description,
        lineup: e.lineup,
        ticketUrl: e.ticketUrl,
        ticketTier: e.ticketTier,
        priceFrom: e.priceFrom,
        savedAmount: e.savedAmount,
        notes: e.notes,
        checklist: e.checklist,
        imageUrl: e.imageUrl,
        isVisited: e.isVisited,
        isFavorite: e.isFavorite,
      );

  static String? _n(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
  static String _d(DateTime d) => d.toIso8601String().split('T').first;

  // user_id diisi otomatis oleh database (default auth.uid())
  Map<String, dynamic> toJson() => {
        'name': name,
        'event_date': _d(date),
        'end_date': endDate == null ? null : _d(endDate!),
        'start_time': _n(startTime),
        'end_time': _n(endTime),
        'door_time': _n(doorTime),
        'location': location,
        'address': _n(address),
        'event_type': _n(eventType),
        'category': _n(category),
        'description': _n(description),
        'lineup': _n(lineup),
        'ticket_url': _n(ticketUrl),
        'ticket_tier': _n(ticketTier),
        'price_from': priceFrom,
        'saved_amount': savedAmount,
        'notes': _n(notes),
        'checklist': _n(checklist),
        'image_url': _n(imageUrl),
        'is_visited': isVisited,
        'is_favorite': isFavorite,
      };
}
