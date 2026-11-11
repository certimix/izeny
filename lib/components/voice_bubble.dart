import 'package:flutter/material.dart';
import 'package:social_media_app/utils/audio_helper.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int? initialDuration;

  const VoiceMessageBubble({
    Key? key,
    required this.audioUrl,
    required this.isMe,
    this.initialDuration,
  }) : super(key: key);

  @override
  _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  static AppAudioPlayer? _activePlayer;
  static String? _activeUrl;
  static VoidCallback? _stopActiveListener;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.initialDuration != null && widget.initialDuration! > 0) {
      _duration = Duration(seconds: widget.initialDuration!);
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _activePlayer?.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    // Stop any previously playing audio
    if (_stopActiveListener != null) {
      _stopActiveListener!();
    }
    _activePlayer?.stop();

    final player = AppAudioPlayer();
    _activePlayer = player;
    _activeUrl = widget.audioUrl;
    _stopActiveListener = () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    };

    setState(() {
      _isPlaying = true;
    });

    player.play(
      widget.audioUrl,
      onProgress: (pos, dur) {
        if (mounted) {
          setState(() {
            _position = pos;
            if (dur > Duration.zero) _duration = dur;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = widget.isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1E293B));
    final secondaryColor = widget.isMe
        ? Colors.white.withOpacity(0.7)
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    final double progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause circular button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.25)
                    : const Color(0xFF2563EB).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : const Color(0xFF2563EB),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform & Time column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isMe ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Duration and Voice icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPlaying
                          ? _formatDuration(_position)
                          : _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 13,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Voz',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
