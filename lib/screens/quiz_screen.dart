import 'package:flutter/material.dart';
import '../data/quiz_data.dart';
import '../widgets/option_tile.dart';
import 'result_screen.dart';
import 'home_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  final List<int?> _selectedAnswers = List.filled(quizQuestions.length, null);

  bool get _isLastQuestion => _currentIndex == quizQuestions.length - 1;

  void _selectOption(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });
  }

  void _handleNextOrSubmit() {
    if (_selectedAnswers[_currentIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an answer.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF612A7E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
      return;
    }

    if (_isLastQuestion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            selectedAnswers: List<int?>.from(_selectedAnswers),
          ),
        ),
      );
    } else {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = quizQuestions[_currentIndex];
    final labels = ['A', 'B', 'C', 'D'];
    final progress = (_currentIndex + 1) / quizQuestions.length;

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
                      onTap: () => Navigator.of(context).pop(),
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
                      '${_currentIndex + 1}/${quizQuestions.length}',
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
                      // Question number pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Question ${_currentIndex + 1}',
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

              // Options list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    return OptionTile(
                      label: labels[index],
                      text: question.options[index],
                      isSelected: _selectedAnswers[_currentIndex] == index,
                      onTap: () => _selectOption(index),
                    );
                  },
                ),
              ),

              // Next / Submit button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleNextOrSubmit,
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
                      _isLastQuestion ? 'SUBMIT' : 'NEXT →',
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
  }
}