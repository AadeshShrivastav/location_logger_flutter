class LocationEntity {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationEntity({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
