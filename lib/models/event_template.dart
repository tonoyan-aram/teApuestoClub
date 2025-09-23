import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/utils/text_utils.dart';

class EventTemplate {
  final String id;
  final String name;
  final String title;
  final String? note;
  final int rating;
  final String? imageUrl;
  final EventCategory category;
  final bool isPredefined; // Whether this is a built-in template
  final String? description; // Optional description for the template

  EventTemplate({
    required this.id,
    required String name,
    required String title,
    String? note,
    this.rating = 3,
    this.imageUrl,
    this.category = EventCategory.other,
    this.isPredefined = false,
    String? description,
  }) : name = TextUtils.safeDisplayText(name),
       title = TextUtils.safeDisplayText(title),
       note = note != null ? TextUtils.safeDisplayText(note) : null,
       description = description != null ? TextUtils.safeDisplayText(description) : null;

  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      id: TextUtils.safeDisplayText(json['id']),
      name: TextUtils.safeDisplayText(json['name']),
      title: TextUtils.safeDisplayText(json['title']),
      note: TextUtils.safeDisplayText(json['note']),
      rating: json['rating'] ?? 3,
      imageUrl: json['imageUrl'],
      category: EventCategory.values.firstWhere(
        (e) => e.toString() == 'EventCategory.' + json['category'],
        orElse: () => EventCategory.other,
      ),
      isPredefined: json['isPredefined'] ?? false,
      description: TextUtils.safeDisplayText(json['description']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'note': note,
      'rating': rating,
      'imageUrl': imageUrl,
      'category': category.name,
      'isPredefined': isPredefined,
      'description': description,
    };
  }

  // Helper to create a copy with updated values
  EventTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? note,
    int? rating,
    String? imageUrl,
    EventCategory? category,
    bool? isPredefined,
    String? description,
  }) {
    return EventTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      note: note ?? this.note,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isPredefined: isPredefined ?? this.isPredefined,
      description: description ?? this.description,
    );
  }

  // Convert template to Event (for creating events from templates)
  Event toEvent() {
    return Event(
      id: '', // Will be generated when saving
      title: title,
      date: DateTime.now(), // Will be set by user
      note: note,
      rating: rating,
      imageUrl: imageUrl,
      isFavorite: false,
      category: category,
    );
  }
}

