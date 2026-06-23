import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(AuthController(), permanent: true);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AmarProshnoApp());
}

class AmarProshnoApp extends StatelessWidget {
  const AmarProshnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Amar Proshno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB086BC),
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFD9BEDC),
          primary: const Color(0xFF834FA0),
          secondary: const Color(0xFFB086BC),
          onSurface: const Color(0xFF612A7E),
        ),
        scaffoldBackgroundColor: const Color(0xFFD9BEDC),
      ),
      initialRoute: AppRoutes.initial,
      getPages: [
        GetPage(name: AppRoutes.initial, page: () => const AuthGateScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.signup, page: () => const SignupScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.quiz, page: () => const QuizScreen()),
        GetPage(name: AppRoutes.result, page: () => const ResultScreen()),
      ],
    );
  }
}