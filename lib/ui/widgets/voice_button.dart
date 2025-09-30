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

    // Initialize TTS service
    _ttsService.initialize();
    _currentState = _ttsService.state;
  }

  @override
  void dispose() {
    _animationController.dispose();
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
  double _speechRate = 0.5;
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
    setState(() {
      _speechRate = rate;
    });
    await _ttsService.setSpeechRate(rate);
  }

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
