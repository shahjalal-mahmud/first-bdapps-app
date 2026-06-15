import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../data/quiz_data.dart';
import '../routes/app_routes.dart';
import '../widgets/option_tile.dart';
import 'home_screen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<QuizController>();
    final labels = ['A', 'B', 'C', 'D'];

    return Obx(() {
      final index = ctrl.currentIndex.value;
      final question = quizQuestions[index];
      final progress = (index + 1) / quizQuestions.length;

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: appGradient),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Top bar: close + progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.offAllNamed(AppRoutes.home),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                            Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${index + 1}/${quizQuestions.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Question card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 28),
                    decoration: cardDecoration(radius: 28).copyWith(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question ${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: question.options.length,
                    itemBuilder: (context, i) {
                      return OptionTile(
                        label: labels[i],
                        text: question.options[i],
                        isSelected: ctrl.selectedAnswers[index] == i,
                        onTap: () => ctrl.selectOption(i),
                      );
                    },
                  ),
                ),

                // Next / Submit
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (ctrl.selectedAnswers[index] == null) {
                          Get.snackbar(
                            '',
                            'Please select an answer.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF612A7E),
                            colorText: Colors.white,
                            borderRadius: 12,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            titleText: const SizedBox.shrink(),
                          );
                          return;
                        }
                        if (ctrl.isLastQuestion) {
                          Get.offNamed(AppRoutes.result);
                        } else {
                          ctrl.nextQuestion();
                        }
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
                      child: Text(
                        ctrl.isLastQuestion ? 'SUBMIT' : 'NEXT →',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: Color(0xFF612A7E),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}