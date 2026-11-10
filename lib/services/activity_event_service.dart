import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityEventService {
  ActivityEventService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  static final String sessionId = _createId();

  final SupabaseClient _supabase;

  static String createEventId() => _createId();

  static String _createId() {
    final random = Random.secure().nextInt(1 << 32);
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$random';
  }

  Future<void> record({
    required String userId,
    required String eventType,
    String? contextType,
    String? contextId,
    Map<String, dynamic> details = const {},
    DateTime? occurredAt,
  }) async {
    try {
      await _supabase.from('activity_events').insert({
        'user_id': userId,
        'session_id': sessionId,
        'event_type': eventType,
        'context_type': contextType,
        'context_id': contextId,
        'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
        'details': details,
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to record activity event "$eventType": $error');
      Error.throwWithStackTrace(
        ActivityEventException(eventType, error),
        stackTrace,
      );
    }
  }

  Future<void> recordBestEffort({
    required String userId,
    required String eventType,
    String? contextType,
    String? contextId,
    Map<String, dynamic> details = const {},
    DateTime? occurredAt,
  }) async {
    try {
      await record(
        userId: userId,
        eventType: eventType,
        contextType: contextType,
        contextId: contextId,
        details: details,
        occurredAt: occurredAt,
      );
    } on ActivityEventException catch (error) {
      debugPrint('Activity history may be incomplete: $error');
    }
  }

  Future<void> recordQuizAttemptStarted({
    required String userId,
    required String attemptId,
    required String quizId,
    required String quizType,
    required int questionCount,
  }) {
    return record(
      userId: userId,
      eventType: 'quiz_attempt_started',
      contextType: 'quiz',
      contextId: quizId,
      details: {
        'attempt_id': attemptId,
        'quiz_type': quizType,
        'question_count': questionCount,
      },
    );
  }

  Future<void> recordQuizAttemptCompleted({
    required String userId,
    required String attemptId,
    required String quizId,
    required String quizType,
    required int correctAnswers,
    required int totalQuestions,
    required int activeDurationMs,
    required DateTime startedAt,
    required DateTime completedAt,
    required List<Map<String, dynamic>> questionResults,
  }) async {
    await record(
      userId: userId,
      eventType: 'quiz_attempt_completed',
      contextType: 'quiz',
      contextId: quizId,
      occurredAt: completedAt,
      details: {
        'attempt_id': attemptId,
        'quiz_type': quizType,
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'score_percent':
            totalQuestions == 0
                ? 0
                : ((correctAnswers / totalQuestions) * 100).round(),
        'started_at': startedAt.toUtc().toIso8601String(),
        'completed_at': completedAt.toUtc().toIso8601String(),
        'duration_ms': completedAt.difference(startedAt).inMilliseconds,
        'active_duration_ms': activeDurationMs,
      },
    );

    await Future.wait(
      questionResults.map(
        (result) => record(
          userId: userId,
          eventType: 'quiz_question_answered',
          contextType: 'quiz',
          contextId: quizId,
          occurredAt: completedAt,
          details: {'attempt_id': attemptId, ...result},
        ),
      ),
    );
  }
}

class ActivityEventException implements Exception {
  ActivityEventException(this.eventType, this.cause);

  final String eventType;
  final Object cause;

  @override
  String toString() => 'ActivityEventException($eventType): $cause';
}
