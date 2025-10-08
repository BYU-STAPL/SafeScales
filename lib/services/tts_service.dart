import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, paused, stopped }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  String? _currentText;
  int? _currentPageIndex;

  // Getters
  TtsState get state => _state;
  String? get currentText => _currentText;
  int? get currentPageIndex => _currentPageIndex;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isStopped => _state == TtsState.stopped;

  Future<void> initialize() async {
    try {
      // Set language
      await _flutterTts.setLanguage("en-US");

      // Note: Speech rate will be set by VoiceButton to respect global speed settings

      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(0.9);

      // Set pitch closer to natural human voice
      await _flutterTts.setPitch(0.95);

      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _state = TtsState.stopped;
        _currentText = null;
        _currentPageIndex = null;
      });

      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _state = TtsState.stopped;
      });

      // Set up pause handler
      _flutterTts.setPauseHandler(() {
        _state = TtsState.paused;
      });

      // Set up continue handler
      _flutterTts.setContinueHandler(() {
        _state = TtsState.playing;
      });

      // Apply enhanced speech settings for more natural voice
      await setEnhancedSpeechSettings();
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> speak(String text, {int? pageIndex}) async {
    try {
      // Stop any current speech
      await stop();

      // Clean and enhance the text for more natural speech
      String cleanText = _enhanceTextForNaturalSpeech(text);

      _currentText = cleanText;
      _currentPageIndex = pageIndex;
      _state = TtsState.playing;

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _state = TtsState.stopped;
    }
  }

  Future<void> pause() async {
    try {
      if (_state == TtsState.playing) {
        await _flutterTts.pause();
        _state = TtsState.paused;
      }
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_state == TtsState.paused) {
        await _flutterTts.speak(_currentText ?? '');
        _state = TtsState.playing;
      }
    } catch (e) {
      debugPrint('Error resuming TTS: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsState.stopped;
      _currentText = null;
      _currentPageIndex = null;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 2.0);
      await _flutterTts.setSpeechRate(clampedRate);
      debugPrint('TTS Speech rate set to: $clampedRate');
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await getVoices();
      return voices.map((voice) => Map<String, String>.from(voice)).toList();
    } catch (e) {
      debugPrint('Error getting available voices: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getEnhancedVoices() async {
    try {
      final voices = await getAvailableVoices();
      final enhancedVoices =
          voices.where((voice) {
            final name = voice['name']?.toLowerCase() ?? '';
            final locale = voice['locale']?.toLowerCase() ?? '';

            // Look for enhanced, neural, or premium voices
            return name.contains('enhanced') ||
                name.contains('neural') ||
                name.contains('premium') ||
                name.contains('natural') ||
                name.contains('wave') ||
                name.contains('siri') ||
                name.contains('alex') ||
                locale.contains('en');
          }).toList();

      return enhancedVoices;
    } catch (e) {
      debugPrint('Error getting enhanced voices: $e');
      return [];
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  Future<void> setEnhancedSpeechSettings() async {
    try {
      // More natural settings for human-like speech
      // Note: Speech rate will be set separately to respect global speed settings
      await _flutterTts.setPitch(0.95); // Slightly lower pitch
      await _flutterTts.setVolume(0.9); // Higher volume

      // Try to set a more natural voice if available
      final enhancedVoices = await getEnhancedVoices();
      if (enhancedVoices.isNotEmpty) {
        // Use the first enhanced voice found
        final voice = enhancedVoices.first;
        await setVoice(voice);
        debugPrint('Using enhanced voice: ${voice['name']}');
      } else {
        // Fallback to any available English voice
        final allVoices = await getAvailableVoices();
        final englishVoices =
            allVoices.where((voice) {
              final locale = voice['locale']?.toLowerCase() ?? '';
              return locale.contains('en');
            }).toList();

        if (englishVoices.isNotEmpty) {
          await setVoice(englishVoices.first);
          debugPrint('Using English voice: ${englishVoices.first['name']}');
        }
      }
    } catch (e) {
      debugPrint('Error setting enhanced speech settings: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stop();
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error disposing TTS: $e');
    }
  }

  /// Enhance text for more natural speech synthesis
  String _enhanceTextForNaturalSpeech(String text) {
    // Remove markdown formatting while preserving natural pauses
    String enhanced = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Code
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Links
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'^[-*+]\s*'), '') // List items
        .replaceAll(RegExp(r'^\d+\.\s*'), '') // Numbered lists
        .replaceAll(RegExp(r'\n\s*\n'), '. ') // Multiple newlines to periods
        .replaceAll(RegExp(r'\n'), ' ') // Single newlines to spaces
        .replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces to single space

    // Add natural pauses and improve readability
    enhanced =
        enhanced
            // Add pauses after sentences
            .replaceAll(RegExp(r'\.\s+'), '. ')
            .replaceAll(RegExp(r'!\s+'), '! ')
            .replaceAll(RegExp(r'\?\s+'), '? ')
            // Add pauses after colons
            .replaceAll(RegExp(r':\s+'), ': ')
            // Add pauses after semicolons
            .replaceAll(RegExp(r';\s+'), '; ')
            // Handle common abbreviations for better pronunciation
            .replaceAll(RegExp(r'\bMr\.\b', caseSensitive: false), 'Mister')
            .replaceAll(RegExp(r'\bMrs\.\b', caseSensitive: false), 'Misses')
            .replaceAll(RegExp(r'\bDr\.\b', caseSensitive: false), 'Doctor')
            .replaceAll(
              RegExp(r'\bProf\.\b', caseSensitive: false),
              'Professor',
            )
            .replaceAll(RegExp(r'\bvs\.\b', caseSensitive: false), 'versus')
            .replaceAll(RegExp(r'\betc\.\b', caseSensitive: false), 'etcetera')
            // Handle numbers for better pronunciation
            .replaceAll(RegExp(r'\b(\d+)%'), r'\1 percent')
            .replaceAll(RegExp(r'\b(\d+)st\b'), r'\1 first')
            .replaceAll(RegExp(r'\b(\d+)nd\b'), r'\1 second')
            .replaceAll(RegExp(r'\b(\d+)rd\b'), r'\1 third')
            .replaceAll(RegExp(r'\b(\d+)th\b'), r'\1 th')
            // Clean up any remaining artifacts
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    return enhanced;
  }
}
