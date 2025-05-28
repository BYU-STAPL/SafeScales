import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/question/question.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {

    //TODO: Remove later after testing
    Question singleQ = Question.singleAnswer(
      id: 'q1',
      questionText: 'What color is the sky?',
      options: ['Red', 'Blue', 'Green', 'Yellow'],
      correctAnswerIndex: 1,
      explanation: 'The Sky is blue', // Blue is at index 1
    );

    Question multipleQ = Question.multipleAnswer(
      id: 'q2',
      questionText: 'Which are fruits?',
      options: ['Apple', 'Car', 'Banana', 'House', 'Orange'],
      correctAnswerIndices: [0, 2, 4],
      explanation: 'Apples, Bananas, and Oranges are all fruits', // Apple, Banana, Orange
    );

    QuestionSet questionSet = QuestionSet(
      id: "qset0",
      title: "Test Question Set",
      description: "This is a test",
      activityType: ActivityType.preQuiz,
      subject: "test subject",
      questions: [singleQ, multipleQ],
    );


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PreQuizScreen(questionSet: questionSet)
                ),
              );
            }, child: Text("Testing Pre-quiz")),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}