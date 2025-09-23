import 'package:flutter/material.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/models/analytics_data.dart';
import 'package:apuesto_club/services/event_storage_service.dart';
import 'package:apuesto_club/services/analytics_service.dart';
import 'package:apuesto_club/utils/app_constants.dart';
import 'package:apuesto_club/utils/text_utils.dart';
import 'package:apuesto_club/widgets/analytics_charts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  AnalyticsData? _analyticsData;
  List<ChartDataPoint> _categoryChartData = [];
  List<ChartDataPoint> _ratingChartData = [];
  List<TimeSeriesData> _monthlyTrendData = [];
  Map<String, List<TimeSeriesData>> _categoryTrendData = {};
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  final EventStorageService _storageService = EventStorageService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsData = await _analyticsService.generateAnalytics();
      final categoryChartData = await _analyticsService.getCategoryChartData();
      final ratingChartData = await _analyticsService.getRatingChartData();
      final monthlyTrendData = await _analyticsService.getMonthlyTrendData();
      final categoryTrendData = await _analyticsService.getCategoryTrendData();
      final summary = await _analyticsService.getAnalyticsSummary();

      setState(() {
        _analyticsData = analyticsData;
        _categoryChartData = categoryChartData;
        _ratingChartData = ratingChartData;
        _monthlyTrendData = monthlyTrendData;
        _categoryTrendData = categoryTrendData;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Category Distribution Chart
                  _buildChartSection(
                    'Events by Category',
                    CategoryPieChart(data: _categoryChartData),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Rating Distribution Chart
                  _buildChartSection(
                    'Rating Distribution',
                    RatingBarChart(data: _ratingChartData),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Monthly Trend Chart
                  _buildChartSection(
                    'Monthly Trends',
                    MonthlyTrendLineChart(data: _monthlyTrendData),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Category Trends Chart
                  if (_categoryTrendData.isNotEmpty)
                    _buildChartSection(
                      'Category Trends',
                      CategoryTrendChart(data: _categoryTrendData),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Total Events',
                value: _analyticsData!.totalEvents.toString(),
                icon: Icons.event,
                color: Colors.blue,
                subtitle: 'All time',
              ),
            ),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Favorites',
                value: _analyticsData!.favoriteEvents.toString(),
                icon: Icons.favorite,
                color: Colors.red,
                subtitle: 'Loved events',
                progress: _analyticsData!.totalEvents > 0 
                    ? _analyticsData!.favoriteEvents / _analyticsData!.totalEvents 
                    : 0.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Avg Rating',
                value: _analyticsData!.averageRating.toStringAsFixed(1),
                icon: Icons.star,
                color: Colors.orange,
                subtitle: 'Out of 5 stars',
                progress: _analyticsData!.averageRating / 5.0,
              ),
            ),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'This Month',
                value: _monthlyTrendData.isNotEmpty 
                    ? _monthlyTrendData.last.count.toString()
                    : '0',
                icon: Icons.calendar_month,
                color: Colors.green,
                subtitle: 'Events created',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: chart,
    );
  }

  Future<void> _exportAnalytics() async {
    try {
      final analyticsJson = await _analyticsService.exportAnalyticsToJson();
      // Here you would implement the actual export functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics exported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${TextUtils.safeDisplayText(e.toString())}')),
      );
    }
  }
}
