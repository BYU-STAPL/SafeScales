import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _notesPrefix = 'question_note_';

  /// Save a note for a specific question
  Future<void> saveNote(String questionId, String note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_notesPrefix$questionId', note);
    } catch (e) {
      throw Exception('Failed to save note: $e');
    }
  }

  /// Get a note for a specific question
  Future<String?> getNote(String questionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_notesPrefix$questionId');
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  /// Delete a note for a specific question
  Future<void> deleteNote(String questionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_notesPrefix$questionId');
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  /// Get all notes (returns a map of questionId -> note)
  Future<Map<String, String>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final notes = <String, String>{};
      
      for (final key in keys) {
        if (key.startsWith(_notesPrefix)) {
          final questionId = key.substring(_notesPrefix.length);
          final note = prefs.getString(key);
          if (note != null) {
            notes[questionId] = note;
          }
        }
      }
      
      return notes;
    } catch (e) {
      throw Exception('Failed to get all notes: $e');
    }
  }
}
