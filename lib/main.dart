import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
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
      home: const HomeScreen(),
    );
  }
}