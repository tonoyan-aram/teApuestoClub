import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/models/event_template.dart';
import 'package:apuesto_club/services/event_storage_service.dart';
import 'package:apuesto_club/services/template_storage_service.dart';

class ImportResult {
  final bool success;
  final int eventsCount;
  final int templatesCount;
  final String? error;

  ImportResult({
    required this.success,
    this.eventsCount = 0,
    this.templatesCount = 0,
    this.error,
  });
}

class ExportImportService {
  final EventStorageService _eventStorageService = EventStorageService();
  final TemplateStorageService _templateStorageService = TemplateStorageService();

  /// Export all events to a JSON file
  Future<String> exportEvents() async {
    try {
      final events = await _eventStorageService.loadEvents();
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'events',
        'data': events.map((event) => event.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'te_apuesto_club_events_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export events: $e');
    }
  }

  /// Export all templates to a JSON file
  Future<String> exportTemplates() async {
    try {
      final templates = await _templateStorageService.loadTemplates();
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'templates',
        'data': templates.map((template) => template.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'te_apuesto_club_templates_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export templates: $e');
    }
  }

  /// Export both events and templates to a single JSON file
  Future<String> exportAll() async {
    try {
      final events = await _eventStorageService.loadEvents();
      final templates = await _templateStorageService.loadTemplates();
      
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'type': 'all',
        'events': events.map((event) => event.toJson()).toList(),
        'templates': templates.map((template) => template.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'te_apuesto_club_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export all data: $e');
    }
  }

  /// Import events from a JSON file
  Future<int> importEvents(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate file format
      if (jsonData['type'] != 'events' && jsonData['type'] != 'all') {
        throw Exception('Invalid file format. Expected events or all data.');
      }

      final eventsData = jsonData['events'] as List<dynamic>? ?? 
                        (jsonData['data'] as List<dynamic>? ?? []);
      
      final events = eventsData
          .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
          .toList();

      // Add events to storage
      for (final event in events) {
        await _eventStorageService.addEvent(event);
      }

      return events.length;
    } catch (e) {
      throw Exception('Failed to import events: $e');
    }
  }

  /// Import templates from a JSON file
  Future<int> importTemplates(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate file format
      if (jsonData['type'] != 'templates' && jsonData['type'] != 'all') {
        throw Exception('Invalid file format. Expected templates or all data.');
      }

      final templatesData = jsonData['templates'] as List<dynamic>? ?? 
                           (jsonData['data'] as List<dynamic>? ?? []);
      
      final templates = templatesData
          .map((templateJson) => EventTemplate.fromJson(templateJson as Map<String, dynamic>))
          .toList();

      // Add templates to storage
      for (final template in templates) {
        await _templateStorageService.addTemplate(template);
      }

      return templates.length;
    } catch (e) {
      throw Exception('Failed to import templates: $e');
    }
  }

  /// Import all data from a JSON file
  Future<Map<String, int>> importAll(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Validate file format
      if (jsonData['type'] != 'all') {
        throw Exception('Invalid file format. Expected all data.');
      }

      int eventsCount = 0;
      int templatesCount = 0;

      // Import events if present
      if (jsonData['events'] != null) {
        final eventsData = jsonData['events'] as List<dynamic>;
        final events = eventsData
            .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
            .toList();

        for (final event in events) {
          await _eventStorageService.addEvent(event);
        }
        eventsCount = events.length;
      }

      // Import templates if present
      if (jsonData['templates'] != null) {
        final templatesData = jsonData['templates'] as List<dynamic>;
        final templates = templatesData
            .map((templateJson) => EventTemplate.fromJson(templateJson as Map<String, dynamic>))
            .toList();

        for (final template in templates) {
          await _templateStorageService.addTemplate(template);
        }
        templatesCount = templates.length;
      }

      return {
        'events': eventsCount,
        'templates': templatesCount,
      };
    } catch (e) {
      throw Exception('Failed to import all data: $e');
    }
  }

  /// Pick a file for import
  Future<String?> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Share a file
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  /// Export and share JSON file with all data
  Future<void> exportAndShareJson() async {
    try {
      final filePath = await exportAll();
      await shareFile(filePath);
    } catch (e) {
      throw Exception('Failed to export and share JSON: $e');
    }
  }

  /// Export and share CSV file with events data
  Future<void> exportAndShareCsv() async {
    try {
      final filePath = await exportEventsAsCsv();
      await shareFile(filePath);
    } catch (e) {
      throw Exception('Failed to export and share CSV: $e');
    }
  }

  /// Export events as CSV file
  Future<String> exportEventsAsCsv() async {
    try {
      final events = await _eventStorageService.loadEvents();
      
      // Create CSV header
      final csvLines = <String>[
        'Title,Date,Category,Rating,Note,Is Favorite,Image URL',
      ];
      
      // Add event data
      for (final event in events) {
        final csvLine = [
          '"${event.title.replaceAll('"', '""')}"',
          event.date.toIso8601String(),
          event.category.name,
          event.rating.toString(),
          '"${(event.note ?? '').replaceAll('"', '""')}"',
          event.isFavorite.toString(),
          '"${event.imageUrl ?? ''}"',
        ].join(',');
        csvLines.add(csvLine);
      }
      
      final csvContent = csvLines.join('\n');
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'te_apuesto_club_events_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export events as CSV: $e');
    }
  }

  /// Get file info for display
  Future<Map<String, dynamic>> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return {
        'version': jsonData['version'] ?? 'Unknown',
        'exportDate': jsonData['exportDate'] ?? 'Unknown',
        'type': jsonData['type'] ?? 'Unknown',
        'eventsCount': (jsonData['events'] as List?)?.length ?? 
                      (jsonData['data'] as List?)?.length ?? 0,
        'templatesCount': (jsonData['templates'] as List?)?.length ?? 0,
        'fileSize': await file.length(),
        'fileName': file.path.split('/').last,
      };
    } catch (e) {
      throw Exception('Failed to read file info: $e');
    }
  }

  /// Validate import file format
  Future<bool> validateImportFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Check required fields
      if (jsonData['version'] == null || jsonData['type'] == null) {
        return false;
      }

      // Check if it's a valid type
      final validTypes = ['events', 'templates', 'all'];
      if (!validTypes.contains(jsonData['type'])) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import from JSON file and return ImportResult
  Future<ImportResult> importFromJson(String filePath) async {
    try {
      final result = await importAll(filePath);
      return ImportResult(
        success: true,
        eventsCount: result['events'] ?? 0,
        templatesCount: result['templates'] ?? 0,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Import from CSV file and return ImportResult
  Future<ImportResult> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      final csvContent = await file.readAsString();
      final lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Empty CSV file',
        );
      }

      // Skip header line
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
      int importedCount = 0;

      for (final line in dataLines) {
        try {
          final fields = _parseCsvLine(line);
          if (fields.length >= 6) {
            final event = Event(
              id: const Uuid().v4(),
              title: fields[0],
              date: DateTime.parse(fields[1]),
              category: EventCategory.values.firstWhere(
                (e) => e.name == fields[2],
                orElse: () => EventCategory.other,
              ),
              rating: int.tryParse(fields[3]) ?? 3,
              note: fields[4].isEmpty ? null : fields[4],
              isFavorite: fields[5].toLowerCase() == 'true',
              imageUrl: fields.length > 6 && fields[6].isNotEmpty ? fields[6] : null,
            );
            
            await _eventStorageService.addEvent(event);
            importedCount++;
          }
        } catch (e) {
          // Skip invalid lines
          continue;
        }
      }

      return ImportResult(
        success: true,
        eventsCount: importedCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Parse a CSV line handling quoted fields
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          currentField += '"';
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    result.add(currentField);
    return result;
  }
}
