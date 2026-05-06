import 'package:flutter/material.dart';
import '../../data/models/user_profile_model.dart';
import '../../di/injector.dart';
import '../controllers/auth_controller.dart';
import '../../data/datasources/firebase_datasource.dart';
import 'user_entries_page.dart';

class AdminUsersPage extends StatelessWidget {
  AdminUsersPage({super.key});

  final FirebaseDatasource firebaseDatasource = sl<FirebaseDatasource>();
  final AuthController authController = sl<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: authController.signOut,
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: StreamBuilder<List<UserProfileModel>>(
        stream: firebaseDatasource.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text("No users available"));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Select a user to view location entries",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: authController.signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text("Sign Out"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.email.isEmpty ? user.userId : user.email),
                      subtitle: Text("Role: ${user.role}"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserEntriesPage(
                              userId: user.userId,
                              userEmail: user.email,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
