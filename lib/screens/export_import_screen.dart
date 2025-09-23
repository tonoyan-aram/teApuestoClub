import 'package:flutter/material.dart';
import 'package:apuesto_club/services/export_import_service.dart';
import 'package:apuesto_club/utils/app_constants.dart';
import 'package:apuesto_club/utils/text_utils.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  final ExportImportService _exportService = ExportImportService();
  bool _isLoading = false;

  Future<void> _exportJson() async {
    setState(() => _isLoading = true);
    try {
      await _exportService.exportAndShareJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isLoading = true);
    try {
      await _exportService.exportAndShareCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importFile() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await _exportService.pickImportFile();
      if (filePath == null) {
        setState(() => _isLoading = false);
        return;
      }

      ImportResult result;
      if (filePath.toLowerCase().endsWith('.json')) {
        result = await _exportService.importFromJson(filePath);
      } else if (filePath.toLowerCase().endsWith('.csv')) {
        result = await _exportService.importFromCsv(filePath);
      } else {
        throw Exception('Unsupported file format');
      }

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import completed! ${result.eventsCount} events, ${result.templatesCount} templates imported.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: ${TextUtils.safeDisplayText(result.error)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export/Import Data'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppConstants.spacingMedium),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Export Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.upload,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppConstants.spacingSmall),
                              Text(
                                'Export Data',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text(
                            'Export your events and templates to share or backup your data.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportJson,
                                  icon: const Icon(Icons.code),
                                  label: const Text('Export JSON'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSmall),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportCsv,
                                  icon: const Icon(Icons.table_chart),
                                  label: const Text('Export CSV'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Import Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.download,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppConstants.spacingSmall),
                              Text(
                                'Import Data',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Text(
                            'Import events and templates from a backup file. This will replace your current data.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMedium),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _importFile,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Import from File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.tertiary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  
                  // Info Section
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppConstants.spacingSmall),
                              Text(
                                'Information',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingSmall),
                          Text(
                            '• JSON format includes all data (events and templates)\n'
                            '• CSV format includes only events data\n'
                            '• Import will replace all current data\n'
                            '• Make sure to backup your data before importing',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

