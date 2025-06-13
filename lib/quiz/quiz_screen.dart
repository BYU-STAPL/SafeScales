// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:safe_scales/question/question.dart';
// import 'package:safe_scales/themes/app_theme.dart';
//
// class QuizScreen extends StatefulWidget {
//   final QuestionSet questionSet;
//
//   const QuizScreen({super.key, required this.questionSet});
//
//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }
//
// class _QuizScreenState extends State<QuizScreen> {
//   int _currentQuestionIndex = 0;
//   List<int> _selectedAnswers = [];
//   bool _isAnswered = false;
//   int _score = 0;
//
//   Question get _currentQuestion =>
//       widget.questionSet.questions[_currentQuestionIndex];
//
//   void _handleAnswer(int index) {
//     if (_isAnswered) return;
//
//     setState(() {
//       if (_currentQuestion.isMultipleChoice) {
//         if (_selectedAnswers.contains(index)) {
//           _selectedAnswers.remove(index);
//         } else {
//           _selectedAnswers.add(index);
//         }
//       } else {
//         _selectedAnswers = [index];
//       }
//     });
//   }
//
//   void _submitAnswer() {
//     if (_selectedAnswers.isEmpty) return;
//
//     setState(() {
//       _isAnswered = true;
//
//       // Check if answer is correct
//       if (_currentQuestion.isMultipleChoice) {
//         if (listEquals(
//           _selectedAnswers,
//           _currentQuestion.correctAnswerIndices,
//         )) {
//           _score++;
//         }
//       } else {
//         if (_selectedAnswers.first ==
//             _currentQuestion.correctAnswerIndices.first) {
//           _score++;
//         }
//       }
//     });
//   }
//
//   void _nextQuestion() {
//     if (_currentQuestionIndex < widget.questionSet.questions.length - 1) {
//       setState(() {
//         _currentQuestionIndex++;
//         _selectedAnswers = [];
//         _isAnswered = false;
//       });
//     } else {
//       // Quiz completed
//       final score = (_score / widget.questionSet.questions.length) * 100;
//       _showCompletionDialog(score);
//     }
//   }
//
//   void _showCompletionDialog(double score) {
//
//     ThemeData theme = Theme.of(context);
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Quiz Completed!',
//             style: theme.textTheme.headlineMedium,
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Your Score: ${score.toStringAsFixed(1)}%',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: score >= 80 ? theme.colorScheme.green : score >= 50 ? theme.colorScheme.orange : theme.colorScheme.red,
//                 )
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 score >= 80
//                     ? 'Great job! You\'ve passed the quiz.'
//                     : score >= 50
//                     ? 'Keep practicing! You can try again.'
//                     : 'Try re-reading the lesson.',
//                 style: theme.textTheme.bodySmall,
//               ),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close dialog
//                   Navigator.of(context).pop(true); // Return to activity page
//                 },
//                 child: Text(
//                   'Continue'.toUpperCase(),
//                 ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     ThemeData theme = Theme.of(context);
//
//     final Color primary = theme.colorScheme.primary;
//     final Color textColor = theme.colorScheme.onSurface;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Question ${_currentQuestionIndex + 1}/${widget.questionSet.questions.length}',
//           style: theme.textTheme.bodyMedium,
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Progress indicator
//             LinearProgressIndicator(
//               value:
//                   (_currentQuestionIndex + 1) /
//                   widget.questionSet.questions.length,
//               backgroundColor: primary.withValues(alpha: 0.1),
//               valueColor: AlwaysStoppedAnimation<Color>(primary),
//             ),
//             const SizedBox(height: 25),
//
//             // Question text
//             Text(
//               _currentQuestion.questionText,
//               style: theme.textTheme.bodyLarge,
//             ),
//             const SizedBox(height: 25),
//
//             // Options
//             ...List.generate(
//               _currentQuestion.options.length,
//               (index) => Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: _buildOptionCard(
//                   option: _currentQuestion.options[index],
//                   index: index,
//                   isSelected: _selectedAnswers.contains(index),
//                   isCorrect:
//                       _isAnswered &&
//                       _currentQuestion.correctAnswerIndices.contains(index),
//                   isWrong:
//                       _isAnswered &&
//                       _selectedAnswers.contains(index) &&
//                       !_currentQuestion.correctAnswerIndices.contains(index),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             // Submit/Next button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isAnswered ? _nextQuestion : _submitAnswer,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   _isAnswered ? 'Next Question' : 'Submit Answer',
//                   style: GoogleFonts.poppins(
//                     fontSize: 16 * AppTheme.fontSizeScale,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOptionCard({
//     required String option,
//     required int index,
//     required bool isSelected,
//     required bool isCorrect,
//     required bool isWrong,
//   }) {
//     final Color primary = Theme.of(context).colorScheme.primary;
//     final Color textColor = Theme.of(context).colorScheme.onSurface;
//     final Color cardBg = Theme.of(context).colorScheme.surface;
//
//     Color borderColor = isSelected ? primary : Colors.grey.withOpacity(0.3);
//     Color backgroundColor = cardBg;
//
//     if (_isAnswered) {
//       if (isCorrect) {
//         borderColor = Colors.green;
//         backgroundColor = Colors.green.withOpacity(0.1);
//       } else if (isWrong) {
//         borderColor = Colors.red;
//         backgroundColor = Colors.red.withOpacity(0.1);
//       }
//     }
//
//     return GestureDetector(
//       onTap: () => _handleAnswer(index),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: borderColor, width: 2),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 24,
//               height: 24,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: borderColor, width: 2),
//               ),
//               child:
//                   isSelected
//                       ? Center(
//                         child: Container(
//                           width: 12,
//                           height: 12,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: borderColor,
//                           ),
//                         ),
//                       )
//                       : null,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 option,
//                 style: GoogleFonts.poppins(
//                   fontSize: 16 * AppTheme.fontSizeScale,
//                   color: textColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
