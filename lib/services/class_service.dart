import 'package:safe_scales/models/reading_slide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import '../models/question.dart';

class ClassService {
  final SupabaseClient supabase;

  ClassService(this.supabase);

  Future<Map<String, dynamic>> getUserClass(String userId) async {
    try {
      // Get user's joined classes
      final userResponse =
          await supabase
              .from('Users')
              .select('joined_classes')
              .eq('id', userId)
              .single();

      if (userResponse['joined_classes'] == null ||
          (userResponse['joined_classes'] as List).isEmpty) {
        print('No joined classes found for user: $userId');
        return {};
      }

      // Get the first class ID from the array
      final classId = (userResponse['joined_classes'] as List).first;

      // Get class details
      final classResponse =
          await supabase.from('classes').select().eq('id', classId).single();

      // print('Class details: $classResponse');

      return Map<String, dynamic>.from(classResponse);

    } catch (e) {
      print('❌Error getting user class: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getClassModules(String classId) async {
    try {
      // Get class details to get course_modules
      final classResponse =
          await supabase
              .from('classes')
              .select('course_modules')
              .eq('id', classId)
              .single();

      if (classResponse['course_modules'] == null) {
        print('No course modules found for class: $classId');
        return [];
      }

      // Get module IDs from the course_modules array
      final moduleIds = List<String>.from(classResponse['course_modules']);

      // Get module details for each module ID
      final modulesResponse = await supabase
          .from('modules')
          .select()
          .inFilter('id', moduleIds)
          .order('created_at', ascending: true);

      final modules = List<Map<String, dynamic>>.from(modulesResponse);

      return modules;
    } catch (e) {
      print('❌Error getting class modules: $e');
      return [];
    }
  }

  // Main function - now much cleaner
  Future<Map<String, Lesson>> getLessons(String classId) async {
    final tempLessons = await getClassModules(classId);
    Map<String, Lesson> lessons = {};

    for (var lessonMap in tempLessons) {
      final lesson = _createLessonFromMap(lessonMap);
      lessons[lessonMap['id']] = lesson;
    }

    return lessons;
  }

  // Create a complete lesson from the raw data
  Lesson _createLessonFromMap(Map<String, dynamic> lessonMap) {
    return Lesson(
      lessonId: lessonMap['id'].toString(),
      title: lessonMap['title'].toString(),
      preQuiz: _createPreQuiz(lessonMap),
      reading: _createReadingSlides(lessonMap),
      postQuiz: _createPostQuiz(lessonMap),
    );
  }

  // Create pre-quiz question set
  QuestionSet _createPreQuiz(Map<String, dynamic> lessonMap) {
    final preQuizMap = lessonMap['pre_quiz'];
    final questions = _createQuestionsFromList(preQuizMap['questions']);

    return QuestionSet(
      id: '',
      title: '${lessonMap['title']} Pre-Quiz',
      description: '',
      activityType: ActivityType.preQuiz,
      subject: '',
      questions: questions,
    );
  }

  // Create post-quiz question set
  QuestionSet _createPostQuiz(Map<String, dynamic> lessonMap) {
    final postQuizMap = lessonMap['post_quiz'];
    final questions = _createQuestionsFromList(postQuizMap['questions']);

    return QuestionSet(
      id: '',
      title: '${lessonMap['title']} Post-Quiz',
      description: '',
      activityType: ActivityType.postQuiz,
      subject: '',
      questions: questions,
      passingScore: lessonMap['minimum_passing_grade'],
    );
  }

// Create questions from raw question data (reusable for both quizzes)
  List<Question> _createQuestionsFromList(List<dynamic> questionsData) {
    List<Question> questions = [];

    for (var q in questionsData) {
      final question = _createSingleQuestion(q);
      questions.add(question);
    }

    return questions;
  }

// Create a single question from raw data
  Question _createSingleQuestion(Map<String, dynamic> questionData) {
    //TODO: Later add option to create multiple answer question
    return Question.singleAnswer(
      id: '',
      questionText: questionData['question'],
      options: List<String>.from(questionData['choices']),
      correctAnswerIndex: int.parse(questionData['answer']),
      explanation: '', //TODO: Currently nothing in database for this
    );
  }

  // Create reading slides from lesson data
  List<ReadingSlide> _createReadingSlides(Map<String, dynamic> lessonMap) {
    final revision = lessonMap['revision'];
    final slides = revision['slides'];
    List<ReadingSlide> reading = [];

    for (var slideData in slides) {
      final slide = _createSingleReadingSlide(slideData);
      reading.add(slide);
    }

    return reading;
  }

// Create a single reading slide
  ReadingSlide _createSingleReadingSlide(Map<String, dynamic> slideData) {
    final content = slideData['content'];

    //TODO: Edit this code when images can be added to reading slides
    return ReadingSlide(
      content: [TextContent(content)],
    );
  }

  Future<List<String>> getLessonOrder(String classId) async {
    final classResponse =
    await supabase
        .from('classes')
        .select('course_modules')
        .eq('id', classId)
        .single();

    if (classResponse['course_modules'] == null) {
      print('No course modules found for class: $classId');
      return [];
    }

    final moduleIds = List<String>.from(classResponse['course_modules']);

    // Get module details for each module ID
    final modulesResponse = await supabase
        .from('modules')
        .select()
        .inFilter('id', moduleIds)
        .order('created_at', ascending: true);

    List<String> lessonOrder = [];
    for (var lessonMap in modulesResponse) {
      lessonOrder.add(lessonMap['id'].toString());
    }

    return lessonOrder;
  }

  Future<Map<String, dynamic>?> getModuleById(String moduleId) async {
    try {
      final moduleResponse =
          await supabase.from('modules').select().eq('id', moduleId).single();


      return Map<String, dynamic>.from(moduleResponse);
    } catch (e) {
      print('❌Error getting module by ID: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getClassAssets(String classId) async {
    try {
      final classResponse =
          await supabase
              .from('classes')
              .select('assets')
              .eq('id', classId)
              .single();

      if (classResponse['assets'] != null) {
        return List<dynamic>.from(classResponse['assets']);
      }

      return null;
    } catch (e) {
      print('❌Error getting class assets: $e');
      return null;
    }
  }
}
