import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'home_screen.dart'; // for appGradient

/// Shown briefly on app start. Listens to Firebase's auth state and
/// routes the user to Home (if signed in) or Login (if not), so users
/// stay signed in across app restarts.
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: appGradient),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final user = snapshot.data;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (user != null) {
                Get.offAllNamed(AppRoutes.home);
              } else {
                Get.offAllNamed(AppRoutes.login);
              }
            });

            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}