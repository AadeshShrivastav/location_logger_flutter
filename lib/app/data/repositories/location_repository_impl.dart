import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/firebase_datasource.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatasource firebaseDatasource;

  LocationRepositoryImpl(this.firebaseDatasource);

  @override
  Future<void> saveLocation(LocationEntity location) async {
    final model = LocationModel(
      userId: location.userId,
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: location.timestamp,
    );

    await firebaseDatasource.saveLocation(model);
  }
}
