import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apuesto_club/models/event_template.dart';
import 'package:apuesto_club/models/event.dart';

class TemplateStorageService {
  static const String _templatesKey = 'event_templates';
  static const String _predefinedTemplatesKey = 'predefined_templates_loaded';

  // Predefined templates
  static final List<EventTemplate> _predefinedTemplates = [
    EventTemplate(
      id: 'football_match',
      name: 'Football Match',
      title: 'Football Match',
      note: 'Watch the game and enjoy!',
      rating: 4,
      category: EventCategory.football,
      isPredefined: true,
      description: 'Template for football matches',
    ),
    EventTemplate(
      id: 'basketball_game',
      name: 'Basketball Game',
      title: 'Basketball Game',
      note: 'Exciting basketball action!',
      rating: 4,
      category: EventCategory.basketball,
      isPredefined: true,
      description: 'Template for basketball games',
    ),
    EventTemplate(
      id: 'tennis_tournament',
      name: 'Tennis Tournament',
      title: 'Tennis Tournament',
      note: 'Follow the tournament matches',
      rating: 5,
      category: EventCategory.tennis,
      isPredefined: true,
      description: 'Template for tennis tournaments',
    ),
    EventTemplate(
      id: 'marathon_run',
      name: 'Marathon Run',
      title: 'Marathon Run',
      note: 'Track your running progress',
      rating: 5,
      category: EventCategory.marathon,
      isPredefined: true,
      description: 'Template for marathon events',
    ),
    EventTemplate(
      id: 'gym_workout',
      name: 'Gym Workout',
      title: 'Gym Workout',
      note: 'Strength training session',
      rating: 3,
      category: EventCategory.other,
      isPredefined: true,
      description: 'Template for gym workouts',
    ),
    EventTemplate(
      id: 'swimming_session',
      name: 'Swimming Session',
      title: 'Swimming Session',
      note: 'Pool or open water swimming',
      rating: 4,
      category: EventCategory.other,
      isPredefined: true,
      description: 'Template for swimming activities',
    ),
  ];

  Future<List<EventTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesString = prefs.getStringList(_templatesKey) ?? [];
    
    // Load user-created templates
    final userTemplates = templatesString
        .map((templateJson) => EventTemplate.fromJson(json.decode(templateJson)))
        .toList();

    // Check if predefined templates have been loaded
    final predefinedLoaded = prefs.getBool(_predefinedTemplatesKey) ?? false;
    
    if (!predefinedLoaded) {
      // Add predefined templates to user templates
      userTemplates.addAll(_predefinedTemplates);
      await _saveTemplates(userTemplates);
      await prefs.setBool(_predefinedTemplatesKey, true);
    }

    return userTemplates;
  }

  Future<void> _saveTemplates(List<EventTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = templates.map((template) => json.encode(template.toJson())).toList();
    await prefs.setStringList(_templatesKey, templatesJson);
  }

  Future<void> addTemplate(EventTemplate template) async {
    List<EventTemplate> templates = await loadTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }

  Future<void> updateTemplate(EventTemplate updatedTemplate) async {
    List<EventTemplate> templates = await loadTemplates();
    final index = templates.indexWhere((template) => template.id == updatedTemplate.id);
    if (index != -1) {
      templates[index] = updatedTemplate;
      await _saveTemplates(templates);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    List<EventTemplate> templates = await loadTemplates();
    // Don't allow deletion of predefined templates
    templates.removeWhere((template) => template.id == templateId && !template.isPredefined);
    await _saveTemplates(templates);
  }

  Future<List<EventTemplate>> getPredefinedTemplates() async {
    return _predefinedTemplates;
  }

  Future<List<EventTemplate>> getUserTemplates() async {
    final allTemplates = await loadTemplates();
    return allTemplates.where((template) => !template.isPredefined).toList();
  }
}
