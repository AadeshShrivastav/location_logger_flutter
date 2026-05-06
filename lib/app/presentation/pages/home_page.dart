import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../background/live_location_background_service.dart';
import '../../config/tracking_config.dart';
import '../../di/injector.dart';
import '../controllers/auth_controller.dart';
import '../controllers/location_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Get the controllers from DI (GetIt + GetX)
  final LocationController controller = sl<LocationController>();
  final AuthController authController = sl<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(controller.onAppPaused());
    } else if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Logger"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () async {
              controller.pauseTracking();
              LiveLocationBackgroundService.stopService();
              await authController.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(() {
              final email = authController.currentUser.value?.email ?? "";
              return Text(
                email.isEmpty ? "Signed in" : "Signed in as $email",
                style: const TextStyle(fontSize: 14),
              );
            }),

            const SizedBox(height: 40),

            Obx(() => Text(
              controller.status.value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )),

            const SizedBox(height: 40),

            Obx(() {
              return Text(
                controller.isTracking.value
                    ? "Tracking: ON (saving every ${TrackingConfig.intervalSeconds} seconds)"
                    : "Tracking: OFF",
                style: const TextStyle(fontSize: 14),
              );
            }),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  return ElevatedButton(
                    onPressed: controller.isTracking.value
                        ? null
                        : () {
                            controller.startTracking();
                          },
                    child: const Text("Save"),
                  );
                }),
                const SizedBox(width: 12),
                Obx(() {
                  return ElevatedButton(
                    onPressed: controller.isTracking.value
                        ? controller.pauseTracking
                        : null,
                    child: const Text("Pause"),
                  );
                }),
              ],
            ),

            const SizedBox(height: 16),

            Obx(() {
              final lastSavedAt = controller.lastSavedAt.value;
              if (lastSavedAt == null) {
                return const Text("Last saved: not available");
              }
              return Text("Last saved: $lastSavedAt");
            }),
          ],
        ),
      ),
    );
  }
}
