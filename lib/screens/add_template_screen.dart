import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/event_template.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/services/template_storage_service.dart';
import 'package:apuesto_club/utils/app_constants.dart';
import 'package:apuesto_club/utils/text_utils.dart';

class AddTemplateScreen extends StatefulWidget {
  final EventTemplate? templateToEdit;

  const AddTemplateScreen({super.key, this.templateToEdit});

  @override
  State<AddTemplateScreen> createState() => _AddTemplateScreenState();
}

class _AddTemplateScreenState extends State<AddTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _rating = 3;
  EventCategory _selectedCategory = EventCategory.other;
  final TemplateStorageService _templateService = TemplateStorageService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.templateToEdit != null) {
      _nameController.text = widget.templateToEdit!.name;
      _titleController.text = widget.templateToEdit!.title;
      _noteController.text = widget.templateToEdit!.note ?? '';
      _descriptionController.text = widget.templateToEdit!.description ?? '';
      _rating = widget.templateToEdit!.rating;
      _selectedCategory = widget.templateToEdit!.category;
    }
  }

  void _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      EventTemplate templateToSave;

      if (widget.templateToEdit != null) {
        // Update existing template
        templateToSave = EventTemplate(
          id: widget.templateToEdit!.id,
          name: _nameController.text,
          title: _titleController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          rating: _rating,
          category: _selectedCategory,
          isPredefined: widget.templateToEdit!.isPredefined,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );
        await _templateService.updateTemplate(templateToSave);
      } else {
        // Create new template
        templateToSave = EventTemplate(
          id: _uuid.v4(),
          name: _nameController.text,
          title: _titleController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          rating: _rating,
          category: _selectedCategory,
          isPredefined: false,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );
        await _templateService.addTemplate(templateToSave);
      }

      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.templateToEdit == null ? 'Add Template' : 'Edit Template'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'e.g., Football Match Template',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a template name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g., Football Match',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              DropdownButtonFormField<EventCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem<EventCategory>(
                    value: category,
                    child: Text(TextUtils.safeDisplayText(category.toDisplayString())),
                  );
                }).toList(),
                onChanged: (EventCategory? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Template Description (Optional)',
                  hintText: 'Brief description of this template',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Default Note (Optional)',
                  hintText: 'Default note for events created from this template',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              Row(
                children: [
                  Text('Default Rating:', style: AppConstants.bodyTextStyle),
                  Expanded(
                    child: Slider(
                      value: _rating.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _rating.toString(),
                      onChanged: (double newValue) {
                        setState(() {
                          _rating = newValue.round();
                        });
                      },
                    ),
                  ),
                  Text(_rating.toString(), style: AppConstants.bodyTextStyle),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              ElevatedButton(
                onPressed: _saveTemplate,
                child: Text(widget.templateToEdit == null ? 'Create Template' : 'Update Template'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
