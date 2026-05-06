import 'dart:ui';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_logger/firebase_options.dart';
import '../config/tracking_config.dart';

class LiveLocationBackgroundService {
  static const String _cmdStartTracking = "startTracking";
  static const String _cmdPauseTracking = "pauseTracking";
  static const String _cmdStopService = "stopService";

  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: false,
        foregroundServiceNotificationId: 1001,
        initialNotificationTitle: "Location Logger",
        initialNotificationContent: "Tracking paused",
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> startTracking(String userId) async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _service.invoke(_cmdStartTracking, {"userId": userId});
  }

  static void pauseTracking() {
    _service.invoke(_cmdPauseTracking);
  }

  static void stopService() {
    _service.invoke(_cmdStopService);
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    String? currentUserId;
    bool isTracking = false;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: "Location Logger",
        content: "Tracking paused",
      );
    }

    service.on(_cmdStartTracking).listen((event) {
      final userId = (event?["userId"] ?? "").toString();
      if (userId.isEmpty) return;
      currentUserId = userId;
      isTracking = true;

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Location Logger",
          content:
              "Tracking active (every ${TrackingConfig.intervalSeconds} seconds)",
        );
      }
    });

    service.on(_cmdPauseTracking).listen((event) {
      isTracking = false;
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Location Logger",
          content: "Tracking paused",
        );
      }
    });

    service.on(_cmdStopService).listen((event) {
      service.stopSelf();
    });

    Timer.periodic(
      const Duration(seconds: TrackingConfig.intervalSeconds),
      (timer) async {
      if (!isTracking) return;
      if (currentUserId == null || currentUserId!.isEmpty) return;

      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) return;

        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserId)
            .collection("location_logs")
            .doc("current_location")
            .set({
          "userId": currentUserId,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "clientTimestamp": DateTime.now().toIso8601String(),
          "serverTimestamp": FieldValue.serverTimestamp(),
          "geoPoint": GeoPoint(position.latitude, position.longitude),
        }, SetOptions(merge: true));

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Location Logger",
            content: "Last update: ${DateTime.now()}",
          );
        }
      } catch (_) {
        // Keep service alive even if one tick fails.
      }
      },
    );
  }
}
