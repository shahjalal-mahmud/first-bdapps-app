import 'package:get/get.dart';
import '../data/quiz_data.dart';

class QuizController extends GetxController {
  final currentIndex = 0.obs;
  final selectedAnswers = List<int?>.filled(quizQuestions.length, null).obs;

  bool get isLastQuestion => currentIndex.value == quizQuestions.length - 1;

  int get correctCount {
    int count = 0;
    for (int i = 0; i < quizQuestions.length; i++) {
      if (selectedAnswers[i] == quizQuestions[i].correctAnswerIndex) count++;
    }
    return count;
  }

  int get wrongCount => quizQuestions.length - correctCount;
  int get totalCount => quizQuestions.length;
  int get percentage => (correctCount / totalCount * 100).toInt();
  List<int?> get answers => List<int?>.from(selectedAnswers);

  void selectOption(int optionIndex) {
    selectedAnswers[currentIndex.value] = optionIndex;
    selectedAnswers.refresh();
  }

  void nextQuestion() {
    if (currentIndex.value < quizQuestions.length - 1) {
      currentIndex.value++;
    }
  }

  void reset() {
    currentIndex.value = 0;
    for (int i = 0; i < selectedAnswers.length; i++) {
      selectedAnswers[i] = null;
    }
    selectedAnswers.refresh();
  }
}