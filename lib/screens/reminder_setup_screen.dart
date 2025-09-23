import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/reminder_settings.dart';
import 'package:apuesto_club/utils/app_constants.dart';

class ReminderSetupScreen extends StatefulWidget {
  final List<Reminder>? initialReminders;
  final String eventCategory;
  final Function(List<Reminder>) onSave;

  const ReminderSetupScreen({
    super.key,
    this.initialReminders,
    required this.eventCategory,
    required this.onSave,
  });

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  List<Reminder> _reminders = [];
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.initialReminders != null) {
      _reminders = List.from(widget.initialReminders!);
    } else {
      // Load smart reminders based on category
      _reminders = ReminderTemplates.getRemindersForCategory(widget.eventCategory);
    }
  }

  void _addReminder() {
    setState(() {
      _reminders.add(Reminder(
        id: _uuid.v4(),
        value: 1,
        type: ReminderType.hours,
        isEnabled: true,
      ));
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  void _updateReminder(int index, Reminder updatedReminder) {
    setState(() {
      _reminders[index] = updatedReminder;
    });
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index] = _reminders[index].copyWith(
        isEnabled: !_reminders[index].isEnabled,
      );
    });
  }

  void _saveReminders() {
    widget.onSave(_reminders);
    Navigator.of(context).pop();
  }

  void _loadSmartReminders() {
    setState(() {
      _reminders = ReminderTemplates.getRemindersForCategory(widget.eventCategory);
    });
  }

  void _clearAllReminders() {
    setState(() {
      _reminders.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _loadSmartReminders,
            tooltip: 'Load Smart Reminders',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllReminders,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Reminders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Set up multiple reminders for your event',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reminders List
          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.spacingMedium),
                        Text(
                          'No reminders set',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSmall),
                        Text(
                          'Add reminders to get notified about your event',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingMedium),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
                        child: ListTile(
                          leading: Switch(
                            value: reminder.isEnabled,
                            onChanged: (value) => _toggleReminder(index),
                          ),
                          title: Text(reminder.getDescription()),
                          subtitle: Text(
                            '${reminder.value} ${reminder.type.toDisplayString().toLowerCase()} before event',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editReminder(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeReminder(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add Button
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Reminder'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveReminders,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editReminder(int index) {
    final reminder = _reminders[index];
    
    showDialog(
      context: context,
      builder: (context) => _ReminderEditDialog(
        reminder: reminder,
        onSave: (updatedReminder) => _updateReminder(index, updatedReminder),
      ),
    );
  }
}

class _ReminderEditDialog extends StatefulWidget {
  final Reminder reminder;
  final Function(Reminder) onSave;

  const _ReminderEditDialog({
    required this.reminder,
    required this.onSave,
  });

  @override
  State<_ReminderEditDialog> createState() => _ReminderEditDialogState();
}

class _ReminderEditDialogState extends State<_ReminderEditDialog> {
  late int _value;
  late ReminderType _type;
  late String _customMessage;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _value = widget.reminder.value;
    _type = widget.reminder.type;
    _customMessage = widget.reminder.customMessage ?? '';
    _isEnabled = widget.reminder.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _value.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _value = int.tryParse(value) ?? 1;
                  },
                ),
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              Expanded(
                child: DropdownButtonFormField<ReminderType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ReminderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toDisplayString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          TextFormField(
            initialValue: _customMessage,
            decoration: const InputDecoration(
              labelText: 'Custom Message (Optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _customMessage = value;
            },
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          SwitchListTile(
            title: const Text('Enabled'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedReminder = widget.reminder.copyWith(
              value: _value,
              type: _type,
              customMessage: _customMessage.isEmpty ? null : _customMessage,
              isEnabled: _isEnabled,
            );
            widget.onSave(updatedReminder);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

