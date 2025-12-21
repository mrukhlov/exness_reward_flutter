class Event {
  final String id;
  final String title;
  final String description;
  final String date; // YYYY-MM-DD format
  final String startTime; // HH:MM format
  final String endTime; // HH:MM format
  final EventType type;
  final String color; // Hex color code
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.color,
    required this.location,
    required this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String? ?? json['start_time'] as String,
      endTime: json['endTime'] as String? ?? json['end_time'] as String,
      type: _parseEventType(json['type']),
      color: json['color'] as String? ?? '#3b82f6',
      location: json['location'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'type': type.toString().split('.').last,
      'color': color,
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
  }

  static EventType _parseEventType(dynamic value) {
    if (value == null) return EventType.corporate;
    final str = value.toString().toLowerCase();
    return str == 'community' ? EventType.community : EventType.corporate;
  }
}

enum EventType { corporate, community }
