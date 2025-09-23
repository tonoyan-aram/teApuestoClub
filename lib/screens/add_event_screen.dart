import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/models/event_template.dart';
import 'package:apuesto_club/models/recurrence_rule.dart';
import 'package:apuesto_club/models/reminder_settings.dart';
import 'package:apuesto_club/services/event_storage_service.dart';
import 'package:apuesto_club/services/recurrence_service.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // Import for File
import 'package:apuesto_club/utils/app_constants.dart'; // Import AppConstants
import 'package:apuesto_club/services/notification_service.dart'; // Import NotificationService
import 'package:apuesto_club/utils/text_utils.dart'; // Import TextUtils
import 'package:apuesto_club/screens/templates_screen.dart';
import 'package:apuesto_club/screens/recurrence_setup_screen.dart';
import 'package:apuesto_club/screens/reminder_setup_screen.dart';

class AddEventScreen extends StatefulWidget {
  // Removed onEventAdded as it's no longer needed for direct callback
  // final Function() onEventAdded;
  final Event? eventToEdit; // Optional parameter for editing
  final EventTemplate? template; // Optional parameter for creating from template

  const AddEventScreen({super.key, /*required this.onEventAdded,*/ this.eventToEdit, this.template});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); // New: For notification time
  bool _isNotificationEnabled = false; // New: To toggle notifications
  int _rating = 3;
  bool _isFavorite = false;
  String? _imageUrl;
  EventCategory _selectedCategory = EventCategory.other; // New state variable for category
  RecurrenceRule? _recurrenceRule; // New state variable for recurrence
  List<Reminder> _reminders = []; // New state variable for reminders
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  final EventStorageService _storageService = EventStorageService();
  final RecurrenceService _recurrenceService = RecurrenceService();
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService(); // Notification service instance

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      // Initialize fields if editing an existing event
      _titleController.text = TextUtils.safeDisplayText(widget.eventToEdit!.title);
      _noteController.text = TextUtils.safeDisplayText(widget.eventToEdit!.note);
      _selectedDate = widget.eventToEdit!.date;
      _rating = widget.eventToEdit!.rating;
      _isFavorite = widget.eventToEdit!.isFavorite;
      _imageUrl = widget.eventToEdit!.imageUrl;
      _selectedCategory = widget.eventToEdit!.category;
      _recurrenceRule = widget.eventToEdit!.recurrenceRule;

      // For existing events, assume notification is enabled if date is in future
      // and set selected time to event date's time
      if (widget.eventToEdit!.date.isAfter(DateTime.now())) {
        _isNotificationEnabled = true;
        _selectedTime = TimeOfDay.fromDateTime(widget.eventToEdit!.date);
      }
    } else if (widget.template != null) {
      // Initialize fields if creating from template
      _titleController.text = widget.template!.title;
      _noteController.text = widget.template!.note ?? '';
      _rating = widget.template!.rating;
      _selectedCategory = widget.template!.category;
      _imageUrl = widget.template!.imageUrl;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path;
      });
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      // Combine selected date and time for notification scheduling
      final DateTime scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      Event eventToSave;

      if (widget.eventToEdit != null) {
        // Update existing event
        eventToSave = Event(
          id: widget.eventToEdit!.id,
          title: _titleController.text,
          date: scheduledDateTime, // Use scheduledDateTime for event date
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          rating: _rating,
          imageUrl: _imageUrl,
          isFavorite: _isFavorite,
          category: _selectedCategory, // Save selected category
          recurrenceRule: _recurrenceRule,
          parentEventId: widget.eventToEdit!.parentEventId,
          isRecurringInstance: widget.eventToEdit!.isRecurringInstance,
        );
        await _storageService.updateEvent(eventToSave);
      } else {
        // Create new event
        eventToSave = Event(
          id: _uuid.v4(),
          title: _titleController.text,
          date: scheduledDateTime, // Use scheduledDateTime for event date
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          rating: _rating,
          imageUrl: _imageUrl,
          isFavorite: _isFavorite,
          category: _selectedCategory, // Save selected category
          recurrenceRule: _recurrenceRule,
        );

        if (_recurrenceRule != null) {
          // Save recurring event series
          final recurringEvents = await _recurrenceService.generateRecurringEvents(
            eventToSave,
            _recurrenceRule!,
          );
          await _recurrenceService.saveRecurringEvents(eventToSave, recurringEvents);
        } else {
          // Save single event
          await _storageService.addEvent(eventToSave);
        }
      }

      // Schedule or cancel notifications
      if (_isNotificationEnabled && _reminders.isNotEmpty) {
        // Schedule multiple reminders
        await _notificationService.scheduleReminders(
          eventId: eventToSave.id,
          eventTitle: eventToSave.title,
          eventDate: scheduledDateTime,
          reminders: _reminders,
          payload: eventToSave.id,
        );
      } else if (_isNotificationEnabled) {
        // Fallback to single notification if no reminders set
        await _notificationService.scheduleNotification(
          id: eventToSave.id.hashCode,
          title: 'Upcoming Event: ${eventToSave.title}',
          body: 'Your event ${eventToSave.title} is scheduled for ${eventToSave.date.toLocal().toString().split(' ')[0]} at ${_selectedTime.format(context)}.',
          scheduledDate: scheduledDateTime,
          payload: eventToSave.id,
        );
      } else {
        // Cancel all notifications for this event
        await _notificationService.cancelNotification(eventToSave.id.hashCode);
        if (_reminders.isNotEmpty) {
          await _notificationService.cancelEventReminders(eventToSave.id, _reminders);
        }
      }

      Navigator.of(context).pop(true); // Return true to indicate a successful save
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit == null ? 'Add Event' : 'Edit Event'),
        actions: [
          if (widget.eventToEdit == null && widget.template == null)
            IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () async {
                // Navigate to templates screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TemplatesScreen(),
                  ),
                );
                if (result != null) {
                  // Apply template data
                  setState(() {
                    _titleController.text = result.title;
                    _noteController.text = result.note ?? '';
                    _rating = result.rating;
                    _selectedCategory = result.category;
                    _imageUrl = result.imageUrl;
                  });
                }
              },
              tooltip: 'Use Template',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              ListTile(
                title: Text('Date: ${TextUtils.safeDisplayText(_selectedDate.toLocal().toString().split(' ')[0])}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              // Category Dropdown
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
                controller: _noteController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (up to 500 characters)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              Row(
                children: [
                  Text('Event Rating:', style: AppConstants.bodyTextStyle),
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
              const SizedBox(height: AppConstants.spacingMedium),
              // Image Picker section
              if (_imageUrl != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    child: Image.file(
                      File(_imageUrl!),
                      fit: BoxFit.cover, 
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick from Gallery'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSmall), // Add some spacing between buttons
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              Row(
                children: [
                  Text('Add to Favorites:', style: AppConstants.bodyTextStyle),
                  Switch(
                    value: _isFavorite,
                    onChanged: (bool value) {
                      setState(() {
                        _isFavorite = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              // Recurrence Section
              Card(
                child: ListTile(
                  title: Text('Recurrence', style: AppConstants.bodyTextStyle),
                  subtitle: Text(
                    _recurrenceRule?.getDescription() ?? 'No recurrence',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: const Icon(Icons.repeat),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecurrenceSetupScreen(
                          initialRule: _recurrenceRule,
                          onSave: (rule) {
                            setState(() {
                              _recurrenceRule = rule;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              // Reminders Section
              Card(
                child: ListTile(
                  title: Text('Reminders', style: AppConstants.bodyTextStyle),
                  subtitle: Text(
                    _reminders.isEmpty 
                        ? 'No reminders set'
                        : '${_reminders.length} reminder${_reminders.length == 1 ? '' : 's'} configured',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: const Icon(Icons.notifications),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ReminderSetupScreen(
                          initialReminders: _reminders,
                          eventCategory: _selectedCategory.name,
                          onSave: (reminders) {
                            setState(() {
                              _reminders = reminders;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppConstants.spacingMedium),
              // Notification Section
              SwitchListTile(
                title: Text('Enable Notification', style: AppConstants.bodyTextStyle),
                value: _isNotificationEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _isNotificationEnabled = value;
                  });
                },
              ),
              if (_isNotificationEnabled)
                ListTile(
                  title: Text('Notification Time: ${TextUtils.safeDisplayText(_selectedTime.format(context))}'),
                  trailing: const Icon(Icons.alarm),
                  onTap: () => _selectTime(context),
                ),
              const SizedBox(height: AppConstants.spacingLarge),
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
