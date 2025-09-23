enum ReminderType {
  minutes,
  hours,
  days,
  weeks;

  String toDisplayString() {
    switch (this) {
      case ReminderType.minutes:
        return 'Minutes';
      case ReminderType.hours:
        return 'Hours';
      case ReminderType.days:
        return 'Days';
      case ReminderType.weeks:
        return 'Weeks';
    }
  }

  Duration toDuration(int value) {
    switch (this) {
      case ReminderType.minutes:
        return Duration(minutes: value);
      case ReminderType.hours:
        return Duration(hours: value);
      case ReminderType.days:
        return Duration(days: value);
      case ReminderType.weeks:
        return Duration(days: value * 7);
    }
  }
}

class ReminderSettings {
  final String id;
  final String eventId;
  final List<Reminder> reminders;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderSettings({
    required this.id,
    required this.eventId,
    required this.reminders,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      id: json['id'],
      eventId: json['eventId'],
      reminders: (json['reminders'] as List<dynamic>)
          .map((r) => Reminder.fromJson(r as Map<String, dynamic>))
          .toList(),
      isEnabled: json['isEnabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReminderSettings copyWith({
    String? id,
    String? eventId,
    List<Reminder>? reminders,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderSettings(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      reminders: reminders ?? this.reminders,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Reminder {
  final String id;
  final int value;
  final ReminderType type;
  final String? customMessage;
  final bool isEnabled;

  Reminder({
    required this.id,
    required this.value,
    required this.type,
    this.customMessage,
    this.isEnabled = true,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      value: json['value'],
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == 'ReminderType.' + json['type'],
        orElse: () => ReminderType.minutes,
      ),
      customMessage: json['customMessage'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'type': type.name,
      'customMessage': customMessage,
      'isEnabled': isEnabled,
    };
  }

  Reminder copyWith({
    String? id,
    int? value,
    ReminderType? type,
    String? customMessage,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      value: value ?? this.value,
      type: type ?? this.type,
      customMessage: customMessage ?? this.customMessage,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  String getDescription() {
    final message = customMessage ?? _getDefaultMessage();
    return '$value ${type.toDisplayString().toLowerCase()} before: $message';
  }

  String _getDefaultMessage() {
    switch (type) {
      case ReminderType.minutes:
        if (value == 15) return 'Event starting soon!';
        if (value == 30) return 'Event in 30 minutes';
        return 'Event reminder';
      case ReminderType.hours:
        if (value == 1) return 'Event in 1 hour';
        if (value == 2) return 'Event in 2 hours';
        return 'Event reminder';
      case ReminderType.days:
        if (value == 1) return 'Event tomorrow';
        if (value == 7) return 'Event next week';
        return 'Event reminder';
      case ReminderType.weeks:
        if (value == 1) return 'Event next week';
        if (value == 2) return 'Event in 2 weeks';
        return 'Event reminder';
    }
  }

  Duration getDuration() {
    return type.toDuration(value);
  }
}

// Predefined reminder templates for different event categories
class ReminderTemplates {
  static List<Reminder> getFootballReminders() {
    return [
      Reminder(
        id: 'football_1',
        value: 1,
        type: ReminderType.days,
        customMessage: 'Football match tomorrow!',
      ),
      Reminder(
        id: 'football_2',
        value: 2,
        type: ReminderType.hours,
        customMessage: 'Football match in 2 hours!',
      ),
      Reminder(
        id: 'football_3',
        value: 15,
        type: ReminderType.minutes,
        customMessage: 'Football match starting soon!',
      ),
    ];
  }

  static List<Reminder> getBasketballReminders() {
    return [
      Reminder(
        id: 'basketball_1',
        value: 1,
        type: ReminderType.days,
        customMessage: 'Basketball game tomorrow!',
      ),
      Reminder(
        id: 'basketball_2',
        value: 1,
        type: ReminderType.hours,
        customMessage: 'Basketball game in 1 hour!',
      ),
      Reminder(
        id: 'basketball_3',
        value: 30,
        type: ReminderType.minutes,
        customMessage: 'Basketball game starting soon!',
      ),
    ];
  }

  static List<Reminder> getTennisReminders() {
    return [
      Reminder(
        id: 'tennis_1',
        value: 1,
        type: ReminderType.days,
        customMessage: 'Tennis tournament tomorrow!',
      ),
      Reminder(
        id: 'tennis_2',
        value: 2,
        type: ReminderType.hours,
        customMessage: 'Tennis tournament in 2 hours!',
      ),
      Reminder(
        id: 'tennis_3',
        value: 15,
        type: ReminderType.minutes,
        customMessage: 'Tennis tournament starting soon!',
      ),
    ];
  }

  static List<Reminder> getMarathonReminders() {
    return [
      Reminder(
        id: 'marathon_1',
        value: 7,
        type: ReminderType.days,
        customMessage: 'Marathon next week!',
      ),
      Reminder(
        id: 'marathon_2',
        value: 1,
        type: ReminderType.days,
        customMessage: 'Marathon tomorrow!',
      ),
      Reminder(
        id: 'marathon_3',
        value: 2,
        type: ReminderType.hours,
        customMessage: 'Marathon in 2 hours!',
      ),
    ];
  }

  static List<Reminder> getDefaultReminders() {
    return [
      Reminder(
        id: 'default_1',
        value: 1,
        type: ReminderType.days,
        customMessage: 'Event tomorrow!',
      ),
      Reminder(
        id: 'default_2',
        value: 1,
        type: ReminderType.hours,
        customMessage: 'Event in 1 hour!',
      ),
      Reminder(
        id: 'default_3',
        value: 15,
        type: ReminderType.minutes,
        customMessage: 'Event starting soon!',
      ),
    ];
  }

  static List<Reminder> getRemindersForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return getFootballReminders();
      case 'basketball':
        return getBasketballReminders();
      case 'tennis':
        return getTennisReminders();
      case 'marathon':
        return getMarathonReminders();
      default:
        return getDefaultReminders();
    }
  }
}

