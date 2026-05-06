import 'package:get_it/get_it.dart';
import '../data/datasources/auth_datasource.dart';
import '../data/datasources/firebase_datasource.dart';
import '../data/datasources/location_datasource.dart';
import '../data/repositories/location_repository_impl.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/useCases/save_location_usecase.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/controllers/location_controller.dart';

final sl = GetIt.instance; // sl = service locator

Future<void> initDependencies() async {
  // Data Sources
  sl.registerLazySingleton(() => AuthDatasource());
  sl.registerLazySingleton(() => FirebaseDatasource());
  sl.registerLazySingleton(() => LocationDatasource());

  // Repository
  sl.registerLazySingleton<LocationRepository>(
        () => LocationRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SaveLocationUseCase(sl()));

  // Controllers
  sl.registerLazySingleton(() => AuthController(sl(), sl()));
  sl.registerFactory(() => LocationController(sl(), sl(), sl()));
}
