import 'package:flutter/material.dart';
import 'package:apuesto_club/models/event_template.dart';
import 'package:apuesto_club/services/template_storage_service.dart';
import 'package:apuesto_club/utils/app_constants.dart';
import 'package:apuesto_club/utils/text_utils.dart';
import 'package:apuesto_club/screens/add_template_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<EventTemplate> _templates = [];
  List<EventTemplate> _predefinedTemplates = [];
  List<EventTemplate> _userTemplates = [];
  final TemplateStorageService _templateService = TemplateStorageService();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _templateService.loadTemplates();
    final predefined = await _templateService.getPredefinedTemplates();
    final user = await _templateService.getUserTemplates();
    
    setState(() {
      _templates = templates;
      _predefinedTemplates = predefined;
      _userTemplates = user;
    });
  }

  Future<void> _deleteTemplate(EventTemplate template) async {
    if (template.isPredefined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete predefined templates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Template'),
          content: Text('Are you sure you want to delete "${TextUtils.safeDisplayText(template.name)}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _templateService.deleteTemplate(template.id);
      _loadTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "${TextUtils.safeDisplayText(template.name)}" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddTemplateScreen(),
                ),
              );
              if (result == true) {
                _loadTemplates();
              }
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All Templates'),
                Tab(text: 'My Templates'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTemplatesList(_templates),
                  _buildTemplatesList(_userTemplates),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(List<EventTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_copy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Create your first template to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                TextUtils.safeDisplayText(template.category.toDisplayString()).substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(TextUtils.safeDisplayText(template.name)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TextUtils.safeDisplayText(template.title)),
                if (template.description != null)
                  Text(
                    TextUtils.safeDisplayText(template.description),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                Row(
                  children: [
                    Text(TextUtils.safeDisplayText(template.category.toDisplayString())),
                    const SizedBox(width: AppConstants.spacingSmall),
                    ...List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < template.rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      );
                    }),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!template.isPredefined)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTemplateScreen(templateToEdit: template),
                        ),
                      );
                      if (result == true) {
                        _loadTemplates();
                      }
                    },
                  ),
                if (!template.isPredefined)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTemplate(template),
                    color: Colors.red,
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'use') {
                      Navigator.of(context).pop(template);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'use',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text('Use Template'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).pop(template);
            },
          ),
        );
      },
    );
  }
}
