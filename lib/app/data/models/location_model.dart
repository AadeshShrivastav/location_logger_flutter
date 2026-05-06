import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  LocationModel({
    required super.userId,
    required super.latitude,
    required super.longitude,
    required super.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "latitude": latitude,
      "longitude": longitude,
      "clientTimestamp": timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      userId: map["userId"],
      latitude: map["latitude"],
      longitude: map["longitude"],
      timestamp: DateTime.parse(map["clientTimestamp"]),
    );
  }
}
