enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String toDisplayString() {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }
}

enum RecurrenceEndType {
  never,
  afterOccurrences,
  onDate;

  String toDisplayString() {
    switch (this) {
      case RecurrenceEndType.never:
        return 'Never';
      case RecurrenceEndType.afterOccurrences:
        return 'After occurrences';
      case RecurrenceEndType.onDate:
        return 'On date';
    }
  }
}

class RecurrenceRule {
  final String id;
  final RecurrenceFrequency frequency;
  final int interval; // Every X days/weeks/months/years
  final RecurrenceEndType endType;
  final DateTime? endDate;
  final int? maxOccurrences;
  final List<int>? daysOfWeek; // 1-7 (Monday-Sunday) for weekly
  final int? dayOfMonth; // 1-31 for monthly
  final int? weekOfMonth; // 1-4 for monthly
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurrenceRule({
    required this.id,
    required this.frequency,
    this.interval = 1,
    this.endType = RecurrenceEndType.never,
    this.endDate,
    this.maxOccurrences,
    this.daysOfWeek,
    this.dayOfMonth,
    this.weekOfMonth,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      id: json['id'],
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.toString() == 'RecurrenceFrequency.' + json['frequency'],
        orElse: () => RecurrenceFrequency.daily,
      ),
      interval: json['interval'] ?? 1,
      endType: RecurrenceEndType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceEndType.' + json['endType'],
        orElse: () => RecurrenceEndType.never,
      ),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'],
      daysOfWeek: json['daysOfWeek'] != null 
          ? List<int>.from(json['daysOfWeek'])
          : null,
      dayOfMonth: json['dayOfMonth'],
      weekOfMonth: json['weekOfMonth'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frequency': frequency.name,
      'interval': interval,
      'endType': endType.name,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'weekOfMonth': weekOfMonth,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RecurrenceRule copyWith({
    String? id,
    RecurrenceFrequency? frequency,
    int? interval,
    RecurrenceEndType? endType,
    DateTime? endDate,
    int? maxOccurrences,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    int? weekOfMonth,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      endType: endType ?? this.endType,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getDescription() {
    if (!isActive) return 'No recurrence';
    
    String base = 'Every ${interval > 1 ? '$interval ' : ''}${frequency.toDisplayString().toLowerCase()}';
    
    if (frequency == RecurrenceFrequency.weekly && daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final selectedDays = daysOfWeek!.map((day) => dayNames[day - 1]).join(', ');
      base += ' on $selectedDays';
    } else if (frequency == RecurrenceFrequency.monthly) {
      if (dayOfMonth != null) {
        base += ' on day $dayOfMonth';
      } else if (weekOfMonth != null) {
        final weekNames = ['first', 'second', 'third', 'fourth'];
        base += ' on ${weekOfMonth! <= 4 ? weekNames[weekOfMonth! - 1] : 'last'} week';
      }
    }
    
    if (endDate != null) {
      base += ' until ${endDate!.toLocal().toString().split(' ')[0]}';
    } else if (maxOccurrences != null) {
      base += ' for $maxOccurrences times';
    }
    
    return base;
  }

  bool shouldRecur(DateTime currentDate, DateTime originalDate) {
    if (!isActive) return false;
    
    // Check if we've reached the end date
    if (endDate != null && currentDate.isAfter(endDate!)) return false;
    
    // Check if we've reached max occurrences (this would need to be tracked externally)
    // For now, we'll just check the basic recurrence logic
    
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _shouldRecurDaily(currentDate, originalDate);
      case RecurrenceFrequency.weekly:
        return _shouldRecurWeekly(currentDate, originalDate);
      case RecurrenceFrequency.monthly:
        return _shouldRecurMonthly(currentDate, originalDate);
      case RecurrenceFrequency.yearly:
        return _shouldRecurYearly(currentDate, originalDate);
    }
  }

  /// Get the next occurrence date after the given date
  DateTime? getNextOccurrence(DateTime fromDate) {
    if (!isActive) return null;
    
    // Check if we've reached the end date
    if (endDate != null && fromDate.isAfter(endDate!)) return null;
    
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _getNextDailyOccurrence(fromDate);
      case RecurrenceFrequency.weekly:
        return _getNextWeeklyOccurrence(fromDate);
      case RecurrenceFrequency.monthly:
        return _getNextMonthlyOccurrence(fromDate);
      case RecurrenceFrequency.yearly:
        return _getNextYearlyOccurrence(fromDate);
    }
  }

  bool _shouldRecurDaily(DateTime currentDate, DateTime originalDate) {
    final daysDifference = currentDate.difference(originalDate).inDays;
    return daysDifference > 0 && daysDifference % interval == 0;
  }

  bool _shouldRecurWeekly(DateTime currentDate, DateTime originalDate) {
    final weeksDifference = currentDate.difference(originalDate).inDays ~/ 7;
    if (weeksDifference <= 0 || weeksDifference % interval != 0) return false;
    
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      return daysOfWeek!.contains(currentDate.weekday);
    }
    
    return currentDate.weekday == originalDate.weekday;
  }

  bool _shouldRecurMonthly(DateTime currentDate, DateTime originalDate) {
    if (currentDate.year == originalDate.year && currentDate.month == originalDate.month) {
      return false; // Same month, not a recurrence
    }
    
    final monthsDifference = (currentDate.year - originalDate.year) * 12 + 
                           (currentDate.month - originalDate.month);
    
    if (monthsDifference <= 0 || monthsDifference % interval != 0) return false;
    
    if (dayOfMonth != null) {
      return currentDate.day == dayOfMonth;
    } else if (weekOfMonth != null) {
      // This is a simplified version - in practice, you'd need more complex logic
      return currentDate.day <= 7 * weekOfMonth! && 
             currentDate.day > 7 * (weekOfMonth! - 1);
    }
    
    return currentDate.day == originalDate.day;
  }

  bool _shouldRecurYearly(DateTime currentDate, DateTime originalDate) {
    if (currentDate.year == originalDate.year) return false;
    
    final yearsDifference = currentDate.year - originalDate.year;
    if (yearsDifference <= 0 || yearsDifference % interval != 0) return false;
    
    return currentDate.month == originalDate.month && 
           currentDate.day == originalDate.day;
  }

  DateTime? _getNextDailyOccurrence(DateTime fromDate) {
    final nextDate = fromDate.add(Duration(days: interval));
    return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
  }

  DateTime? _getNextWeeklyOccurrence(DateTime fromDate) {
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      // Find next occurrence on specified days of week
      for (int i = 1; i <= 7; i++) {
        final nextDate = fromDate.add(Duration(days: i));
        if (daysOfWeek!.contains(nextDate.weekday)) {
          return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
        }
      }
      // If no day found in current week, go to next week
      final nextWeekDate = fromDate.add(Duration(days: 7 * interval));
      return endDate != null && nextWeekDate.isAfter(endDate!) ? null : nextWeekDate;
    } else {
      // Same day of week, next interval
      final nextDate = fromDate.add(Duration(days: 7 * interval));
      return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
    }
  }

  DateTime? _getNextMonthlyOccurrence(DateTime fromDate) {
    if (dayOfMonth != null) {
      // Same day of month
      var nextDate = DateTime(fromDate.year, fromDate.month + interval, dayOfMonth!);
      if (nextDate.day != dayOfMonth) {
        // Handle months with fewer days
        nextDate = DateTime(nextDate.year, nextDate.month + 1, 0);
      }
      return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
    } else if (weekOfMonth != null) {
      // Same week of month
      var nextDate = DateTime(fromDate.year, fromDate.month + interval, 1);
      final firstWeekday = nextDate.weekday;
      final targetDay = 1 + (weekOfMonth! - 1) * 7 + (7 - firstWeekday) % 7;
      nextDate = DateTime(nextDate.year, nextDate.month, targetDay);
      return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
    } else {
      // Same day of month as original
      var nextDate = DateTime(fromDate.year, fromDate.month + interval, fromDate.day);
      if (nextDate.day != fromDate.day) {
        // Handle months with fewer days
        nextDate = DateTime(nextDate.year, nextDate.month + 1, 0);
      }
      return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
    }
  }

  DateTime? _getNextYearlyOccurrence(DateTime fromDate) {
    var nextDate = DateTime(fromDate.year + interval, fromDate.month, fromDate.day);
    // Handle leap year edge case
    if (nextDate.month == 2 && nextDate.day == 29 && !_isLeapYear(nextDate.year)) {
      nextDate = DateTime(nextDate.year, 3, 1);
    }
    return endDate != null && nextDate.isAfter(endDate!) ? null : nextDate;
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}
