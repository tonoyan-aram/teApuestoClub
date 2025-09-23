import 'package:apuesto_club/models/recurrence_rule.dart';
import 'package:apuesto_club/utils/text_utils.dart';

enum EventCategory {
  football,
  basketball,
  tennis,
  marathon,
  other;

  String toDisplayString() {
    switch (this) {
      case EventCategory.football:
        return '⚽ Football';
      case EventCategory.basketball:
        return '🏀 Basketball';
      case EventCategory.tennis:
        return '🎾 Tennis';
      case EventCategory.marathon:
        return '🏃‍♂️ Marathon';
      case EventCategory.other:
        return '⚙️ Other';
    }
  }
}

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String? note;
  final int rating;
  final String? imageUrl;
  final bool isFavorite;
  final EventCategory category;
  final RecurrenceRule? recurrenceRule; // New field for recurrence
  final String? parentEventId; // ID of the original recurring event
  final bool isRecurringInstance; // Whether this is an instance of a recurring event

  Event({
    required this.id,
    required String title,
    required this.date,
    String? note,
    this.rating = 3,
    this.imageUrl,
    this.isFavorite = false,
    this.category = EventCategory.other,
    this.recurrenceRule,
    this.parentEventId,
    this.isRecurringInstance = false,
  }) : title = TextUtils.safeDisplayText(title),
       note = note != null ? TextUtils.safeDisplayText(note) : null;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: TextUtils.safeDisplayText(json['id']),
      title: TextUtils.safeDisplayText(json['title']),
      date: DateTime.parse(json['date']),
      note: TextUtils.safeDisplayText(json['note']),
      rating: json['rating'] ?? 3,
      imageUrl: json['imageUrl'],
      isFavorite: json['isFavorite'] ?? false,
      category: EventCategory.values.firstWhere(
          (e) => e.toString() == 'EventCategory.' + json['category'],
          orElse: () => EventCategory.other),
      recurrenceRule: json['recurrenceRule'] != null 
          ? RecurrenceRule.fromJson(json['recurrenceRule'])
          : null,
      parentEventId: json['parentEventId'],
      isRecurringInstance: json['isRecurringInstance'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'note': note,
      'rating': rating,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'category': category.name,
      'recurrenceRule': recurrenceRule?.toJson(),
      'parentEventId': parentEventId,
      'isRecurringInstance': isRecurringInstance,
    };
  }

  // Helper to create a copy with updated values
  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? note,
    int? rating,
    String? imageUrl,
    bool? isFavorite,
    EventCategory? category,
    RecurrenceRule? recurrenceRule,
    String? parentEventId,
    bool? isRecurringInstance,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      note: note ?? this.note,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentEventId: parentEventId ?? this.parentEventId,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
    );
  }
}
