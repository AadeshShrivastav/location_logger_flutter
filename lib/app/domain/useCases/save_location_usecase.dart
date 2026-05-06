import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class SaveLocationUseCase {
  final LocationRepository repository;

  SaveLocationUseCase(this.repository);

  Future<void> call(LocationEntity location) {
    return repository.saveLocation(location);
  }
}
