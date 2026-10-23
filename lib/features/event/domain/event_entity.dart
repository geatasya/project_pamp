const eventTypes = ['Festival Musik', 'Konser Solo', 'World Tour'];
const eventGenres = [
  'Pop',
  'Rock',
  'Indie/Alt',
  'Electronic',
  'Jazz',
  'K-Pop',
  'Hip-Hop',
];
const ticketTiers = [
  'Early Bird',
  'Presale 1',
  'Presale 2',
  'Reguler',
  'On The Spot',
];

List<String> _split(String? s) => (s ?? '')
    .split(RegExp(r'[,\n]'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

class EventEntity {
  final String? id;
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final String? startTime; // "HH:mm"
  final String? endTime;
  final String? doorTime;
  final String location;
  final String? address;
  final String? eventType;
  final String? category; // genre, dipisah koma
  final String? description;
  final String? lineup; // dipisah koma
  final String? ticketUrl;
  final String? ticketTier;
  final int? priceFrom;
  final int? savedAmount;
  final String? notes;
  final String? checklist; // dipisah koma
  final String? imageUrl;
  final bool isVisited;
  final bool isFavorite;

  const EventEntity({
    this.id,
    required this.name,
    required this.date,
    this.endDate,
    this.startTime,
    this.endTime,
    this.doorTime,
    required this.location,
    this.address,
    this.eventType,
    this.category,
    this.description,
    this.lineup,
    this.ticketUrl,
    this.ticketTier,
    this.priceFrom,
    this.savedAmount,
    this.notes,
    this.checklist,
    this.imageUrl,
    this.isVisited = false,
    this.isFavorite = false,
  });

  DateTime get lastDate => endDate ?? date;
  List<String> get genreList => _split(category);
  List<String> get lineupList => _split(lineup);
  List<String> get checklistList => _split(checklist);

  int get dayCount {
    final e = endDate;
    if (e == null) return 1;
    final d = DateTime.utc(e.year, e.month, e.day)
            .difference(DateTime.utc(date.year, date.month, date.day))
            .inDays +
        1;
    return d < 1 ? 1 : d;
  }

  EventEntity copyWith({bool? isVisited, bool? isFavorite}) => EventEntity(
        id: id,
        name: name,
        date: date,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        doorTime: doorTime,
        location: location,
        address: address,
        eventType: eventType,
        category: category,
        description: description,
        lineup: lineup,
        ticketUrl: ticketUrl,
        ticketTier: ticketTier,
        priceFrom: priceFrom,
        savedAmount: savedAmount,
        notes: notes,
        checklist: checklist,
        imageUrl: imageUrl,
        isVisited: isVisited ?? this.isVisited,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
