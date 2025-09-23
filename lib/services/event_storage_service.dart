import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apuesto_club/models/event.dart';

class EventStorageService {
  static const String _eventsKey = 'events';

  Future<List<Event>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsString = prefs.getStringList(_eventsKey) ?? [];
    return eventsString
        .map((eventJson) => Event.fromJson(json.decode(eventJson)))
        .toList();
  }

  Future<void> saveEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((event) => json.encode(event.toJson())).toList();
    await prefs.setStringList(_eventsKey, eventsJson);
  }

  Future<void> addEvent(Event event) async {
    List<Event> events = await loadEvents();
    events.add(event);
    await saveEvents(events);
  }

  Future<void> updateEvent(Event updatedEvent) async {
    List<Event> events = await loadEvents();
    final index = events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      events[index] = updatedEvent;
      await saveEvents(events);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    List<Event> events = await loadEvents();
    events.removeWhere((event) => event.id == eventId);
    await saveEvents(events);
  }

  Future<void> toggleFavoriteStatus(String eventId, bool isFavorite) async {
    List<Event> events = await loadEvents();
    final index = events.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      events[index] = events[index].copyWith(isFavorite: isFavorite);
      await saveEvents(events);
    }
  }
}
