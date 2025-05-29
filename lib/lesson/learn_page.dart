import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/question/question.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    //TODO: Remove later after testing
    Question singleQ = Question.singleAnswer(
      id: 'q1',
      questionText: 'What color is the sky?',
      options: ['Red', 'Blue', 'Green', 'Yellow'],
      correctAnswerIndex: 1,
      explanation: 'The Sky is blue', // Blue is at index 1
    );

    Question singleQ2 = Question.singleAnswer(
      id: 'q2',
      questionText: 'What season are oranges ripe?',
      options: ['Spring', 'Summer', 'Fall', 'Winter'],
      correctAnswerIndex: 3,
      explanation: 'Oranges taste best during the winter',
    );

    Question multipleQ = Question.multipleAnswer(
      id: 'q3',
      text: "At your school, there is a security guard named Quinn. You have never met or talked to Quinn, but some of your school mates have.",
      questionText: 'What social tag(s) apply to Quinn?',
      options: ['Acquaintance', 'Community Helper', 'Stranger', 'Work Peer', ],
      correctAnswerIndices: [1, 2,],
      explanation: 'Quinn serves the community, but don\'t know him', // Apple, Banana, Orange
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
      body: Center(
        child: Column(
          children: [
            Text("All Lessons will be added here"),

            SizedBox(height: 50),

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