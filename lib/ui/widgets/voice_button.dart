import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/tts_service.dart';

class VoiceButton extends StatefulWidget {
  final String text;
  final int? pageIndex;
  final VoidCallback? onStateChanged;
  final EdgeInsetsGeometry? margin;
  final double? size;

  const VoiceButton({
    super.key,
    required this.text,
    this.pageIndex,
    this.onStateChanged,
    this.margin,
    this.size,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  TtsState _currentState = TtsState.stopped;

  // Global speed control - shared across all VoiceButton instances
  static final List<double> speedOptions = [1.0, 1.25, 1.5, 1.75, 2.0];
  static int globalSpeedIndex = 0;
  static final Set<_VoiceButtonState> _activeInstances = <_VoiceButtonState>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize TTS service and apply current speed
    _initializeTtsAndApplySpeed();

    // Register this instance for global speed updates
    _activeInstances.add(this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Unregister this instance
    _activeInstances.remove(this);
    super.dispose();
  }

  void _onButtonPressed() async {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _currentState = _ttsService.state;
    });

    switch (_currentState) {
      case TtsState.stopped:
        await _ttsService.speak(widget.text, pageIndex: widget.pageIndex);
        break;
      case TtsState.playing:
        await _ttsService.pause();
        break;
      case TtsState.paused:
        await _ttsService.resume();
        break;
    }

    setState(() {
      _currentState = _ttsService.state;
    });

    widget.onStateChanged?.call();
  }

  void _onStopPressed() async {
    await _ttsService.stop();
    setState(() {
      _currentState = _ttsService.state;
    });
    widget.onStateChanged?.call();
  }

  Future<void> _initializeTtsAndApplySpeed() async {
    // Initialize TTS service
    await _ttsService.initialize();
    _currentState = _ttsService.state;

    // Apply the current global speed setting
    await _setCurrentSpeed();
  }

  void _onSpeedPressed() async {
    // Cycle to next speed
    globalSpeedIndex = (globalSpeedIndex + 1) % speedOptions.length;
    await _setCurrentSpeed();

    // Notify all active instances to update their UI
    _notifyAllInstances();

    setState(() {});
  }

  Future<void> _setCurrentSpeed() async {
    final speed = speedOptions[globalSpeedIndex];
    debugPrint(
      'VoiceButton: Setting speed to $speed (index: $globalSpeedIndex)',
    );
    await _ttsService.setSpeechRate(speed);
  }

  /// Notify all active VoiceButton instances to update their UI
  static void _notifyAllInstances() {
    for (final instance in _activeInstances) {
      if (instance.mounted) {
        instance.setState(() {});
      }
    }
  }

  String _getSpeedText() {
    final speed = speedOptions[globalSpeedIndex];
    if (speed == speed.toInt()) {
      return '${speed.toInt()}x';
    } else {
      return '${speed}x';
    }
  }

  IconData _getIcon() {
    switch (_currentState) {
      case TtsState.playing:
        return FontAwesomeIcons.pause;
      case TtsState.paused:
        return FontAwesomeIcons.play;
      case TtsState.stopped:
        return FontAwesomeIcons.volumeHigh;
    }
  }

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (_currentState) {
      case TtsState.playing:
        return theme.colorScheme.primary;
      case TtsState.paused:
        return theme.colorScheme.secondary;
      case TtsState.stopped:
        return theme.colorScheme.onSurface.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size ?? 48.0;

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stop button (only show when playing or paused)
          // Keep Stop button on left side to avoid accidental stop (most people are right handed, so left side means less likely to press)
          if (_currentState != TtsState.stopped) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onStopPressed,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    FontAwesomeIcons.stop,
                    color: theme.colorScheme.onErrorContainer,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 30),
          ],

          // Main voice button
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onButtonPressed,
                    borderRadius: BorderRadius.circular(size / 2),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(size / 2),
                        border: Border.all(color: _getColor(context), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getColor(context),
                        size: size * 0.4,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 20),

          // Speed control button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onSpeedPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.onSecondaryContainer.withOpacity(
                      0.3,
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.gauge,
                      size: 14,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getSpeedText(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceControls extends StatefulWidget {
  final String text;
  final int? pageIndex;
  final VoidCallback? onStateChanged;

  const VoiceControls({
    super.key,
    required this.text,
    this.pageIndex,
    this.onStateChanged,
  });

  @override
  State<VoiceControls> createState() => _VoiceControlsState();
}

class _VoiceControlsState extends State<VoiceControls> {
  final TtsService _ttsService = TtsService();
  double _volume = 0.8;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _updateSpeechRate(double rate) async {
    // Find the closest speed option index
    int closestIndex = 0;
    double minDifference = double.infinity;
    for (int i = 0; i < _VoiceButtonState.speedOptions.length; i++) {
      double difference = (rate - _VoiceButtonState.speedOptions[i]).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }

    // Update global speed state
    _VoiceButtonState.globalSpeedIndex = closestIndex;
    await _ttsService.setSpeechRate(rate);

    // Notify all VoiceButton instances to update their UI
    _VoiceButtonState._notifyAllInstances();

    setState(() {});
  }

  double get _speechRate =>
      _VoiceButtonState.speedOptions[_VoiceButtonState.globalSpeedIndex];

  void _updateVolume(double volume) async {
    setState(() {
      _volume = volume;
    });
    await _ttsService.setVolume(volume);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main voice button
          VoiceButton(
            text: widget.text,
            pageIndex: widget.pageIndex,
            onStateChanged: widget.onStateChanged,
            margin: const EdgeInsets.all(12),
          ),

          // Expandable controls
          if (_showControls) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Speech rate control
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.gauge,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text('Speed', style: theme.textTheme.labelMedium),
                      Expanded(
                        child: Slider(
                          value: _speechRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: _updateSpeechRate,
                        ),
                      ),
                      Text(
                        '${(_speechRate * 100).round()}%',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Voice quality indicator
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.microphone,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enhanced Voice',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        FontAwesomeIcons.checkCircle,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Volume control
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.volumeHigh,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text('Volume', style: theme.textTheme.labelMedium),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: _updateVolume,
                        ),
                      ),
                      Text(
                        '${(_volume * 100).round()}%',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Toggle controls button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleControls,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(
                  _showControls
                      ? FontAwesomeIcons.chevronUp
                      : FontAwesomeIcons.chevronDown,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
