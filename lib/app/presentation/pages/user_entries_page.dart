import 'package:flutter/material.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/location_model.dart';
import '../../di/injector.dart';
import 'user_locations_map_page.dart';

class UserEntriesPage extends StatelessWidget {
  final String userId;
  final String userEmail;

  UserEntriesPage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  final FirebaseDatasource firebaseDatasource = sl<FirebaseDatasource>();

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userEmail.isEmpty ? userId : userEmail),
      ),
      body: StreamBuilder<List<LocationModel>>(
        stream: firebaseDatasource.streamUserLocations(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("No location entries found"),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.map),
                    label: const Text("Open Map"),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserLocationsMapPage(
                            userId: userId,
                            userEmail: userEmail,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text("Open Map"),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        "Lat: ${item.latitude.toStringAsFixed(6)}, Lng: ${item.longitude.toStringAsFixed(6)}",
                      ),
                      subtitle: Text(_formatDateTime(item.timestamp)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
