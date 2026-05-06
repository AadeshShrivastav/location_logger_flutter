import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/firebase_datasource.dart';
import '../../data/models/location_model.dart';
import '../../di/injector.dart';

class UserLocationsMapPage extends StatelessWidget {
  final String userId;
  final String userEmail;

  UserLocationsMapPage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  final FirebaseDatasource firebaseDatasource = sl<FirebaseDatasource>();

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

          final points = snapshot.data ?? [];
          if (points.isEmpty) {
            return const Center(child: Text("No locations recorded yet"));
          }

          final latLngPoints = points
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList(growable: false);
          final center = latLngPoints.last;

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.location_logger",
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: latLngPoints,
                    strokeWidth: 4,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: latLngPoints.map((point) {
                  return Marker(
                    point: point,
                    width: 36,
                    height: 36,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 32,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
