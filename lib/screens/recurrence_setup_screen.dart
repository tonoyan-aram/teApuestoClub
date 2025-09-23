import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:apuesto_club/models/recurrence_rule.dart';
import 'package:apuesto_club/utils/app_constants.dart';
import 'package:apuesto_club/utils/text_utils.dart';

class RecurrenceSetupScreen extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final Function(RecurrenceRule?) onSave;

  const RecurrenceSetupScreen({
    super.key,
    this.initialRule,
    required this.onSave,
  });

  @override
  State<RecurrenceSetupScreen> createState() => _RecurrenceSetupScreenState();
}

class _RecurrenceSetupScreenState extends State<RecurrenceSetupScreen> {
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _interval = 1;
  List<int> _selectedDaysOfWeek = [];
  int? _dayOfMonth;
  RecurrenceEndType _endType = RecurrenceEndType.never;
  int _maxOccurrences = 10;
  DateTime? _endDate;

  final List<String> _dayNames = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
    'Thursday', 'Friday', 'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRule != null) {
      _frequency = widget.initialRule!.frequency;
      _interval = widget.initialRule!.interval;
      _selectedDaysOfWeek = List.from(widget.initialRule!.daysOfWeek ?? []);
      _dayOfMonth = widget.initialRule!.dayOfMonth;
      _endType = widget.initialRule!.endType;
      _maxOccurrences = widget.initialRule!.maxOccurrences ?? 10;
      _endDate = widget.initialRule!.endDate;
    }
  }

  void _saveRecurrence() {
    if (_frequency == RecurrenceFrequency.weekly && _selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_frequency == RecurrenceFrequency.monthly && _dayOfMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a day of the month'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final rule = RecurrenceRule(
      id: widget.initialRule?.id ?? now.millisecondsSinceEpoch.toString(),
      frequency: _frequency,
      interval: _interval,
      daysOfWeek: _selectedDaysOfWeek,
      dayOfMonth: _dayOfMonth,
      endType: _endType,
      maxOccurrences: _endType == RecurrenceEndType.afterOccurrences ? _maxOccurrences : null,
      endDate: _endType == RecurrenceEndType.onDate ? _endDate : null,
      createdAt: widget.initialRule?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(rule);
    Navigator.of(context).pop();
  }

  void _removeRecurrence() {
    widget.onSave(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurrence Settings'),
        actions: [
          if (widget.initialRule != null)
            TextButton(
              onPressed: _removeRecurrence,
              child: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frequency Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repeat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceFrequency>(
                            value: _frequency,
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(),
                            ),
                            items: RecurrenceFrequency.values.map((frequency) {
                              return DropdownMenuItem(
                                value: frequency,
                                child: Text(TextUtils.safeDisplayText(frequency.toDisplayString())),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _frequency = value!;
                                if (value != RecurrenceFrequency.weekly) {
                                  _selectedDaysOfWeek.clear();
                                }
                                if (value != RecurrenceFrequency.monthly) {
                                  _dayOfMonth = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSmall),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: _interval.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Every',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _interval = int.tryParse(value) ?? 1;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),

            // Days of Week (for weekly)
            if (_frequency == RecurrenceFrequency.weekly)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days of Week',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingSmall),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final isSelected = _selectedDaysOfWeek.contains(index);
                          return FilterChip(
                            label: Text(_dayNames[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDaysOfWeek.add(index);
                                } else {
                                  _selectedDaysOfWeek.remove(index);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

            // Day of Month (for monthly)
            if (_frequency == RecurrenceFrequency.monthly)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day of Month',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingSmall),
                      DropdownButtonFormField<int>(
                        value: _dayOfMonth,
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(31, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text(day.toString()),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _dayOfMonth = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppConstants.spacingMedium),

            // End Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    RadioListTile<RecurrenceEndType>(
                      title: const Text('Never'),
                      value: RecurrenceEndType.never,
                      groupValue: _endType,
                      onChanged: (value) {
                        setState(() {
                          _endType = value!;
                        });
                      },
                    ),
                    RadioListTile<RecurrenceEndType>(
                      title: const Text('After occurrences'),
                      value: RecurrenceEndType.afterOccurrences,
                      groupValue: _endType,
                      onChanged: (value) {
                        setState(() {
                          _endType = value!;
                        });
                      },
                    ),
                    if (_endType == RecurrenceEndType.afterOccurrences)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: TextFormField(
                          initialValue: _maxOccurrences.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Number of occurrences',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxOccurrences = int.tryParse(value) ?? 10;
                          },
                        ),
                      ),
                    RadioListTile<RecurrenceEndType>(
                      title: const Text('On date'),
                      value: RecurrenceEndType.onDate,
                      groupValue: _endType,
                      onChanged: (value) {
                        setState(() {
                          _endType = value!;
                        });
                      },
                    ),
                    if (_endType == RecurrenceEndType.onDate)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ListTile(
                          title: Text(
                            _endDate != null 
                                ? 'End date: ${_endDate!.toLocal().toString().split(' ')[0]}'
                                : 'Select end date',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Preview
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      _getPreviewText(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecurrence,
                child: const Text('Save Recurrence'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText() {
    final now = DateTime.now();
    final rule = RecurrenceRule(
      id: 'preview',
      frequency: _frequency,
      interval: _interval,
      daysOfWeek: _selectedDaysOfWeek,
      dayOfMonth: _dayOfMonth,
      endType: _endType,
      maxOccurrences: _endType == RecurrenceEndType.afterOccurrences ? _maxOccurrences : null,
      endDate: _endType == RecurrenceEndType.onDate ? _endDate : null,
      createdAt: now,
      updatedAt: now,
    );

    return rule.getDescription();
  }
}

