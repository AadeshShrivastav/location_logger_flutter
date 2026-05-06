import 'package:location_logger/app/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<void> saveLocation(LocationEntity location);
}
