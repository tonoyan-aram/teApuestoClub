import 'package:flutter/material.dart';
import 'dart:io'; // Required for File
import 'package:apuesto_club/models/event.dart'; // Use absolute path
import 'package:apuesto_club/services/event_storage_service.dart'; // Use absolute path
import 'package:apuesto_club/utils/app_constants.dart'; // Import AppConstants
import 'package:apuesto_club/services/notification_service.dart'; // Import NotificationService
import 'package:apuesto_club/utils/text_utils.dart'; // Import TextUtils
import 'add_event_screen.dart'; // Added import for AddEventScreen
import 'package:share_plus/share_plus.dart'; // Added import for share_plus

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Event> _events = [];
  List<Event> _filteredEvents = []; // Added for filtered/sorted events
  final EventStorageService _storageService = EventStorageService();
  final NotificationService _notificationService =
      NotificationService(); // Notification service instance
  final TextEditingController _searchController =
      TextEditingController(); // Added search controller
  String _searchQuery = '';
  String _sortOption = 'date_desc'; // Default sort option
  DateTime? _filterStartDate; // Added for date range filter
  DateTime? _filterEndDate; // Added for date range filter
  int? _filterMinRating; // Added for minimum rating filter
  EventCategory? _filterCategory; // New: Filter by category

  @override
  void initState() {
    super.initState();
    loadEvents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFiltersAndSort();
      });
    });
  }

  Future<void> loadEvents() async {
    final events = await _storageService.loadEvents();
    setState(() {
      _events = events;
      _applyFiltersAndSort(); // Apply filters and sort after loading events
    });
  }

  void _applyFiltersAndSort() {
    List<Event> tempEvents = List.from(_events);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      tempEvents = tempEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(searchLower) ||
                (event.note?.toLowerCase().contains(searchLower) ?? false),
          )
          .toList();
    }

    // Apply date range filter
    if (_filterStartDate != null) {
      final startDate = _filterStartDate!.subtract(const Duration(days: 1));
      tempEvents = tempEvents
          .where((event) => event.date.isAfter(startDate))
          .toList();
    }
    if (_filterEndDate != null) {
      final endDate = _filterEndDate!.add(const Duration(days: 1));
      tempEvents = tempEvents
          .where((event) => event.date.isBefore(endDate))
          .toList();
    }

    // Apply minimum rating filter
    if (_filterMinRating != null) {
      final minRating = _filterMinRating!;
      tempEvents = tempEvents
          .where((event) => event.rating >= minRating)
          .toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      final category = _filterCategory!;
      tempEvents = tempEvents
          .where((event) => event.category == category)
          .toList();
    }

    // Apply sorting
    tempEvents.sort((a, b) {
      switch (_sortOption) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'date_desc':
          return b.date.compareTo(a.date);
        case 'title_asc':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'title_desc':
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        default:
          return 0;
      }
    });

    setState(() {
      _filteredEvents = tempEvents;
    });
  }

  Future<void> _selectFilterDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStartDate ? _filterStartDate : _filterEndDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filterStartDate = picked;
        } else {
          _filterEndDate = picked;
        }
        _applyFiltersAndSort();
      });
    }
  }

  void _showRatingFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempRating = _filterMinRating ?? 1;
        return AlertDialog(
          title: const Text("Filter by Minimum Rating"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Slider(
                value: tempRating.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: tempRating.toString(),
                onChanged: (double newValue) {
                  setState(() {
                    tempRating = newValue.round();
                  });
                },
              ),
              Text('Minimum Rating: ${tempRating.toString()}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterMinRating = tempRating;
                  _applyFiltersAndSort();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _filterMinRating = null;
      _filterCategory = null; // Clear category filter
      _searchController.clear();
      _searchQuery = '';
      _sortOption = 'date_desc'; // Reset to default sort
      _applyFiltersAndSort();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home (Event List)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: EventSearchDelegate(
                  events: _events,
                  onSearch: (query) {
                    setState(() {
                      _searchController.text = query;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter modalSetState) {
                      return Container(
                        padding: const EdgeInsets.all(
                          AppConstants.spacingMedium,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Filter Events',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppConstants.spacingMedium),
                            ListTile(
                              title: Text(
                                'Start Date: ${_filterStartDate?.toLocal().toString().split(' ')[0] ?? 'Any'}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                await _selectFilterDate(
                                  context,
                                  isStartDate: true,
                                );
                                modalSetState(() {}); // Refresh modal state
                              },
                            ),
                            ListTile(
                              title: Text(
                                'End Date: ${_filterEndDate?.toLocal().toString().split(' ')[0] ?? 'Any'}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                await _selectFilterDate(
                                  context,
                                  isStartDate: false,
                                );
                                modalSetState(() {}); // Refresh modal state
                              },
                            ),
                            ListTile(
                              title: Text(
                                'Min Rating: ${_filterMinRating ?? 'Any'}',
                              ),
                              trailing: const Icon(Icons.star),
                              onTap: () async {
                                // Show rating filter dialog
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    int tempRating = _filterMinRating ?? 1;
                                    return AlertDialog(
                                      title: const Text(
                                        "Filter by Minimum Rating",
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Slider(
                                            value: tempRating.toDouble(),
                                            min: 1,
                                            max: 5,
                                            divisions: 4,
                                            label: tempRating.toString(),
                                            onChanged: (double newValue) {
                                              modalSetState(() {
                                                // Update modal's state
                                                tempRating = newValue.round();
                                              });
                                            },
                                          ),
                                          Text(
                                            'Minimum Rating: ${tempRating.toString()}',
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              // Update HomeScreen's state
                                              _filterMinRating = tempRating;
                                              _applyFiltersAndSort();
                                            });
                                            Navigator.of(context).pop();
                                            modalSetState(
                                              () {},
                                            ); // Refresh modal state
                                          },
                                          child: const Text("Apply"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              title: Text(
                                'Category: ${_filterCategory?.toDisplayString() ?? 'Any'}',
                              ),
                              trailing: const Icon(Icons.category),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Filter by Category"),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: EventCategory.values
                                              .map(
                                                (
                                                  category,
                                                ) => RadioListTile<EventCategory>(
                                                  title: Text(
                                                    category.toDisplayString(),
                                                  ),
                                                  value: category,
                                                  groupValue: _filterCategory,
                                                  onChanged:
                                                      (EventCategory? value) {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        setState(() {
                                                          _filterCategory =
                                                              value;
                                                          _applyFiltersAndSort();
                                                        });
                                                        modalSetState(() {});
                                                      },
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _filterCategory =
                                                  null; // Clear category filter
                                              _applyFiltersAndSort();
                                            });
                                            Navigator.of(context).pop();
                                            modalSetState(() {});
                                          },
                                          child: const Text("Clear Category"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppConstants.spacingMedium),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _clearFilters();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Clear Filters'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _applyFiltersAndSort();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Apply Filters'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String result) {
              setState(() {
                _sortOption = result;
                _applyFiltersAndSort();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'date_asc',
                child: Text('Sort by Date (Asc)'),
              ),
              const PopupMenuItem<String>(
                value: 'date_desc',
                child: Text('Sort by Date (Desc)'),
              ),
              const PopupMenuItem<String>(
                value: 'title_asc',
                child: Text('Sort by Title (A-Z)'),
              ),
              const PopupMenuItem<String>(
                value: 'title_desc',
                child: Text('Sort by Title (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingSmall),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events found. Adjust your search or filters.',
                      style: AppConstants.bodyTextStyle.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return Dismissible(
                        key: ValueKey(event.id), // Unique key for Dismissible
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingMedium,
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text(
                                  "Are you sure you want to delete this event?",
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteEvent(event.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Event \'${TextUtils.safeDisplayText(event.title)}\' deleted'),
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () async {
                            // Navigate to Add Event screen for editing
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddEventScreen(
                                  eventToEdit: event, // Pass the event to edit
                                ),
                              ),
                            );
                            if (result == true) {
                              loadEvents(); // Refresh events after edit
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Event \'${event.title}\' updated successfully!',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _EventCard(
                            event: event,
                            onToggleFavorite: () async {
                              await _storageService.toggleFavoriteStatus(
                                event.id,
                                !event.isFavorite,
                              );
                              loadEvents();
                            },
                            onShare: () => _shareEvent(event),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to Add Event screen for creating a new event
          debugPrint('Navigating to AddEventScreen for new event...');
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
          debugPrint('Returned from AddEventScreen with result: $result');
          if (result == true) {
            debugPrint(
              'Result is true, calling loadEvents() and showing Snackbar...',
            );
            loadEvents(); // Refresh events after creation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );
          } else {
            debugPrint(
              'Result is not true or null. Not refreshing list or showing Snackbar.',
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    await _storageService.deleteEvent(eventId);
    await _notificationService.cancelNotification(
      eventId.hashCode,
    ); // Cancel notification
    loadEvents(); // Refresh events after deletion
  }

  Future<void> _shareEvent(Event event) async {
    final String eventDetails =
        'Check out this event: ${TextUtils.safeDisplayText(event.title)} on ${event.date.toLocal().toString().split(' ')[0]} in category ${TextUtils.safeDisplayText(event.category.toDisplayString())}.${event.note != null && event.note!.isNotEmpty ? ' Note: ${TextUtils.safeDisplayText(event.note)}' : ''}';
    await Share.share(eventDetails);
  }
}

// Custom Search Delegate for in-app search functionality
class EventSearchDelegate extends SearchDelegate<String> {
  final List<Event> events;
  final Function(String) onSearch;

  EventSearchDelegate({required this.events, required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return Container(); // Results are displayed on the HomeScreen
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? events // Show all events if search query is empty
        : events
              .where(
                (event) =>
                    event.title.toLowerCase().contains(query.toLowerCase()) ||
                    (event.note?.toLowerCase().contains(query.toLowerCase()) ??
                        false) ||
                    event.category.toDisplayString().toLowerCase().contains(
                      query.toLowerCase(),
                    ), // Search by category
              )
              .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final event = suggestionList[index];
        return ListTile(
          title: Text(TextUtils.safeDisplayText(event.title)),
          subtitle: Text(
            '${TextUtils.safeDisplayText(event.category.toDisplayString())} - ${TextUtils.safeDisplayText(event.note)}',
          ), // Display category in subtitle
          onTap: () {
            query = TextUtils.safeDisplayText(event.title); // Set query to the selected event's title
            onSearch(query);
            close(context, query);
          },
        );
      },
    );
  }
}

// Memoized event card widget for better performance
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  const _EventCard({
    required this.event,
    required this.onToggleFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.spacingSmall),
      color: Colors.white60,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  TextUtils.safeDisplayText(event.category.toDisplayString()),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Expanded(
                  child: Text(
                    TextUtils.safeDisplayText(event.title),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text('Date: ${TextUtils.safeDisplayText(event.date.toLocal().toString().split(' ')[0])}'),
            const SizedBox(height: AppConstants.spacingSmall),
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              _SafeImageWidget(imageUrl: event.imageUrl!),
            const SizedBox(height: AppConstants.spacingSmall),
            Row(
              children: List.generate(5, (starIndex) {
                return Icon(
                  starIndex < event.rating ? Icons.star : Icons.star_border,
                  color: Theme.of(context).colorScheme.secondary,
                );
              }),
            ),
            if (event.note != null && event.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingSmall),
                child: Text('Note: ${TextUtils.safeDisplayText(event.note)}'),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(
                  event.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: event.isFavorite
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                onPressed: onToggleFavorite,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: IconButton(
                icon: const Icon(Icons.share),
                color: Theme.of(context).colorScheme.secondary,
                onPressed: onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Safe image widget that handles file existence checks
class _SafeImageWidget extends StatefulWidget {
  final String imageUrl;

  const _SafeImageWidget({required this.imageUrl});

  @override
  State<_SafeImageWidget> createState() => _SafeImageWidgetState();
}

class _SafeImageWidgetState extends State<_SafeImageWidget> {
  bool _fileExists = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    if (widget.imageUrl.startsWith('http')) {
      setState(() {
        _isLoading = false;
        _fileExists = true;
      });
      return;
    }

    try {
      final file = File(Uri.parse(widget.imageUrl).toFilePath());
      final exists = await file.exists();
      setState(() {
        _fileExists = exists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fileExists = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_fileExists) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Image not found', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: (Uri.parse(widget.imageUrl).scheme == 'http' ||
              Uri.parse(widget.imageUrl).scheme == 'https')
          ? Image.network(
              widget.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
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
            )
          : Image.file(
              File(Uri.parse(widget.imageUrl).toFilePath()),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
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
    );
  }
}
