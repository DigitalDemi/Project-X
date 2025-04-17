import 'package:flutter/material.dart';
import 'package:frontend/models/content.dart';
import 'dart:convert';

class QuizView extends StatefulWidget {
  final Content content;

  const QuizView({
    super.key,
    required this.content,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  // ignore: prefer_final_fields
  Map<int, int> _userAnswers = {}; // Maps question index to answer index
  bool _quizCompleted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _parseQuizContent();
  }

  void _parseQuizContent() {
    try {
      // Assuming quiz content is stored as JSON
      final quizData = json.decode(widget.content.content);
      if (quizData['questions'] is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(quizData['questions']);
        });
      }
    } catch (e) {
      // Fallback for improperly formatted quizzes
      setState(() {
        _questions = [
          {
            'question': 'Error loading quiz content',
            'options': ['Please try again later'],
            'correctAnswer': 0
          }
        ];
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    if (_quizCompleted) return;

    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateScore();
    }
  }

  void _calculateScore() {
    int correctAnswers = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correctAnswer']) {
        correctAnswers++;
      }
    }
    
    setState(() {
      _score = correctAnswers;
      _quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: const Text('Loading Quiz...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.content.title),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _quizCompleted 
              ? _buildQuizResults() 
              : _buildQuizQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuizQuestion() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final options = List<String>.from(currentQuestion['options']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
        ),
        const SizedBox(height: 8),
        Text(
          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        
        // Question text
        Text(
          currentQuestion['question'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        
        // Answer options
        ...List.generate(options.length, (index) {
          final isSelected = _userAnswers[_currentQuestionIndex] == index;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _selectAnswer(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurpleAccent.withValues(alpha: 0.3) : Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurpleAccent : Colors.grey[800]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.deepPurpleAccent : Colors.grey[700],
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D...
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        options[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        const Spacer(),
        
        // Next button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _userAnswers.containsKey(_currentQuestionIndex) 
                ? _nextQuestion 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: Text(
              _currentQuestionIndex < _questions.length - 1 
                  ? 'Next Question' 
                  : 'Complete Quiz',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResults() {
    final percentage = (_score / _questions.length * 100).round();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Score display
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_score/${_questions.length}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Result message
        Text(
          _getResultMessage(percentage),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'You answered $_score out of ${_questions.length} questions correctly.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        // Exit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 75) return 'Great Job!';
    if (percentage >= 60) return 'Good Effort!';
    if (percentage >= 40) return 'Keep Practicing!';
    return 'More Review Needed';
  }
}