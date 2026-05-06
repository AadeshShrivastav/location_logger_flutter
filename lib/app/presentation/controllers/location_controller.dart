import 'dart:async';
import 'package:get/get.dart';
import '../../background/live_location_background_service.dart';
import '../../config/tracking_config.dart';
import '../../domain/useCases/save_location_usecase.dart';
import '../../domain/entities/location_entity.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/location_datasource.dart';

class LocationController extends GetxController {
  final SaveLocationUseCase saveLocationUseCase;
  final LocationDatasource locationDatasource;
  final AuthDatasource authDatasource;

  LocationController(
    this.saveLocationUseCase,
    this.locationDatasource,
    this.authDatasource,
  );

  RxString status = "Idle".obs;
  RxBool isTracking = false.obs;
  Rxn<DateTime> lastSavedAt = Rxn<DateTime>();
  bool _isInBackground = false;
  Timer? _foregroundTimer;

  Future<void> fetchAndSaveLocation() async {
    try {
      status.value = "Fetching...";

      final currentUser = authDatasource.currentUser;
      if (currentUser == null) {
        throw Exception("Please sign in to save location");
      }

      final position = await locationDatasource.getCurrentLocation();

      final entity = LocationEntity(
        userId: currentUser.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await saveLocationUseCase(entity);
      lastSavedAt.value = entity.timestamp;

      status.value =
          "Saved: ${entity.latitude}, ${entity.longitude} at ${entity.timestamp}";
    } catch (e) {
      status.value = "Error: $e";
    }
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;

    final currentUser = authDatasource.currentUser;
    if (currentUser == null) {
      status.value = "Error: Please sign in to start tracking";
      return;
    }

    isTracking.value = true;
    _isInBackground = false;
    status.value = "Tracking started";
    LiveLocationBackgroundService.pauseTracking();
    _startForegroundLoop(saveImmediately: true);
  }

  void pauseTracking() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    LiveLocationBackgroundService.pauseTracking();
    isTracking.value = false;
    _isInBackground = false;
    status.value = "Paused";
  }

  Future<void> onAppPaused() async {
    if (!isTracking.value || _isInBackground) return;

    final currentUser = authDatasource.currentUser;
    if (currentUser == null) return;

    try {
      _isInBackground = true;
      _foregroundTimer?.cancel();
      _foregroundTimer = null;
      status.value = "Background tracking active";
      await LiveLocationBackgroundService.startTracking(currentUser.uid);
    } catch (e) {
      // If service start fails, keep tracking alive in foreground path.
      _isInBackground = false;
      status.value = "Background start failed: $e";
      _startForegroundLoop(saveImmediately: false);
    }
  }

  void onAppResumed() {
    if (!isTracking.value || !_isInBackground) return;

    try {
      _isInBackground = false;
      LiveLocationBackgroundService.pauseTracking();
      status.value = "Foreground tracking active";
      _startForegroundLoop(saveImmediately: false);
    } catch (e) {
      status.value = "Resume tracking error: $e";
    }
  }

  void _startForegroundLoop({required bool saveImmediately}) {
    _foregroundTimer?.cancel();

    if (saveImmediately) {
      fetchAndSaveLocation();
    }

    _foregroundTimer = Timer.periodic(
      const Duration(seconds: TrackingConfig.intervalSeconds),
      (_) {
      if (!isTracking.value || _isInBackground) return;
      if (authDatasource.currentUser == null) {
        pauseTracking();
        status.value = "Paused: user signed out";
        return;
      }
      fetchAndSaveLocation();
      },
    );
  }

  @override
  void onClose() {
    _foregroundTimer?.cancel();
    LiveLocationBackgroundService.pauseTracking();
    super.onClose();
  }
}
