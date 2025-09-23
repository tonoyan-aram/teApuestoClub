import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/models/recurrence_rule.dart';
import 'package:apuesto_club/services/event_storage_service.dart';

class RecurrenceService {
  final EventStorageService _eventService = EventStorageService();
  final Uuid _uuid = const Uuid();

  // Generate recurring events from a parent event
  Future<List<Event>> generateRecurringEvents(
    Event parentEvent,
    RecurrenceRule recurrenceRule,
    {DateTime? endDate}
  ) async {
    if (parentEvent.recurrenceRule != null) {
      throw Exception('Event already has a recurrence rule');
    }

    final generatedEvents = <Event>[];
    final startDate = parentEvent.date;
    final finalEndDate = endDate ?? 
        (recurrenceRule.endType == RecurrenceEndType.onDate 
            ? recurrenceRule.endDate 
            : DateTime.now().add(const Duration(days: 365)));

    if (finalEndDate == null) return generatedEvents;

    DateTime currentDate = startDate;
    int occurrenceCount = 0;

    while (currentDate.isBefore(finalEndDate)) {
      // Get next occurrence
      final nextDate = recurrenceRule.getNextOccurrence(currentDate);
      if (nextDate == null || nextDate.isAfter(finalEndDate)) break;

      // Check if we've reached max occurrences
      if (recurrenceRule.endType == RecurrenceEndType.afterOccurrences &&
          recurrenceRule.maxOccurrences != null &&
          occurrenceCount >= recurrenceRule.maxOccurrences!) {
        break;
      }

      // Create recurring event instance
      final recurringEvent = Event(
        id: _uuid.v4(),
        title: parentEvent.title,
        date: nextDate,
        note: parentEvent.note,
        rating: parentEvent.rating,
        imageUrl: parentEvent.imageUrl,
        isFavorite: parentEvent.isFavorite,
        category: parentEvent.category,
        recurrenceRule: null, // Recurring instances don't have their own rule
        parentEventId: parentEvent.id,
        isRecurringInstance: true,
      );

      generatedEvents.add(recurringEvent);
      currentDate = nextDate;
      occurrenceCount++;
    }

    return generatedEvents;
  }

  // Save recurring events to storage
  Future<void> saveRecurringEvents(Event parentEvent, List<Event> recurringEvents) async {
    // First, save the parent event with recurrence rule
    await _eventService.addEvent(parentEvent);

    // Then save all recurring instances
    for (final event in recurringEvents) {
      await _eventService.addEvent(event);
    }
  }

  // Update a recurring event series
  Future<void> updateRecurringEventSeries(
    String parentEventId,
    Event updatedParentEvent,
    RecurrenceRule updatedRecurrenceRule,
  ) async {
    // Get all events in the series
    final allEvents = await _eventService.loadEvents();
    final seriesEvents = allEvents.where((e) => 
        e.id == parentEventId || e.parentEventId == parentEventId).toList();

    // Delete all existing instances
    for (final event in seriesEvents) {
      await _eventService.deleteEvent(event.id);
    }

    // Create new series with updated data
    final newRecurringEvents = await generateRecurringEvents(
      updatedParentEvent,
      updatedRecurrenceRule,
    );

    // Save new series
    await saveRecurringEvents(updatedParentEvent, newRecurringEvents);
  }

  // Delete a recurring event series
  Future<void> deleteRecurringEventSeries(String parentEventId) async {
    final allEvents = await _eventService.loadEvents();
    final seriesEvents = allEvents.where((e) => 
        e.id == parentEventId || e.parentEventId == parentEventId).toList();

    for (final event in seriesEvents) {
      await _eventService.deleteEvent(event.id);
    }
  }

  // Delete a single instance of a recurring event
  Future<void> deleteRecurringEventInstance(String eventId) async {
    await _eventService.deleteEvent(eventId);
  }

  // Get all events in a recurring series
  Future<List<Event>> getRecurringEventSeries(String parentEventId) async {
    final allEvents = await _eventService.loadEvents();
    return allEvents.where((e) => 
        e.id == parentEventId || e.parentEventId == parentEventId).toList();
  }

  // Check if an event is part of a recurring series
  bool isRecurringEvent(Event event) {
    return event.recurrenceRule != null || event.isRecurringInstance;
  }

  // Get the parent event of a recurring instance
  Future<Event?> getParentEvent(Event recurringInstance) async {
    if (!recurringInstance.isRecurringInstance || recurringInstance.parentEventId == null) {
      return null;
    }

    final allEvents = await _eventService.loadEvents();
    return allEvents.firstWhere(
      (e) => e.id == recurringInstance.parentEventId,
      orElse: () => throw Exception('Parent event not found'),
    );
  }

  // Generate future occurrences for display
  Future<List<Event>> getFutureOccurrences(
    Event parentEvent,
    {int maxOccurrences = 10}
  ) async {
    if (parentEvent.recurrenceRule == null) return [];

    final futureEvents = <Event>[];
    DateTime currentDate = DateTime.now();
    int count = 0;

    while (count < maxOccurrences) {
      final nextDate = parentEvent.recurrenceRule!.getNextOccurrence(currentDate);
      if (nextDate == null) break;

      final futureEvent = Event(
        id: _uuid.v4(),
        title: parentEvent.title,
        date: nextDate,
        note: parentEvent.note,
        rating: parentEvent.rating,
        imageUrl: parentEvent.imageUrl,
        isFavorite: parentEvent.isFavorite,
        category: parentEvent.category,
        parentEventId: parentEvent.id,
        isRecurringInstance: true,
      );

      futureEvents.add(futureEvent);
      currentDate = nextDate;
      count++;
    }

    return futureEvents;
  }

  // Update recurrence rule for an existing event
  Future<void> updateRecurrenceRule(
    String eventId,
    RecurrenceRule newRecurrenceRule,
  ) async {
    final allEvents = await _eventService.loadEvents();
    final event = allEvents.firstWhere((e) => e.id == eventId);

    if (event.recurrenceRule == null) {
      // Convert single event to recurring
      final updatedEvent = event.copyWith(recurrenceRule: newRecurrenceRule);
      await _eventService.updateEvent(updatedEvent);

      // Generate recurring instances
      final recurringEvents = await generateRecurringEvents(updatedEvent, newRecurrenceRule);
      for (final recurringEvent in recurringEvents) {
        await _eventService.addEvent(recurringEvent);
      }
    } else {
      // Update existing recurring event
      await updateRecurringEventSeries(eventId, event, newRecurrenceRule);
    }
  }

  // Remove recurrence from an event (convert to single event)
  Future<void> removeRecurrence(String eventId) async {
    final allEvents = await _eventService.loadEvents();
    final event = allEvents.firstWhere((e) => e.id == eventId);

    if (event.recurrenceRule == null) return;

    // Delete all recurring instances
    final seriesEvents = allEvents.where((e) => e.parentEventId == eventId).toList();
    for (final seriesEvent in seriesEvents) {
      await _eventService.deleteEvent(seriesEvent.id);
    }

    // Update parent event to remove recurrence
    final updatedEvent = event.copyWith(
      recurrenceRule: null,
      parentEventId: null,
      isRecurringInstance: false,
    );
    await _eventService.updateEvent(updatedEvent);
  }
}

