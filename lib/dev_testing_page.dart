import 'package:flutter/material.dart';
import 'package:safe_scales/pre_quiz/pre_quiz_screen.dart';
import 'package:safe_scales/question/question.dart';
import 'package:safe_scales/quiz/post_quiz_screen.dart';
import 'package:safe_scales/review/review_screen.dart';

// ##################################################
/*
This page for develop purposes only to test different screens and other widgets
This will be removed after development
 */
// ##################################################


class DevTestingPage extends StatefulWidget {
  const DevTestingPage({
    super.key,
  });

  @override
  State<DevTestingPage> createState() => _DevTestingPageState();
}

class _DevTestingPageState extends State<DevTestingPage> {

  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

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
      options: ['Spring', 'Summer', 'Fall', 'Winter', "Year-round"],
      correctAnswerIndex: 3,
      explanation: 'Oranges taste best during the winter',
    );

    Question multipleQ = Question.multipleAnswer(
      id: 'q3',
      text: "At your school, there is a security guard named Quinn. You have never met or talked to Quinn, but some of your school mates have."
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn."
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn. "
          "At your school, there is a security guard named Quinn. At your school, there is a security guard named Quinn.",
      questionText: 'What social tag(s) apply to Quinn?',
      options: ['Acquaintance', 'Community Helper', 'Stranger', 'Work Peer', 'In-Person Friend', 'Family'],
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

    QuestionSet questionSet2 = QuestionSet(
      id: "qset2",
      title: "Test Post Quiz",
      description: "This is a post-test",
      activityType: ActivityType.postQuiz,
      subject: "test subject",
      questions: [singleQ, singleQ2, multipleQ,],
    );

    QuestionSet questionSet3 = QuestionSet(
      id: "qset3",
      title: "Review",
      description: "This is a review set",
      activityType: ActivityType.review,
      subject: "review subject",
      questions: [multipleQ,],
    );


    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 50),

            ElevatedButton(
              onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PreQuizScreen(questionSet: questionSet)
                    ),
                  );
                },
              child: Text("Testing Pre-quiz"),
            ),

            SizedBox(height: 50),

            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostQuizScreen(questionSet: questionSet2)
                  ),
                );
              },
              child: Text("Testing Post-quiz"),
            ),

            SizedBox(height: 50),


            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ReviewScreen(questionSet: questionSet3)
                  ),
                );
              },
              child: Text("Testing Review set"),
            ),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}