import 'package:apuesto_club/models/event.dart';

class AnalyticsData {
  final int totalEvents;
  final int favoriteEvents;
  final double averageRating;
  final Map<EventCategory, int> categoryCounts;
  final Map<String, int> monthlyCounts;
  final Map<String, int> yearlyCounts;
  final Map<int, int> ratingDistribution;
  final List<EventTrend> trends;
  final List<CategoryAnalytics> categoryAnalytics;
  final DateTime generatedAt;

  AnalyticsData({
    required this.totalEvents,
    required this.favoriteEvents,
    required this.averageRating,
    required this.categoryCounts,
    required this.monthlyCounts,
    required this.yearlyCounts,
    required this.ratingDistribution,
    required this.trends,
    required this.categoryAnalytics,
    required this.generatedAt,
  });

  factory AnalyticsData.fromEvents(List<Event> events) {
    final now = DateTime.now();
    final totalEvents = events.length;
    final favoriteEvents = events.where((e) => e.isFavorite).length;
    
    final averageRating = totalEvents > 0 
        ? events.map((e) => e.rating).reduce((a, b) => a + b) / totalEvents
        : 0.0;

    // Category counts
    final categoryCounts = <EventCategory, int>{};
    for (final category in EventCategory.values) {
      categoryCounts[category] = events.where((e) => e.category == category).length;
    }

    // Monthly counts (last 12 months)
    final monthlyCounts = <String, int>{};
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyCounts[monthKey] = events.where((e) => 
          e.date.year == month.year && e.date.month == month.month).length;
    }

    // Yearly counts (last 5 years)
    final yearlyCounts = <String, int>{};
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      yearlyCounts[year.toString()] = events.where((e) => e.date.year == year).length;
    }

    // Rating distribution
    final ratingDistribution = <int, int>{};
    for (int rating = 1; rating <= 5; rating++) {
      ratingDistribution[rating] = events.where((e) => e.rating == rating).length;
    }

    // Trends
    final trends = _calculateTrends(events);

    // Category analytics
    final categoryAnalytics = EventCategory.values.map((category) {
      final categoryEvents = events.where((e) => e.category == category).toList();
      return CategoryAnalytics.fromEvents(category, categoryEvents);
    }).toList();

    return AnalyticsData(
      totalEvents: totalEvents,
      favoriteEvents: favoriteEvents,
      averageRating: averageRating,
      categoryCounts: categoryCounts,
      monthlyCounts: monthlyCounts,
      yearlyCounts: yearlyCounts,
      ratingDistribution: ratingDistribution,
      trends: trends,
      categoryAnalytics: categoryAnalytics,
      generatedAt: now,
    );
  }

  static List<EventTrend> _calculateTrends(List<Event> events) {
    final trends = <EventTrend>[];
    final now = DateTime.now();

    // Last 30 days trend
    final last30Days = events.where((e) => 
        e.date.isAfter(now.subtract(const Duration(days: 30)))).length;
    final previous30Days = events.where((e) => 
        e.date.isAfter(now.subtract(const Duration(days: 60))) &&
        e.date.isBefore(now.subtract(const Duration(days: 30)))).length;
    
    trends.add(EventTrend(
      period: 'Last 30 days',
      current: last30Days,
      previous: previous30Days,
      changePercent: previous30Days > 0 
          ? ((last30Days - previous30Days) / previous30Days * 100)
          : 0.0,
    ));

    // Last 7 days trend
    final last7Days = events.where((e) => 
        e.date.isAfter(now.subtract(const Duration(days: 7)))).length;
    final previous7Days = events.where((e) => 
        e.date.isAfter(now.subtract(const Duration(days: 14))) &&
        e.date.isBefore(now.subtract(const Duration(days: 7)))).length;
    
    trends.add(EventTrend(
      period: 'Last 7 days',
      current: last7Days,
      previous: previous7Days,
      changePercent: previous7Days > 0 
          ? ((last7Days - previous7Days) / previous7Days * 100)
          : 0.0,
    ));

    return trends;
  }
}

class EventTrend {
  final String period;
  final int current;
  final int previous;
  final double changePercent;

  EventTrend({
    required this.period,
    required this.current,
    required this.previous,
    required this.changePercent,
  });

  bool get isIncreasing => changePercent > 0;
  bool get isDecreasing => changePercent < 0;
  bool get isStable => changePercent == 0;
}

class CategoryAnalytics {
  final EventCategory category;
  final int totalEvents;
  final double averageRating;
  final int favoriteEvents;
  final Map<String, int> monthlyCounts;
  final double percentageOfTotal;

  CategoryAnalytics({
    required this.category,
    required this.totalEvents,
    required this.averageRating,
    required this.favoriteEvents,
    required this.monthlyCounts,
    required this.percentageOfTotal,
  });

  factory CategoryAnalytics.fromEvents(EventCategory category, List<Event> events) {
    final now = DateTime.now();
    final totalEvents = events.length;
    final averageRating = totalEvents > 0 
        ? events.map((e) => e.rating).reduce((a, b) => a + b) / totalEvents
        : 0.0;
    final favoriteEvents = events.where((e) => e.isFavorite).length;

    // Monthly counts for this category (last 6 months)
    final monthlyCounts = <String, int>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyCounts[monthKey] = events.where((e) => 
          e.date.year == month.year && e.date.month == month.month).length;
    }

    return CategoryAnalytics(
      category: category,
      totalEvents: totalEvents,
      averageRating: averageRating,
      favoriteEvents: favoriteEvents,
      monthlyCounts: monthlyCounts,
      percentageOfTotal: 0.0, // Will be calculated later
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final String? color;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

class TimeSeriesData {
  final String period;
  final int count;
  final DateTime date;

  TimeSeriesData({
    required this.period,
    required this.count,
    required this.date,
  });
}

