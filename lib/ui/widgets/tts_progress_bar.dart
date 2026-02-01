import 'package:flutter/material.dart';
import '../../services/tts_service.dart';

/// A progress bar widget for TTS playback using Flutter's Slider
/// Shows current position and allows dragging to seek (onChangeEnd only)
class TtsProgressBar extends StatefulWidget {
  final TtsService ttsService;
  final String cleanText; // Clean text for calculating total length
  /// Optional callback when TTS position changes (e.g. to rebuild parent for word highlighting)
  final VoidCallback? onPositionChanged;

  /// Optional page index for multi-page contexts (e.g. reading slides)
  final int? pageIndex;

  const TtsProgressBar({
    super.key,
    required this.ttsService,
    required this.cleanText,
    this.onPositionChanged,
    this.pageIndex,
  });

  @override
  State<TtsProgressBar> createState() => _TtsProgressBarState();
}

class _TtsProgressBarState extends State<TtsProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted && !_isDragging) {
        setState(() {});
      }
      widget.onPositionChanged?.call();
    };
    widget.ttsService.addListener(_listener!);
    widget.ttsService.onPositionChanged = (start, end) {
      widget.onPositionChanged?.call();
    };
  }

  @override
  void dispose() {
    if (_listener != null) {
      widget.ttsService.removeListener(_listener!);
    }
    super.dispose();
  }

  double _getProgress() {
    final currentStart = widget.ttsService.currentWordStart;
    final cleanText = widget.cleanText;

    if (cleanText.isEmpty || currentStart == null) {
      return 0.0;
    }
    final progress = currentStart / cleanText.length;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Permanent when there's content: show whenever we're playing, paused,
    // seeking, or have loaded content. Only hide when fully stopped with
    // no content. isSeeking covers the seek transition (when stop() runs
    // before speak() restarts - that gap caused the slider to disappear).
    if (widget.cleanText.isEmpty) {
      return const SizedBox.shrink();
    }
    if (widget.ttsService.isStopped &&
        !widget.ttsService.isSeeking &&
        widget.ttsService.currentText == null) {
      return const SizedBox.shrink();
    }

    final progress = _isDragging ? _dragValue : _getProgress();
    final currentStart = widget.ttsService.currentWordStart;
    final totalLength = widget.cleanText.length;
    const progressColor = Color(0xFF00BCD4); // Teal/Cyan

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: progressColor,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  thumbColor: progressColor,
                  overlayColor: progressColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: progress,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _isDragging = true;
                      _dragValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    final len = widget.cleanText.length;
                    final position =
                        len > 0 ? (value * len).round().clamp(0, len - 1) : 0;
                    widget.ttsService.seekToPosition(
                      position,
                      pageIndex: widget.pageIndex,
                    );
                    setState(() {
                      _isDragging = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatPosition(currentStart, totalLength),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPosition(int? current, int total) {
    if (current == null) return '0 / $total';
    return '$current / $total';
  }
}
