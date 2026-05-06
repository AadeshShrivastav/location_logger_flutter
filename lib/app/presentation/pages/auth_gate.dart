import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../di/injector.dart';
import '../controllers/auth_controller.dart';
import 'admin_users_page.dart';
import 'home_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthController authController = sl<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = authController.currentUser.value;
      if (user == null) {
        return SignInPage();
      }

      if (authController.isResolvingRole.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (authController.role.value == "admin") {
        return AdminUsersPage();
      }

      return HomePage();
    });
  }
}
