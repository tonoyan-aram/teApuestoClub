import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/models/analytics_data.dart';
import 'package:apuesto_club/services/event_storage_service.dart';

class AnalyticsService {
  final EventStorageService _eventService = EventStorageService();

  Future<AnalyticsData> generateAnalytics() async {
    final events = await _eventService.loadEvents();
    return AnalyticsData.fromEvents(events);
  }

  Future<List<ChartDataPoint>> getCategoryChartData() async {
    final analytics = await generateAnalytics();
    return analytics.categoryCounts.entries.map((entry) {
      return ChartDataPoint(
        label: entry.key.toDisplayString(),
        value: entry.value.toDouble(),
        color: _getCategoryColor(entry.key),
      );
    }).toList();
  }

  Future<List<ChartDataPoint>> getRatingChartData() async {
    final analytics = await generateAnalytics();
    return analytics.ratingDistribution.entries.map((entry) {
      return ChartDataPoint(
        label: '${entry.key} Star${entry.key == 1 ? '' : 's'}',
        value: entry.value.toDouble(),
        color: _getRatingColor(entry.key),
      );
    }).toList();
  }

  Future<List<TimeSeriesData>> getMonthlyTrendData() async {
    final analytics = await generateAnalytics();
    final now = DateTime.now();
    
    return analytics.monthlyCounts.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      return TimeSeriesData(
        period: entry.key,
        count: entry.value,
        date: DateTime(year, month, 1),
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TimeSeriesData>> getYearlyTrendData() async {
    final analytics = await generateAnalytics();
    
    return analytics.yearlyCounts.entries.map((entry) {
      final year = int.parse(entry.key);
      
      return TimeSeriesData(
        period: entry.key,
        count: entry.value,
        date: DateTime(year, 1, 1),
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<Map<String, List<TimeSeriesData>>> getCategoryTrendData() async {
    final analytics = await generateAnalytics();
    final result = <String, List<TimeSeriesData>>{};
    
    for (final categoryAnalytics in analytics.categoryAnalytics) {
      final trendData = categoryAnalytics.monthlyCounts.entries.map((entry) {
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        return TimeSeriesData(
          period: entry.key,
          count: entry.value,
          date: DateTime(year, month, 1),
        );
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
      
      result[categoryAnalytics.category.name] = trendData;
    }
    
    return result;
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final analytics = await generateAnalytics();
    
    return {
      'totalEvents': analytics.totalEvents,
      'favoriteEvents': analytics.favoriteEvents,
      'averageRating': analytics.averageRating,
      'mostPopularCategory': _getMostPopularCategory(analytics.categoryCounts),
      'leastPopularCategory': _getLeastPopularCategory(analytics.categoryCounts),
      'totalRecurringEvents': await _getRecurringEventsCount(),
      'upcomingEvents': await _getUpcomingEventsCount(),
      'recentActivity': await _getRecentActivity(),
    };
  }

  Future<String> exportAnalyticsToJson() async {
    final analytics = await generateAnalytics();
    final summary = await getAnalyticsSummary();
    
    final exportData = {
      'summary': summary,
      'categoryCounts': analytics.categoryCounts.map((k, v) => MapEntry(k.name, v)),
      'monthlyCounts': analytics.monthlyCounts,
      'yearlyCounts': analytics.yearlyCounts,
      'ratingDistribution': analytics.ratingDistribution,
      'trends': analytics.trends.map((t) => {
        'period': t.period,
        'current': t.current,
        'previous': t.previous,
        'changePercent': t.changePercent,
      }).toList(),
      'generatedAt': analytics.generatedAt.toIso8601String(),
    };
    
    return exportData.toString();
  }

  String _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.football:
        return '#4CAF50'; // Green
      case EventCategory.basketball:
        return '#FF9800'; // Orange
      case EventCategory.tennis:
        return '#2196F3'; // Blue
      case EventCategory.marathon:
        return '#F44336'; // Red
      case EventCategory.other:
        return '#9C27B0'; // Purple
    }
  }

  String _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return '#F44336'; // Red
      case 2:
        return '#FF9800'; // Orange
      case 3:
        return '#FFC107'; // Yellow
      case 4:
        return '#4CAF50'; // Green
      case 5:
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String _getMostPopularCategory(Map<EventCategory, int> categoryCounts) {
    if (categoryCounts.isEmpty) return 'None';
    
    final maxEntry = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxEntry.value > 0 ? maxEntry.key.toDisplayString() : 'None';
  }

  String _getLeastPopularCategory(Map<EventCategory, int> categoryCounts) {
    if (categoryCounts.isEmpty) return 'None';
    
    final minEntry = categoryCounts.entries.reduce((a, b) => a.value < b.value ? a : b);
    return minEntry.value > 0 ? minEntry.key.toDisplayString() : 'None';
  }

  Future<int> _getRecurringEventsCount() async {
    final events = await _eventService.loadEvents();
    return events.where((e) => e.recurrenceRule != null || e.isRecurringInstance).length;
  }

  Future<int> _getUpcomingEventsCount() async {
    final events = await _eventService.loadEvents();
    final now = DateTime.now();
    return events.where((e) => e.date.isAfter(now)).length;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    final events = await _eventService.loadEvents();
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    
    return events
        .where((e) => e.date.isAfter(last7Days))
        .map((e) => {
          'title': e.title,
          'category': e.category.toDisplayString(),
          'date': e.date.toIso8601String(),
          'rating': e.rating,
        })
        .toList()
      ..sort((a, b) => DateTime.parse(b['date'] as String).compareTo(DateTime.parse(a['date'] as String)));
  }
}

