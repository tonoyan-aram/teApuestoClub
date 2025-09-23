import 'package:flutter/material.dart';
import 'package:apuesto_club/models/event.dart';
import 'package:apuesto_club/services/event_storage_service.dart';
import 'package:apuesto_club/utils/text_utils.dart';
import 'dart:io'; // Required for File

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Event> _favoriteEvents = [];
  final EventStorageService _storageService = EventStorageService();

  @override
  void initState() {
    super.initState();
    _loadFavoriteEvents();
  }

  Future<void> _loadFavoriteEvents() async {
    final allEvents = await _storageService.loadEvents();
    setState(() {
      _favoriteEvents = allEvents.where((event) => event.isFavorite).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40.0, // Reduced height
        title: const Text('Favorites'), // Added title back
      ),
      body: _favoriteEvents.isEmpty
          ? const Center(
              child: Text('No favorite events.'),
            )
          : ListView.builder(
              itemCount: _favoriteEvents.length,
              itemBuilder: (context, index) {
                final event = _favoriteEvents[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TextUtils.safeDisplayText(event.title),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Date: ${TextUtils.safeDisplayText(event.date.toLocal().toString().split(' ')[0])}'),
                        const SizedBox(height: 8),
                        if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0), // Rounded corners for image
                            child: (Uri.parse(event.imageUrl!).scheme == 'http' || Uri.parse(event.imageUrl!).scheme == 'https')
                                ? Image.network(event.imageUrl!,
                                    height: 150, width: double.infinity, fit: BoxFit.cover)
                                : Image.file(File(Uri.parse(event.imageUrl!).toFilePath()),
                                    height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < event.rating ? Icons.star : Icons.star_border,
                              color: Theme.of(context).colorScheme.secondary, // Use accent color for stars
                            );
                          }),
                        ),
                        if (event.note != null && event.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Note: ${TextUtils.safeDisplayText(event.note)}'),
                          ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: Icon(
                              event.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: event.isFavorite ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            onPressed: () async {
                              await _storageService.toggleFavoriteStatus(event.id, !event.isFavorite);
                              _loadFavoriteEvents(); // Refresh events after toggling favorite status
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
