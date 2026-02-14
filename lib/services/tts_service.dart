import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, paused, stopped }

class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  String? _currentText;
  String? _originalText; // Store original text before cleaning
  int? _currentPageIndex;
  double _currentSpeechRate = 0.8; // Default speed

  // Word position tracking for scrubbing
  int? _currentWordStart;
  int? _currentWordEnd;
  Set<int> _wordsRead =
      {}; // Track read word positions (character indices in clean text)
  int _seekOffset = 0; // Offset when seeking to a position
  bool _isSeeking = false; // True during seek (keeps progress bar visible)
  void Function(int? start, int? end)? onPositionChanged;

  // Getters
  TtsState get state => _state;
  bool get isSeeking => _isSeeking;
  String? get currentText => _currentText;
  String? get originalText => _originalText;
  int? get currentPageIndex => _currentPageIndex;
  int? get currentWordStart => _currentWordStart;
  int? get currentWordEnd => _currentWordEnd;
  Set<int> get wordsRead => _wordsRead;
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
        _originalText = null;
        _currentPageIndex = null;
        _currentWordStart = null;
        _currentWordEnd = null;
        _seekOffset = 0;
        onPositionChanged?.call(null, null);
        notifyListeners();
      });

      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _state = TtsState.stopped;
        notifyListeners();
      });

      // Set up pause handler
      _flutterTts.setPauseHandler(() {
        _state = TtsState.paused;
        notifyListeners();
      });

      // Set up continue handler
      _flutterTts.setContinueHandler(() {
        _state = TtsState.playing;
        notifyListeners();
      });

      // Set up progress handler for word-level tracking
      _setupProgressHandler();

      // Apply enhanced speech settings for more natural voice
      await setEnhancedSpeechSettings();
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> speak(String text, {int? pageIndex, int? seekOffset}) async {
    try {
      // Stop any current speech
      await stop();

      // Ensure speech rate is applied before speaking
      await _flutterTts.setSpeechRate(_currentSpeechRate);

      // Clean and enhance the text for more natural speech
      String cleanText = _enhanceTextForNaturalSpeech(text);

      // Store original text for position mapping
      _originalText = text;

      // Reset position tracking
      _currentWordStart = null;
      _currentWordEnd = null;
      _seekOffset = seekOffset ?? 0;

      // If seeking, reset wordsRead after the seek position
      if (seekOffset != null && seekOffset > 0) {
        _wordsRead.removeWhere((pos) => pos >= seekOffset);
      } else {
        _wordsRead.clear();
      }

      _currentText = cleanText;
      _currentPageIndex = pageIndex;
      _state = TtsState.playing;
      notifyListeners();

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _state = TtsState.stopped;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      if (_state == TtsState.playing) {
        await _flutterTts.pause();
        _state = TtsState.paused;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_state == TtsState.paused) {
        // Ensure speech rate is applied before resuming
        await _flutterTts.setSpeechRate(_currentSpeechRate);
        await _flutterTts.speak(_currentText ?? '');
        _state = TtsState.playing;
        notifyListeners();
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
      _originalText = null;
      _currentPageIndex = null;
      _currentWordStart = null;
      _currentWordEnd = null;
      _seekOffset = 0;
      _wordsRead.clear();
      onPositionChanged?.call(null, null);
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 2.0);
      _currentSpeechRate = clampedRate;

      // If TTS is currently playing, we need to stop and restart with new rate
      // This ensures speed changes apply immediately
      final wasPlaying = _state == TtsState.playing;
      final wasPaused = _state == TtsState.paused;
      final textToRestart = wasPlaying || wasPaused ? _currentText : null;

      if (wasPlaying || wasPaused) {
        await stop();
      }

      await _flutterTts.setSpeechRate(clampedRate);
      debugPrint('TTS Speech rate set to: $clampedRate');

      // Restart speech with new rate if it was playing
      if (wasPlaying && textToRestart != null) {
        await speak(textToRestart, pageIndex: _currentPageIndex);
      }
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

  @override
  // ignore: must_call_super
  void dispose() {
    // Singleton - do not call super.dispose() to allow reuse across screens.
    // Fire-and-forget cleanup when screen disposes.
    stop();
  }

  /// Returns text cleaned for TTS (used by TtsProgressBar for progress calculation)
  static String cleanTextForProgress(String text) {
    // Remove markdown formatting while preserving natural pauses
    String enhanced = text
        .replaceAll(RegExp(r'!\[[^\]]*\]\s*\([^)]*\)'), ' ') // Images
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

  /// Enhance text for more natural speech synthesis
  String _enhanceTextForNaturalSpeech(String text) {
    return cleanTextForProgress(text);
  }

  /// Set up progress handler for word-level position tracking
  void _setupProgressHandler() {
    try {
      _flutterTts.setProgressHandler((
        String text,
        int start,
        int end,
        String word,
      ) {
        // Adjust positions based on seek offset
        final adjustedStart = _seekOffset + start;
        final adjustedEnd = _seekOffset + end;

        _currentWordStart = adjustedStart;
        _currentWordEnd = adjustedEnd;

        // Track all character positions in the current word range as read
        for (int i = adjustedStart; i < adjustedEnd; i++) {
          _wordsRead.add(i);
        }

        // Notify listeners of position change
        onPositionChanged?.call(adjustedStart, adjustedEnd);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error setting up progress handler: $e');
      // ProgressHandler may not be supported on all platforms/versions
      // Continue without it
    }
  }

  /// Seek to a specific position in the original text
  /// Position should be in the cleaned text (as returned by _enhanceTextForNaturalSpeech)
  Future<void> seekToPosition(int position, {int? pageIndex}) async {
    if (_currentText == null || _originalText == null) {
      debugPrint('Cannot seek: no text is currently loaded');
      return;
    }

    _isSeeking = true;
    notifyListeners();
    try {
      // Get the cleaned text to find the position
      final cleanedOriginal = cleanTextForProgress(_originalText!);

      // Ensure position is within bounds
      if (position < 0 || position >= cleanedOriginal.length) {
        debugPrint(
          'Seek position $position is out of bounds (0-${cleanedOriginal.length - 1})',
        );
        return;
      }

      // Extract text from the seek position
      final textFromPosition = cleanedOriginal.substring(position);

      if (textFromPosition.isEmpty) {
        debugPrint('No text remaining from position $position');
        return;
      }

      // Stop current playback
      await _flutterTts.stop();

      // Speak from the new position with seek offset
      await speak(textFromPosition, pageIndex: pageIndex, seekOffset: position);
    } catch (e) {
      debugPrint('Error seeking to position: $e');
    } finally {
      _isSeeking = false;
      notifyListeners();
    }
  }
}
