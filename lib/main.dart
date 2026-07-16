import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'controllers/subscription_controller.dart';
import 'repositories/subscription_repository.dart';
import 'routes/app_routes.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/phone_registration_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap persistence before any controller touches it.
  final storage = await LocalStorageService.create();
  Get.put<LocalStorageService>(storage, permanent: true);

  // Repository (singleton) wrapping the REST client.
  Get.put<SubscriptionRepository>(
    SubscriptionRepository(),
    permanent: true,
  );

  // Reactive subscription state controller.
  Get.put<SubscriptionController>(
    SubscriptionController(
      repository: Get.find<SubscriptionRepository>(),
      storage: Get.find<LocalStorageService>(),
    ),
    permanent: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AmarProshnoApp());
}

/// Root widget. Wires the GetX navigation table. Routes are intentionally
/// flat - the splash screen is the only entry point and it decides
/// where to send the user next.
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
        GetPage(name: AppRoutes.initial, page: () => const SplashScreen()),
        GetPage(
          name: AppRoutes.phoneRegistration,
          page: () => const PhoneRegistrationScreen(),
        ),
        GetPage(
          name: AppRoutes.subscription,
          page: () => const SubscriptionScreen(),
        ),
        GetPage(name: AppRoutes.otp, page: () => const OtpVerificationScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.quiz, page: () => const QuizScreen()),
        GetPage(name: AppRoutes.result, page: () => const ResultScreen()),
        GetPage(name: AppRoutes.aiChat, page: () => const AIChatScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
      ],
    );
  }
}