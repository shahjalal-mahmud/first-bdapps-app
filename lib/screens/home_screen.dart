import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../routes/app_routes.dart';

const appGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFD9BEDC),
    Color(0xFFB086BC),
    Color(0xFF834FA0),
  ],
  stops: [0.0, 0.41, 0.82],
);

BoxDecoration cardDecoration({double radius = 32}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD9BEDC),
      Color(0xFFB086BC),
      Color(0xFF834FA0),
    ],
    stops: [1.0, 0.41, 0.0512],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: const Color(0xFFD9BEDC).withValues(alpha: 0.55),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF612A7E).withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Container(
                width: 200,
                height: 200,
                decoration: cardDecoration(radius: 100),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD9BEDC).withValues(alpha: 0.18),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings_rounded,
                                size: 24,
                                color: const Color(0xFFD9BEDC)
                                    .withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Icon(Icons.settings_rounded,
                                size: 16,
                                color: const Color(0xFFD9BEDC)
                                    .withValues(alpha: 0.6)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Icon(Icons.psychology_rounded,
                            size: 60,
                            color: const Color(0xFFFFFFFF)
                                .withValues(alpha: 0.9)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 20,
                                color: const Color(0xFFD9BEDC)
                                    .withValues(alpha: 0.75)),
                            const SizedBox(width: 6),
                            Icon(Icons.auto_awesome_rounded,
                                size: 15,
                                color: const Color(0xFFD9BEDC)
                                    .withValues(alpha: 0.55)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'QUIZ',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: Color(0x55612A7E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'আমার প্রশ্ন',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      // Put a fresh controller for each quiz session
                      Get.put(QuizController());
                      Get.toNamed(AppRoutes.quiz);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF612A7E),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Color(0xFF612A7E),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.toNamed(AppRoutes.aiChat);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 20),
                    label: const Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == 0 ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}